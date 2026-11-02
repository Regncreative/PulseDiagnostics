import 'dart:async';

import 'package:pulse_protocol/pulse_constants.dart';

import '../application/assistant_controller.dart';
import '../application/background_mode_controller.dart';
import '../application/channels_controller.dart';
import '../application/client_frame_metrics.dart';
import '../application/connection_controller.dart';
import '../application/crash_history_controller.dart';
import '../application/diagnostics_controller.dart';
import '../application/evtx_import_controller.dart';
import '../application/health_navigation.dart';
import '../application/legacy_mcp_cleanup.dart';
import '../application/service_lifecycle_controller.dart';
import '../application/settings_controller.dart';
import '../application/shell_navigation.dart';
import '../application/timeline_library_controller.dart';
import '../application/timeline_session_controller.dart';
import '../application/update_check_controller.dart';
import '../ipc/pulse_ipc_client.dart';
import '../logging/app_log_file.dart';
import '../logging/app_logger.dart';
import '../platform/local_ai_token_store.dart';
import '../platform/pulse_deployment.dart';

class AppServices {
  AppServices({
    required this.ipcClient,
    required this.logger,
    required this.connectionController,
    required this.settingsController,
    required this.timelineSession,
    required this.timelineLibrary,
    required this.evtxImport,
    required this.updateCheck,
    required this.diagnosticsController,
    required this.serviceLifecycle,
    required this.clientFrameMetrics,
    required this.healthNavigation,
    required this.shellNavigation,
    required this.backgroundMode,
    required this.assistant,
    required this.crashHistory,
    required this.channels,
  });

  final PulseIpcClient ipcClient;
  final AppLogger logger;
  final ConnectionController connectionController;
  final SettingsController settingsController;
  final TimelineSessionController timelineSession;
  final TimelineLibraryController timelineLibrary;
  final EvtxImportController evtxImport;
  final UpdateCheckController updateCheck;
  final DiagnosticsController diagnosticsController;
  final ServiceLifecycleController serviceLifecycle;
  final ClientFrameMetrics clientFrameMetrics;
  final HealthNavigation healthNavigation;
  final ShellNavigation shellNavigation;
  final BackgroundModeController backgroundMode;
  final AssistantController assistant;
  final CrashHistoryController crashHistory;
  final ChannelsController channels;

  static Future<AppServices> create() async {
    final logger = AppLogger(file: AppLogFile.openDefault());
    logger.info('App', 'Pulse $kAppVersion starting');
    final settings = SettingsController(logger: logger);
    await settings.load();
    final timelineLibrary = TimelineLibraryController(logger: logger);
    await timelineLibrary.load();
    final evtxImport = EvtxImportController(logger: logger);

    final ipc = PulseIpcClient();
    final frameMetrics = ClientFrameMetrics();
    frameMetrics.start();
    final connection = ConnectionController(ipc: ipc, logger: logger);
    final timeline = TimelineSessionController(
      ipc: ipc,
      settings: settings,
      logger: logger,
    );
    final diagnostics = DiagnosticsController(
      ipc: ipc,
      timeline: timeline,
      settings: settings,
      logger: logger,
      frameMetrics: frameMetrics,
    );
    final serviceLifecycle = ServiceLifecycleController(logger: logger);
    serviceLifecycle.startPolling();
    final healthNavigation = HealthNavigation();
    // AI Integration (PulseMCP) was removed in 1.3; tidy up what it left.
    unawaited(LegacyMcpCleanup(logger: logger).run());
    final shellNavigation = ShellNavigation();
    final backgroundMode = BackgroundModeController(
      settings: settings,
      ipc: ipc,
      shellNavigation: shellNavigation,
      timelineLibrary: timelineLibrary,
      logger: logger,
    );
    final assistant = AssistantController(
      settings: settings,
      ipc: ipc,
      tokenStore: WindowsCredentialTokenStore(logger: logger),
    );
    final updateCheck = UpdateCheckController(settings: settings, logger: logger);
    final crashHistory = CrashHistoryController(ipc: ipc, logger: logger);
    final channels = ChannelsController(ipc: ipc, logger: logger);
    // GitHub edition only, and only when the user turned it on.
    if (!const WindowsPulseDeployment().isPackagedMsix) {
      unawaited(updateCheck.checkAutomaticallyIfDue());
    }

    // Attach before start so the connecting→connected edge is never missed.
    // Snapshot loading always goes through TimelineSessionController.reloadSnapshot
    // (same method as the Timeline Retry button).
    timeline.attach();
    await ipc.start();

    return AppServices(
      ipcClient: ipc,
      logger: logger,
      connectionController: connection,
      settingsController: settings,
      timelineSession: timeline,
      timelineLibrary: timelineLibrary,
      evtxImport: evtxImport,
      updateCheck: updateCheck,
      diagnosticsController: diagnostics,
      serviceLifecycle: serviceLifecycle,
      clientFrameMetrics: frameMetrics,
      healthNavigation: healthNavigation,
      shellNavigation: shellNavigation,
      backgroundMode: backgroundMode,
      assistant: assistant,
      crashHistory: crashHistory,
      channels: channels,
    );
  }
}
