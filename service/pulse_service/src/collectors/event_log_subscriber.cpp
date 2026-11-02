#include "collectors/event_log_subscriber.hpp"

#include "collectors/event_log_collector.hpp"
#include "logging/logger.hpp"
#include "windows/wevt_helpers.hpp"

#include <utility>

#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <Windows.h>
#include <winevt.h>

namespace pulse {
namespace {

constexpr DWORD kReconnectDelayMs = 2000;

struct SubscriberCallbackState {
  EventLogSubscriber* self = nullptr;
  std::shared_ptr<SubscriberCallbackState> keep_alive;
};

DWORD WINAPI SubscribeNotify(EVT_SUBSCRIBE_NOTIFY_ACTION action,
                             PVOID context,
                             EVT_HANDLE event_handle) {
  auto* state = static_cast<SubscriberCallbackState*>(context);
  if (state == nullptr || state->self == nullptr) {
    if (action == EvtSubscribeActionDeliver && event_handle != nullptr) {
      EvtClose(event_handle);
    }
    return ERROR_SUCCESS;
  }

  EventLogSubscriber* self = state->self;

  if (action == EvtSubscribeActionError) {
    const DWORD status =
        static_cast<DWORD>(reinterpret_cast<uintptr_t>(event_handle));
    self->RequestReconnect(status);
    return ERROR_SUCCESS;
  }

  if (action == EvtSubscribeActionDeliver) {
    // Do NOT EvtClose(event_handle): Wevtapi owns it for the callback duration
    // (see EVT_SUBSCRIBE_CALLBACK docs). Closing it breaks the subscription.
    self->DeliverEvent(event_handle);
    return ERROR_SUCCESS;
  }

  return ERROR_SUCCESS;
}

}  // namespace

EventLogSubscriber::EventLogSubscriber() = default;

EventLogSubscriber::~EventLogSubscriber() { Stop(); }

bool EventLogSubscriber::Start(const std::wstring& channel,
                               EventCallback callback) {
  if (channel.empty() || !callback) {
    return false;
  }

  std::lock_guard lock(mu_);
  channel_ = channel;
  callback_ = std::move(callback);
  running_ = true;

  if (subscription_ != nullptr) {
    return true;
  }
  return StartSubscriptionLocked();
}

void EventLogSubscriber::Stop() {
  void* subscription = nullptr;
  {
    std::lock_guard lock(mu_);
    running_ = false;
    reconnect_requested_ = false;
    subscription = std::exchange(subscription_, nullptr);
  }
  // Close outside mu_: a callback in flight takes mu_ in DeliverEvent, so
  // holding it here could deadlock if EvtClose waits for that callback.
  // Tracked channels are stopped while the service runs (ADR-016).
  if (subscription != nullptr) {
    EvtClose(static_cast<EVT_HANDLE>(subscription));
  }
  {
    std::lock_guard lock(mu_);
    StopSubscriptionLocked();
    callback_ = nullptr;
  }
  if (reconnect_thread_.joinable()) {
    reconnect_thread_.join();
  }
}

bool EventLogSubscriber::StartSubscriptionLocked() {
  DWORD error = ERROR_SUCCESS;
  wevt::EvtHandle context = wevt::CreateSystemRenderContext(&error);
  if (!context) {
    Logger::Instance().Error(
        "EventLogSubscriber",
        "EvtCreateRenderContext failed: " + wevt::FormatWin32Error(error));
    return false;
  }

  auto state = std::make_shared<SubscriberCallbackState>();
  state->self = this;
  state->keep_alive = state;

  EVT_HANDLE raw =
      EvtSubscribe(nullptr, nullptr, channel_.c_str(), L"*", nullptr,
                   state.get(), SubscribeNotify, EvtSubscribeToFutureEvents);
  if (raw == nullptr) {
    const DWORD err = GetLastError();
    Logger::Instance().Error(
        "EventLogSubscriber",
        "EvtSubscribe failed: " + wevt::FormatWin32Error(err));
    state->keep_alive.reset();
    return false;
  }

  render_context_ = context.release();
  subscription_ = raw;
  callback_state_ = state;

  Logger::Instance().Info(
      "EventLogSubscriber",
      "EvtSubscribe Active on " + wevt::WideToUtf8(channel_));
  return true;
}

void EventLogSubscriber::StopSubscriptionLocked() {
  if (subscription_ != nullptr) {
    EvtClose(static_cast<EVT_HANDLE>(subscription_));
    subscription_ = nullptr;
  }
  if (render_context_ != nullptr) {
    EvtClose(static_cast<EVT_HANDLE>(render_context_));
    render_context_ = nullptr;
  }
  if (callback_state_) {
    auto* state = static_cast<SubscriberCallbackState*>(callback_state_.get());
    state->self = nullptr;
    state->keep_alive.reset();
    callback_state_.reset();
  }
}

void EventLogSubscriber::DeliverEvent(void* event_handle) {
  EventCallback cb;
  void* render_ctx = nullptr;
  {
    std::lock_guard lock(mu_);
    if (!running_) {
      return;
    }
    cb = callback_;
    render_ctx = render_context_;
  }
  if (!cb || render_ctx == nullptr || event_handle == nullptr) {
    return;
  }

  auto parsed = EventLogCollector::ParseEvtHandle(event_handle, render_ctx);
  if (!parsed) {
    Logger::Instance().Warn("EventLogSubscriber",
                            "Event Received but parse failed");
    return;
  }
  Logger::Instance().Debug(
      "EventLogSubscriber",
      std::string("Event Received (Wevtapi callback) event_id=") +
          (parsed->event_id ? std::to_string(*parsed->event_id) : "0"));
  try {
    cb(std::move(*parsed));
  } catch (...) {
    Logger::Instance().Warn("EventLogSubscriber", "Live event callback threw");
  }
}

void EventLogSubscriber::RequestReconnect(unsigned long status) {
  Logger::Instance().Warn(
      "EventLogSubscriber",
      "Subscription error, will reconnect: " +
          wevt::FormatWin32Error(static_cast<DWORD>(status)));

  if (!running_.load()) {
    return;
  }
  if (reconnect_requested_.exchange(true)) {
    return;
  }

  if (reconnect_thread_.joinable()) {
    reconnect_thread_.join();
  }
  reconnect_thread_ = std::thread([this] { ReconnectWorker(); });
}

void EventLogSubscriber::ReconnectWorker() {
  while (running_.load()) {
    Sleep(kReconnectDelayMs);
    if (!running_.load()) {
      break;
    }

    {
      std::lock_guard lock(mu_);
      if (!running_) {
        break;
      }
      StopSubscriptionLocked();
      if (StartSubscriptionLocked()) {
        reconnect_requested_ = false;
        ++reconnect_count_;
        Logger::Instance().Info("EventLogSubscriber",
                                "Subscription reconnected");
        return;
      }
    }
    Logger::Instance().Warn("EventLogSubscriber",
                            "Reconnect attempt failed; retrying");
  }
  reconnect_requested_ = false;
}

}  // namespace pulse
