#pragma once

#include "models/event_record.hpp"

#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace pulse {

/// One live subscription to one channel. EventLogSubscriber in production;
/// a fake in tests.
class LiveChannelSource {
 public:
  using EventCallback = std::function<void(EventRecord)>;
  virtual ~LiveChannelSource() = default;
  [[nodiscard]] virtual bool Start(const std::wstring& channel,
                                   EventCallback callback) = 0;
  virtual void Stop() = 0;
  [[nodiscard]] virtual std::uint64_t reconnect_count() const { return 0; }
};

using LiveChannelSourceFactory =
    std::function<std::unique_ptr<LiveChannelSource>()>;

/// A factory that creates EventLogSubscriber-backed sources.
[[nodiscard]] LiveChannelSourceFactory EventLogSubscriberFactory();

/// Live subscriptions for the built-in channels plus the user's tracked ones
/// (ADR-016). Tracked channels can change while live monitoring runs: only the
/// difference is subscribed or cancelled, so other channels keep streaming.
///
/// Thread-safe. The event callback must not call back into this class.
class LiveChannelSubscriptions {
 public:
  explicit LiveChannelSubscriptions(LiveChannelSourceFactory factory);
  ~LiveChannelSubscriptions();

  LiveChannelSubscriptions(const LiveChannelSubscriptions&) = delete;
  LiveChannelSubscriptions& operator=(const LiveChannelSubscriptions&) = delete;

  /// Subscribes `built_in` plus the tracked channels. No-op when running.
  /// Returns false when no channel could be subscribed.
  bool Start(const std::vector<std::wstring>& built_in,
             LiveChannelSource::EventCallback callback);

  /// Cancels every subscription. Idempotent.
  void Stop();

  /// Replaces the tracked list. When running, subscribes added channels and
  /// cancels removed ones; built-in channels are never touched.
  void SetTracked(const std::vector<std::wstring>& tracked);

  /// Cancels and re-creates one tracked subscription (e.g. after the user
  /// enabled the channel). No-op when not running or not tracked.
  void Restart(const std::wstring& channel);

  [[nodiscard]] bool running() const;

  /// Channels with an active subscription, built-in first.
  [[nodiscard]] std::vector<std::wstring> ActiveChannels() const;

  [[nodiscard]] std::vector<std::wstring> TrackedChannels() const;

  /// Sum of subscription reconnects (Diagnostics page).
  [[nodiscard]] std::uint64_t ReconnectCount() const;

 private:
  struct Subscription {
    std::wstring channel;
    bool built_in = false;
    std::unique_ptr<LiveChannelSource> source;
  };

  bool SubscribeLocked(const std::wstring& channel, bool built_in);
  std::unique_ptr<LiveChannelSource> TakeLocked(const std::wstring& channel);

  LiveChannelSourceFactory factory_;
  mutable std::mutex mu_;
  bool running_ = false;
  LiveChannelSource::EventCallback callback_;
  std::vector<std::wstring> tracked_;
  std::vector<Subscription> active_;
};

/// Case-insensitive channel name match for UTF-16 names.
[[nodiscard]] bool WideChannelPathEquals(const std::wstring& a,
                                         const std::wstring& b);

}  // namespace pulse
