#include "collectors/event_log_channel_catalog.hpp"

#include <chrono>
#include <cstdlib>
#include <iostream>
#include <map>
#include <string>

#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <Windows.h>
#include <winevt.h>

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

void TestChannelTypeMapping() {
  CHECK(ChannelTypeFromEvt(EvtChannelTypeAdmin) == EventLogChannelType::Admin);
  CHECK(ChannelTypeFromEvt(EvtChannelTypeOperational) ==
        EventLogChannelType::Operational);
  CHECK(ChannelTypeFromEvt(EvtChannelTypeAnalytic) ==
        EventLogChannelType::Analytic);
  CHECK(ChannelTypeFromEvt(EvtChannelTypeDebug) == EventLogChannelType::Debug);
  CHECK(ChannelTypeFromEvt(42) == EventLogChannelType::Unknown);
}

void TestOnlyAdminAndOperationalAreTrackable() {
  CHECK(IsTrackableChannelType(EventLogChannelType::Admin));
  CHECK(IsTrackableChannelType(EventLogChannelType::Operational));
  CHECK(!IsTrackableChannelType(EventLogChannelType::Analytic));
  CHECK(!IsTrackableChannelType(EventLogChannelType::Debug));
  CHECK(!IsTrackableChannelType(EventLogChannelType::Unknown));
}

void TestAccessMapping() {
  CHECK(ChannelAccessFromError(ERROR_SUCCESS) == EventLogChannelAccess::Readable);
  CHECK(ChannelAccessFromError(ERROR_ACCESS_DENIED) ==
        EventLogChannelAccess::Denied);
  CHECK(ChannelAccessFromError(ERROR_EVT_CHANNEL_NOT_FOUND) ==
        EventLogChannelAccess::NotFound);
  CHECK(ChannelAccessFromError(ERROR_INVALID_PARAMETER) ==
        EventLogChannelAccess::Error);
}

void TestPathComparisonIgnoresCase() {
  CHECK(ChannelPathEquals("Microsoft-Windows-TaskScheduler/Operational",
                          "microsoft-windows-taskscheduler/OPERATIONAL"));
  CHECK(!ChannelPathEquals("System", "Setup"));
  CHECK(!ChannelPathEquals("System", "System "));
}

void TestSortIgnoresCase() {
  std::vector<EventLogChannelInfo> channels(3);
  channels[0].path = "system";
  channels[1].path = "Application";
  channels[2].path = "Microsoft-Windows-TaskScheduler/Operational";
  SortChannelsByPath(&channels);
  CHECK(channels[0].path == "Application");
  CHECK(channels[1].path == "Microsoft-Windows-TaskScheduler/Operational");
  CHECK(channels[2].path == "system");
}

void TestUnknownChannelIsNotFound() {
  const EventLogChannelInfo info =
      ProbeChannel(L"Pulse-Test-Channel-That-Does-Not-Exist/Operational");
  CHECK(info.access == EventLogChannelAccess::NotFound);
  CHECK(!info.detail.empty());
  CHECK(!info.has_record_count);
}

/// Real enumeration on this PC: every Windows install has a readable System log.
void TestEnumerationOnThisMachine() {
  const auto start = std::chrono::steady_clock::now();
  ChannelEnumeration listed;
  std::string error;
  CHECK(ListTrackableChannels({"System"}, {"Application"}, &listed, &error));
  const auto elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                              std::chrono::steady_clock::now() - start)
                              .count();

  CHECK(!listed.channels.empty());
  CHECK(listed.skipped_channels > 0);  // Windows ships Analytic/Debug channels

  bool saw_system = false;
  std::map<EventLogChannelAccess, int> by_access;
  int disabled = 0;
  int empty = 0;
  for (std::size_t i = 0; i < listed.channels.size(); ++i) {
    const EventLogChannelInfo& c = listed.channels[i];
    CHECK(IsTrackableChannelType(c.type));
    if (i > 0) {
      CHECK(!ChannelPathEquals(listed.channels[i - 1].path, c.path));
    }
    ++by_access[c.access];
    if (!c.enabled) ++disabled;
    if (c.has_record_count && c.record_count == 0) ++empty;
    if (ChannelPathEquals(c.path, "System")) {
      saw_system = true;
      CHECK(c.built_in && !c.tracked);
      CHECK(c.type == EventLogChannelType::Admin);
      CHECK(c.enabled);
      CHECK(c.access == EventLogChannelAccess::Readable);
      CHECK(c.has_record_count);
    }
    if (ChannelPathEquals(c.path, "Application")) {
      CHECK(c.tracked && !c.built_in);
    }
  }
  CHECK(saw_system);

  std::cout << "channels=" << listed.channels.size()
            << " skipped=" << listed.skipped_channels
            << " readable=" << by_access[EventLogChannelAccess::Readable]
            << " denied=" << by_access[EventLogChannelAccess::Denied]
            << " not_found=" << by_access[EventLogChannelAccess::NotFound]
            << " error=" << by_access[EventLogChannelAccess::Error]
            << " disabled=" << disabled << " empty=" << empty
            << " elapsed_ms=" << elapsed_ms << "\n";
}

}  // namespace

int main() {
  TestChannelTypeMapping();
  TestOnlyAdminAndOperationalAreTrackable();
  TestAccessMapping();
  TestPathComparisonIgnoresCase();
  TestSortIgnoresCase();
  TestUnknownChannelIsNotFound();
  TestEnumerationOnThisMachine();
  std::cout << "event_log_channel_catalog_tests OK\n";
  return 0;
}
