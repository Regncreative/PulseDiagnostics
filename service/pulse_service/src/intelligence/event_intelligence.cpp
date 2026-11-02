#include "intelligence/event_intelligence.hpp"

#include "intelligence/crash_explainer.hpp"
#include "intelligence/wake_explainer.hpp"
#include "util/text_match.hpp"

#include <string_view>
#include <utility>

namespace pulse {
namespace {

struct IntelligenceRule {
  std::uint32_t event_id = 0;
  /// Case-insensitive substring of provider_name; empty = any provider.
  std::string_view provider_hint;
  std::string_view title;
  std::string_view summary;
  /// Empty string = omit recommendation in UI.
  std::string_view recommendation;
  bool action_required = false;
  Importance importance = Importance::Low;
  InsightCategory category = InsightCategory::General;
};

// Append-only catalog. Matching logic stays in MatchRule.
// Event IDs are Microsoft-documented (Wevtapi / Event Viewer / Learn).
// More specific provider hints are listed before broader ones for the same ID.
constexpr IntelligenceRule kRules[] = {
    // --- COM / existing ---
    {10016, "DistributedCOM", "COM Permission Warning",
     "An application attempted to access a COM component without sufficient "
     "permissions.",
     "Usually harmless unless an application is failing to start.", false,
     Importance::Low, InsightCategory::Com},

    // --- Service Control Manager ---
    {7040, "Service Control Manager", "Windows Service Configuration Changed",
     "Windows updated the startup configuration of a background service.", "",
     false, Importance::Low, InsightCategory::Service},

    {7036, "Service Control Manager", "Windows Service State Changed",
     "A Windows service started, stopped, or changed its running state.", "",
     false, Importance::Low, InsightCategory::Service},

    {7023, "Service Control Manager", "Windows Service Failed",
     "A Windows service reported an error and stopped or failed to complete "
     "its operation.",
     "Check the service name in the event details and recent application or "
     "driver changes.",
     true, Importance::High, InsightCategory::Service},

    {7031, "Service Control Manager", "Windows Service Crashed",
     "A Windows service terminated unexpectedly and Windows scheduled a "
     "recovery action.",
     "Repeated crashes for the same service usually mean a deeper fault.", true,
     Importance::High, InsightCategory::Service},

    {7034, "Service Control Manager", "Windows Service Stopped Unexpectedly",
     "A Windows service terminated unexpectedly.",
     "Look for matching application or driver errors around the same time.",
     true, Importance::High, InsightCategory::Service},

    {7045, "Service Control Manager", "New Service or Driver Installed",
     "Windows recorded that a service or driver was installed on this system.",
     "", false, Importance::Medium, InsightCategory::Driver},

    // --- Network / HTTP (existing) ---
    {4266, "Tcpip", "Temporary UDP Port Allocation Failed",
     "Windows could not allocate a temporary UDP port because the ephemeral "
     "port range is exhausted.",
     "Identify which process is holding UDP ports (for example with "
     "netstat). Reboot may temporarily clear the issue.",
     true, Importance::High, InsightCategory::Network},

    {4231, "Tcpip", "Temporary TCP Port Allocation Failed",
     "Windows could not allocate a temporary TCP port because the ephemeral "
     "port range is exhausted.",
     "Identify which process is holding TCP ports. This often breaks "
     "outbound network connections until ports are freed.",
     true, Importance::High, InsightCategory::Network},

    {114, "HttpService", "HTTP Service Endpoint Removed",
     "An HTTP URL endpoint was removed from the Windows HTTP service.", "",
     false, Importance::Low, InsightCategory::Http},

    {32, "HttpService", "HTTP Service Endpoint Removed",
     "An HTTP URL endpoint was removed from the Windows HTTP service.", "",
     false, Importance::Low, InsightCategory::Http},

    // --- Boot / shutdown ---
    {12, "Kernel-General", "Windows Started",
     "Windows has started successfully.", "", false, Importance::Low,
     InsightCategory::Boot},

    {13, "Kernel-General", "Windows Shutdown", "Windows has shut down.", "",
     false, Importance::Low, InsightCategory::Boot},

    {6005, "EventLog", "Event Log Service Started",
     "The Windows Event Log service started (typical at boot).", "", false,
     Importance::Low, InsightCategory::Boot},

    {6006, "EventLog", "Event Log Service Stopped",
     "The Windows Event Log service stopped (typical during a clean shutdown).",
     "", false, Importance::Low, InsightCategory::Boot},

    {1074, "User32", "Shutdown or Restart Initiated",
     "A user or application initiated a shutdown or restart.", "", false,
     Importance::Low, InsightCategory::Boot},

    // --- Unexpected power / dirty shutdown ---
    {41, "Kernel-Power", "Windows Restarted Unexpectedly",
     "Windows rebooted without cleanly shutting down first. This can happen "
     "after a crash, hang, or sudden power loss.",
     "Check for a matching bug check (Event ID 1001) and recent driver or "
     "hardware changes.",
     true, Importance::Critical, InsightCategory::Power},

    {6008, "EventLog", "Previous Shutdown Was Unexpected",
     "Windows recorded that the previous system shutdown was unexpected.",
     "Correlate with Kernel-Power 41 and any bug check events nearby.", true,
     Importance::High, InsightCategory::Power},

    // --- Sleep / wake (Microsoft-documented System log events) ---
    {42, "Kernel-Power", "Windows Entered Sleep",
     "The system is entering a sleep state.", "", false, Importance::Low,
     InsightCategory::Power},

    {107, "Kernel-Power", "Windows Resumed From Sleep",
     "The system has resumed from sleep.", "", false, Importance::Low,
     InsightCategory::Power},

    {1, "Power-Troubleshooter", "Windows Woke From Sleep",
     "Windows woke from sleep or hibernation.", "", false, Importance::Low,
     InsightCategory::Power},

    // --- Time (existing) ---
    {158, "Time-Service", "Time Synchronization Stopped",
     "The Windows time synchronization provider stopped.",
     "Usually expected on systems without Hyper-V.", false, Importance::Low,
     InsightCategory::Time},

    // --- Crash / BSOD / application faults ---
    // Prefer specific bugcheck providers before generic WER 1001.
    {1001, "WER-SystemErrorReporting", "Windows Stopped Unexpectedly",
     "Windows recorded a bug check (blue screen) and may have saved a crash "
     "dump.",
     "Open the dump path from the event details in a debugger when you need "
     "the faulting module.",
     true, Importance::Critical, InsightCategory::Crash},

    {1001, "BugCheck", "Windows Stopped Unexpectedly",
     "Windows recorded a bug check (blue screen).",
     "Review the bug check code and recent driver changes.", true,
     Importance::Critical, InsightCategory::Crash},

    {1000, "Application Error", "Application Crashed",
     "An application exited unexpectedly after a fault.",
     "Note the faulting application and module in the event details.", true,
     Importance::High, InsightCategory::Crash},

    {1002, "Application Hang", "Application Stopped Responding",
     "Windows detected that an application stopped responding.",
     "If this repeats for the same app, check for updates or conflicting "
     "extensions.",
     false, Importance::Medium, InsightCategory::Crash},

    {1001, "Windows Error Reporting", "Windows Error Reporting Recorded a Problem",
     "Windows Error Reporting captured a problem report for an application or "
     "component.",
     "", false, Importance::Medium, InsightCategory::Crash},

    // --- Windows Update ---
    {19, "WindowsUpdateClient", "Windows Update Installed Successfully",
     "Windows successfully installed an update.", "", false, Importance::Low,
     InsightCategory::Update},

    {20, "WindowsUpdateClient", "Windows Update Installation Failed",
     "Windows failed to install an update. The event message includes an error "
     "code.",
     "Retry the update or inspect the HRESULT in the event details.", true,
     Importance::High, InsightCategory::Update},

    {43, "WindowsUpdateClient", "Windows Update Installation Started",
     "Windows has started installing an update.", "", false, Importance::Low,
     InsightCategory::Update},

    {44, "WindowsUpdateClient", "Windows Update Download Started",
     "Windows Update started downloading an update.", "", false,
     Importance::Low, InsightCategory::Update},

    // --- Device / Plug and Play ---
    {400, "Kernel-PnP", "Device Configured",
     "Windows configured a Plug and Play device.", "", false, Importance::Low,
     InsightCategory::Device},

    {410, "Kernel-PnP", "Device Started",
     "Windows started a Plug and Play device.", "", false, Importance::Low,
     InsightCategory::Device},

    {411, "Kernel-PnP", "Device Failed to Start",
     "A Plug and Play device had a problem starting.",
     "Check Device Manager for the device instance in the event details.", true,
     Importance::Medium, InsightCategory::Device},

    // --- Storage (classic disk provider events) ---
    {7, "disk", "Storage Reported a Bad Block",
     "Windows reported that a storage device has a bad block.",
     "Back up important data and check the drive health tools for that disk.",
     true, Importance::High, InsightCategory::Storage},

    {51, "disk", "Storage Reported a Disk Error",
     "Windows detected an error on a storage device during an I/O operation.",
     "Watch for repeats; persistent errors warrant a drive health check.", true,
     Importance::High, InsightCategory::Storage},

    // --- Security (only present when Security channel is readable) ---
    {4624, "Security-Auditing", "User Signed In",
     "A user account successfully signed in.", "", false, Importance::Low,
     InsightCategory::Security},

    {4634, "Security-Auditing", "User Signed Out",
     "A user account signed out (logon session ended).", "", false,
     Importance::Low, InsightCategory::Security},

    // --- R2 expansions (Microsoft-documented Event IDs) ---
    {4101, "Display", "Display Driver Reset",
     "The display driver stopped responding and Windows recovered it (TDR).",
     "Note the driver name in the message. Update GPU drivers and check "
     "thermals if this repeats.",
     true, Importance::High, InsightCategory::Driver},

    {7000, "Service Control Manager", "Windows Service Failed to Start",
     "A Windows service failed to start.",
     "Open the service name from the event and check its dependencies and "
     "recent software changes.",
     true, Importance::High, InsightCategory::Service},

    {7009, "Service Control Manager", "Windows Service Start Timed Out",
     "A Windows service did not respond within the expected start timeout.",
     "Look for disk or dependency delays around the same time.", true,
     Importance::Medium, InsightCategory::Service},

    {7011, "Service Control Manager", "Windows Service Timed Out",
     "A Windows service did not respond to a control request in time.",
     "Repeated timeouts for the same service warrant further investigation.",
     true, Importance::Medium, InsightCategory::Service},

    {7022, "Service Control Manager", "Windows Service Hung on Start",
     "A Windows service hung while starting.",
     "Check the service executable and recent updates.", true,
     Importance::High, InsightCategory::Service},

    {7024, "Service Control Manager", "Windows Service Reported a Specific Error",
     "A Windows service exited with a service-specific error code.",
     "Read the error code in the event details.", true, Importance::High,
     InsightCategory::Service},

    {7026, "Service Control Manager", "Windows Service Boot Driver Issue",
     "At least one boot-start or system-start driver failed to load.",
     "Review Device Manager and recent driver installs.", true,
     Importance::High, InsightCategory::Driver},

    {55, "Ntfs", "NTFS Structure Corruption Detected",
     "NTFS detected corruption on a volume and may have repaired metadata.",
     "Back up important data and run chkdsk when safe if this repeats.", true,
     Importance::Critical, InsightCategory::Storage},

    {50, "Ntfs", "Delayed Write Failed",
     "Windows could not write file data to storage (delayed write failed).",
     "Check disk health, cable/power, and free space.", true,
     Importance::High, InsightCategory::Storage},

    {7, "Ntfs", "NTFS Reported a Bad Cluster",
     "NTFS reported a bad cluster on a volume.",
     "Back up data and check the drive health tools for that volume.", true,
     Importance::High, InsightCategory::Storage},

    {1014, "DNS-Client", "DNS Name Resolution Timed Out",
     "Windows timed out resolving a DNS name.",
     "Check network connectivity and DNS server settings.", false,
     Importance::Medium, InsightCategory::Network},

    {1001, "Dhcp-Client", "DHCP Lease Acquisition Issue",
     "The DHCP client reported a problem obtaining or renewing a lease.",
     "Check the network adapter link and DHCP server availability.", true,
     Importance::Medium, InsightCategory::Network},

    {8001, "WLAN-AutoConfig", "Wireless Network Disconnected",
     "The wireless connection was disconnected.", "", false, Importance::Low,
     InsightCategory::Network},

    {8002, "WLAN-AutoConfig", "Wireless Connection Attempt Failed",
     "A wireless connection attempt failed.",
     "Verify SSID credentials and radio interference.", false,
     Importance::Medium, InsightCategory::Network},

    {8003, "WLAN-AutoConfig", "Wireless Network Connected",
     "The wireless adapter connected to a network.", "", false,
     Importance::Low, InsightCategory::Network},

    {36887, "Schannel", "Schannel Received a Fatal Alert",
     "A TLS/SSL fatal alert was received while negotiating a secure channel.",
     "Inspect the alert code and the remote endpoint if a service is failing.",
     true, Importance::Medium, InsightCategory::Network},

    {36874, "Schannel", "Schannel Could Not Create Credentials",
     "Schannel could not create credentials required for a secure connection.",
     "Check certificate stores and clock skew.", true, Importance::Medium,
     InsightCategory::Network},

    {2004, "Resource-Exhaustion-Detector", "Windows Is Low on Virtual Memory",
     "Windows detected that the system is low on committed virtual memory.",
     "Close memory-heavy apps and check for leaks if this repeats.", true,
     Importance::High, InsightCategory::General},

    {100, "Diagnostics-Performance", "Boot Performance Degraded",
     "Windows recorded that boot performance was degraded.",
     "Review the boot details and recently installed startup programs.", false,
     Importance::Medium, InsightCategory::Boot},

    {1129, "GroupPolicy", "Group Policy Processing Failed",
     "Group Policy processing failed for a user or computer.",
     "Check network connectivity to domain controllers if this is a domain "
     "joined PC.",
     true, Importance::Medium, InsightCategory::Security},

    {4625, "Security-Auditing", "Sign-In Failed",
     "An account failed to sign in.",
     "Repeated failures may indicate a mistyped password or attack attempt.",
     true, Importance::Medium, InsightCategory::Security},

    {4648, "Security-Auditing", "Explicit Credentials Sign-In",
     "A logon was attempted using explicit credentials.", "", false,
     Importance::Low, InsightCategory::Security},

    {4720, "Security-Auditing", "User Account Created",
     "A user account was created.", "", false, Importance::Medium,
     InsightCategory::Security},

    {4732, "Security-Auditing", "Member Added to Security Group",
     "A member was added to a security-enabled local group.", "", false,
     Importance::Medium, InsightCategory::Security},

    {1102, "Security-Auditing", "Audit Log Cleared",
     "The audit log was cleared.",
     "Confirm this was an expected administrative action.", true,
     Importance::High, InsightCategory::Security},

    {1116, "Windows Defender", "Windows Defender Detected Malware",
     "Microsoft Defender Antivirus detected malware or other potentially "
     "unwanted software.",
     "Open Windows Security to review the detection and recommended actions.",
     true, Importance::Critical, InsightCategory::Security},

    {1117, "Windows Defender", "Windows Defender Took Action on Malware",
     "Microsoft Defender Antivirus took action to protect this machine.",
     "Review the action result in Windows Security.", true, Importance::High,
     InsightCategory::Security},

    {104, "EventLog", "Event Log Cleared",
     "An Event Log was cleared.",
     "Confirm this was an expected administrative action.", true,
     Importance::Medium, InsightCategory::General},

    {6009, "EventLog", "Windows Version at Boot",
     "Windows recorded operating system version information at boot.", "",
     false, Importance::Low, InsightCategory::Boot},

    {6013, "EventLog", "System Uptime Reported",
     "Windows reported how long the system has been running.", "", false,
     Importance::Low, InsightCategory::Boot},

    // --- Secure Boot updates (TPM-WMI, System log) ---
    // Source: support.microsoft.com, "Secure Boot DB and DBX variable update
    // events". Several are logged at Error level but describe a deliberate
    // check or a retry, so their importance follows Microsoft's description,
    // not the level. SBAT is not a separate event: it is one of the update
    // types event 1796 can name.
    {1034, "TPM-WMI", "Secure Boot Blocklist Updated",
     "Windows added entries to the Secure Boot revocation list (DBX), which "
     "stops known-vulnerable boot software from starting.",
     "", false, Importance::Low, InsightCategory::Security},

    {1036, "TPM-WMI", "Secure Boot Database Updated",
     "Windows updated the Secure Boot signature database (DB).", "", false,
     Importance::Low, InsightCategory::Security},

    {1037, "TPM-WMI", "Old Microsoft Boot Certificate Revoked",
     "Windows revoked the Microsoft Windows Production PCA 2011 certificate in "
     "Secure Boot.",
     "", false, Importance::Low, InsightCategory::Security},

    {1042, "TPM-WMI", "Older Boot Managers Revoked",
     "Windows revoked older versions of the Windows boot manager in Secure "
     "Boot.",
     "", false, Importance::Low, InsightCategory::Security},

    {1043, "TPM-WMI", "Secure Boot Key Updated",
     "Windows updated the Secure Boot Key Exchange Key with the Microsoft "
     "Corporation KEK CA 2023 certificate. The 2011 certificates it replaces "
     "expire in 2026.",
     "", false, Importance::Low, InsightCategory::Security},

    {1044, "TPM-WMI", "Secure Boot Certificate Added",
     "Windows added the Microsoft Option ROM UEFI CA 2023 certificate to "
     "Secure Boot. The 2011 certificates expire in 2026.",
     "", false, Importance::Low, InsightCategory::Security},

    {1045, "TPM-WMI", "Secure Boot Certificate Added",
     "Windows added the Microsoft UEFI CA 2023 certificate to Secure Boot. "
     "The 2011 certificates expire in 2026.",
     "", false, Importance::Low, InsightCategory::Security},

    {1799, "TPM-WMI", "New Boot Manager Installed",
     "Windows installed a boot manager signed with the Windows UEFI CA 2023 "
     "certificate.",
     "", false, Importance::Low, InsightCategory::Security},

    {1808, "TPM-WMI", "Secure Boot Certificates Up to Date",
     "This PC has the 2023 Secure Boot certificates and boot manager. Nothing "
     "else needs to be done.",
     "", false, Importance::Low, InsightCategory::Security},

    {1797, "TPM-WMI", "Secure Boot Update Held Back",
     "Windows did not apply a revocation (DBX) update because the Windows UEFI "
     "CA 2023 certificate is not in the Secure Boot database yet. This is a "
     "deliberate check, not a fault.",
     "", false, Importance::Low, InsightCategory::Security},

    {1798, "TPM-WMI", "Secure Boot Update Held Back",
     "Windows did not apply a revocation (DBX) update because the boot manager "
     "is still signed with the 2011 certificate. This is a deliberate check, "
     "not a fault.",
     "", false, Importance::Low, InsightCategory::Security},

    {1800, "TPM-WMI", "Secure Boot Update Needs a Restart",
     "A Secure Boot update is waiting for the PC to restart.",
     "Restart the PC to let the update continue.", true, Importance::Low,
     InsightCategory::Security},

    {1796, "TPM-WMI", "Secure Boot Update Failed",
     "Windows could not apply a Secure Boot update (such as DB, DBX or SBAT) "
     "because of an unexpected error. It tries again at the next restart.",
     "A single failure is not a problem. If it appears after every restart, "
     "the event details name the update type and the error code.",
     false, Importance::Medium, InsightCategory::Security},

    {1795, "TPM-WMI", "Firmware Rejected a Secure Boot Update",
     "The PC's firmware returned an error while Windows updated Secure Boot "
     "(DB, DBX or KEK). Windows tries again at the next restart.",
     "If it keeps happening, check with the PC or motherboard maker for a "
     "firmware (BIOS/UEFI) update.",
     true, Importance::Medium, InsightCategory::Security},

    {1801, "TPM-WMI", "Secure Boot Certificates Not Applied Yet",
     "The updated Secure Boot certificates and boot manager have not been "
     "applied to this PC's firmware yet.",
     "Microsoft's guidance on the Secure Boot certificate update explains how "
     "to complete it.",
     true, Importance::Medium, InsightCategory::Security},

    {1802, "TPM-WMI", "Secure Boot Update Blocked by Firmware",
     "Windows did not apply a Secure Boot update because of a known firmware "
     "issue on this PC.",
     "Check with the PC or motherboard maker for a firmware (BIOS/UEFI) "
     "update.",
     true, Importance::Medium, InsightCategory::Security},

    {1803, "TPM-WMI", "Secure Boot Key Missing in Firmware",
     "The firmware has no Key Exchange Key signed by this PC's platform key, "
     "so Windows cannot update the Secure Boot keys.",
     "Ask the PC maker about Secure Boot key provisioning for this model.",
     true, Importance::Medium, InsightCategory::Security},

    {1032, "TPM-WMI", "Secure Boot Update Paused for BitLocker",
     "Windows did not apply a Secure Boot update because it would have sent "
     "the system drive into BitLocker recovery.",
     "Microsoft's fix: suspend BitLocker for two restarts, restart twice, then "
     "check that BitLocker protection is on again.",
     true, Importance::High, InsightCategory::Security},

    {1033, "TPM-WMI", "Vulnerable Boot Software Found",
     "A revoked boot manager is on the EFI system partition, so Windows "
     "postponed a revocation (DBX) update.",
     "Contact the vendor of that boot software for an updated version.", true,
     Importance::High, InsightCategory::Security},
};

const IntelligenceRule* MatchRule(const ipc::TimelineEvent& event) {
  if (event.win_event_id == 0) {
    return nullptr;
  }
  for (const auto& rule : kRules) {
    if (rule.event_id != event.win_event_id) {
      continue;
    }
    if (rule.provider_hint.empty() ||
        ContainsIgnoreCase(event.provider_name, rule.provider_hint)) {
      return &rule;
    }
  }
  return nullptr;
}

Importance ImportanceFromSeverity(ipc::Severity severity) {
  switch (severity) {
    case ipc::Severity::Critical:
      return Importance::Critical;
    case ipc::Severity::Error:
      return Importance::High;
    case ipc::Severity::Warning:
      return Importance::Medium;
    case ipc::Severity::Info:
    case ipc::Severity::Verbose:
    case ipc::Severity::Unknown:
    default:
      return Importance::Low;
  }
}

std::string TruncateMessage(std::string_view message, std::size_t max_len) {
  if (message.empty()) {
    return "A Windows event was recorded.";
  }
  // Prefer first line for card-friendly fallback summaries.
  const auto newline = message.find('\n');
  std::string_view first =
      newline == std::string_view::npos ? message : message.substr(0, newline);
  while (!first.empty() &&
         (first.back() == '\r' || first.back() == ' ' || first.back() == '\t')) {
    first.remove_suffix(1);
  }
  if (first.size() <= max_len) {
    return std::string(first);
  }
  return std::string(first.substr(0, max_len - 1)) + "...";
}

std::string FriendlyProviderName(std::string_view provider) {
  if (provider.empty()) {
    return "Windows";
  }
  // Never leave raw provider as-is when we can soften common prefixes.
  constexpr std::string_view kPrefix = "Microsoft-Windows-";
  if (provider.size() > kPrefix.size() &&
      ContainsIgnoreCase(provider.substr(0, kPrefix.size()), kPrefix)) {
    return std::string(provider.substr(kPrefix.size()));
  }
  return std::string(provider);
}

/// "TaskScheduler · Event 201": unknown events still name who logged them and
/// which Event ID to look up (ADR-016, user-added channels).
std::string FallbackTitle(std::string_view provider, std::uint32_t event_id) {
  const std::string name = FriendlyProviderName(provider);
  if (event_id == 0) {
    return name + " event";
  }
  return name + " · Event " + std::to_string(event_id);
}

EventInsight Fallback(const ipc::TimelineEvent& event) {
  EventInsight out;
  out.title = FallbackTitle(event.provider_name, event.win_event_id);
  out.summary = TruncateMessage(event.message, 180);
  out.recommendation.clear();
  out.action_required = false;
  out.importance = ImportanceFromSeverity(event.severity);
  out.category = InsightCategory::General;
  return out;
}

}  // namespace

const char* ImportanceName(Importance value) {
  switch (value) {
    case Importance::Low:
      return "Low";
    case Importance::Medium:
      return "Medium";
    case Importance::High:
      return "High";
    case Importance::Critical:
      return "Critical";
  }
  return "Low";
}

const char* InsightCategoryName(InsightCategory value) {
  switch (value) {
    case InsightCategory::General:
      return "General";
    case InsightCategory::Service:
      return "Service";
    case InsightCategory::Network:
      return "Network";
    case InsightCategory::Com:
      return "COM";
    case InsightCategory::Boot:
      return "Boot";
    case InsightCategory::Time:
      return "Time";
    case InsightCategory::Http:
      return "HTTP";
    case InsightCategory::Crash:
      return "Crash";
    case InsightCategory::Power:
      return "Power";
    case InsightCategory::Update:
      return "Update";
    case InsightCategory::Device:
      return "Device";
    case InsightCategory::Driver:
      return "Driver";
    case InsightCategory::Security:
      return "Security";
    case InsightCategory::Storage:
      return "Storage";
  }
  return "General";
}

EventInsight EventIntelligence::Analyze(const ipc::TimelineEvent& event) const {
  // Crash events carry the real cause in their data (stop code, power
  // button); prefer that over the catalog's generic wording.
  if (auto crash = ExplainCrashEvent(event)) {
    return *std::move(crash);
  }
  // Likewise the wake source names what woke the PC.
  if (auto wake = ExplainWakeEvent(event)) {
    return *std::move(wake);
  }

  const IntelligenceRule* rule = MatchRule(event);
  if (rule == nullptr) {
    return Fallback(event);
  }

  EventInsight out;
  out.title = std::string(rule->title);
  out.summary = std::string(rule->summary);
  out.recommendation = std::string(rule->recommendation);
  out.action_required = rule->action_required;
  out.importance = rule->importance;
  out.category = rule->category;
  return out;
}

}  // namespace pulse
