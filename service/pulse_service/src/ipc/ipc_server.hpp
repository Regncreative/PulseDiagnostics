#pragma once

#include "collectors/health_metrics_collector.hpp"
#include "collectors/live_channel_subscriptions.hpp"
#include "collectors/tracked_channels.hpp"
#include "inventory/inventory_engine.hpp"
#include "pulse_wire.hpp"

#include <atomic>
#include <deque>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace pulse {

class IpcServer {
 public:
  explicit IpcServer(std::wstring pipe_name, size_t live_queue_capacity = 1000,
                     uint32_t max_pipe_instances = 32);
  ~IpcServer();

  bool Start();
  void Stop();

  /// "Console" or "Windows Service" — set before Start when known.
  void SetRunMode(std::string mode);

  /// Where the user's tracked channels are saved (ADR-016). Set before Start;
  /// without it the list lives in memory only.
  void SetTrackedChannelsPath(std::wstring path);

 private:
  struct ClientConnection {
    void* pipe_handle = nullptr;  // HANDLE
    void* wake_event = nullptr;   // HANDLE — outbound work / shutdown
    std::mutex write_mu;
    std::mutex queue_mu;
    std::deque<ipc::Envelope> outbound;
    size_t queue_capacity = 1000;
    uint64_t dropped = 0;
    std::atomic<bool> alive{true};
    std::atomic<bool> live_enabled{false};
    std::atomic<bool> health_enabled{false};
    std::thread reader;
  };

  void AcceptLoop();
  void ClientReader(std::shared_ptr<ClientConnection> conn);
  bool WriteEnvelopeLocked(const std::shared_ptr<ClientConnection>& conn,
                           const ipc::Envelope& env);
  bool WriteExact(void* pipe, const void* buffer, size_t size);
  void FlushOutbound(const std::shared_ptr<ClientConnection>& conn);
  void EnqueueOutbound(const std::shared_ptr<ClientConnection>& conn,
                       ipc::Envelope env);
  void HandleEnvelope(const std::shared_ptr<ClientConnection>& conn,
                      const ipc::Envelope& env);
  void* CreatePipeInstance();

  void EnsureLiveSubscriber();
  void StopLiveSubscribers();
  void LoadTrackedChannels();
  [[nodiscard]] std::vector<std::wstring> TimelineChannels() const;
  [[nodiscard]] ipc::EventLogChannelList ListChannels(std::string* out_error);
  [[nodiscard]] ipc::TrackedChannels ApplyTrackedChannels(
      const std::vector<std::string>& requested);
  void OnLiveEventRecord(EventRecord record);
  void PushLiveEvent(const ipc::TimelineEvent& event);
  void EnableLiveForClient(const std::shared_ptr<ClientConnection>& conn);
  void DisableLiveForClient(const std::shared_ptr<ClientConnection>& conn);

  void EnsureHealthCollector();
  void EnableHealthForClient(const std::shared_ptr<ClientConnection>& conn);
  void DisableHealthForClient(const std::shared_ptr<ClientConnection>& conn);
  void HealthPushLoop();
  void PushHealthUpdate(const ipc::HealthUpdate& update);

  ipc::DiagnosticsSnapshot BuildDiagnosticsSnapshot();
  void FillServiceProcessMetrics(ipc::DiagnosticsSnapshot* out);
  void FillIpcThroughputRates(ipc::DiagnosticsSnapshot* out);
  void InjectTestEvent();

  std::wstring pipe_name_;
  size_t live_queue_capacity_;
  uint32_t max_pipe_instances_ = 32;
  std::atomic<bool> running_{false};
  std::thread accept_thread_;
  std::mutex clients_mu_;
  std::vector<std::shared_ptr<ClientConnection>> clients_;

  LiveChannelSubscriptions live_channels_{EventLogSubscriberFactory()};

  // Serializes SetTrackedChannels / ListEventLogChannels (ADR-016).
  std::mutex tracked_mu_;
  std::unique_ptr<TrackedChannelsStore> tracked_store_;
  // Tracked channels that were disabled when last checked; subscribed again
  // once they are seen enabled.
  std::vector<std::string> tracked_disabled_;

  std::mutex health_mu_;
  HealthMetricsCollector health_collector_;
  bool health_collector_ready_ = false;
  std::thread health_thread_;
  std::atomic<bool> health_thread_running_{false};

  // TASK-008 diagnostics counters
  std::string run_mode_{"Console"};
  int64_t service_start_unix_ms_ = 0;
  uint64_t service_start_tick_ms_ = 0;
  std::atomic<uint64_t> ipc_messages_received_{0};
  std::atomic<uint64_t> ipc_messages_sent_{0};
  std::atomic<uint64_t> ipc_errors_{0};
  std::atomic<uint64_t> ipc_bytes_received_{0};
  std::atomic<uint64_t> ipc_bytes_sent_{0};
  std::atomic<uint64_t> live_events_pushed_{0};
  std::atomic<uint64_t> live_events_dropped_{0};
  std::mutex last_live_mu_;
  int64_t last_live_event_unix_ms_ = 0;
  std::string last_live_event_title_;

  // Self-process CPU baseline (100ns units).
  uint64_t prev_proc_cpu_100ns_ = 0;
  uint64_t prev_proc_cpu_tick_ms_ = 0;
  bool have_proc_cpu_baseline_ = false;

  // IPC throughput baseline (messages + bytes over wall time).
  std::mutex ipc_rate_mu_;
  bool have_ipc_rate_baseline_ = false;
  uint64_t prev_ipc_msgs_total_ = 0;
  uint64_t prev_ipc_bytes_total_ = 0;
  uint64_t prev_ipc_rate_tick_ms_ = 0;

  inventory::InventoryEngine inventory_engine_;
};

}  // namespace pulse
