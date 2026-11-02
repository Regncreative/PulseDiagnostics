#include "intelligence/event_intelligence.hpp"

#include <cassert>
#include <iostream>

int main() {
  using namespace pulse;
  EventIntelligence engine;

  {
    ipc::TimelineEvent e;
    e.provider_name = "Service Control Manager";
    e.win_event_id = 7040;
    e.severity = ipc::Severity::Info;
    e.message = "The start type of the Background Intelligent Transfer Service "
                "service was changed from auto start to demand start.";
    const auto insight = engine.Analyze(e);
    assert(insight.title == "Windows Service Configuration Changed");
    assert(insight.action_required == false);
    assert(insight.recommendation.empty());
    assert(insight.importance == Importance::Low);
  }

  {
    ipc::TimelineEvent e;
    e.provider_name = "Service Control Manager";
    e.win_event_id = 7034;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "Windows Service Stopped Unexpectedly");
    assert(insight.category == InsightCategory::Service);
    assert(insight.action_required == true);
  }

  {
    ipc::TimelineEvent e;
    e.provider_name = "Tcpip";
    e.win_event_id = 4266;
    e.severity = ipc::Severity::Warning;
    e.message = "A request to allocate an ephemeral port number from the global "
                "UDP port space has failed due to all such ports being in use.";
    const auto insight = engine.Analyze(e);
    assert(insight.title == "Temporary UDP Port Allocation Failed");
    assert(insight.action_required == true);
    assert(insight.importance == Importance::High);
    assert(!insight.recommendation.empty());
  }

  {
    ipc::TimelineEvent e;
    e.provider_name = "Microsoft-Windows-HttpService";
    e.win_event_id = 114;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "HTTP Service Endpoint Removed");
    assert(insight.action_required == false);
    assert(insight.recommendation.empty());
  }

  {
    ipc::TimelineEvent e;
    e.provider_name = "Microsoft-Windows-DistributedCOM";
    e.win_event_id = 10016;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "COM Permission Warning");
    assert(insight.action_required == false);
  }

  {
    ipc::TimelineEvent e;
    e.provider_name = "Microsoft-Windows-Kernel-Power";
    e.win_event_id = 41;
    e.severity = ipc::Severity::Critical;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "Windows Restarted Unexpectedly");
    assert(insight.category == InsightCategory::Power);
    assert(insight.importance == Importance::Critical);
    assert(insight.action_required == true);
  }

  {
    ipc::TimelineEvent e;
    e.provider_name = "Microsoft-Windows-WER-SystemErrorReporting";
    e.win_event_id = 1001;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "Windows Stopped Unexpectedly");
    assert(insight.category == InsightCategory::Crash);
  }

  {
    ipc::TimelineEvent e;
    e.provider_name = "Application Error";
    e.win_event_id = 1000;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "Application Crashed");
    assert(insight.category == InsightCategory::Crash);
  }

  {
    ipc::TimelineEvent e;
    e.provider_name = "Microsoft-Windows-WindowsUpdateClient";
    e.win_event_id = 19;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "Windows Update Installed Successfully");
    assert(insight.category == InsightCategory::Update);
  }

  {
    ipc::TimelineEvent e;
    e.provider_name = "Microsoft-Windows-Kernel-PnP";
    e.win_event_id = 400;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "Device Configured");
    assert(insight.category == InsightCategory::Device);
  }

  {
    ipc::TimelineEvent e;
    e.provider_name = "Microsoft-Windows-Security-Auditing";
    e.win_event_id = 4624;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "User Signed In");
    assert(insight.category == InsightCategory::Security);
  }

  {
    ipc::TimelineEvent e;
    e.provider_name = "disk";
    e.win_event_id = 7;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "Storage Reported a Bad Block");
    assert(insight.category == InsightCategory::Storage);
  }

  {
    ipc::TimelineEvent e;
    e.provider_name = "SomeUnknownProvider";
    e.win_event_id = 9999;
    e.message = "Raw Event Viewer paragraph that should be softened.\nSecond line.";
    const auto insight = engine.Analyze(e);
    assert(insight.title == "SomeUnknownProvider");
    assert(insight.recommendation.empty());
    assert(insight.action_required == false);
    assert(insight.summary.find("Second line") == std::string::npos);
  }

  // R2 expansions — spot-check Microsoft-documented IDs.
  {
    ipc::TimelineEvent e;
    e.provider_name = "Display";
    e.win_event_id = 4101;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "Display Driver Reset");
    assert(insight.action_required == true);
    assert(insight.category == InsightCategory::Driver);
  }
  {
    ipc::TimelineEvent e;
    e.provider_name = "Service Control Manager";
    e.win_event_id = 7000;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "Windows Service Failed to Start");
    assert(insight.action_required == true);
  }
  {
    ipc::TimelineEvent e;
    e.provider_name = "Microsoft-Windows-DNS-Client";
    e.win_event_id = 1014;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "DNS Name Resolution Timed Out");
  }
  {
    ipc::TimelineEvent e;
    e.provider_name = "Microsoft-Windows-Windows Defender";
    e.win_event_id = 1116;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "Windows Defender Detected Malware");
    assert(insight.importance == Importance::Critical);
  }
  {
    ipc::TimelineEvent e;
    e.provider_name = "Microsoft-Windows-NTFS";
    e.win_event_id = 55;
    const auto insight = engine.Analyze(e);
    assert(insight.title == "NTFS Structure Corruption Detected");
    assert(insight.importance == Importance::Critical);
  }

  // Unknown events (e.g. from a user-added channel, ADR-016). CHECK, not
  // assert: CI builds Release, where assert() is compiled out.
#define CHECK(condition)                                                \
  do {                                                                  \
    if (!(condition)) {                                                 \
      std::cerr << __FILE__ << ":" << __LINE__ << " CHECK failed: "     \
                << #condition << "\n";                                  \
      return 1;                                                         \
    }                                                                   \
  } while (false)
  {
    ipc::TimelineEvent e;
    e.provider_name = "Microsoft-Windows-TaskScheduler";
    e.win_event_id = 201;
    e.severity = ipc::Severity::Info;
    e.message = "Task Scheduler successfully completed task \"\\Backup\".\r\n"
                "Instance \"{1234}\", action \"C:\\backup.exe\".";
    const auto insight = engine.Analyze(e);
    CHECK(insight.title == "TaskScheduler · Event 201");
    CHECK(insight.summary ==
          "Task Scheduler successfully completed task \"\\Backup\".");
    CHECK(insight.category == InsightCategory::General);
    CHECK(!insight.action_required);
  }
  {
    ipc::TimelineEvent e;
    e.provider_name = "Contoso Backup Agent";
    e.win_event_id = 7;
    e.severity = ipc::Severity::Error;
    const auto insight = engine.Analyze(e);
    CHECK(insight.title == "Contoso Backup Agent · Event 7");
    CHECK(insight.summary == "A Windows event was recorded.");
    CHECK(insight.importance == Importance::High);
  }
  {
    ipc::TimelineEvent e;  // no provider, no Event ID
    const auto insight = engine.Analyze(e);
    CHECK(insight.title == "Windows event");
  }
#undef CHECK

  std::cout << "event_intelligence_tests OK\n";
  return 0;
}
