#include "collectors/live_channel_subscriptions.hpp"
#include "collectors/tracked_channels.hpp"

#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <map>
#include <string>

#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <Windows.h>

// CI builds Release, where assert() is compiled out; fail loudly instead.
#define CHECK(condition)                                                  \
  do {                                                                    \
    if (!(condition)) {                                                   \
      std::cerr << __FILE__ << ":" << __LINE__ << " CHECK failed: "       \
                << #condition << "\n";                                    \
      std::exit(1);                                                       \
    }                                                                     \
  } while (false)

namespace {

using namespace pulse;
using ipc::EventLogChannelAccess;
using ipc::EventLogChannelInfo;
using ipc::EventLogChannelType;
using ipc::TrackedChannelStatus;

EventLogChannelInfo Channel(std::string path, EventLogChannelType type,
                            bool enabled, EventLogChannelAccess access) {
  EventLogChannelInfo info;
  info.path = std::move(path);
  info.type = type;
  info.enabled = enabled;
  info.access = access;
  return info;
}

/// A fake PC: the probe answers from this table, NotFound otherwise.
ChannelProber FakeProber() {
  static const std::map<std::string, EventLogChannelInfo> kChannels = {
      {"task", Channel("Microsoft-Windows-TaskScheduler/Operational",
                       EventLogChannelType::Operational, true,
                       EventLogChannelAccess::Readable)},
      {"disabled", Channel("Microsoft-Windows-DNS-Client/Operational",
                           EventLogChannelType::Operational, false,
                           EventLogChannelAccess::Readable)},
      {"denied", Channel("Microsoft-Windows-LSA/Operational",
                         EventLogChannelType::Operational, true,
                         EventLogChannelAccess::Denied)},
      // ProbeChannel leaves access Unknown for Analytic / Debug channels.
      {"analytic", Channel("Microsoft-Windows-Kernel-File/Analytic",
                           EventLogChannelType::Analytic, false,
                           EventLogChannelAccess::Unknown)},
      {"debug", Channel("Microsoft-Windows-Kernel-Power/Diagnostic",
                        EventLogChannelType::Debug, false,
                        EventLogChannelAccess::Unknown)},
  };
  return [](const std::string& path) {
    for (const auto& [key, info] : kChannels) {
      if (path == key || path == info.path) return info;
    }
    EventLogChannelInfo missing;
    missing.path = path;
    missing.access = EventLogChannelAccess::NotFound;
    missing.detail = "The specified channel could not be found.";
    return missing;
  };
}

TrackedChannelStatus StatusOf(const ipc::TrackedChannels& out,
                              const std::string& path) {
  for (const auto& r : out.results) {
    if (r.path == path) return r.status;
  }
  return TrackedChannelStatus::Unspecified;
}

void TestValidationStatuses() {
  ipc::TrackedChannels out;
  ValidateTrackedChannels(
      {"task", "disabled", "denied", "analytic", "debug", "missing", "System"},
      {"System", "Application"}, FakeProber(), kMaxTrackedChannels, &out);
  CHECK(out.max_tracked == kMaxTrackedChannels);
  CHECK(StatusOf(out, "task") == TrackedChannelStatus::Tracked);
  CHECK(StatusOf(out, "disabled") == TrackedChannelStatus::Disabled);
  CHECK(StatusOf(out, "denied") == TrackedChannelStatus::AccessDenied);
  CHECK(StatusOf(out, "analytic") == TrackedChannelStatus::UnsupportedType);
  CHECK(StatusOf(out, "debug") == TrackedChannelStatus::UnsupportedType);
  CHECK(StatusOf(out, "missing") == TrackedChannelStatus::NotFound);
  CHECK(StatusOf(out, "System") == TrackedChannelStatus::BuiltIn);
  // Only accepted channels are kept, under Windows' spelling.
  CHECK(out.tracked.size() == 2);
  CHECK(out.tracked[0] == "Microsoft-Windows-TaskScheduler/Operational");
  CHECK(out.tracked[1] == "Microsoft-Windows-DNS-Client/Operational");
}

void TestValidationDropsDuplicatesAndBlanks() {
  ipc::TrackedChannels out;
  ValidateTrackedChannels(
      {"Microsoft-Windows-TaskScheduler/Operational", "  ",
       "microsoft-windows-taskscheduler/operational", "system"},
      {"System"}, FakeProber(), kMaxTrackedChannels, &out);
  CHECK(out.results.size() == 2);
  CHECK(out.tracked.size() == 1);
  CHECK(out.results[1].status == TrackedChannelStatus::BuiltIn);
}

void TestValidationCap() {
  ipc::TrackedChannels out;
  ValidateTrackedChannels({"task", "disabled", "missing"}, {}, FakeProber(), 1,
                          &out);
  CHECK(out.tracked.size() == 1);
  CHECK(StatusOf(out, "task") == TrackedChannelStatus::Tracked);
  CHECK(StatusOf(out, "disabled") == TrackedChannelStatus::OverLimit);
  // Rejected channels do not use up the cap.
  CHECK(StatusOf(out, "missing") == TrackedChannelStatus::NotFound);
}

void TestJsonRoundTrip() {
  const std::vector<std::string> channels = {
      "Microsoft-Windows-TaskScheduler/Operational", "Odd \"quoted\" \\ name",
      "Caf\xC3\xA9/Operational"};
  std::vector<std::string> parsed;
  std::string error;
  CHECK(ParseTrackedChannels(SerializeTrackedChannels(channels), &parsed, &error));
  CHECK(parsed == channels);

  CHECK(ParseTrackedChannels(SerializeTrackedChannels({}), &parsed, &error));
  CHECK(parsed.empty());

  CHECK(ParseTrackedChannels(R"({"channels":["aé\/b"]})", &parsed, &error));
  CHECK(parsed.size() == 1 && parsed[0] == "a\xC3\xA9/b");

  CHECK(!ParseTrackedChannels(R"({"version":1})", &parsed, &error));
  CHECK(!ParseTrackedChannels(R"({"channels":["a",)", &parsed, &error));
  CHECK(!ParseTrackedChannels(R"({"channels":"a"})", &parsed, &error));
  CHECK(parsed.empty());
}

void TestStoreSaveAndLoad() {
  const auto dir = std::filesystem::temp_directory_path() /
                   ("pulse_tracked_channels_test_" +
                    std::to_string(GetCurrentProcessId()));
  std::filesystem::remove_all(dir);
  const TrackedChannelsStore store((dir / L"tracked_channels.json").wstring());

  std::vector<std::string> loaded = {"stale"};
  std::string error;
  CHECK(store.Load(&loaded, &error));  // missing file → empty list
  CHECK(loaded.empty());

  CHECK(store.Save({"A/Operational", "B/Admin"}, &error));
  CHECK(store.Save({"B/Admin"}, &error));  // replaces the existing file
  CHECK(store.Load(&loaded, &error));
  CHECK(loaded == std::vector<std::string>{"B/Admin"});
  CHECK(!std::filesystem::exists(dir / L"tracked_channels.json.tmp"));
  std::filesystem::remove_all(dir);
}

/// Records Start / Stop calls instead of subscribing to Windows.
struct FakeLog {
  std::vector<std::wstring> started;
  std::vector<std::wstring> stopped;
  std::vector<std::wstring> refuse;  // Start() fails for these
};

class FakeSource final : public LiveChannelSource {
 public:
  explicit FakeSource(FakeLog* log) : log_(log) {}
  bool Start(const std::wstring& channel, EventCallback) override {
    for (const auto& r : log_->refuse) {
      if (r == channel) return false;
    }
    channel_ = channel;
    log_->started.push_back(channel);
    return true;
  }
  void Stop() override {
    if (!channel_.empty()) log_->stopped.push_back(channel_);
    channel_.clear();
  }

 private:
  FakeLog* log_;
  std::wstring channel_;
};

LiveChannelSourceFactory FakeFactory(FakeLog* log) {
  return [log] { return std::make_unique<FakeSource>(log); };
}

void TestSubscriptionsDiffWhileRunning() {
  FakeLog log;
  LiveChannelSubscriptions subs(FakeFactory(&log));
  subs.SetTracked({L"Task/Operational"});
  CHECK(log.started.empty());  // nothing until live starts

  CHECK(subs.Start({L"System", L"Application"}, [](EventRecord) {}));
  CHECK(log.started.size() == 3);
  CHECK(subs.ActiveChannels().front() == L"System");

  // Add one, keep one: only the new channel is subscribed.
  subs.SetTracked({L"task/OPERATIONAL", L"Dns/Operational"});
  CHECK(log.started.size() == 4 && log.started.back() == L"Dns/Operational");
  CHECK(log.stopped.empty());

  // Remove one: only it is cancelled; built-in channels stay.
  subs.SetTracked({L"Dns/Operational"});
  CHECK(log.stopped.size() == 1 && log.stopped[0] == L"Task/Operational");
  CHECK(subs.ActiveChannels().size() == 3);

  // A tracked name that is also built in never cancels the built-in one.
  subs.SetTracked({L"System"});
  CHECK(log.stopped.size() == 2 && log.stopped[1] == L"Dns/Operational");
  CHECK(subs.ActiveChannels().size() == 2);

  subs.Stop();
  CHECK(!subs.running());
  CHECK(log.stopped.size() == 4);
  CHECK(subs.ActiveChannels().empty());
}

void TestRestartAndFailures() {
  FakeLog log;
  log.refuse = {L"Denied/Operational"};
  LiveChannelSubscriptions subs(FakeFactory(&log));
  subs.SetTracked({L"Task/Operational", L"Denied/Operational"});
  CHECK(subs.Start({L"System"}, [](EventRecord) {}));
  CHECK(subs.ActiveChannels().size() == 2);  // the refused one is skipped

  subs.Restart(L"Task/Operational");
  CHECK(log.stopped.size() == 1 && log.stopped[0] == L"Task/Operational");
  CHECK(log.started.back() == L"Task/Operational");
  CHECK(subs.ActiveChannels().size() == 2);

  subs.Restart(L"System");  // built-in: not restarted
  CHECK(log.stopped.size() == 1);
  subs.Stop();

  FakeLog none;
  none.refuse = {L"System"};
  LiveChannelSubscriptions empty(FakeFactory(&none));
  CHECK(!empty.Start({L"System"}, [](EventRecord) {}));
  CHECK(!empty.running());
}

}  // namespace

int main() {
  TestValidationStatuses();
  TestValidationDropsDuplicatesAndBlanks();
  TestValidationCap();
  TestJsonRoundTrip();
  TestStoreSaveAndLoad();
  TestSubscriptionsDiffWhileRunning();
  TestRestartAndFailures();
  std::cout << "tracked_channels_tests OK\n";
  return 0;
}
