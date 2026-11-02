import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pulse/app/theme/pulse_theme.dart';
import 'package:pulse/application/connection_controller.dart';
import 'package:pulse/application/evtx_import_controller.dart';
import 'package:pulse/application/settings_controller.dart';
import 'package:pulse/application/timeline_library_controller.dart';
import 'package:pulse/application/timeline_session_controller.dart';
import 'package:pulse/features/timeline/evtx_import.dart';
import 'package:pulse/ipc/pulse_ipc_client.dart';
import 'package:pulse/logging/app_logger.dart';
import 'package:pulse/platform/evtx_file_reader.dart';
import 'package:pulse/presentation/timeline/timeline_page.dart';
import 'package:pulse_protocol/pulse_wire.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _task = 'Microsoft-Windows-TaskScheduler/Operational';

TimelineEvent _event(String id, String channel, String title) => TimelineEvent(
      eventId: id,
      timestampUnixMs: DateTime.now().millisecondsSinceEpoch,
      severity: Severity.info,
      channel: channel,
      providerName: 'Provider-$id',
      winEventId: 100,
      title: title,
    );

class _FakeReader implements EvtxFileReader {
  _FakeReader(this.events);
  final List<TimelineEvent> events;

  @override
  Future<EvtxImport> read(String path) async =>
      EvtxImport(filePath: path, events: events, eventLimit: 0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The Timeline shows the events of an opened file, so the channel filter can
/// be exercised without PulseService.
Future<TimelineLibraryController> _pumpTimeline(
  WidgetTester tester, {
  List<String> favorites = const [],
}) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final logger = AppLogger();
  final settings = SettingsController(logger: logger);
  await settings.load();
  await settings.completeWelcome();
  final ipc = PulseIpcClient();
  final library = TimelineLibraryController(logger: logger);
  await library.load();
  for (final f in favorites) {
    await library.toggleFavoriteChannel(f);
  }
  final imports = EvtxImportController(
    logger: logger,
    reader: _FakeReader([
      _event('a', _task, 'Backup task finished'),
      _event('b', 'System', 'Service started'),
      _event('c', 'Application', 'App installed'),
    ]),
  );
  await imports.open(r'C:\logs\pc.evtx');

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ipc),
        ChangeNotifierProvider.value(
          value: ConnectionController(ipc: ipc, logger: logger),
        ),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(
          value: TimelineSessionController(
            ipc: ipc,
            settings: settings,
            logger: logger,
          ),
        ),
        ChangeNotifierProvider.value(value: library),
        ChangeNotifierProvider.value(value: imports),
      ],
      child: MaterialApp(
        theme: PulseTheme.dark(),
        home: const Scaffold(body: TimelinePage(title: 'Timeline')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return library;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the log filter shows one log, then all merged again',
      (tester) async {
    await _pumpTimeline(tester);
    expect(find.text('Backup task finished'), findsOneWidget);
    expect(find.text('Service started'), findsOneWidget);

    await tester.tap(find.text('All logs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TaskScheduler/Operational').last);
    await tester.pumpAndSettle();

    expect(find.text('Backup task finished'), findsOneWidget);
    expect(find.text('Service started'), findsNothing);
    expect(find.text('App installed'), findsNothing);
    expect(find.text('Log: TaskScheduler/Operational'), findsOneWidget);

    // Removing the active chip merges every log again.
    await tester.tap(find.descendant(
      of: find.ancestor(
        of: find.text('Log: TaskScheduler/Operational'),
        matching: find.byType(Row),
      ).first,
      matching: find.byType(Icon),
    ).last);
    await tester.pumpAndSettle();
    expect(find.text('Service started'), findsOneWidget);
  });

  testWidgets('a favorite log is one click away', (tester) async {
    await _pumpTimeline(tester, favorites: [_task]);

    await tester.tap(find.text('★ TaskScheduler/Operational'));
    await tester.pumpAndSettle();
    expect(find.text('Backup task finished'), findsOneWidget);
    expect(find.text('Service started'), findsNothing);

    // Second click shows every log again.
    await tester.tap(find.text('★ TaskScheduler/Operational'));
    await tester.pumpAndSettle();
    expect(find.text('Service started'), findsOneWidget);
  });

  testWidgets('no Manage button while a file is open', (tester) async {
    await _pumpTimeline(tester);
    expect(find.byTooltip('Manage event logs'), findsNothing);
  });
}
