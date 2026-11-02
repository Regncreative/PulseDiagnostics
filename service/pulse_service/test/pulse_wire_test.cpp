#include "pulse_wire.hpp"

#include <cassert>
#include <iostream>

int main() {
  using namespace pulse::ipc;

  Envelope ping;
  ping.request_id = 42;
  ping.body = Ping{7, 123456789};

  std::vector<uint8_t> payload;
  assert(EncodeEnvelope(ping, &payload));

  Envelope decoded;
  assert(DecodeEnvelope(payload.data(), payload.size(), &decoded));
  assert(decoded.request_id == 42);
  assert(std::holds_alternative<Ping>(decoded.body));
  assert(std::get<Ping>(decoded.body).nonce == 7);

  std::vector<uint8_t> frame;
  assert(EncodeFrame(payload, &frame));
  std::vector<uint8_t> frame_payload;
  size_t consumed = 0;
  std::string err;
  assert(TryDecodeFrame(frame.data(), frame.size(), &frame_payload, &consumed, &err));
  assert(consumed == frame.size());
  assert(frame_payload == payload);

  // Oversized length should fail.
  std::vector<uint8_t> bad = {'P', 'U', 'L', 'S', 0xFF, 0xFF, 0xFF, 0x7F};
  assert(!TryDecodeFrame(bad.data(), bad.size(), &frame_payload, &consumed, &err));

  // Historical TimelineSnapshot roundtrip (TASK-002.2).
  TimelineEvent ev;
  ev.event_id = "System|42|7036|2026-07-27T12:00:00Z";
  ev.timestamp_unix_ms = 1722081600000;
  ev.timestamp_iso = "2026-07-27T12:00:00Z";
  ev.severity = Severity::Info;
  ev.channel = "System";
  ev.provider_name = "Service Control Manager";
  ev.win_event_id = 7036;
  ev.record_id = 42;
  ev.computer_name = "DESKTOP";
  ev.summary = "The Windows Update service entered the running state.";
  ev.technical_summary = "Service Control Manager Event ID 7036 · System";
  ev.message = "The Windows Update service entered the running state.";
  ev.title = "Service State Changed";
  ev.recommendation = "Normal operating system behavior.";
  ev.action_required = false;
  ev.importance = Importance::Low;
  ev.category = "Service";

  Envelope snap;
  snap.request_id = 9;
  snap.body = TimelineSnapshot{{ev}, "System", 100, 1722081601000};

  std::vector<uint8_t> snap_payload;
  if (!EncodeEnvelope(snap, &snap_payload)) {
    std::cerr << "timeline encode failed\n";
    return 2;
  }
  Envelope snap_decoded;
  if (!DecodeEnvelope(snap_payload.data(), snap_payload.size(), &snap_decoded) ||
      !std::holds_alternative<TimelineSnapshot>(snap_decoded.body)) {
    std::cerr << "timeline decode failed\n";
    return 2;
  }
  assert(snap_decoded.request_id == 9);
  const auto& out = std::get<TimelineSnapshot>(snap_decoded.body);
  assert(out.channel == "System");
  assert(out.requested_limit == 100);
  assert(out.events.size() == 1);
  assert(out.events[0].win_event_id == 7036);
  assert(out.events[0].summary == ev.summary);
  assert(out.events[0].title == ev.title);
  assert(out.events[0].recommendation == ev.recommendation);
  assert(out.events[0].action_required == ev.action_required);
  assert(out.events[0].importance == ev.importance);
  assert(out.events[0].category == ev.category);

  // R2 additive TimelineEvent fields roundtrip.
  TimelineEvent rich;
  rich.event_id = "System|99|41|2026-08-01T00:00:00Z";
  rich.has_process_id = true;
  rich.process_id = 1234;
  rich.process_name = "explorer.exe";
  rich.has_task = true;
  rich.task = 7;
  rich.has_opcode = true;
  rich.opcode = 1;
  rich.has_keywords = true;
  rich.keywords = 0x8000000000000011ULL;
  rich.user_sid = "S-1-5-18";
  rich.activity_id = "{11111111-2222-3333-4444-555555555555}";
  rich.related_activity_id = "{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}";
  rich.level_name = "Critical";
  rich.raw_xml =
      "<Event xmlns='http://schemas.microsoft.com/win/2004/08/events/event'/>";

  Envelope detail_env;
  detail_env.request_id = 11;
  detail_env.body = TimelineEventDetail{true, rich};
  std::vector<uint8_t> detail_payload;
  if (!EncodeEnvelope(detail_env, &detail_payload)) {
    std::cerr << "TimelineEventDetail encode failed\n";
    return 12;
  }
  Envelope detail_decoded;
  if (!DecodeEnvelope(detail_payload.data(), detail_payload.size(),
                      &detail_decoded) ||
      !std::holds_alternative<TimelineEventDetail>(detail_decoded.body)) {
    std::cerr << "TimelineEventDetail decode failed\n";
    return 12;
  }
  const auto& detail_out = std::get<TimelineEventDetail>(detail_decoded.body);
  if (!detail_out.found || !detail_out.event.has_process_id ||
      detail_out.event.process_id != 1234 ||
      detail_out.event.process_name != "explorer.exe" ||
      !detail_out.event.has_keywords ||
      detail_out.event.keywords != 0x8000000000000011ULL ||
      detail_out.event.raw_xml != rich.raw_xml) {
    std::cerr << "TimelineEventDetail fields mismatch\n";
    return 12;
  }

  GetTimelineEventDetail tl_detail_req;
  tl_detail_req.channel = "System";
  tl_detail_req.record_id = 99;
  Envelope tl_detail_req_env;
  tl_detail_req_env.request_id = 12;
  tl_detail_req_env.body = tl_detail_req;
  std::vector<uint8_t> tl_detail_req_payload;
  if (!EncodeEnvelope(tl_detail_req_env, &tl_detail_req_payload)) {
    std::cerr << "GetTimelineEventDetail encode failed\n";
    return 13;
  }
  Envelope tl_detail_req_decoded;
  if (!DecodeEnvelope(tl_detail_req_payload.data(),
                      tl_detail_req_payload.size(), &tl_detail_req_decoded) ||
      !std::holds_alternative<GetTimelineEventDetail>(
          tl_detail_req_decoded.body) ||
      std::get<GetTimelineEventDetail>(tl_detail_req_decoded.body).record_id !=
          99) {
    std::cerr << "GetTimelineEventDetail decode failed\n";
    return 13;
  }

  Envelope req;
  req.request_id = 8;
  req.body = GetTimelineSnapshot{100, "System"};
  std::vector<uint8_t> req_payload;
  assert(EncodeEnvelope(req, &req_payload));
  Envelope req_decoded;
  assert(DecodeEnvelope(req_payload.data(), req_payload.size(), &req_decoded));
  assert(std::holds_alternative<GetTimelineSnapshot>(req_decoded.body));
  assert(std::get<GetTimelineSnapshot>(req_decoded.body).limit == 100);

  // HealthSnapshot / HealthUpdate roundtrip (TASK-007 + issue #11).
  HealthSample sample;
  sample.unix_ms = 1722081602000;
  sample.has_cpu_percent = true;
  sample.cpu_percent = 42.5;
  sample.memory_used_bytes = 8ull * 1024 * 1024 * 1024;
  sample.memory_total_bytes = 16ull * 1024 * 1024 * 1024;
  sample.has_gpu_percent = false;  // unsupported sensor
  sample.gpu_percent = 0.0;
  sample.has_net_download_bps = true;
  sample.net_download_bps = 125000.0;
  sample.has_net_upload_bps = true;
  sample.net_upload_bps = 32000.0;
  sample.has_disk_read_bps = true;
  sample.disk_read_bps = 1048576.0;
  sample.has_disk_write_bps = true;
  sample.disk_write_bps = 524288.0;
  sample.disk_used_bytes = 200ull * 1024 * 1024 * 1024;
  sample.disk_total_bytes = 512ull * 1024 * 1024 * 1024;
  sample.uptime_ms = 3600000;
  sample.has_cpu_temp_c = true;
  sample.cpu_temp_c = 58.25;
  sample.has_gpu_temp_c = false;
  sample.gpu_temp_c = 0.0;
  sample.has_ssd_temp_c = false;
  sample.ssd_temp_c = 0.0;
  sample.has_cpu_current_mhz = true;
  sample.cpu_current_mhz = 4200.0;
  sample.memory_available_bytes = 8ull * 1024 * 1024 * 1024;
  sample.has_memory_committed = true;
  sample.memory_committed_bytes = 10ull * 1024 * 1024 * 1024;
  sample.memory_commit_limit_bytes = 20ull * 1024 * 1024 * 1024;
  sample.has_memory_cached = true;
  sample.memory_cached_bytes = 2ull * 1024 * 1024 * 1024;
  sample.ipv4 = "192.168.1.10";
  sample.ipv6 = "fe80::1";
  sample.gateway = "192.168.1.1";
  sample.dns = "1.1.1.1";
  HealthVolume vol_c;
  vol_c.id = "C:";
  vol_c.mount_point = "C:\\";
  vol_c.label = "Windows";
  vol_c.file_system = "NTFS";
  vol_c.kind = HealthDriveKind::Fixed;
  vol_c.used_bytes = 200ull * 1024 * 1024 * 1024;
  vol_c.total_bytes = 512ull * 1024 * 1024 * 1024;
  vol_c.has_capacity = true;
  vol_c.included_in_summary = true;
  HealthVolume vol_d;
  vol_d.id = "D:";
  vol_d.mount_point = "D:\\";
  vol_d.kind = HealthDriveKind::Fixed;
  vol_d.used_bytes = 100ull * 1024 * 1024 * 1024;
  vol_d.total_bytes = 1000ull * 1024 * 1024 * 1024;
  vol_d.has_capacity = true;
  vol_d.included_in_summary = true;
  HealthVolume vol_z;
  vol_z.id = "Z:";
  vol_z.mount_point = "Z:\\";
  vol_z.kind = HealthDriveKind::Remote;
  vol_z.has_capacity = false;
  vol_z.included_in_summary = false;
  sample.volumes.push_back(vol_c);
  sample.volumes.push_back(vol_d);
  sample.volumes.push_back(vol_z);
  HealthPhysicalDisk disk0;
  disk0.id = "0 C:";
  disk0.name = "0 C:";
  disk0.has_read_bps = true;
  disk0.read_bps = 1048576.0;
  disk0.has_write_bps = true;
  disk0.write_bps = 524288.0;
  HealthPhysicalDisk disk1;
  disk1.id = "1 D:";
  disk1.name = "1 D:";
  disk1.has_read_bps = true;
  disk1.read_bps = 2048.0;
  sample.disks.push_back(disk0);
  sample.disks.push_back(disk1);
  HealthProcessEntry proc;
  proc.pid = 4242;
  proc.name = "chrome.exe";
  proc.has_cpu_percent = true;
  proc.cpu_percent = 12.25;
  sample.top_cpu.push_back(proc);
  // Two GPUs (issue #9); a negative LUID high part must survive the trip.
  HealthGpuAdapter dedicated_gpu;
  dedicated_gpu.luid_high = -2;
  dedicated_gpu.luid_low = 0xF21B;
  dedicated_gpu.name = "NVIDIA GeForce RTX 3060";
  dedicated_gpu.vendor = "NVIDIA";
  dedicated_gpu.is_primary = true;
  dedicated_gpu.dedicated_total_bytes = 12ull * 1024 * 1024 * 1024;
  dedicated_gpu.has_percent = true;
  dedicated_gpu.percent = 37.5;
  dedicated_gpu.has_dedicated_used = true;
  dedicated_gpu.dedicated_used_bytes = 3ull * 1024 * 1024 * 1024;
  HealthGpuAdapter integrated_gpu;
  integrated_gpu.luid_low = 0xA001;
  integrated_gpu.name = "Intel(R) UHD Graphics 770";
  integrated_gpu.shared_total_bytes = 16ull * 1024 * 1024 * 1024;
  integrated_gpu.has_shared_used = true;
  integrated_gpu.shared_used_bytes = 0;
  sample.gpus.push_back(dedicated_gpu);
  sample.gpus.push_back(integrated_gpu);

  HealthStaticInfo info;
  info.windows_edition = "Windows 11 Pro";
  info.windows_version = "10.0.26100";
  info.cpu_model = "AMD Ryzen 7";
  info.gpu_model = "NVIDIA RTX";
  info.installed_ram_bytes = 16ull * 1024 * 1024 * 1024;
  info.primary_storage_bytes = 512ull * 1024 * 1024 * 1024;
  info.active_network_adapter = "Ethernet";
  info.cpu_base_mhz = 3700;
  info.cpu_sockets = 1;
  info.cpu_cores = 8;
  info.cpu_logical_processors = 16;
  info.cpu_virtualization_enabled = true;
  info.gpu_dedicated_bytes = 12ull * 1024 * 1024 * 1024;
  info.gpu_shared_bytes = 16ull * 1024 * 1024 * 1024;

  Envelope health_snap;
  health_snap.request_id = 11;
  health_snap.body = HealthSnapshot{info, sample};

  std::vector<uint8_t> health_payload;
  if (!EncodeEnvelope(health_snap, &health_payload) || health_payload.empty()) {
    std::cerr << "health encode failed\n";
    return 3;
  }
  Envelope health_decoded;
  if (!DecodeEnvelope(health_payload.data(), health_payload.size(),
                      &health_decoded) ||
      !std::holds_alternative<HealthSnapshot>(health_decoded.body)) {
    std::cerr << "health decode failed\n";
    return 4;
  }
  assert(health_decoded.request_id == 11);
  const auto& hs = std::get<HealthSnapshot>(health_decoded.body);
  assert(hs.info.windows_edition == "Windows 11 Pro");
  assert(hs.info.cpu_model == "AMD Ryzen 7");
  assert(hs.info.installed_ram_bytes == 16ull * 1024 * 1024 * 1024);
  assert(hs.sample.has_cpu_percent == true);
  assert(hs.sample.cpu_percent == 42.5);
  assert(hs.sample.has_gpu_percent == false);
  assert(hs.sample.memory_used_bytes == 8ull * 1024 * 1024 * 1024);
  assert(hs.sample.has_cpu_temp_c == true);
  assert(hs.sample.cpu_temp_c == 58.25);
  assert(hs.sample.has_ssd_temp_c == false);
  assert(hs.info.cpu_base_mhz == 3700);
  assert(hs.info.cpu_cores == 8);
  assert(hs.info.cpu_virtualization_enabled == true);
  assert(hs.info.gpu_dedicated_bytes == 12ull * 1024 * 1024 * 1024);
  assert(hs.sample.has_cpu_current_mhz == true);
  assert(hs.sample.cpu_current_mhz == 4200.0);
  assert(hs.sample.ipv4 == "192.168.1.10");
  assert(hs.sample.top_cpu.size() == 1);
  assert(hs.sample.top_cpu[0].pid == 4242);
  assert(hs.sample.top_cpu[0].name == "chrome.exe");
  assert(hs.sample.top_cpu[0].cpu_percent == 12.25);
  {
    const auto& gpus = hs.sample.gpus;
    const bool gpus_ok =
        gpus.size() == 2 && gpus[0].luid_high == -2 &&
        gpus[0].luid_low == 0xF21B &&
        gpus[0].name == "NVIDIA GeForce RTX 3060" &&
        gpus[0].vendor == "NVIDIA" && gpus[0].is_primary &&
        gpus[0].dedicated_total_bytes == 12ull * 1024 * 1024 * 1024 &&
        gpus[0].has_percent && gpus[0].percent == 37.5 &&
        gpus[0].has_dedicated_used &&
        gpus[0].dedicated_used_bytes == 3ull * 1024 * 1024 * 1024 &&
        !gpus[0].has_shared_used && gpus[1].luid_low == 0xA001 &&
        !gpus[1].is_primary && !gpus[1].has_percent &&
        gpus[1].shared_total_bytes == 16ull * 1024 * 1024 * 1024 &&
        gpus[1].has_shared_used && gpus[1].shared_used_bytes == 0;
    if (!gpus_ok) {
      std::cerr << "health gpus roundtrip failed\n";
      return 9;
    }
  }
  // Release builds strip assert(); keep explicit checks for multi-volume fields.
  if (hs.sample.volumes.size() != 3 || hs.sample.volumes[0].id != "C:" ||
      hs.sample.volumes[0].kind != HealthDriveKind::Fixed ||
      !hs.sample.volumes[0].has_capacity ||
      !hs.sample.volumes[0].included_in_summary ||
      hs.sample.volumes[1].id != "D:" || hs.sample.volumes[2].id != "Z:" ||
      hs.sample.volumes[2].kind != HealthDriveKind::Remote ||
      hs.sample.volumes[2].has_capacity || hs.sample.disks.size() != 2 ||
      hs.sample.disks[0].id != "0 C:" || !hs.sample.disks[0].has_read_bps ||
      hs.sample.disks[1].id != "1 D:") {
    std::cerr << "health volumes/disks mismatch\n";
    return 5;
  }

  Envelope health_upd;
  health_upd.request_id = 0;
  health_upd.body = HealthUpdate{sample};

  std::vector<uint8_t> upd_payload;
  if (!EncodeEnvelope(health_upd, &upd_payload)) {
    std::cerr << "health update encode failed\n";
    return 6;
  }
  Envelope upd_decoded;
  if (!DecodeEnvelope(upd_payload.data(), upd_payload.size(), &upd_decoded) ||
      !std::holds_alternative<HealthUpdate>(upd_decoded.body)) {
    std::cerr << "health update decode failed\n";
    return 6;
  }
  assert(upd_decoded.request_id == 0);
  const auto& hu = std::get<HealthUpdate>(upd_decoded.body);
  assert(hu.sample.has_cpu_percent == true);
  assert(hu.sample.cpu_percent == 42.5);
  assert(hu.sample.has_gpu_percent == false);
  assert(hu.sample.net_download_bps == 125000.0);

  HealthProcessInventoryUpdate inv;
  inv.seq = 3;
  inv.full_resync = true;
  HealthProcessEntry inv_proc;
  inv_proc.pid = 55;
  inv_proc.name = "Pulse.exe";
  inv_proc.has_cpu_percent = true;
  inv_proc.cpu_percent = 1.5;
  inv_proc.has_create_time = true;
  inv_proc.create_time_unix_ms = 1700000000000ull;
  inv_proc.has_is_critical = true;
  inv_proc.is_critical = false;
  inv.upserts.push_back(inv_proc);
  inv.removed_pids.push_back(9);

  HealthUpdate with_inv;
  with_inv.sample = sample;
  with_inv.process_inventory = inv;
  Envelope inv_env;
  inv_env.request_id = 0;
  inv_env.body = with_inv;
  std::vector<uint8_t> inv_payload;
  if (!EncodeEnvelope(inv_env, &inv_payload)) {
    std::cerr << "inventory encode failed\n";
    return 7;
  }
  Envelope inv_decoded;
  if (!DecodeEnvelope(inv_payload.data(), inv_payload.size(), &inv_decoded) ||
      !std::holds_alternative<HealthUpdate>(inv_decoded.body)) {
    std::cerr << "inventory decode failed\n";
    return 7;
  }
  const auto& hu_inv = std::get<HealthUpdate>(inv_decoded.body);
  if (hu_inv.process_inventory.seq != 3 ||
      !hu_inv.process_inventory.full_resync ||
      hu_inv.process_inventory.upserts.size() != 1 ||
      hu_inv.process_inventory.upserts[0].pid != 55 ||
      hu_inv.process_inventory.upserts[0].name != "Pulse.exe" ||
      hu_inv.process_inventory.upserts[0].create_time_unix_ms !=
          1700000000000ull ||
      hu_inv.process_inventory.removed_pids.size() != 1 ||
      hu_inv.process_inventory.removed_pids[0] != 9) {
    std::cerr << "inventory fields mismatch\n";
    return 8;
  }

  ProcessDetails details;
  details.pid = 55;
  details.name = "Pulse.exe";
  details.path = "C:\\Pulse\\Pulse.exe";
  details.company = "Pulse";
  details.command_line = "Pulse.exe --ui";
  details.has_path = true;
  details.has_company = true;
  details.has_command_line = true;
  details.thread_count = 12;
  details.handle_count = 200;
  details.parent_pid = 4;
  details.has_parent_pid = true;
  details.parent_name = "System";
  details.has_parent_name = true;
  details.user = "NT AUTHORITY\\SYSTEM";
  details.has_user = true;
  details.integrity_level = "System";
  details.has_integrity_level = true;
  details.elevated = true;
  details.has_elevated = true;
  details.architecture = "x64";
  details.has_architecture = true;
  details.product_name = "Pulse";
  details.has_product_name = true;
  details.cpu_time_ms = 123456789012ULL;
  details.has_cpu_time = true;
  Envelope det_env;
  det_env.request_id = 12;
  det_env.body = details;
  std::vector<uint8_t> det_payload;
  if (!EncodeEnvelope(det_env, &det_payload)) {
    std::cerr << "ProcessDetails encode failed\n";
    return 9;
  }
  Envelope det_decoded;
  if (!DecodeEnvelope(det_payload.data(), det_payload.size(), &det_decoded) ||
      !std::holds_alternative<ProcessDetails>(det_decoded.body)) {
    std::cerr << "ProcessDetails decode failed\n";
    return 9;
  }
  const auto& det = std::get<ProcessDetails>(det_decoded.body);
  if (det.pid != 55 || det.company != "Pulse" || !det.has_command_line ||
      det.thread_count != 12 || det.parent_pid != 4 ||
      det.architecture != "x64" || det.product_name != "Pulse" ||
      !det.has_cpu_time || det.cpu_time_ms != 123456789012ULL) {
    std::cerr << "ProcessDetails fields mismatch\n";
    return 10;
  }

  GetProcessDetails get_det;
  get_det.pid = 4242;
  Envelope get_proc_env;
  get_proc_env.request_id = 13;
  get_proc_env.body = get_det;
  std::vector<uint8_t> get_proc_payload;
  if (!EncodeEnvelope(get_proc_env, &get_proc_payload)) {
    std::cerr << "GetProcessDetails encode failed\n";
    return 11;
  }
  Envelope get_proc_decoded;
  if (!DecodeEnvelope(get_proc_payload.data(), get_proc_payload.size(),
                      &get_proc_decoded) ||
      !std::holds_alternative<GetProcessDetails>(get_proc_decoded.body) ||
      std::get<GetProcessDetails>(get_proc_decoded.body).pid != 4242) {
    std::cerr << "GetProcessDetails decode failed\n";
    return 11;
  }

  GetInventoryDomain get_inv;
  get_inv.domain = InventoryDomainId::Services;
  get_inv.force_refresh = true;
  get_inv.limit = 50;
  Envelope get_inv_env;
  get_inv_env.request_id = 37;
  get_inv_env.body = get_inv;
  std::vector<uint8_t> get_inv_payload;
  if (!EncodeEnvelope(get_inv_env, &get_inv_payload)) {
    std::cerr << "GetInventoryDomain encode failed\n";
    return 37;
  }
  Envelope get_inv_decoded;
  if (!DecodeEnvelope(get_inv_payload.data(), get_inv_payload.size(),
                      &get_inv_decoded) ||
      !std::holds_alternative<GetInventoryDomain>(get_inv_decoded.body) ||
      std::get<GetInventoryDomain>(get_inv_decoded.body).domain !=
          InventoryDomainId::Services ||
      !std::get<GetInventoryDomain>(get_inv_decoded.body).force_refresh) {
    std::cerr << "GetInventoryDomain decode failed\n";
    return 37;
  }

  InventoryDomainSnapshot catalog_snap;
  catalog_snap.domain = InventoryDomainId::Services;
  catalog_snap.status = InventoryStatus::Available;
  catalog_snap.generation = 9;
  catalog_snap.cache_ttl_ms = 30000;
  catalog_snap.full_resync = true;
  InventoryServiceEntry svc;
  svc.id = "EventLog";
  svc.display_name = "Windows Event Log";
  svc.state = "running";
  svc.start_type = "automatic";
  catalog_snap.services.push_back(svc);
  Envelope catalog_env;
  catalog_env.request_id = 38;
  catalog_env.body = catalog_snap;
  std::vector<uint8_t> catalog_payload;
  if (!EncodeEnvelope(catalog_env, &catalog_payload)) {
    std::cerr << "InventoryDomainSnapshot encode failed\n";
    return 38;
  }
  Envelope catalog_decoded;
  if (!DecodeEnvelope(catalog_payload.data(), catalog_payload.size(),
                      &catalog_decoded) ||
      !std::holds_alternative<InventoryDomainSnapshot>(catalog_decoded.body)) {
    std::cerr << "InventoryDomainSnapshot decode failed\n";
    return 38;
  }
  const auto& catalog_out =
      std::get<InventoryDomainSnapshot>(catalog_decoded.body);
  if (catalog_out.services.size() != 1 ||
      catalog_out.services[0].id != "EventLog" ||
      catalog_out.generation != 9 ||
      catalog_out.status != InventoryStatus::Available) {
    std::cerr << "InventoryDomainSnapshot payload mismatch\n";
    return 38;
  }

  InventoryDomainSnapshot drivers_snap;
  drivers_snap.domain = InventoryDomainId::Drivers;
  drivers_snap.status = InventoryStatus::Partial;
  drivers_snap.generation = 2;
  drivers_snap.full_resync = true;
  InventoryDriverEntry drv;
  drv.id = "Wdf01000";
  drv.display_name = "Kernel Mode Driver Frameworks";
  drv.state = "running";
  drv.start_type = "boot";
  drv.driver_type = "kernel";
  drivers_snap.drivers.push_back(drv);
  Envelope drivers_env;
  drivers_env.request_id = 39;
  drivers_env.body = drivers_snap;
  std::vector<uint8_t> drivers_payload;
  if (!EncodeEnvelope(drivers_env, &drivers_payload)) {
    std::cerr << "InventoryDomainSnapshot drivers encode failed\n";
    return 39;
  }
  Envelope drivers_decoded;
  if (!DecodeEnvelope(drivers_payload.data(), drivers_payload.size(),
                      &drivers_decoded) ||
      !std::holds_alternative<InventoryDomainSnapshot>(drivers_decoded.body)) {
    std::cerr << "InventoryDomainSnapshot drivers decode failed\n";
    return 39;
  }
  const auto& drivers_out =
      std::get<InventoryDomainSnapshot>(drivers_decoded.body);
  if (drivers_out.drivers.size() != 1 ||
      drivers_out.drivers[0].id != "Wdf01000" ||
      drivers_out.drivers[0].driver_type != "kernel") {
    std::cerr << "InventoryDomainSnapshot drivers payload mismatch\n";
    return 39;
  }

  InventoryDomainSnapshot software_snap;
  software_snap.domain = InventoryDomainId::Software;
  software_snap.status = InventoryStatus::Available;
  software_snap.generation = 4;
  InventorySoftwareEntry soft;
  soft.id = "{ABCDEF12-3456-7890-ABCD-EF1234567890}";
  soft.display_name = "Pulse Test App";
  soft.version = "1.0.0";
  soft.publisher = "Pulse";
  soft.architecture = "x64";
  software_snap.software.push_back(soft);
  Envelope software_env;
  software_env.request_id = 40;
  software_env.body = software_snap;
  std::vector<uint8_t> software_payload;
  if (!EncodeEnvelope(software_env, &software_payload)) {
    std::cerr << "InventoryDomainSnapshot software encode failed\n";
    return 40;
  }
  Envelope software_decoded;
  if (!DecodeEnvelope(software_payload.data(), software_payload.size(),
                      &software_decoded) ||
      !std::holds_alternative<InventoryDomainSnapshot>(software_decoded.body)) {
    std::cerr << "InventoryDomainSnapshot software decode failed\n";
    return 40;
  }
  const auto& software_out =
      std::get<InventoryDomainSnapshot>(software_decoded.body);
  if (software_out.software.size() != 1 ||
      software_out.software[0].id != soft.id ||
      software_out.software[0].display_name != "Pulse Test App") {
    std::cerr << "InventoryDomainSnapshot software payload mismatch\n";
    return 40;
  }

  InventoryDomainSnapshot usb_snap;
  usb_snap.domain = InventoryDomainId::Usb;
  usb_snap.status = InventoryStatus::Available;
  usb_snap.generation = 5;
  InventoryUsbEntry usb;
  usb.id = R"(USB\VID_046D&PID_C52B\5&12345678&0&2)";
  usb.description = "USB Receiver";
  usb.hardware_id = R"(USB\VID_046D&PID_C52B)";
  usb.manufacturer = "Logitech";
  usb.class_name = "USB";
  usb_snap.usb.push_back(usb);
  Envelope usb_env;
  usb_env.request_id = 41;
  usb_env.body = usb_snap;
  std::vector<uint8_t> usb_payload;
  if (!EncodeEnvelope(usb_env, &usb_payload)) {
    std::cerr << "InventoryDomainSnapshot usb encode failed\n";
    return 41;
  }
  Envelope usb_decoded;
  if (!DecodeEnvelope(usb_payload.data(), usb_payload.size(), &usb_decoded) ||
      !std::holds_alternative<InventoryDomainSnapshot>(usb_decoded.body)) {
    std::cerr << "InventoryDomainSnapshot usb decode failed\n";
    return 41;
  }
  const auto& usb_out = std::get<InventoryDomainSnapshot>(usb_decoded.body);
  if (usb_out.usb.size() != 1 || usb_out.usb[0].id != usb.id ||
      usb_out.usb[0].manufacturer != "Logitech") {
    std::cerr << "InventoryDomainSnapshot usb payload mismatch\n";
    return 41;
  }

  InventoryDomainSnapshot pci_snap;
  pci_snap.domain = InventoryDomainId::Pci;
  pci_snap.status = InventoryStatus::Available;
  pci_snap.generation = 6;
  InventoryPciEntry pci;
  pci.id = R"(PCI\VEN_10DE&DEV_2684&SUBSYS_1234&REV_A1\4&ABCD&0&0008)";
  pci.description = "NVIDIA GeForce";
  pci.hardware_id = R"(PCI\VEN_10DE&DEV_2684)";
  pci.manufacturer = "NVIDIA";
  pci.class_name = "Display";
  pci.location_info = "PCI bus 1, device 0, function 0";
  pci_snap.pci.push_back(pci);
  Envelope pci_env;
  pci_env.request_id = 42;
  pci_env.body = pci_snap;
  std::vector<uint8_t> pci_payload;
  if (!EncodeEnvelope(pci_env, &pci_payload)) {
    std::cerr << "InventoryDomainSnapshot pci encode failed\n";
    return 42;
  }
  Envelope pci_decoded;
  if (!DecodeEnvelope(pci_payload.data(), pci_payload.size(), &pci_decoded) ||
      !std::holds_alternative<InventoryDomainSnapshot>(pci_decoded.body)) {
    std::cerr << "InventoryDomainSnapshot pci decode failed\n";
    return 42;
  }
  const auto& pci_out = std::get<InventoryDomainSnapshot>(pci_decoded.body);
  if (pci_out.pci.size() != 1 || pci_out.pci[0].id != pci.id ||
      pci_out.pci[0].location_info.empty()) {
    std::cerr << "InventoryDomainSnapshot pci payload mismatch\n";
    return 42;
  }

  InventoryDomainSnapshot p1_snap;
  p1_snap.domain = InventoryDomainId::Displays;
  p1_snap.status = InventoryStatus::Partial;
  p1_snap.generation = 7;
  InventoryPnPDeviceEntry display;
  display.id = R"(DISPLAY\ABC1234\5&1&0&UID256)";
  display.description = "Generic PnP Monitor";
  display.adapter_name = "Intel UHD";
  display.description_from_enum_display = true;
  p1_snap.displays.push_back(display);
  InventoryPnPDeviceEntry audio;
  audio.id = R"(HDAUDIO\FUNC_01&VEN_10EC&DEV_0899\4&2&0)";
  audio.description = "Realtek Audio";
  p1_snap.audio.push_back(audio);
  InventoryPnPDeviceEntry bluetooth;
  bluetooth.id = R"(BTH\MS_BTHBRB\6&3&0&0)";
  bluetooth.description = "Bluetooth Radio";
  p1_snap.bluetooth.push_back(bluetooth);
  InventoryPrinterEntry printer;
  printer.id = "Microsoft Print to PDF";
  printer.port_name = "PORTPROMPT:";
  printer.driver_name = "Microsoft Print To PDF";
  printer.is_default = true;
  printer.has_attributes = true;
  p1_snap.printers.push_back(printer);
  InventoryBatteryEntry battery;
  battery.id = "system_power";
  battery.description = "System power status aggregate";
  battery.capacity_percent = 87;
  battery.has_capacity_percent = true;
  battery.power_state = "online";
  battery.from_system_power_fallback = true;
  p1_snap.batteries.push_back(battery);
  Envelope p1_env;
  p1_env.request_id = 43;
  p1_env.body = p1_snap;
  std::vector<uint8_t> p1_payload;
  if (!EncodeEnvelope(p1_env, &p1_payload)) {
    std::cerr << "InventoryDomainSnapshot p1 encode failed\n";
    return 43;
  }
  Envelope p1_decoded;
  if (!DecodeEnvelope(p1_payload.data(), p1_payload.size(), &p1_decoded) ||
      !std::holds_alternative<InventoryDomainSnapshot>(p1_decoded.body)) {
    std::cerr << "InventoryDomainSnapshot p1 decode failed\n";
    return 43;
  }
  const auto& p1_out = std::get<InventoryDomainSnapshot>(p1_decoded.body);
  if (p1_out.displays.size() != 1 ||
      p1_out.displays[0].adapter_name != "Intel UHD" ||
      p1_out.audio.size() != 1 || p1_out.bluetooth.size() != 1 ||
      p1_out.printers.size() != 1 ||
      p1_out.printers[0].id != "Microsoft Print to PDF" ||
      p1_out.batteries.size() != 1 ||
      !p1_out.batteries[0].from_system_power_fallback) {
    std::cerr << "InventoryDomainSnapshot p1 payload mismatch\n";
    return 43;
  }

  InventoryDomainSnapshot p2_snap;
  p2_snap.domain = InventoryDomainId::Motherboard;
  p2_snap.status = InventoryStatus::Available;
  p2_snap.generation = 8;
  InventoryMotherboardEntry motherboard;
  motherboard.id = "motherboard";
  motherboard.manufacturer = "ASUSTeK COMPUTER INC.";
  motherboard.product = "ROG STRIX Z790-E GAMING";
  motherboard.board_type = "Motherboard";
  p2_snap.motherboard.push_back(motherboard);
  InventoryBiosEntry bios;
  bios.id = "bios";
  bios.vendor = "American Megatrends International, LLC.";
  bios.version = "1901";
  bios.release_date = "03/14/2026";
  bios.major_release = 19;
  bios.has_major_release = true;
  bios.uefi_capable = true;
  bios.has_uefi_capable = true;
  p2_snap.bios.push_back(bios);
  InventoryCpuEntry cpu;
  cpu.id = "cpu";
  cpu.name = "13th Gen Intel(R) Core(TM) i9-13900K";
  cpu.manufacturer = "GenuineIntel";
  cpu.architecture = "x64";
  cpu.sockets = 1;
  cpu.has_sockets = true;
  cpu.physical_cores = 24;
  cpu.has_physical_cores = true;
  cpu.logical_processors = 32;
  cpu.has_logical_processors = true;
  cpu.instruction_set = "SSE2 SSE3 SSE4.2 AVX AVX2";
  p2_snap.cpu.push_back(cpu);
  InventoryMemoryModuleEntry mem;
  mem.id = "DIMM_A1";
  mem.bank_locator = "BANK 0";
  mem.manufacturer = "Corsair";
  mem.size_bytes = 17179869184ULL;
  mem.has_size_bytes = true;
  mem.speed_mts = 6000;
  mem.has_speed_mts = true;
  mem.memory_type = "DDR5";
  mem.populated = true;
  p2_snap.memory_modules.push_back(mem);
  InventoryMemoryModuleEntry mem_empty;
  mem_empty.id = "DIMM_A2";
  mem_empty.bank_locator = "BANK 1";
  mem_empty.populated = false;
  p2_snap.memory_modules.push_back(mem_empty);
  InventoryStorageEntry storage;
  storage.id = R"(SCSI\DISK&VEN_NVME&PROD_SAMSUNG_SSD\4&1234ABCD&0&000000)";
  storage.device_path = R"(\\.\PhysicalDrive0)";
  storage.physical_drive_number = 0;
  storage.has_physical_drive_number = true;
  storage.model = "Samsung SSD 990 PRO 2TB";
  storage.bus_type = "NVMe";
  storage.media_type = "SSD";
  storage.size_bytes = 2000398934016ULL;
  storage.has_size_bytes = true;
  storage.partition_style = "GPT";
  p2_snap.storage.push_back(storage);
  InventoryNetworkAdapterEntry net;
  net.id = "{4D36E96E-E325-11CE-BFC1-08002BE10318}";
  net.description = "Intel(R) Ethernet Controller";
  net.mac_address = "00:1a:2b:3c:4d:5e";
  net.connection_type = "Ethernet";
  net.if_index = 12;
  net.has_if_index = true;
  net.dhcp_enabled = true;
  net.has_dhcp_enabled = true;
  net.ipv4_addresses.push_back("192.168.1.50");
  net.gateway_addresses.push_back("192.168.1.1");
  net.dns_addresses.push_back("192.168.1.1");
  net.dns_addresses.push_back("1.1.1.1");
  p2_snap.network_adapters.push_back(net);
  Envelope p2_env;
  p2_env.request_id = 44;
  p2_env.body = p2_snap;
  std::vector<uint8_t> p2_payload;
  if (!EncodeEnvelope(p2_env, &p2_payload)) {
    std::cerr << "InventoryDomainSnapshot p2 encode failed\n";
    return 44;
  }
  Envelope p2_decoded;
  if (!DecodeEnvelope(p2_payload.data(), p2_payload.size(), &p2_decoded) ||
      !std::holds_alternative<InventoryDomainSnapshot>(p2_decoded.body)) {
    std::cerr << "InventoryDomainSnapshot p2 decode failed\n";
    return 44;
  }
  const auto& p2_out = std::get<InventoryDomainSnapshot>(p2_decoded.body);
  if (p2_out.motherboard.size() != 1 ||
      p2_out.motherboard[0].product != "ROG STRIX Z790-E GAMING" ||
      p2_out.bios.size() != 1 || p2_out.bios[0].major_release != 19 ||
      !p2_out.bios[0].has_uefi_capable || !p2_out.bios[0].uefi_capable ||
      p2_out.cpu.size() != 1 || p2_out.cpu[0].logical_processors != 32 ||
      p2_out.memory_modules.size() != 2 ||
      p2_out.memory_modules[0].id != "DIMM_A1" ||
      !p2_out.memory_modules[0].populated ||
      p2_out.memory_modules[1].populated ||
      p2_out.storage.size() != 1 ||
      p2_out.storage[0].physical_drive_number != 0 ||
      p2_out.network_adapters.size() != 1 ||
      p2_out.network_adapters[0].ipv4_addresses.size() != 1 ||
      p2_out.network_adapters[0].dns_addresses.size() != 2 ||
      p2_out.network_adapters[0].dns_addresses[1] != "1.1.1.1") {
    std::cerr << "InventoryDomainSnapshot p2 payload mismatch\n";
    return 44;
  }

  // Crash history (doc 43).
  Envelope crash_req_env;
  crash_req_env.request_id = 5001;
  crash_req_env.body = GetCrashHistory{30};
  std::vector<uint8_t> crash_req_payload;
  Envelope crash_req_decoded;
  if (!EncodeEnvelope(crash_req_env, &crash_req_payload) ||
      !DecodeEnvelope(crash_req_payload.data(), crash_req_payload.size(),
                      &crash_req_decoded) ||
      !std::holds_alternative<GetCrashHistory>(crash_req_decoded.body) ||
      std::get<GetCrashHistory>(crash_req_decoded.body).days != 30) {
    std::cerr << "GetCrashHistory round trip failed\n";
    return 45;
  }

  CrashGroup crash_group;
  crash_group.kind = CrashKind::AppCrash;
  crash_group.key = "app|discord.exe|nvwgf2umx.dll|c0000005";
  crash_group.subject = "Discord.exe";
  crash_group.module_name = "nvwgf2umx.dll";
  crash_group.module_company = "NVIDIA Corporation";
  crash_group.module_origin = FaultingModuleOrigin::Driver;
  crash_group.code = 0xC0000005;
  crash_group.has_code = true;
  crash_group.title = "Discord Crashed";
  crash_group.count = 3;
  crash_group.first_unix_ms = 1760000000000;
  crash_group.last_unix_ms = 1760100000000;
  crash_group.occurrence_unix_ms = {1760100000000, 1760050000000, 1760000000000};
  crash_group.versions.push_back(CrashVersion{"1.0.9170", 2, 1760100000000});
  crash_group.versions.push_back(CrashVersion{"1.0.9168", 1, 1760000000000});
  crash_group.recent.push_back(
      CrashOccurrence{1760100000000, "Application", 9876543210ull, "1.0.9170"});
  CrashHistory crash_history;
  crash_history.days = 30;
  crash_history.collected_unix_ms = 1760200000000;
  crash_history.groups.push_back(crash_group);
  crash_history.scanned_events = 42;
  crash_history.truncated = true;
  crash_history.unreadable_channels.push_back("Security");
  Envelope crash_env;
  crash_env.request_id = 5002;
  crash_env.body = crash_history;
  std::vector<uint8_t> crash_payload;
  Envelope crash_decoded;
  if (!EncodeEnvelope(crash_env, &crash_payload) ||
      !DecodeEnvelope(crash_payload.data(), crash_payload.size(),
                      &crash_decoded) ||
      !std::holds_alternative<CrashHistory>(crash_decoded.body)) {
    std::cerr << "CrashHistory round trip failed\n";
    return 46;
  }
  const auto& crash_out = std::get<CrashHistory>(crash_decoded.body);
  if (crash_out.days != 30 || crash_out.scanned_events != 42 ||
      !crash_out.truncated || crash_out.unreadable_channels.size() != 1 ||
      crash_out.groups.size() != 1) {
    std::cerr << "CrashHistory payload mismatch\n";
    return 46;
  }
  const auto& group_out = crash_out.groups[0];
  if (group_out.kind != CrashKind::AppCrash ||
      group_out.module_origin != FaultingModuleOrigin::Driver ||
      group_out.code != 0xC0000005 || !group_out.has_code ||
      group_out.module_company != "NVIDIA Corporation" ||
      group_out.count != 3 || group_out.last_unix_ms != 1760100000000 ||
      group_out.occurrence_unix_ms.size() != 3 ||
      group_out.occurrence_unix_ms[2] != 1760000000000 ||
      group_out.versions.size() != 2 ||
      group_out.versions[0].version != "1.0.9170" ||
      group_out.versions[0].count != 2 || group_out.recent.size() != 1 ||
      group_out.recent[0].record_id != 9876543210ull ||
      group_out.recent[0].channel != "Application") {
    std::cerr << "CrashGroup payload mismatch\n";
    return 46;
  }

  // Event Log channels (ADR-016).
  Envelope list_req_env;
  list_req_env.request_id = 6001;
  list_req_env.body = ListEventLogChannels{};
  std::vector<uint8_t> list_req_payload;
  Envelope list_req_decoded;
  if (!EncodeEnvelope(list_req_env, &list_req_payload) ||
      !DecodeEnvelope(list_req_payload.data(), list_req_payload.size(),
                      &list_req_decoded) ||
      list_req_decoded.request_id != 6001 ||
      !std::holds_alternative<ListEventLogChannels>(list_req_decoded.body)) {
    std::cerr << "ListEventLogChannels round trip failed\n";
    return 47;
  }

  EventLogChannelInfo task_scheduler;
  task_scheduler.path = "Microsoft-Windows-TaskScheduler/Operational";
  task_scheduler.type = EventLogChannelType::Operational;
  task_scheduler.enabled = false;
  task_scheduler.access = EventLogChannelAccess::Readable;
  task_scheduler.record_count = 0;
  task_scheduler.has_record_count = true;
  task_scheduler.tracked = true;
  EventLogChannelInfo security;
  security.path = "Security";
  security.type = EventLogChannelType::Admin;
  security.enabled = true;
  security.access = EventLogChannelAccess::Denied;
  security.built_in = true;
  security.detail = "Access is denied.";
  EventLogChannelList channel_list;
  channel_list.channels = {task_scheduler, security};
  channel_list.collected_unix_ms = 1762000000000;
  channel_list.max_tracked = 16;
  channel_list.skipped_channels = 512;
  Envelope list_env;
  list_env.request_id = 6001;
  list_env.body = channel_list;
  std::vector<uint8_t> list_payload;
  Envelope list_decoded;
  if (!EncodeEnvelope(list_env, &list_payload) ||
      !DecodeEnvelope(list_payload.data(), list_payload.size(), &list_decoded) ||
      !std::holds_alternative<EventLogChannelList>(list_decoded.body)) {
    std::cerr << "EventLogChannelList round trip failed\n";
    return 48;
  }
  const auto& list_out = std::get<EventLogChannelList>(list_decoded.body);
  if (list_out.channels.size() != 2 || list_out.max_tracked != 16 ||
      list_out.skipped_channels != 512 ||
      list_out.collected_unix_ms != 1762000000000 ||
      list_out.channels[0].path != task_scheduler.path ||
      list_out.channels[0].type != EventLogChannelType::Operational ||
      list_out.channels[0].enabled || !list_out.channels[0].has_record_count ||
      !list_out.channels[0].tracked || list_out.channels[0].built_in ||
      list_out.channels[1].access != EventLogChannelAccess::Denied ||
      !list_out.channels[1].built_in ||
      list_out.channels[1].detail != "Access is denied.") {
    std::cerr << "EventLogChannelList payload mismatch\n";
    return 48;
  }

  Envelope set_env;
  set_env.request_id = 6002;
  set_env.body = SetTrackedChannels{
      {"Microsoft-Windows-TaskScheduler/Operational", "Security"}};
  std::vector<uint8_t> set_payload;
  Envelope set_decoded;
  if (!EncodeEnvelope(set_env, &set_payload) ||
      !DecodeEnvelope(set_payload.data(), set_payload.size(), &set_decoded) ||
      !std::holds_alternative<SetTrackedChannels>(set_decoded.body) ||
      std::get<SetTrackedChannels>(set_decoded.body).channels.size() != 2 ||
      std::get<SetTrackedChannels>(set_decoded.body).channels[1] != "Security") {
    std::cerr << "SetTrackedChannels round trip failed\n";
    return 49;
  }

  TrackedChannels tracked;
  tracked.results = {
      {"Microsoft-Windows-TaskScheduler/Operational",
       TrackedChannelStatus::Disabled, ""},
      {"Security", TrackedChannelStatus::BuiltIn, ""},
      {"Missing/Channel", TrackedChannelStatus::NotFound,
       "The specified channel could not be found."}};
  tracked.max_tracked = 16;
  tracked.tracked = {"Microsoft-Windows-TaskScheduler/Operational"};
  Envelope tracked_env;
  tracked_env.request_id = 6002;
  tracked_env.body = tracked;
  std::vector<uint8_t> tracked_payload;
  Envelope tracked_decoded;
  if (!EncodeEnvelope(tracked_env, &tracked_payload) ||
      !DecodeEnvelope(tracked_payload.data(), tracked_payload.size(),
                      &tracked_decoded) ||
      !std::holds_alternative<TrackedChannels>(tracked_decoded.body)) {
    std::cerr << "TrackedChannels round trip failed\n";
    return 50;
  }
  const auto& tracked_out = std::get<TrackedChannels>(tracked_decoded.body);
  if (tracked_out.results.size() != 3 || tracked_out.max_tracked != 16 ||
      tracked_out.tracked.size() != 1 ||
      tracked_out.results[0].status != TrackedChannelStatus::Disabled ||
      tracked_out.results[1].status != TrackedChannelStatus::BuiltIn ||
      tracked_out.results[2].status != TrackedChannelStatus::NotFound ||
      tracked_out.results[2].detail.empty()) {
    std::cerr << "TrackedChannels payload mismatch\n";
    return 50;
  }

  std::cout << "pulse_wire_tests OK\n";
  return 0;
}
