#include "collectors/live_channel_subscriptions.hpp"

#include "collectors/event_log_subscriber.hpp"
#include "logging/logger.hpp"
#include "windows/wevt_helpers.hpp"

#include <algorithm>
#include <utility>

namespace pulse {
namespace {

class EventLogSubscriberSource final : public LiveChannelSource {
 public:
  bool Start(const std::wstring& channel, EventCallback callback) override {
    return subscriber_.Start(channel, std::move(callback));
  }
  void Stop() override { subscriber_.Stop(); }
  std::uint64_t reconnect_count() const override {
    return subscriber_.reconnect_count();
  }

 private:
  EventLogSubscriber subscriber_;
};

wchar_t AsciiLower(wchar_t c) {
  return (c >= L'A' && c <= L'Z') ? static_cast<wchar_t>(c - L'A' + L'a') : c;
}

bool ContainsChannel(const std::vector<std::wstring>& channels,
                     const std::wstring& channel) {
  return std::any_of(channels.begin(), channels.end(),
                     [&](const std::wstring& c) {
                       return WideChannelPathEquals(c, channel);
                     });
}

}  // namespace

bool WideChannelPathEquals(const std::wstring& a, const std::wstring& b) {
  return a.size() == b.size() &&
         std::equal(a.begin(), a.end(), b.begin(), [](wchar_t x, wchar_t y) {
           return AsciiLower(x) == AsciiLower(y);
         });
}

LiveChannelSourceFactory EventLogSubscriberFactory() {
  return [] { return std::make_unique<EventLogSubscriberSource>(); };
}

LiveChannelSubscriptions::LiveChannelSubscriptions(
    LiveChannelSourceFactory factory)
    : factory_(std::move(factory)) {}

LiveChannelSubscriptions::~LiveChannelSubscriptions() { Stop(); }

bool LiveChannelSubscriptions::Start(const std::vector<std::wstring>& built_in,
                                     LiveChannelSource::EventCallback callback) {
  std::lock_guard lock(mu_);
  if (running_) {
    return !active_.empty();
  }
  callback_ = std::move(callback);
  for (const std::wstring& channel : built_in) {
    SubscribeLocked(channel, true);
  }
  for (const std::wstring& channel : tracked_) {
    if (!ContainsChannel(built_in, channel)) {
      SubscribeLocked(channel, false);
    }
  }
  running_ = !active_.empty();
  if (!running_) {
    callback_ = nullptr;
  }
  return running_;
}

void LiveChannelSubscriptions::Stop() {
  std::vector<Subscription> stopping;
  {
    std::lock_guard lock(mu_);
    running_ = false;
    callback_ = nullptr;
    stopping.swap(active_);
  }
  // Outside the lock: Stop() waits for the subscriber's own worker.
  for (auto& sub : stopping) {
    if (sub.source) {
      sub.source->Stop();
    }
  }
}

void LiveChannelSubscriptions::SetTracked(
    const std::vector<std::wstring>& tracked) {
  std::vector<std::unique_ptr<LiveChannelSource>> removed;
  {
    std::lock_guard lock(mu_);
    if (running_) {
      // Cancel tracked channels that are no longer in the list.
      for (const std::wstring& old_channel : tracked_) {
        if (!ContainsChannel(tracked, old_channel)) {
          if (auto source = TakeLocked(old_channel)) {
            removed.push_back(std::move(source));
          }
        }
      }
      // Subscribe channels that are new and not already active.
      for (const std::wstring& channel : tracked) {
        const bool active = std::any_of(
            active_.begin(), active_.end(), [&](const Subscription& s) {
              return WideChannelPathEquals(s.channel, channel);
            });
        if (!active) {
          SubscribeLocked(channel, false);
        }
      }
    }
    tracked_ = tracked;
  }
  for (auto& source : removed) {
    source->Stop();
  }
}

void LiveChannelSubscriptions::Restart(const std::wstring& channel) {
  std::unique_ptr<LiveChannelSource> old;
  {
    std::lock_guard lock(mu_);
    if (!running_ || !ContainsChannel(tracked_, channel)) {
      return;
    }
    old = TakeLocked(channel);
  }
  if (old) {
    old->Stop();
  }
  std::lock_guard lock(mu_);
  // Stop() or SetTracked() may have run while the old source was stopping.
  if (running_ && ContainsChannel(tracked_, channel)) {
    SubscribeLocked(channel, false);
  }
}

bool LiveChannelSubscriptions::running() const {
  std::lock_guard lock(mu_);
  return running_;
}

std::vector<std::wstring> LiveChannelSubscriptions::ActiveChannels() const {
  std::lock_guard lock(mu_);
  std::vector<std::wstring> channels;
  channels.reserve(active_.size());
  for (const auto& sub : active_) {
    if (sub.built_in) channels.push_back(sub.channel);
  }
  for (const auto& sub : active_) {
    if (!sub.built_in) channels.push_back(sub.channel);
  }
  return channels;
}

std::vector<std::wstring> LiveChannelSubscriptions::TrackedChannels() const {
  std::lock_guard lock(mu_);
  return tracked_;
}

std::uint64_t LiveChannelSubscriptions::ReconnectCount() const {
  std::lock_guard lock(mu_);
  std::uint64_t total = 0;
  for (const auto& sub : active_) {
    if (sub.source) total += sub.source->reconnect_count();
  }
  return total;
}

bool LiveChannelSubscriptions::SubscribeLocked(const std::wstring& channel,
                                               bool built_in) {
  auto source = factory_ ? factory_() : nullptr;
  if (!source || !callback_) {
    return false;
  }
  if (!source->Start(channel, callback_)) {
    Logger::Instance().Warn(
        "LiveChannelSubscriptions",
        "Live subscribe skipped for " + wevt::WideToUtf8(channel));
    return false;
  }
  Logger::Instance().Info(
      "LiveChannelSubscriptions",
      std::string(built_in ? "Subscribed built-in channel " :
                             "Subscribed tracked channel ") +
          wevt::WideToUtf8(channel));
  active_.push_back(Subscription{channel, built_in, std::move(source)});
  return true;
}

std::unique_ptr<LiveChannelSource> LiveChannelSubscriptions::TakeLocked(
    const std::wstring& channel) {
  const auto it = std::find_if(
      active_.begin(), active_.end(), [&](const Subscription& s) {
        return !s.built_in && WideChannelPathEquals(s.channel, channel);
      });
  if (it == active_.end()) {
    return nullptr;
  }
  auto source = std::move(it->source);
  active_.erase(it);
  Logger::Instance().Info(
      "LiveChannelSubscriptions",
      "Cancelled tracked channel " + wevt::WideToUtf8(channel));
  return source;
}

}  // namespace pulse
