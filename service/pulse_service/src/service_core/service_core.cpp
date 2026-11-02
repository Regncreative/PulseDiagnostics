#include "service_core/service_core.hpp"

#include "collector/event_engine.hpp"
#include "logging/logger.hpp"
#include "pulse/constants.hpp"
#include "windows/wevt_helpers.hpp"

#include <atomic>
#include <iostream>
#include <string>

#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <appmodel.h>
#include <winsvc.h>

namespace pulse {
namespace {

/// True when this process has an MSIX / Store package identity.
bool IsRunningAsPackagedApp() {
  UINT32 length = 0;
  const LONG rc = GetCurrentPackageFullName(&length, nullptr);
  return rc == ERROR_INSUFFICIENT_BUFFER;
}

int RefusePackagedScmSelfInstall(const wchar_t* action) {
  std::wcerr
      << L"PulseService " << action
      << L" is not allowed under an MSIX / Microsoft Store package.\n"
      << L"Windows registers PulseService via the package AppxManifest "
         L"(desktop6:Service).\n"
      << L"Use --start / --stop / --restart, or repair the app from the Store.\n";
  return 3;
}

SERVICE_STATUS_HANDLE g_status_handle = nullptr;
SERVICE_STATUS g_status{};
ServiceCore* g_core = nullptr;
std::atomic<bool> g_stop_console{false};

void ReportStatus(DWORD state, DWORD exit_code = NO_ERROR, DWORD wait_hint_ms = 0) {
  static DWORD checkpoint = 1;
  g_status.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
  g_status.dwCurrentState = state;
  g_status.dwWin32ExitCode = exit_code;
  g_status.dwWaitHint = wait_hint_ms;
  if (state == SERVICE_START_PENDING || state == SERVICE_STOP_PENDING) {
    g_status.dwControlsAccepted = 0;
    g_status.dwCheckPoint = checkpoint++;
  } else {
    g_status.dwControlsAccepted = SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN;
    g_status.dwCheckPoint = 0;
  }
  if (g_status_handle) {
    SetServiceStatus(g_status_handle, &g_status);
  }
}

DWORD WINAPI ServiceCtrlHandler(DWORD control, DWORD, LPVOID, LPVOID) {
  switch (control) {
    case SERVICE_CONTROL_STOP:
    case SERVICE_CONTROL_SHUTDOWN:
      ReportStatus(SERVICE_STOP_PENDING, NO_ERROR, 10000);
      if (g_core) g_core->Stop();
      return NO_ERROR;
    default:
      return ERROR_CALL_NOT_IMPLEMENTED;
  }
}

BOOL WINAPI ConsoleCtrlHandler(DWORD type) {
  if (type == CTRL_C_EVENT || type == CTRL_CLOSE_EVENT || type == CTRL_BREAK_EVENT) {
    g_stop_console = true;
    return TRUE;
  }
  return FALSE;
}

bool BootstrapFromDisk(ServiceConfig* config) {
  std::string err;
  const auto cfg_path = DefaultProgramDataPulseDir() + L"\\config.json";
  WriteDefaultConfigIfMissing(cfg_path, &err);
  if (!LoadConfig(cfg_path, config, &err)) {
    Logger::Instance().Error("ServiceCore", "Config load failed: " + err);
    return false;
  }
  if (!EnsureDataDirectories(*config, &err)) {
    Logger::Instance().Error("ServiceCore", "Data dirs failed: " + err);
    return false;
  }
  Logger::Instance().SetLogDirectory(config->log_dir);
  if (config->log_level == "debug") {
    Logger::Instance().SetLevel(LogLevel::Debug);
  }
  return true;
}

void WINAPI ServiceMain(DWORD, LPWSTR*) {
  g_status_handle =
      RegisterServiceCtrlHandlerExW(L"PulseService", ServiceCtrlHandler, nullptr);
  if (!g_status_handle) return;

  ReportStatus(SERVICE_START_PENDING, NO_ERROR, 5000);

  ServiceConfig config = DefaultConfig();
  if (!BootstrapFromDisk(&config)) {
    ReportStatus(SERVICE_STOPPED, ERROR_SERVICE_SPECIFIC_ERROR);
    return;
  }

  ServiceCore core;
  g_core = &core;
  if (!core.Initialize(config)) {
    g_core = nullptr;
    ReportStatus(SERVICE_STOPPED, ERROR_SERVICE_SPECIFIC_ERROR);
    return;
  }
  core.SetRunMode("Windows Service");
  if (!core.Start()) {
    g_core = nullptr;
    ReportStatus(SERVICE_STOPPED, ERROR_SERVICE_SPECIFIC_ERROR);
    return;
  }
  ReportStatus(SERVICE_RUNNING);
  Logger::Instance().Info("ServiceCore", "PulseService running");

  while (core.IsRunning()) {
    Sleep(200);
  }

  g_core = nullptr;
  ReportStatus(SERVICE_STOPPED);
}

}  // namespace

bool ServiceCore::Initialize(const ServiceConfig& config) {
  config_ = config;
  collector_ = std::make_unique<Collector>();
  ipc_ = std::make_unique<IpcServer>(config_.pipe_name, config_.live_queue_capacity,
                                     config_.max_pipe_instances);
  ipc_->SetTrackedChannelsPath(DefaultProgramDataPulseDir() +
                               L"\\tracked_channels.json");
  EventEnginePlaceholder engine;
  Logger::Instance().Info("ServiceCore",
                          std::string("Initialized placeholder ") + engine.Name());
  return true;
}

void ServiceCore::SetRunMode(std::string mode) {
  if (ipc_) ipc_->SetRunMode(std::move(mode));
}

bool ServiceCore::Start() {
  if (!collector_->Start()) return false;
  if (!ipc_->Start()) return false;
  running_ = true;
  return true;
}

void ServiceCore::Stop() {
  if (!running_.exchange(false)) return;
  Logger::Instance().Info("ServiceCore", "Stopping");
  if (ipc_) ipc_->Stop();
  if (collector_) collector_->Stop();
}

int InstallService() {
  if (IsRunningAsPackagedApp()) {
    return RefusePackagedScmSelfInstall(L"--install");
  }

  wchar_t path[MAX_PATH];
  if (!GetModuleFileNameW(nullptr, path, MAX_PATH)) return 1;
  // Quote the image path: an unquoted path with spaces (C:\Program Files\...)
  // makes the SCM probe C:\Program.exe first (unquoted service path).
  const std::wstring binary_path = L"\"" + std::wstring(path) + L"\"";
  const std::wstring display_name = wevt::Utf8ToWide(kServiceDisplayName);

  SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_ALL_ACCESS);
  if (!scm) {
    std::wcerr << L"OpenSCManager failed. Run as Administrator.\n";
    return 1;
  }

  SC_HANDLE svc = OpenServiceW(scm, L"PulseService", SERVICE_ALL_ACCESS);
  if (svc) {
    // Already installed — refresh binary path + auto-start.
    if (!ChangeServiceConfigW(svc, SERVICE_WIN32_OWN_PROCESS, SERVICE_AUTO_START,
                              SERVICE_ERROR_NORMAL, binary_path.c_str(), nullptr,
                              nullptr, nullptr,
                              L"NT AUTHORITY\\LocalService", nullptr,
                              display_name.c_str())) {
      const DWORD err = GetLastError();
      CloseServiceHandle(svc);
      CloseServiceHandle(scm);
      std::wcerr << L"ChangeServiceConfig failed: " << err << L"\n";
      return 1;
    }
  } else {
    svc = CreateServiceW(
        scm, L"PulseService", display_name.c_str(), SERVICE_ALL_ACCESS,
        SERVICE_WIN32_OWN_PROCESS, SERVICE_AUTO_START, SERVICE_ERROR_NORMAL,
        binary_path.c_str(), nullptr, nullptr, nullptr, L"NT AUTHORITY\\LocalService",
        nullptr);
    if (!svc) {
      const DWORD err = GetLastError();
      CloseServiceHandle(scm);
      std::wcerr << L"CreateService failed: " << err << L"\n";
      return 1;
    }
  }

  SERVICE_DESCRIPTIONW desc{};
  wchar_t text[] = L"Read-only Windows diagnostics collector for Pulse Diagnostics";
  desc.lpDescription = text;
  ChangeServiceConfig2W(svc, SERVICE_CONFIG_DESCRIPTION, &desc);

  CloseServiceHandle(svc);
  CloseServiceHandle(scm);
  std::wcout << L"PulseService installed (auto-start).\n";
  return 0;
}

int StartPulseServiceAndWait(DWORD timeout_ms) {
  SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_CONNECT);
  if (!scm) return 1;

  SC_HANDLE svc = OpenServiceW(scm, L"PulseService",
                               SERVICE_START | SERVICE_QUERY_STATUS);
  if (!svc) {
    const DWORD err = GetLastError();
    CloseServiceHandle(scm);
    if (err == ERROR_SERVICE_DOES_NOT_EXIST) {
      std::wcerr << L"PulseService is not installed.\n";
      return 2;
    }
    std::wcerr << L"OpenService failed for start: " << err << L"\n";
    return 1;
  }

  SERVICE_STATUS_PROCESS ssp{};
  DWORD bytes = 0;
  if (!QueryServiceStatusEx(svc, SC_STATUS_PROCESS_INFO,
                            reinterpret_cast<LPBYTE>(&ssp), sizeof(ssp),
                            &bytes)) {
    CloseServiceHandle(svc);
    CloseServiceHandle(scm);
    return 1;
  }

  if (ssp.dwCurrentState != SERVICE_RUNNING &&
      ssp.dwCurrentState != SERVICE_START_PENDING) {
    if (!StartServiceW(svc, 0, nullptr)) {
      const DWORD err = GetLastError();
      if (err != ERROR_SERVICE_ALREADY_RUNNING) {
        CloseServiceHandle(svc);
        CloseServiceHandle(scm);
        std::wcerr << L"StartService failed: " << err << L"\n";
        return 1;
      }
    }
  }

  const DWORD deadline = GetTickCount() + timeout_ms;
  for (;;) {
    if (!QueryServiceStatusEx(svc, SC_STATUS_PROCESS_INFO,
                              reinterpret_cast<LPBYTE>(&ssp), sizeof(ssp),
                              &bytes)) {
      CloseServiceHandle(svc);
      CloseServiceHandle(scm);
      return 1;
    }
    if (ssp.dwCurrentState == SERVICE_RUNNING) {
      // Confirm it stays up briefly (catches immediate SCM crash-loop).
      Sleep(1500);
      if (!QueryServiceStatusEx(svc, SC_STATUS_PROCESS_INFO,
                                reinterpret_cast<LPBYTE>(&ssp), sizeof(ssp),
                                &bytes) ||
          ssp.dwCurrentState != SERVICE_RUNNING) {
        CloseServiceHandle(svc);
        CloseServiceHandle(scm);
        std::wcerr << L"PulseService started then stopped unexpectedly.\n";
        return 1;
      }
      CloseServiceHandle(svc);
      CloseServiceHandle(scm);
      std::wcout << L"PulseService is running.\n";
      return 0;
    }
    if (GetTickCount() > deadline) {
      CloseServiceHandle(svc);
      CloseServiceHandle(scm);
      std::wcerr << L"Timed out waiting for PulseService to start.\n";
      return 1;
    }
    Sleep(200);
  }
}

int InstallAndStartService() {
  const int installed = InstallService();
  if (installed != 0) return installed;
  return StartPulseServiceAndWait(20000);
}

int StartInstalledService() { return StartPulseServiceAndWait(20000); }

int StopPulseServiceAndWait(DWORD timeout_ms) {
  SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_CONNECT);
  if (!scm) {
    std::wcerr << L"OpenSCManager failed. Run as Administrator.\n";
    return 1;
  }

  SC_HANDLE svc = OpenServiceW(scm, L"PulseService",
                               SERVICE_STOP | SERVICE_QUERY_STATUS);
  if (!svc) {
    const DWORD err = GetLastError();
    CloseServiceHandle(scm);
    if (err == ERROR_SERVICE_DOES_NOT_EXIST) {
      std::wcerr << L"PulseService is not installed.\n";
      return 2;
    }
    std::wcerr << L"OpenService failed for stop: " << err << L"\n";
    return 1;
  }

  SERVICE_STATUS_PROCESS ssp{};
  DWORD bytes = 0;
  if (!QueryServiceStatusEx(svc, SC_STATUS_PROCESS_INFO,
                            reinterpret_cast<LPBYTE>(&ssp), sizeof(ssp),
                            &bytes)) {
    CloseServiceHandle(svc);
    CloseServiceHandle(scm);
    return 1;
  }

  if (ssp.dwCurrentState != SERVICE_STOPPED &&
      ssp.dwCurrentState != SERVICE_STOP_PENDING) {
    SERVICE_STATUS status{};
    if (!ControlService(svc, SERVICE_CONTROL_STOP, &status)) {
      const DWORD err = GetLastError();
      if (err != ERROR_SERVICE_NOT_ACTIVE) {
        CloseServiceHandle(svc);
        CloseServiceHandle(scm);
        std::wcerr << L"ControlService(STOP) failed: " << err << L"\n";
        return 1;
      }
    }
  }

  const DWORD deadline = GetTickCount() + timeout_ms;
  for (;;) {
    if (!QueryServiceStatusEx(svc, SC_STATUS_PROCESS_INFO,
                              reinterpret_cast<LPBYTE>(&ssp), sizeof(ssp),
                              &bytes)) {
      CloseServiceHandle(svc);
      CloseServiceHandle(scm);
      return 1;
    }
    if (ssp.dwCurrentState == SERVICE_STOPPED) {
      CloseServiceHandle(svc);
      CloseServiceHandle(scm);
      std::wcout << L"PulseService is stopped.\n";
      return 0;
    }
    if (GetTickCount() > deadline) {
      CloseServiceHandle(svc);
      CloseServiceHandle(scm);
      std::wcerr << L"Timed out waiting for PulseService to stop.\n";
      return 1;
    }
    Sleep(200);
  }
}

int StopInstalledService() { return StopPulseServiceAndWait(20000); }

int RestartInstalledService() {
  // Best-effort stop; continue if already stopped.
  StopPulseServiceAndWait(20000);
  return StartPulseServiceAndWait(20000);
}

int PrintServiceStatus() {
  SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_CONNECT);
  if (!scm) {
    std::wcout << L"unknown\n";
    return 1;
  }

  SC_HANDLE svc =
      OpenServiceW(scm, L"PulseService", SERVICE_QUERY_STATUS);
  if (!svc) {
    const DWORD err = GetLastError();
    CloseServiceHandle(scm);
    if (err == ERROR_SERVICE_DOES_NOT_EXIST) {
      std::wcout << L"not_installed\n";
      return 0;
    }
    std::wcout << L"unknown\n";
    return 1;
  }

  SERVICE_STATUS_PROCESS ssp{};
  DWORD bytes = 0;
  if (!QueryServiceStatusEx(svc, SC_STATUS_PROCESS_INFO,
                            reinterpret_cast<LPBYTE>(&ssp), sizeof(ssp),
                            &bytes)) {
    CloseServiceHandle(svc);
    CloseServiceHandle(scm);
    std::wcout << L"unknown\n";
    return 1;
  }

  CloseServiceHandle(svc);
  CloseServiceHandle(scm);

  switch (ssp.dwCurrentState) {
    case SERVICE_STOPPED:
      std::wcout << L"stopped\n";
      break;
    case SERVICE_START_PENDING:
      std::wcout << L"start_pending\n";
      break;
    case SERVICE_STOP_PENDING:
      std::wcout << L"stop_pending\n";
      break;
    case SERVICE_RUNNING:
      std::wcout << L"running\n";
      break;
    default:
      std::wcout << L"unknown\n";
      break;
  }
  return 0;
}

int UninstallService() {
  if (IsRunningAsPackagedApp()) {
    return RefusePackagedScmSelfInstall(L"--uninstall");
  }

  SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_CONNECT);
  if (!scm) return 1;
  SC_HANDLE svc = OpenServiceW(scm, L"PulseService", SERVICE_STOP | DELETE);
  if (!svc) {
    CloseServiceHandle(scm);
    std::wcerr << L"OpenService failed.\n";
    return 1;
  }
  SERVICE_STATUS status{};
  ControlService(svc, SERVICE_CONTROL_STOP, &status);
  if (!DeleteService(svc)) {
    std::wcerr << L"DeleteService failed.\n";
    CloseServiceHandle(svc);
    CloseServiceHandle(scm);
    return 1;
  }
  CloseServiceHandle(svc);
  CloseServiceHandle(scm);
  std::wcout << L"PulseService uninstalled.\n";
  return 0;
}

int RunConsoleMode(int argc, wchar_t** argv) {
  SetConsoleCtrlHandler(ConsoleCtrlHandler, TRUE);
  ServiceConfig config = DefaultConfig();
  if (!BootstrapFromDisk(&config)) return 1;

  // Development only: `--pipe <name>` runs a second instance next to the
  // installed service (e.g. to test client reconnect without stopping it).
  for (int i = 1; i + 1 < argc; ++i) {
    if (std::wstring(argv[i]) == L"--pipe") {
      config.pipe_name = argv[i + 1];
    }
  }

  ServiceCore core;
  if (!core.Initialize(config)) return 1;
  core.SetRunMode("Console");
  if (!core.Start()) return 1;
  Logger::Instance().Info("ServiceCore", "Console mode running. Ctrl+C to stop.");
  std::wcout << L"PulseService console mode. Pipe: " << config.pipe_name << L"\n";
  std::wcout << L"Historical Timeline snapshot available via GetTimelineSnapshot (System).\n";

  while (!g_stop_console && core.IsRunning()) {
    Sleep(200);
  }
  core.Stop();
  Logger::Instance().Info("ServiceCore", "Console mode stopped");
  return 0;
}

int RunServiceMode() {
  SERVICE_TABLE_ENTRYW table[] = {
      {const_cast<LPWSTR>(L"PulseService"), ServiceMain},
      {nullptr, nullptr},
  };
  if (!StartServiceCtrlDispatcherW(table)) {
    std::wcerr << L"StartServiceCtrlDispatcher failed. Use --console for interactive.\n";
    return 1;
  }
  return 0;
}

}  // namespace pulse
