cmake_minimum_required(VERSION 3.25)
project(PulseService VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(PULSE_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../..")

# Embed short git commit at configure time (override with -DPULSE_GIT_COMMIT=...).
if(NOT DEFINED PULSE_GIT_COMMIT OR PULSE_GIT_COMMIT STREQUAL "")
  execute_process(
    COMMAND git rev-parse --short HEAD
    WORKING_DIRECTORY "${PULSE_ROOT}"
    OUTPUT_VARIABLE PULSE_GIT_COMMIT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
    RESULT_VARIABLE PULSE_GIT_RESULT
  )
  if(NOT PULSE_GIT_RESULT EQUAL 0 OR PULSE_GIT_COMMIT STREQUAL "")
    set(PULSE_GIT_COMMIT "unknown")
  endif()
endif()
configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/pulse_build_info.hpp.in"
  "${CMAKE_CURRENT_BINARY_DIR}/generated/pulse_build_info.hpp"
  @ONLY
)

add_library(pulse_wire STATIC
  "${PULSE_ROOT}/shared/pulse_protocol/cpp/pulse_wire.cpp"
)
target_include_directories(pulse_wire PUBLIC
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)

add_executable(PulseService WIN32
  src/main.cpp
  res/PulseService.rc
  src/service_core/service_core.cpp
  src/ipc/ipc_server.cpp
  src/ipc/event_mapper.cpp
  src/intelligence/event_intelligence.cpp
  src/intelligence/crash_explainer.cpp
  src/intelligence/wake_explainer.cpp
  src/intelligence/bugcheck_catalog.cpp
  src/intelligence/app_crash_explainer.cpp
  src/intelligence/exception_catalog.cpp
  src/humanization/event_humanizer.cpp
  src/collector/collector.cpp
  src/collectors/event_log_collector.cpp
  src/collectors/event_log_subscriber.cpp
  src/collectors/crash_history_collector.cpp
  src/intelligence/crash_history.cpp
  src/windows/file_version_info.cpp
  src/collectors/event_log_channels.cpp
  src/collectors/event_log_channel_catalog.cpp
  src/collectors/evtx_file_reader.cpp
  src/commands/read_evtx_command.cpp
  src/collectors/health_metrics_collector.cpp
  src/collectors/hardware_sensors_collector.cpp
  src/collectors/disk_health.cpp
  src/collectors/network_etw_engine.cpp
  src/collectors/gpu_adapter_info.cpp
  src/collectors/gpu_engine_load.cpp
  src/collectors/system_overview_info.cpp
  src/collectors/process_metrics.cpp
  src/diagnostics/service_identity.cpp
  src/inventory/inventory_engine.cpp
  src/inventory/services_collector.cpp
  src/inventory/drivers_collector.cpp
  src/inventory/software_collector.cpp
  src/inventory/usb_collector.cpp
  src/inventory/pci_collector.cpp
  src/inventory/displays_collector.cpp
  src/inventory/audio_collector.cpp
  src/inventory/bluetooth_collector.cpp
  src/inventory/printers_collector.cpp
  src/inventory/battery_collector.cpp
  src/inventory/setupapi_device_enumerator.cpp
  src/inventory/smbios_table.cpp
  src/inventory/motherboard_collector.cpp
  src/inventory/bios_collector.cpp
  src/inventory/memory_modules_collector.cpp
  src/inventory/cpu_collector.cpp
  src/inventory/storage_collector.cpp
  src/inventory/network_adapters_collector.cpp
  src/windows/wevt_helpers.cpp
  src/logging/logger.cpp
  src/util/config.cpp
  src/util/windows_edition.cpp
)

# Console subsystem so --console works with stdout; also fine for SCM.
set_target_properties(PulseService PROPERTIES
  WIN32_EXECUTABLE FALSE
)

target_include_directories(PulseService PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${CMAKE_CURRENT_BINARY_DIR}/generated"
  "${PULSE_ROOT}/shared/pulse_common/include"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
)

target_link_libraries(PulseService PRIVATE
  pulse_wire
  advapi32
  shell32
  ole32
  wevtapi
  pdh
  iphlpapi
  dxgi
  d3d12
  gdi32
  psapi
  version
  wlanapi
  setupapi
  cfgmgr32
  winspool
  bcrypt
  delayimp
)

# Windows Server ships wlanapi.dll only with the Wireless LAN Service feature.
# A normal import would stop PulseService from starting there, so the DLL is
# loaded on first use and the Wi-Fi sample checks for it (system_overview_info).
target_link_options(PulseService PRIVATE "/DELAYLOAD:wlanapi.dll")

enable_testing()
add_executable(pulse_wire_tests
  test/pulse_wire_test.cpp
)
target_include_directories(pulse_wire_tests PRIVATE
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(pulse_wire_tests PRIVATE pulse_wire)
add_test(NAME pulse_wire_tests COMMAND pulse_wire_tests)

add_executable(event_humanizer_tests
  test/event_humanizer_test.cpp
  src/humanization/event_humanizer.cpp
)
target_include_directories(event_humanizer_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
)
add_test(NAME event_humanizer_tests COMMAND event_humanizer_tests)

add_executable(event_intelligence_tests
  test/event_intelligence_test.cpp
  src/intelligence/event_intelligence.cpp
  src/intelligence/crash_explainer.cpp
  src/intelligence/wake_explainer.cpp
  src/intelligence/bugcheck_catalog.cpp
  src/intelligence/app_crash_explainer.cpp
  src/intelligence/exception_catalog.cpp
)
target_include_directories(event_intelligence_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(event_intelligence_tests PRIVATE pulse_wire)
add_test(NAME event_intelligence_tests COMMAND event_intelligence_tests)

add_executable(crash_explainer_tests
  test/crash_explainer_test.cpp
  src/intelligence/event_intelligence.cpp
  src/intelligence/crash_explainer.cpp
  src/intelligence/wake_explainer.cpp
  src/intelligence/bugcheck_catalog.cpp
  src/intelligence/app_crash_explainer.cpp
  src/intelligence/exception_catalog.cpp
)
target_include_directories(crash_explainer_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(crash_explainer_tests PRIVATE pulse_wire)
add_test(NAME crash_explainer_tests COMMAND crash_explainer_tests)

add_executable(app_crash_explainer_tests
  test/app_crash_explainer_test.cpp
  src/intelligence/event_intelligence.cpp
  src/intelligence/crash_explainer.cpp
  src/intelligence/wake_explainer.cpp
  src/intelligence/bugcheck_catalog.cpp
  src/intelligence/app_crash_explainer.cpp
  src/intelligence/exception_catalog.cpp
)
target_include_directories(app_crash_explainer_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(app_crash_explainer_tests PRIVATE pulse_wire)
add_test(NAME app_crash_explainer_tests COMMAND app_crash_explainer_tests)

add_executable(crash_history_tests
  test/crash_history_test.cpp
  src/intelligence/crash_history.cpp
  src/intelligence/event_intelligence.cpp
  src/intelligence/crash_explainer.cpp
  src/intelligence/wake_explainer.cpp
  src/intelligence/bugcheck_catalog.cpp
  src/intelligence/app_crash_explainer.cpp
  src/intelligence/exception_catalog.cpp
)
target_include_directories(crash_history_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(crash_history_tests PRIVATE pulse_wire)
add_test(NAME crash_history_tests COMMAND crash_history_tests)

add_executable(logger_tests
  test/logger_test.cpp
  src/logging/logger.cpp
)
target_include_directories(logger_tests PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
add_test(NAME logger_tests COMMAND logger_tests)

add_executable(wake_explainer_tests
  test/wake_explainer_test.cpp
  src/intelligence/event_intelligence.cpp
  src/intelligence/crash_explainer.cpp
  src/intelligence/wake_explainer.cpp
  src/intelligence/bugcheck_catalog.cpp
  src/intelligence/app_crash_explainer.cpp
  src/intelligence/exception_catalog.cpp
)
target_include_directories(wake_explainer_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(wake_explainer_tests PRIVATE pulse_wire)
add_test(NAME wake_explainer_tests COMMAND wake_explainer_tests)

add_executable(secure_boot_rules_tests
  test/secure_boot_rules_test.cpp
  src/intelligence/event_intelligence.cpp
  src/intelligence/crash_explainer.cpp
  src/intelligence/wake_explainer.cpp
  src/intelligence/bugcheck_catalog.cpp
  src/intelligence/app_crash_explainer.cpp
  src/intelligence/exception_catalog.cpp
)
target_include_directories(secure_boot_rules_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(secure_boot_rules_tests PRIVATE pulse_wire)
add_test(NAME secure_boot_rules_tests COMMAND secure_boot_rules_tests)

add_executable(disk_health_tests
  test/disk_health_test.cpp
  src/collectors/disk_health.cpp
)
target_include_directories(disk_health_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(disk_health_tests PRIVATE pulse_wire)
add_test(NAME disk_health_tests COMMAND disk_health_tests)

add_executable(event_log_channel_catalog_tests
  test/event_log_channel_catalog_test.cpp
  src/collectors/event_log_channel_catalog.cpp
  src/windows/wevt_helpers.cpp
  src/logging/logger.cpp
)
target_include_directories(event_log_channel_catalog_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(event_log_channel_catalog_tests PRIVATE
  pulse_wire wevtapi ole32 advapi32 psapi
)
add_test(NAME event_log_channel_catalog_tests
  COMMAND event_log_channel_catalog_tests)

add_executable(gpu_engine_load_tests
  test/gpu_engine_load_test.cpp
  src/collectors/gpu_engine_load.cpp
)
target_include_directories(gpu_engine_load_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
)
add_test(NAME gpu_engine_load_tests COMMAND gpu_engine_load_tests)

add_executable(services_collector_tests
  test/services_collector_test.cpp
  src/inventory/services_collector.cpp
  src/windows/wevt_helpers.cpp
)
target_include_directories(services_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(services_collector_tests PRIVATE pulse_wire Advapi32 Wevtapi)
add_test(NAME services_collector_tests COMMAND services_collector_tests)

add_executable(drivers_collector_tests
  test/drivers_collector_test.cpp
  src/inventory/drivers_collector.cpp
  src/windows/wevt_helpers.cpp
)
target_include_directories(drivers_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(drivers_collector_tests PRIVATE pulse_wire Advapi32 Wevtapi)
add_test(NAME drivers_collector_tests COMMAND drivers_collector_tests)

add_executable(software_collector_tests
  test/software_collector_test.cpp
  src/inventory/software_collector.cpp
  src/windows/wevt_helpers.cpp
)
target_include_directories(software_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(software_collector_tests PRIVATE pulse_wire Advapi32 Wevtapi)
add_test(NAME software_collector_tests COMMAND software_collector_tests)

add_executable(usb_collector_tests
  test/usb_collector_test.cpp
  src/inventory/usb_collector.cpp
  src/inventory/setupapi_device_enumerator.cpp
  src/windows/wevt_helpers.cpp
)
target_include_directories(usb_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(usb_collector_tests PRIVATE pulse_wire Advapi32 Wevtapi setupapi cfgmgr32)
add_test(NAME usb_collector_tests COMMAND usb_collector_tests)

add_executable(pci_collector_tests
  test/pci_collector_test.cpp
  src/inventory/pci_collector.cpp
  src/inventory/setupapi_device_enumerator.cpp
  src/windows/wevt_helpers.cpp
)
target_include_directories(pci_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(pci_collector_tests PRIVATE pulse_wire Advapi32 Wevtapi setupapi cfgmgr32)
add_test(NAME pci_collector_tests COMMAND pci_collector_tests)

add_executable(displays_collector_tests
  test/displays_collector_test.cpp
  src/inventory/displays_collector.cpp
  src/inventory/setupapi_device_enumerator.cpp
  src/windows/wevt_helpers.cpp
)
target_include_directories(displays_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(displays_collector_tests PRIVATE pulse_wire Advapi32 Wevtapi setupapi cfgmgr32)
add_test(NAME displays_collector_tests COMMAND displays_collector_tests)

add_executable(audio_collector_tests
  test/audio_collector_test.cpp
  src/inventory/audio_collector.cpp
  src/inventory/setupapi_device_enumerator.cpp
  src/windows/wevt_helpers.cpp
)
target_include_directories(audio_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(audio_collector_tests PRIVATE pulse_wire Advapi32 Wevtapi setupapi cfgmgr32)
add_test(NAME audio_collector_tests COMMAND audio_collector_tests)

add_executable(bluetooth_collector_tests
  test/bluetooth_collector_test.cpp
  src/inventory/bluetooth_collector.cpp
  src/inventory/setupapi_device_enumerator.cpp
  src/windows/wevt_helpers.cpp
)
target_include_directories(bluetooth_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(bluetooth_collector_tests PRIVATE pulse_wire Advapi32 Wevtapi setupapi cfgmgr32)
add_test(NAME bluetooth_collector_tests COMMAND bluetooth_collector_tests)

add_executable(printers_collector_tests
  test/printers_collector_test.cpp
  src/inventory/printers_collector.cpp
  src/windows/wevt_helpers.cpp
)
target_include_directories(printers_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(printers_collector_tests PRIVATE pulse_wire Advapi32 Wevtapi winspool)
add_test(NAME printers_collector_tests COMMAND printers_collector_tests)

add_executable(battery_collector_tests
  test/battery_collector_test.cpp
  src/inventory/battery_collector.cpp
  src/inventory/setupapi_device_enumerator.cpp
  src/windows/wevt_helpers.cpp
)
target_include_directories(battery_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(battery_collector_tests PRIVATE pulse_wire Advapi32 Wevtapi setupapi cfgmgr32)
add_test(NAME battery_collector_tests COMMAND battery_collector_tests)

add_executable(motherboard_collector_tests
  test/motherboard_collector_test.cpp
  src/inventory/motherboard_collector.cpp
  src/inventory/smbios_table.cpp
)
target_include_directories(motherboard_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(motherboard_collector_tests PRIVATE pulse_wire)
add_test(NAME motherboard_collector_tests COMMAND motherboard_collector_tests)

add_executable(bios_collector_tests
  test/bios_collector_test.cpp
  src/inventory/bios_collector.cpp
  src/inventory/smbios_table.cpp
)
target_include_directories(bios_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(bios_collector_tests PRIVATE pulse_wire)
add_test(NAME bios_collector_tests COMMAND bios_collector_tests)

add_executable(memory_modules_collector_tests
  test/memory_modules_collector_test.cpp
  src/inventory/memory_modules_collector.cpp
  src/inventory/smbios_table.cpp
)
target_include_directories(memory_modules_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(memory_modules_collector_tests PRIVATE pulse_wire)
add_test(NAME memory_modules_collector_tests COMMAND memory_modules_collector_tests)

add_executable(windows_edition_tests
  test/windows_edition_test.cpp
  src/util/windows_edition.cpp
)
target_include_directories(windows_edition_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
)
add_test(NAME windows_edition_tests COMMAND windows_edition_tests)

add_executable(cpu_collector_tests
  test/cpu_collector_test.cpp
  src/inventory/cpu_collector.cpp
)
target_include_directories(cpu_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(cpu_collector_tests PRIVATE pulse_wire Advapi32)
add_test(NAME cpu_collector_tests COMMAND cpu_collector_tests)

add_executable(storage_collector_tests
  test/storage_collector_test.cpp
  src/inventory/storage_collector.cpp
  src/windows/wevt_helpers.cpp
)
target_include_directories(storage_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(storage_collector_tests PRIVATE pulse_wire Advapi32 Wevtapi setupapi cfgmgr32)
add_test(NAME storage_collector_tests COMMAND storage_collector_tests)

add_executable(network_adapters_collector_tests
  test/network_adapters_collector_test.cpp
  src/inventory/network_adapters_collector.cpp
)
target_include_directories(network_adapters_collector_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(network_adapters_collector_tests PRIVATE pulse_wire Advapi32 iphlpapi ws2_32)
add_test(NAME network_adapters_collector_tests COMMAND network_adapters_collector_tests)

add_executable(inventory_engine_smoke_tests
  test/inventory_engine_smoke_test.cpp
  src/inventory/inventory_engine.cpp
  src/inventory/services_collector.cpp
  src/inventory/drivers_collector.cpp
  src/inventory/software_collector.cpp
  src/inventory/usb_collector.cpp
  src/inventory/pci_collector.cpp
  src/inventory/displays_collector.cpp
  src/inventory/audio_collector.cpp
  src/inventory/bluetooth_collector.cpp
  src/inventory/printers_collector.cpp
  src/inventory/battery_collector.cpp
  src/inventory/setupapi_device_enumerator.cpp
  src/inventory/smbios_table.cpp
  src/inventory/motherboard_collector.cpp
  src/inventory/bios_collector.cpp
  src/inventory/memory_modules_collector.cpp
  src/inventory/cpu_collector.cpp
  src/inventory/storage_collector.cpp
  src/inventory/network_adapters_collector.cpp
  src/windows/wevt_helpers.cpp
)
target_include_directories(inventory_engine_smoke_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(inventory_engine_smoke_tests PRIVATE pulse_wire Advapi32 Wevtapi setupapi cfgmgr32 winspool iphlpapi ws2_32)
add_test(NAME inventory_engine_smoke_tests COMMAND inventory_engine_smoke_tests)

add_executable(inventory_dump_tests
  test/inventory_dump_test.cpp
  src/inventory/inventory_engine.cpp
  src/inventory/services_collector.cpp
  src/inventory/drivers_collector.cpp
  src/inventory/software_collector.cpp
  src/inventory/usb_collector.cpp
  src/inventory/pci_collector.cpp
  src/inventory/displays_collector.cpp
  src/inventory/audio_collector.cpp
  src/inventory/bluetooth_collector.cpp
  src/inventory/printers_collector.cpp
  src/inventory/battery_collector.cpp
  src/inventory/setupapi_device_enumerator.cpp
  src/inventory/smbios_table.cpp
  src/inventory/motherboard_collector.cpp
  src/inventory/bios_collector.cpp
  src/inventory/memory_modules_collector.cpp
  src/inventory/cpu_collector.cpp
  src/inventory/storage_collector.cpp
  src/inventory/network_adapters_collector.cpp
  src/windows/wevt_helpers.cpp
)
target_include_directories(inventory_dump_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(inventory_dump_tests PRIVATE pulse_wire Advapi32 Wevtapi setupapi cfgmgr32 winspool iphlpapi ws2_32)

add_executable(ipc_client_thread_lifetime_test
  test/ipc_client_thread_lifetime_test.cpp
)
add_test(NAME ipc_client_thread_lifetime_test
         COMMAND ipc_client_thread_lifetime_test)

# Optional IPC ping tool (same tree)
add_executable(pulse_ipc_ping
  "${PULSE_ROOT}/tools/ipc_ping/pulse_ipc_ping.cpp"
)
target_include_directories(pulse_ipc_ping PRIVATE
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(pulse_ipc_ping PRIVATE pulse_wire)

add_executable(pulse_health_ping
  "${PULSE_ROOT}/tools/ipc_ping/pulse_health_ping.cpp"
)
target_include_directories(pulse_health_ping PRIVATE
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(pulse_health_ping PRIVATE pulse_wire)

add_executable(pulse_diagnostics_ping
  "${PULSE_ROOT}/tools/ipc_ping/pulse_diagnostics_ping.cpp"
)
target_include_directories(pulse_diagnostics_ping PRIVATE
  "${PULSE_ROOT}/shared/pulse_protocol/cpp"
  "${PULSE_ROOT}/shared/pulse_common/include"
)
target_link_libraries(pulse_diagnostics_ping PRIVATE pulse_wire)
