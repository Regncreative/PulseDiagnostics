import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pulse/app/theme/pulse_theme.dart';
import 'package:pulse/application/channels_controller.dart';
import 'package:pulse/application/timeline_library_controller.dart';
import 'package:pulse/features/channels/channel_display.dart';
import 'package:pulse/ipc/pulse_ipc_client.dart';
import 'package:pulse/logging/app_logger.dart';
import 'package:pulse/presentation/timeline/manage_channels_dialog.dart';
import 'package:pulse_protocol/pulse_wire.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _task = 'Microsoft-Windows-TaskScheduler/Operational';
const _dns = 'Microsoft-Windows-DNS-Client/Operational';
const _lsa = 'Microsoft-Windows-LSA/Operational';
const _empty = 'Microsoft-Windows-Bits-Client/Operational';

EventLogChannelInfo _channel(
  String path, {
  bool enabled = true,
  EventLogChannelAccess access = EventLogChannelAccess.readable,
  int records = 12,
  bool builtIn = false,
  bool tracked = false,
}) =>
    EventLogChannelInfo(
      path: path,
      type: EventLogChannelType.operational,
      enabled: enabled,
      access: access,
      recordCount: records,
      hasRecordCount: access == EventLogChannelAccess.readable,
      builtIn: builtIn,
      tracked: tracked,
    );

List<EventLogChannelInfo> _machine() => [
      _channel(_empty, records: 0),
      _channel(_dns, enabled: false, records: 0),
      _channel(_lsa, access: EventLogChannelAccess.denied),
      _channel(_task),
      _channel('System', builtIn: true),
    ];

/// Plays PulseService: answers List and Set like the real service would.
class _FakeIpc extends PulseIpcClient {
  _FakeIpc({this.maxTracked = 16, this.listError});

  final int maxTracked;
  final ChannelsUnavailable? listError;
  final List<String> tracked = [];
  final List<List<String>> setCalls = [];

  @override
  IpcStatus get status => const IpcStatus(state: IpcConnectionState.connected);

  @override
  Future<EventLogChannelList> listEventLogChannels() async {
    if (listError != null) throw listError!;
    return EventLogChannelList(
      maxTracked: maxTracked,
      channels: [
        for (final c in _machine())
          c..tracked = tracked.any((t) => t.toLowerCase() == c.path.toLowerCase()),
      ],
    );
  }

  @override
  Future<TrackedChannels> setTrackedChannels(List<String> channels) async {
    setCalls.add(List.of(channels));
    final results = <TrackedChannelResult>[];
    tracked.clear();
    for (final path in channels) {
      final c = _machine().firstWhere((m) => m.path == path);
      if (c.access == EventLogChannelAccess.denied) {
        results.add(TrackedChannelResult(
          path: path,
          status: TrackedChannelStatus.accessDenied,
        ));
      } else if (tracked.length >= maxTracked) {
        results.add(TrackedChannelResult(
          path: path,
          status: TrackedChannelStatus.overLimit,
          detail: 'At most $maxTracked channels can be added.',
        ));
      } else {
        tracked.add(path);
        results.add(TrackedChannelResult(
          path: path,
          status: c.enabled
              ? TrackedChannelStatus.tracked
              : TrackedChannelStatus.disabled,
        ));
      }
    }
    return TrackedChannels(
      results: results,
      maxTracked: maxTracked,
      tracked: List.of(tracked),
    );
  }
}

Future<TimelineLibraryController> _library() async {
  final library = TimelineLibraryController(logger: AppLogger());
  await library.load();
  return library;
}

Future<void> _pumpDialog(
  WidgetTester tester,
  ChannelsController channels,
  TimelineLibraryController library,
) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: channels),
        ChangeNotifierProvider.value(value: library),
      ],
      child: MaterialApp(
        theme: PulseTheme.dark(),
        home: const Scaffold(body: ManageChannelsDialog()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _rowCheckbox(String path) => find.descendant(
      of: find.byKey(ValueKey(path)),
      matching: find.byType(Checkbox),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('channel display', () {
    test('state shows denied, disabled and empty logs', () {
      expect(channelStateOf(_channel(_task)), ChannelState.ready);
      expect(channelStateOf(_channel(_empty, records: 0)), ChannelState.empty);
      expect(
        channelStateOf(_channel(_dns, enabled: false)),
        ChannelState.disabled,
      );
      expect(
        channelStateOf(_channel(_lsa, access: EventLogChannelAccess.denied)),
        ChannelState.accessDenied,
      );
    });

    test('built-in and unreadable logs cannot be checked', () {
      expect(canTrackChannel(_channel(_task)), isTrue);
      expect(canTrackChannel(_channel(_dns, enabled: false)), isTrue);
      expect(canTrackChannel(_channel('System', builtIn: true)), isFalse);
      expect(
        canTrackChannel(_channel(_lsa, access: EventLogChannelAccess.denied)),
        isFalse,
      );
    });

    test('enable command quotes names with spaces', () {
      expect(
        enableChannelCommand('Microsoft-User Experience Virtualization-IPC/Operational'),
        'wevtutil sl "Microsoft-User Experience Virtualization-IPC/Operational" /e:true',
      );
    });

    test('search and filters', () {
      final all = _machine()..[3].tracked = true;
      expect(filterChannels(all, search: 'dns').map((c) => c.path), [_dns]);
      expect(
        filterChannels(all, filter: ChannelListFilter.added).map((c) => c.path),
        [_task, 'System'],
      );
      expect(
        filterChannels(
          all,
          filter: ChannelListFilter.favorites,
          isFavorite: (p) => p == _lsa,
        ).map((c) => c.path),
        [_lsa],
      );
    });

    test('short labels drop the Microsoft-Windows- prefix', () {
      expect(shortChannelLabel(_task), 'TaskScheduler/Operational');
      expect(shortChannelLabel('System'), 'System');
    });

    test('timeline options list favorites first, then channels seen', () {
      final events = [
        TimelineEvent(channel: 'System'),
        TimelineEvent(channel: _task),
        TimelineEvent(channel: 'Application'),
        TimelineEvent(channel: 'system'),
      ];
      expect(
        timelineChannelOptions(events, [_task]),
        [_task, 'Application', 'System'],
      );
    });
  });

  group('ChannelsController', () {
    test('adds and removes through the service, keeping the full list', () async {
      final ipc = _FakeIpc();
      final c = ChannelsController(ipc: ipc, logger: AppLogger());
      await c.load();
      expect(c.channels, hasLength(5));
      expect(c.trackedChannels, isEmpty);

      await c.setTracked(_task, true);
      await c.setTracked(_dns, true);
      expect(ipc.setCalls.last, [_task, _dns]);
      expect(c.trackedChannels, [_dns, _task]); // service order (sorted)
      expect(c.resultFor(_dns)!.status, TrackedChannelStatus.disabled);
      expect(c.takeTrackedChanged(), isTrue);
      expect(c.takeTrackedChanged(), isFalse);

      await c.setTracked(_task, false);
      expect(ipc.setCalls.last, [_dns]);
      expect(c.trackedChannels, [_dns]);
    });

    test('a refused log is reported, not tracked', () async {
      final ipc = _FakeIpc();
      final c = ChannelsController(ipc: ipc, logger: AppLogger());
      await c.load();
      await c.setTracked(_lsa, true);
      expect(c.trackedChannels, isEmpty);
      expect(trackedChannelProblem(c.resultFor(_lsa)!), isNotNull);
    });

    test('at the limit, adding is blocked', () async {
      final ipc = _FakeIpc(maxTracked: 1);
      final c = ChannelsController(ipc: ipc, logger: AppLogger());
      await c.load();
      await c.setTracked(_task, true);
      expect(c.atLimit, isTrue);
    });

    test('an older service is explained', () async {
      final ipc = _FakeIpc(
        listError: const ChannelsUnavailable('Unsupported message', ''),
      );
      final c = ChannelsController(ipc: ipc, logger: AppLogger());
      await c.load();
      expect(c.list, isNull);
      expect(c.error, contains('older than this version'));
    });
  });

  group('Manage channels screen', () {
    testWidgets('shows states, searches and adds a log', (tester) async {
      final ipc = _FakeIpc();
      final channels = ChannelsController(ipc: ipc, logger: AppLogger());
      await _pumpDialog(tester, channels, await _library());

      expect(find.text('Event logs'), findsOneWidget);
      expect(find.text('0 of 16 added'), findsOneWidget);
      expect(find.text('Turned off'), findsOneWidget);
      expect(find.text('Access denied'), findsOneWidget);
      expect(find.text('Empty'), findsWidgets);
      expect(find.text('Built in'), findsOneWidget);

      // Built-in and denied rows cannot be toggled.
      expect(tester.widget<Checkbox>(_rowCheckbox('System')).onChanged, isNull);
      expect(tester.widget<Checkbox>(_rowCheckbox(_lsa)).onChanged, isNull);
      expect(tester.widget<Checkbox>(_rowCheckbox('System')).value, isTrue);

      await tester.tap(_rowCheckbox(_task));
      await tester.pumpAndSettle();
      expect(ipc.setCalls.single, [_task]);
      expect(tester.widget<Checkbox>(_rowCheckbox(_task)).value, isTrue);
      expect(find.text('1 of 16 added'), findsOneWidget);
      expect(find.text('In Timeline'), findsWidgets);

      await tester.enterText(find.byKey(const ValueKey('channels-search')), 'dns');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey(_dns)), findsOneWidget);
      expect(find.byKey(const ValueKey(_task)), findsNothing);
    });

    testWidgets('a turned-off log shows the command to run, never runs it',
        (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      final ipc = _FakeIpc();
      final channels = ChannelsController(ipc: ipc, logger: AppLogger());
      await _pumpDialog(tester, channels, await _library());

      await tester.tap(find.text('How to turn it on'));
      await tester.pumpAndSettle();
      expect(find.text(enableChannelCommand(_dns)), findsOneWidget);
      await tester.tap(find.byTooltip('Copy command'));
      await tester.pumpAndSettle();
      expect(copied, 'wevtutil sl "$_dns" /e:true');
      expect(ipc.setCalls, isEmpty); // copying changes nothing
    });

    testWidgets('the star pins a favorite and the filter finds it',
        (tester) async {
      final library = await _library();
      final channels = ChannelsController(ipc: _FakeIpc(), logger: AppLogger());
      await _pumpDialog(tester, channels, library);

      await tester.tap(find.descendant(
        of: find.byKey(const ValueKey(_task)),
        matching: find.byTooltip('Add to favorites'),
      ));
      await tester.pumpAndSettle();
      expect(library.favoriteChannels, [_task]);

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey(_task)), findsOneWidget);
      expect(find.byKey(const ValueKey(_dns)), findsNothing);
    });

    testWidgets('a full list disables unchecked logs', (tester) async {
      final ipc = _FakeIpc(maxTracked: 1)..tracked.add(_task);
      final channels = ChannelsController(ipc: ipc, logger: AppLogger());
      await _pumpDialog(tester, channels, await _library());

      expect(find.textContaining('remove one to add another'), findsOneWidget);
      expect(tester.widget<Checkbox>(_rowCheckbox(_empty)).onChanged, isNull);
      expect(tester.widget<Checkbox>(_rowCheckbox(_task)).onChanged, isNotNull);
    });
  });
}
