#pragma once

// Minimal protobuf wire codec for pulse.ipc.Envelope.
// Field numbers match shared/pulse_protocol/proto/pulse.proto.
// Replace with protoc-generated code when codegen is wired in CI.

#include <cstdint>
#include <string>
#include <variant>
#include <vector>

namespace pulse::ipc {

struct ClientHello {
  uint32_t protocol_version = 1;
  std::string client_name;
  std::string client_version;
};

struct ServerHello {
  uint32_t protocol_version = 1;
  std::string service_version;
};

struct Ping {
  uint64_t nonce = 0;
  int64_t unix_ms = 0;
};

struct Pong {
  uint64_t nonce = 0;
  int64_t unix_ms = 0;
  std::string service_version;
};

struct Heartbeat {
  int64_t unix_ms = 0;
};

struct ErrorResponse {
  int32_t code = 0;
  std::string message;
  std::string technical_detail;
  std::string component;
};

enum class Severity : int32_t {
  Unknown = 0,
  Info = 1,
  Warning = 2,
  Error = 3,
  Critical = 4,
  Verbose = 5,
};

enum class Importance : int32_t {
  Low = 0,
  Medium = 1,
  High = 2,
  Critical = 3,
};

struct TimelineEvent {
  std::string event_id;
  int64_t timestamp_unix_ms = 0;
  std::string timestamp_iso;
  Severity severity = Severity::Unknown;
  std::string channel;
  std::string provider_name;
  uint32_t win_event_id = 0;
  uint64_t record_id = 0;
  std::string computer_name;
  std::string summary;
  std::string technical_summary;
  std::string message;
  std::string title;
  std::string recommendation;
  bool action_required = false;
  Importance importance = Importance::Low;
  std::string category;

  // R2 additive Wevtapi fields
  uint32_t task = 0;
  bool has_task = false;
  uint32_t opcode = 0;
  bool has_opcode = false;
  uint64_t keywords = 0;
  bool has_keywords = false;
  uint32_t process_id = 0;
  bool has_process_id = false;
  std::string process_name;
  uint32_t thread_id = 0;
  bool has_thread_id = false;
  std::string user_sid;
  std::string activity_id;
  std::string related_activity_id;
  std::string level_name;
  std::string raw_xml;
};

struct GetTimelineEventDetail {
  std::string channel;
  uint64_t record_id = 0;
};

struct TimelineEventDetail {
  bool found = false;
  TimelineEvent event;
};

struct GetTimelineSnapshot {
  uint32_t limit = 100;
  std::string channel = "System";
};

struct TimelineSnapshot {
  std::vector<TimelineEvent> events;
  std::string channel;
  uint32_t requested_limit = 0;
  int64_t collected_unix_ms = 0;
};

struct StartLiveMonitoring {
  std::string channel = "System";
};

struct StopLiveMonitoring {};

struct HealthStaticInfo {
  std::string windows_edition;
  std::string windows_version;
  std::string cpu_model;
  std::string gpu_model;
  uint64_t installed_ram_bytes = 0;
  uint64_t primary_storage_bytes = 0;
  std::string active_network_adapter;
  uint32_t cpu_base_mhz = 0;
  uint32_t cpu_sockets = 0;
  uint32_t cpu_cores = 0;
  uint32_t cpu_logical_processors = 0;
  bool cpu_virtualization_enabled = false;
  uint64_t gpu_dedicated_bytes = 0;
  uint64_t gpu_shared_bytes = 0;
  std::string cpu_architecture;
  std::string cpu_instruction_set;
  uint32_t cpu_numa_nodes = 0;
  bool has_cpu_smt = false;
  bool cpu_smt_enabled = false;
  bool has_cpu_l1_cache = false;
  uint64_t cpu_l1_cache_bytes = 0;
  bool has_cpu_l2_cache = false;
  uint64_t cpu_l2_cache_bytes = 0;
  bool has_cpu_l3_cache = false;
  uint64_t cpu_l3_cache_bytes = 0;
  std::string cpu_virtualization_vendor;
  std::string gpu_vendor;
  std::string gpu_driver_version;
  std::string gpu_driver_date;
  bool has_gpu_luid = false;
  int32_t gpu_luid_high = 0;
  uint32_t gpu_luid_low = 0;
  std::string gpu_directx_version;
  std::string gpu_wddm_version;
  bool has_gpu_hardware_scheduling = false;
  bool gpu_hardware_scheduling = false;
  std::string gpu_pcie_link_speed;
  std::string gpu_pcie_link_width;
  std::string gpu_pci_location;
  bool has_gpu_resizable_bar = false;
  bool gpu_resizable_bar = false;
  std::string net_manufacturer;
  std::string net_description;
  std::string net_mac_address;
  std::string net_driver_version;
  std::string net_driver_date;
  std::string net_connection_type;
  std::string net_duplex;
  bool has_net_mtu = false;
  uint32_t net_mtu = 0;
  bool has_net_if_index = false;
  uint32_t net_if_index = 0;
  bool has_net_link_speed_bps = false;
  uint64_t net_link_speed_bps = 0;
  bool has_net_dhcp = false;
  bool net_dhcp_enabled = false;
  std::string net_dhcp_server;
  bool has_net_lease_obtained = false;
  int64_t net_lease_obtained_unix_ms = 0;
  bool has_net_lease_expires = false;
  int64_t net_lease_expires_unix_ms = 0;
  bool has_mem_slots_used = false;
  uint32_t mem_slots_used = 0;
  bool has_mem_module_count = false;
  uint32_t mem_module_count = 0;
  std::string mem_ddr_generation;
  bool has_mem_speed_mhz = false;
  uint32_t mem_speed_mhz = 0;
  std::string mem_form_factor;
  bool has_mem_ecc = false;
  bool mem_ecc = false;
  bool has_mem_channels = false;
  uint32_t mem_channels = 0;
  std::string mem_dimm_vendor;
  std::string mem_dimm_part_number;
  std::string mem_dimm_serial;
  std::string disk_interface;
  std::string disk_bus;
  std::string disk_model;
  std::string disk_serial;
  std::string disk_firmware;
  std::string disk_partition_style;
  bool has_disk_sector_size = false;
  uint32_t disk_sector_size = 0;
  bool has_disk_rotation_rate = false;
  uint32_t disk_rotation_rate = 0;
  bool has_disk_trim = false;
  bool disk_trim_supported = false;
};

struct HealthProcessEntry {
  uint32_t pid = 0;
  std::string name;
  bool has_cpu_percent = false;
  double cpu_percent = 0.0;
  bool has_memory_bytes = false;
  uint64_t memory_bytes = 0;
  bool has_gpu_percent = false;
  double gpu_percent = 0.0;
  bool has_disk_bps = false;
  double disk_bps = 0.0;
  bool has_net_bps = false;
  double net_bps = 0.0;
  std::string path;
  uint32_t thread_count = 0;
  uint32_t handle_count = 0;
  bool has_create_time = false;
  uint64_t create_time_unix_ms = 0;
  bool has_is_critical = false;
  bool is_critical = false;
  bool has_working_set_bytes = false;
  uint64_t working_set_bytes = 0;
  bool has_commit_bytes = false;
  uint64_t commit_bytes = 0;
  bool has_paged_pool_bytes = false;
  uint64_t paged_pool_bytes = 0;
  bool has_nonpaged_pool_bytes = false;
  uint64_t nonpaged_pool_bytes = 0;
  bool has_gpu_dedicated_bytes = false;
  uint64_t gpu_dedicated_bytes = 0;
  bool has_gpu_shared_bytes = false;
  uint64_t gpu_shared_bytes = 0;
  std::string gpu_engine;
  bool has_net_upload_bps = false;
  double net_upload_bps = 0.0;
  bool has_net_download_bps = false;
  double net_download_bps = 0.0;
  bool has_net_bytes_total = false;
  uint64_t net_bytes_total = 0;
};

struct HealthProcessInventoryUpdate {
  uint64_t seq = 0;
  bool full_resync = false;
  std::vector<HealthProcessEntry> upserts;
  std::vector<uint32_t> removed_pids;
};

struct GetProcessDetails {
  uint32_t pid = 0;
};

struct ProcessDetails {
  uint32_t pid = 0;
  std::string name;
  std::string path;
  std::string company;
  std::string command_line;
  bool has_create_time = false;
  uint64_t create_time_unix_ms = 0;
  uint32_t thread_count = 0;
  uint32_t handle_count = 0;
  bool has_path = false;
  bool has_company = false;
  bool has_command_line = false;
  uint32_t parent_pid = 0;
  bool has_parent_pid = false;
  std::string parent_name;
  bool has_parent_name = false;
  std::string user;
  bool has_user = false;
  std::string integrity_level;
  bool has_integrity_level = false;
  bool elevated = false;
  bool has_elevated = false;
  std::string architecture;
  bool has_architecture = false;
  std::string product_name;
  bool has_product_name = false;
  /// User + kernel CPU time since the process started (GetProcessTimes).
  uint64_t cpu_time_ms = 0;
  bool has_cpu_time = false;
};

enum class HealthDriveKind : uint32_t {
  Unspecified = 0,
  Fixed = 1,
  Removable = 2,
  Remote = 3,
  CdRom = 4,
  RamDisk = 5,
  Unknown = 6,
};

struct HealthVolume {
  std::string id;
  std::string mount_point;
  std::string label;
  std::string file_system;
  HealthDriveKind kind = HealthDriveKind::Unspecified;
  uint64_t used_bytes = 0;
  uint64_t total_bytes = 0;
  bool has_capacity = false;
  bool included_in_summary = false;
};

/// Health of one physical disk (issue #12 / #20).
struct HealthDiskHealth {
  uint32_t index = 0;
  std::string model;
  std::string bus;
  bool has_temp_c = false;
  double temp_c = 0.0;
  bool has_failure_predicted = false;
  bool failure_predicted = false;
  bool has_critical_warning = false;
  uint32_t critical_warning = 0;
  bool has_percentage_used = false;
  uint32_t percentage_used = 0;
  bool has_available_spare = false;
  uint32_t available_spare = 0;
  uint32_t available_spare_threshold = 0;
  bool has_power_on_hours = false;
  uint64_t power_on_hours = 0;
  bool has_unsafe_shutdowns = false;
  uint64_t unsafe_shutdowns = 0;
  bool has_media_errors = false;
  uint64_t media_errors = 0;
  bool has_bytes_read = false;
  uint64_t bytes_read = 0;
  bool has_bytes_written = false;
  uint64_t bytes_written = 0;
};

/// One hardware GPU adapter (issue #9).
struct HealthGpuAdapter {
  int32_t luid_high = 0;
  uint32_t luid_low = 0;
  std::string name;
  std::string vendor;
  bool is_primary = false;
  uint64_t dedicated_total_bytes = 0;
  uint64_t shared_total_bytes = 0;
  bool has_percent = false;
  double percent = 0.0;
  bool has_dedicated_used = false;
  uint64_t dedicated_used_bytes = 0;
  bool has_shared_used = false;
  uint64_t shared_used_bytes = 0;
};

struct HealthPhysicalDisk {
  std::string id;
  std::string name;
  bool has_read_bps = false;
  double read_bps = 0.0;
  bool has_write_bps = false;
  double write_bps = 0.0;
};

struct HealthSample {
  int64_t unix_ms = 0;
  bool has_cpu_percent = false;
  double cpu_percent = 0.0;
  uint64_t memory_used_bytes = 0;
  uint64_t memory_total_bytes = 0;
  bool has_gpu_percent = false;
  double gpu_percent = 0.0;
  bool has_net_download_bps = false;
  double net_download_bps = 0.0;
  bool has_net_upload_bps = false;
  double net_upload_bps = 0.0;
  bool has_disk_read_bps = false;
  double disk_read_bps = 0.0;
  bool has_disk_write_bps = false;
  double disk_write_bps = 0.0;
  uint64_t disk_used_bytes = 0;
  uint64_t disk_total_bytes = 0;
  uint64_t uptime_ms = 0;
  bool has_cpu_temp_c = false;
  double cpu_temp_c = 0.0;
  bool has_gpu_temp_c = false;
  double gpu_temp_c = 0.0;
  bool has_ssd_temp_c = false;
  double ssd_temp_c = 0.0;
  bool has_cpu_current_mhz = false;
  double cpu_current_mhz = 0.0;
  uint64_t memory_available_bytes = 0;
  bool has_memory_committed = false;
  uint64_t memory_committed_bytes = 0;
  uint64_t memory_commit_limit_bytes = 0;
  bool has_memory_cached = false;
  uint64_t memory_cached_bytes = 0;
  std::string ipv4;
  std::string ipv6;
  std::string gateway;
  std::string dns;
  std::vector<HealthProcessEntry> top_cpu;
  std::vector<HealthProcessEntry> top_memory;
  std::vector<HealthProcessEntry> top_gpu;
  std::vector<HealthProcessEntry> top_disk;
  std::vector<HealthProcessEntry> top_network;
  std::vector<double> cpu_core_percent;
  std::vector<HealthVolume> volumes;
  std::vector<HealthPhysicalDisk> disks;
  bool has_memory_compressed = false;
  uint64_t memory_compressed_bytes = 0;
  bool has_memory_hardware_reserved = false;
  uint64_t memory_hardware_reserved_bytes = 0;
  bool has_memory_paged_pool = false;
  uint64_t memory_paged_pool_bytes = 0;
  bool has_memory_nonpaged_pool = false;
  uint64_t memory_nonpaged_pool_bytes = 0;
  bool has_memory_page_faults_per_sec = false;
  double memory_page_faults_per_sec = 0.0;
  bool has_gpu_util_3d = false;
  double gpu_util_3d = 0.0;
  bool has_gpu_util_compute = false;
  double gpu_util_compute = 0.0;
  bool has_gpu_util_copy = false;
  double gpu_util_copy = 0.0;
  bool has_gpu_util_video_decode = false;
  double gpu_util_video_decode = 0.0;
  bool has_gpu_util_video_encode = false;
  double gpu_util_video_encode = 0.0;
  bool has_gpu_util_video_processing = false;
  double gpu_util_video_processing = 0.0;
  bool has_gpu_dedicated_used = false;
  uint64_t gpu_dedicated_used_bytes = 0;
  bool has_gpu_shared_used = false;
  uint64_t gpu_shared_used_bytes = 0;
  bool has_gpu_clock_mhz = false;
  double gpu_clock_mhz = 0.0;
  bool has_gpu_memory_clock_mhz = false;
  double gpu_memory_clock_mhz = 0.0;
  bool has_gpu_fan_rpm = false;
  double gpu_fan_rpm = 0.0;
  bool has_gpu_power_percent = false;
  double gpu_power_percent = 0.0;
  bool has_net_peak_download_bps = false;
  double net_peak_download_bps = 0.0;
  bool has_net_peak_upload_bps = false;
  double net_peak_upload_bps = 0.0;
  bool has_net_avg_download_bps = false;
  double net_avg_download_bps = 0.0;
  bool has_net_avg_upload_bps = false;
  double net_avg_upload_bps = 0.0;
  bool has_net_utilization_percent = false;
  double net_utilization_percent = 0.0;
  bool has_net_connection_ms = false;
  uint64_t net_connection_ms = 0;
  bool has_net_bytes_sent = false;
  uint64_t net_bytes_sent = 0;
  bool has_net_bytes_received = false;
  uint64_t net_bytes_received = 0;
  bool has_net_packets_sent = false;
  uint64_t net_packets_sent = 0;
  bool has_net_packets_received = false;
  uint64_t net_packets_received = 0;
  bool has_net_errors = false;
  uint64_t net_errors = 0;
  bool has_net_drops = false;
  uint64_t net_drops = 0;
  std::string net_ssid;
  bool has_net_signal_percent = false;
  double net_signal_percent = 0.0;
  std::string net_wifi_channel;
  std::string net_wifi_frequency;
  std::string net_wifi_security;
  // Phase 3 — storage SMART / lifetime (has_* false → Not supported)
  bool has_disk_power_on_hours = false;
  uint64_t disk_power_on_hours = 0;
  bool has_disk_total_bytes_written = false;
  uint64_t disk_total_bytes_written = 0;
  bool has_disk_total_bytes_read = false;
  uint64_t disk_total_bytes_read = 0;
  bool has_disk_smart_ok = false;
  bool disk_smart_ok = false;
  std::vector<HealthDiskHealth> disk_health;
  std::vector<HealthGpuAdapter> gpus;
};

struct GetHealthSnapshot {};

struct HealthSnapshot {
  HealthStaticInfo info;
  HealthSample sample;
};

struct HealthUpdate {
  HealthSample sample;
  HealthProcessInventoryUpdate process_inventory;
};

struct StartHealthMonitoring {};

struct StopHealthMonitoring {};

// --- Diagnostics (TASK-008) ---

struct GetDiagnosticsSnapshot {};

// Pipeline stage health: 0 = healthy, 1 = warning, 2 = error.
struct DiagnosticsSnapshot {
  std::string service_version;
  uint32_t protocol_version = 0;
  int64_t service_start_unix_ms = 0;
  uint64_t service_uptime_ms = 0;
  std::string run_mode;
  bool ipc_listening = false;

  bool live_subscribed = false;
  std::string live_channel;
  uint64_t live_events_pushed = 0;
  uint64_t live_events_dropped = 0;
  uint64_t live_subscriber_reconnects = 0;
  int64_t last_live_event_unix_ms = 0;
  std::string last_live_event_title;
  uint32_t live_queue_depth = 0;
  uint32_t live_queue_capacity = 0;

  uint64_t ipc_messages_received = 0;
  uint64_t ipc_messages_sent = 0;
  uint64_t ipc_errors = 0;
  uint32_t connected_clients = 0;

  uint32_t service_pid = 0;
  bool has_cpu_percent = false;
  double cpu_percent = 0.0;
  uint64_t working_set_bytes = 0;
  uint32_t thread_count = 0;
  uint32_t handle_count = 0;

  int32_t stage_event_log = 0;
  int32_t stage_collector = 0;
  int32_t stage_intelligence = 0;
  int32_t stage_ipc = 0;
  std::string stage_detail;

  std::string windows_edition;
  std::string windows_version;

  // Phase 5 — service identity
  std::string executable_path;
  std::string build_version;
  std::string git_commit;
  std::string binary_sha256;
  std::string install_path;
  bool has_paths_match = false;
  bool paths_match = false;
  std::string scm_state;
  std::string scm_startup_type;

  // Phase 5 — IPC throughput
  uint64_t ipc_bytes_received = 0;
  uint64_t ipc_bytes_sent = 0;
  bool has_ipc_messages_per_sec = false;
  double ipc_messages_per_sec = 0.0;
  bool has_ipc_bytes_per_sec = false;
  double ipc_bytes_per_sec = 0.0;

  // Phase 5 — collectors
  bool health_monitoring_active = false;
  double health_sample_rate_hz = 0.0;
  bool network_etw_running = false;
  std::string network_etw_last_error;

  // Phase 5 — per-stage detail
  std::string stage_event_log_detail;
  std::string stage_collector_detail;
  std::string stage_intelligence_detail;
  std::string stage_ipc_detail;
};

struct InjectDiagnosticsTestEvent {};

// R3 Inventory Engine (ADR-011)
enum class InventoryDomainId : uint32_t {
  Unspecified = 0,
  Services = 1,
  Drivers = 2,
  Software = 3,
  Usb = 4,
  Pci = 5,
  Displays = 6,
  Audio = 7,
  Bluetooth = 8,
  Printers = 9,
  Battery = 10,
  Motherboard = 11,
  Bios = 12,
  Cpu = 13,
  MemoryModules = 14,
  Storage = 15,
  NetworkAdapters = 16,
};

enum class InventoryStatus : uint32_t {
  Unspecified = 0,
  Available = 1,
  Unsupported = 2,
  AccessDenied = 3,
  Partial = 4,
  Error = 5,
};

struct InventoryServiceEntry {
  std::string id;
  std::string display_name;
  std::string state;
  std::string start_type;
  std::string account;
  std::string binary_path;
  std::string description;
};

struct InventoryDriverEntry {
  std::string id;
  std::string display_name;
  std::string state;
  std::string start_type;
  std::string binary_path;
  std::string description;
  std::string driver_type;
};

struct InventorySoftwareEntry {
  std::string id;
  std::string display_name;
  std::string version;
  std::string publisher;
  std::string install_date;
  std::string install_location;
  uint64_t estimated_size_bytes = 0;
  bool has_estimated_size = false;
  bool system_component = false;
  std::string architecture;
};

struct InventoryUsbEntry {
  std::string id;
  std::string description;
  std::string hardware_id;
  std::string manufacturer;
  std::string service;
  std::string class_name;
  std::string class_guid;
  uint32_t problem_code = 0;
  bool has_problem_code = false;
};

struct InventoryPciEntry {
  std::string id;
  std::string description;
  std::string hardware_id;
  std::string manufacturer;
  std::string service;
  std::string class_name;
  std::string class_guid;
  std::string location_info;
  uint32_t problem_code = 0;
  bool has_problem_code = false;
};

struct InventoryPnPDeviceEntry {
  std::string id;
  std::string description;
  std::string hardware_id;
  std::string manufacturer;
  std::string service;
  std::string class_name;
  std::string class_guid;
  std::string location_info;
  uint32_t problem_code = 0;
  bool has_problem_code = false;
  std::string adapter_name;
  bool description_from_enum_display = false;
};

struct InventoryPrinterEntry {
  std::string id;
  std::string port_name;
  std::string driver_name;
  std::string location;
  std::string comment;
  bool is_shared = false;
  bool is_default = false;
  bool is_network = false;
  uint32_t attributes = 0;
  bool has_attributes = false;
};

struct InventoryBatteryEntry {
  std::string id;
  std::string description;
  std::string manufacturer;
  std::string chemistry;
  uint32_t design_capacity_mwh = 0;
  bool has_design_capacity = false;
  uint32_t full_charged_capacity_mwh = 0;
  bool has_full_charged_capacity = false;
  uint32_t cycle_count = 0;
  bool has_cycle_count = false;
  uint32_t capacity_percent = 0;
  bool has_capacity_percent = false;
  std::string power_state;
  bool from_system_power_fallback = false;
};

struct InventoryMotherboardEntry {
  std::string id;
  std::string manufacturer;
  std::string product;
  std::string version;
  std::string serial_number;
  std::string asset_tag;
  std::string location_in_chassis;
  std::string board_type;
};

struct InventoryBiosEntry {
  std::string id;
  std::string vendor;
  std::string version;
  std::string release_date;
  uint32_t major_release = 0;
  bool has_major_release = false;
  uint32_t minor_release = 0;
  bool has_minor_release = false;
  uint64_t rom_size_bytes = 0;
  bool has_rom_size_bytes = false;
  bool uefi_capable = false;
  bool has_uefi_capable = false;
};

struct InventoryCpuEntry {
  std::string id;
  std::string name;
  std::string manufacturer;
  std::string architecture;
  uint32_t sockets = 0;
  bool has_sockets = false;
  uint32_t physical_cores = 0;
  bool has_physical_cores = false;
  uint32_t logical_processors = 0;
  bool has_logical_processors = false;
  uint32_t base_clock_mhz = 0;
  bool has_base_clock_mhz = false;
  uint32_t numa_nodes = 0;
  bool has_numa_nodes = false;
  uint64_t l1_cache_bytes = 0;
  bool has_l1_cache_bytes = false;
  uint64_t l2_cache_bytes = 0;
  bool has_l2_cache_bytes = false;
  uint64_t l3_cache_bytes = 0;
  bool has_l3_cache_bytes = false;
  std::string instruction_set;
  bool smt_enabled = false;
  bool has_smt_enabled = false;
  std::string virtualization_vendor;
};

struct InventoryMemoryModuleEntry {
  std::string id;
  std::string bank_locator;
  std::string manufacturer;
  std::string part_number;
  std::string serial_number;
  uint64_t size_bytes = 0;
  bool has_size_bytes = false;
  uint32_t speed_mts = 0;
  bool has_speed_mts = false;
  uint32_t configured_speed_mts = 0;
  bool has_configured_speed_mts = false;
  std::string form_factor;
  std::string memory_type;
  bool is_ecc = false;
  bool has_is_ecc = false;
  uint32_t total_width_bits = 0;
  bool has_total_width_bits = false;
  uint32_t data_width_bits = 0;
  bool has_data_width_bits = false;
  uint32_t configured_voltage_mv = 0;
  bool has_configured_voltage_mv = false;
  bool populated = false;
};

struct InventoryStorageEntry {
  std::string id;
  std::string device_path;
  uint32_t physical_drive_number = 0;
  bool has_physical_drive_number = false;
  std::string model;
  std::string vendor;
  std::string serial_number;
  std::string firmware_revision;
  std::string bus_type;
  std::string media_type;
  uint64_t size_bytes = 0;
  bool has_size_bytes = false;
  uint32_t sector_size_bytes = 0;
  bool has_sector_size_bytes = false;
  std::string partition_style;
  bool is_removable = false;
  bool has_is_removable = false;
  bool trim_supported = false;
  bool has_trim_supported = false;
  std::string manufacturer;
  std::string description;
};

struct InventoryNetworkAdapterEntry {
  std::string id;
  std::string description;
  std::string friendly_name;
  std::string mac_address;
  std::string connection_type;
  uint32_t if_index = 0;
  bool has_if_index = false;
  uint32_t mtu = 0;
  bool has_mtu = false;
  std::string operational_status;
  bool dhcp_enabled = false;
  bool has_dhcp_enabled = false;
  uint64_t link_speed_bps = 0;
  bool has_link_speed_bps = false;
  bool is_loopback = false;
  std::vector<std::string> ipv4_addresses;
  std::vector<std::string> ipv6_addresses;
  std::vector<std::string> gateway_addresses;
  std::vector<std::string> dns_addresses;
  std::string driver_provider;
  std::string driver_version;
  std::string driver_date;
};

struct GetInventoryDomain {
  InventoryDomainId domain = InventoryDomainId::Unspecified;
  bool force_refresh = false;
  uint64_t since_generation = 0;
  uint32_t limit = 0;
};

struct InventoryDomainSnapshot {
  InventoryDomainId domain = InventoryDomainId::Unspecified;
  InventoryStatus status = InventoryStatus::Unspecified;
  std::string status_detail;
  bool truncated = false;
  uint64_t generation = 0;
  int64_t generated_at_unix_ms = 0;
  bool full_resync = true;
  uint32_t cache_ttl_ms = 0;
  std::vector<InventoryServiceEntry> services;
  std::vector<InventoryDriverEntry> drivers;
  std::vector<InventorySoftwareEntry> software;
  std::vector<InventoryUsbEntry> usb;
  std::vector<InventoryPciEntry> pci;
  std::vector<InventoryPnPDeviceEntry> displays;
  std::vector<InventoryPnPDeviceEntry> audio;
  std::vector<InventoryPnPDeviceEntry> bluetooth;
  std::vector<InventoryPrinterEntry> printers;
  std::vector<InventoryBatteryEntry> batteries;
  std::vector<InventoryMotherboardEntry> motherboard;
  std::vector<InventoryBiosEntry> bios;
  std::vector<InventoryCpuEntry> cpu;
  std::vector<InventoryMemoryModuleEntry> memory_modules;
  std::vector<InventoryStorageEntry> storage;
  std::vector<InventoryNetworkAdapterEntry> network_adapters;
};

// Crash history (doc 43).
enum class CrashKind : uint32_t {
  Unspecified = 0,
  AppCrash = 1,
  AppHang = 2,
  BlueScreen = 3,
  UnexpectedRestart = 4,
  GpuReset = 5,
  ServiceCrash = 6,
  HardwareError = 7,
};

enum class FaultingModuleOrigin : uint32_t {
  Unknown = 0,
  App = 1,
  Windows = 2,
  Driver = 3,
  Other = 4,
};

struct CrashOccurrence {
  int64_t timestamp_unix_ms = 0;
  std::string channel;
  uint64_t record_id = 0;
  std::string version;
};

struct CrashVersion {
  std::string version;
  uint32_t count = 0;
  int64_t last_unix_ms = 0;
};

struct CrashGroup {
  CrashKind kind = CrashKind::Unspecified;
  std::string key;
  std::string subject;
  std::string module_name;
  std::string module_path;
  std::string module_company;
  FaultingModuleOrigin module_origin = FaultingModuleOrigin::Unknown;
  uint32_t code = 0;
  bool has_code = false;
  std::string title;
  std::string summary;
  std::string recommendation;
  uint32_t count = 0;
  int64_t first_unix_ms = 0;
  int64_t last_unix_ms = 0;
  std::vector<int64_t> occurrence_unix_ms;
  std::vector<CrashVersion> versions;
  std::vector<CrashOccurrence> recent;
};

struct GetCrashHistory {
  uint32_t days = 0;
};

struct CrashHistory {
  uint32_t days = 0;
  int64_t collected_unix_ms = 0;
  std::vector<CrashGroup> groups;
  uint32_t scanned_events = 0;
  bool truncated = false;
  std::vector<std::string> unreadable_channels;
};

// Event Log channels (ADR-016).
/// EVT_CHANNEL_TYPE + 1, so 0 stays "unknown".
enum class EventLogChannelType : uint32_t {
  Unknown = 0,
  Admin = 1,
  Operational = 2,
  Analytic = 3,
  Debug = 4,
};

/// Whether PulseService (LocalService) can read the channel.
enum class EventLogChannelAccess : uint32_t {
  Unknown = 0,
  Readable = 1,
  Denied = 2,
  NotFound = 3,
  Error = 4,
};

struct EventLogChannelInfo {
  std::string path;
  EventLogChannelType type = EventLogChannelType::Unknown;
  bool enabled = false;
  EventLogChannelAccess access = EventLogChannelAccess::Unknown;
  uint64_t record_count = 0;
  bool has_record_count = false;
  bool built_in = false;
  bool tracked = false;
  std::string detail;
};

struct ListEventLogChannels {};

struct EventLogChannelList {
  std::vector<EventLogChannelInfo> channels;
  int64_t collected_unix_ms = 0;
  uint32_t max_tracked = 0;
  uint32_t skipped_channels = 0;
};

/// The full tracked list; replaces the previous one.
struct SetTrackedChannels {
  std::vector<std::string> channels;
};

enum class TrackedChannelStatus : uint32_t {
  Unspecified = 0,
  Tracked = 1,
  Disabled = 2,
  AccessDenied = 3,
  NotFound = 4,
  UnsupportedType = 5,
  OverLimit = 6,
  BuiltIn = 7,
  Failed = 8,
};

struct TrackedChannelResult {
  std::string path;
  TrackedChannelStatus status = TrackedChannelStatus::Unspecified;
  std::string detail;
};

struct TrackedChannels {
  std::vector<TrackedChannelResult> results;
  uint32_t max_tracked = 0;
  std::vector<std::string> tracked;
};

struct Envelope {
  uint64_t request_id = 0;
  std::variant<std::monostate, ClientHello, ServerHello, Ping, Pong, Heartbeat,
               GetTimelineSnapshot, TimelineSnapshot, TimelineEvent,
               StartLiveMonitoring, StopLiveMonitoring, GetHealthSnapshot,
               HealthSnapshot, HealthUpdate, StartHealthMonitoring,
               StopHealthMonitoring, GetDiagnosticsSnapshot,
               DiagnosticsSnapshot, InjectDiagnosticsTestEvent,
               GetProcessDetails, ProcessDetails, GetTimelineEventDetail,
               TimelineEventDetail, GetInventoryDomain, InventoryDomainSnapshot,
               GetCrashHistory, CrashHistory, ListEventLogChannels,
               EventLogChannelList, SetTrackedChannels, TrackedChannels,
               ErrorResponse>
      body;
};

bool EncodeEnvelope(const Envelope& env, std::vector<uint8_t>* out);
bool DecodeEnvelope(const uint8_t* data, size_t len, Envelope* out);

// Frame: magic(4) + length(4 LE) + payload
bool EncodeFrame(const std::vector<uint8_t>& payload, std::vector<uint8_t>* out);
bool TryDecodeFrame(const uint8_t* data, size_t len, std::vector<uint8_t>* payload,
                    size_t* consumed_bytes, std::string* error);

}  // namespace pulse::ipc
