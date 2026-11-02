import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_protocol/pulse_wire.dart';

import 'package:pulse/features/timeline/timeline_query.dart';

TimelineEvent _ev({
  int severity = Severity.info,
  String channel = 'System',
  String category = 'Service',
  String provider = 'Service Control Manager',
  int winEventId = 7036,
  String computer = 'DESKTOP',
  String message = 'The service entered the running state.',
  String processName = '',
  bool hasProcessId = false,
  int processId = 0,
  int timestampUnixMs = 1_700_000_000_000,
  String rawXml = '',
}) {
  return TimelineEvent(
    eventId: '$channel|$winEventId',
    severity: severity,
    channel: channel,
    category: category,
    providerName: provider,
    winEventId: winEventId,
    computerName: computer,
    message: message,
    title: 'Title',
    summary: 'Summary',
    processName: processName,
    hasProcessId: hasProcessId,
    processId: processId,
    timestampUnixMs: timestampUnixMs,
    rawXml: rawXml,
  );
}

void main() {
  group('TimelineQuery', () {
    test('empty query matches everything', () {
      expect(const TimelineQuery().matches(_ev()), isTrue);
      expect(const TimelineQuery().isActive, isFalse);
    });

    test('severity errors filter', () {
      const q = TimelineQuery(severity: TimelineSeverityFilter.errors);
      expect(q.matches(_ev(severity: Severity.error)), isTrue);
      expect(q.matches(_ev(severity: Severity.critical)), isTrue);
      expect(q.matches(_ev(severity: Severity.warning)), isFalse);
      expect(q.isActive, isTrue);
    });

    test('source application filter', () {
      const q = TimelineQuery(source: TimelineSourceFilter.application);
      expect(q.matches(_ev(channel: 'Application')), isTrue);
      expect(q.matches(_ev(channel: 'System')), isFalse);
    });

    test('channel filter shows one channel, case-insensitive', () {
      const task = 'Microsoft-Windows-TaskScheduler/Operational';
      final events = [
        _ev(channel: task),
        _ev(channel: 'System'),
        _ev(channel: 'Application'),
      ];
      const q = TimelineQuery(
        channel: 'microsoft-windows-taskscheduler/OPERATIONAL',
      );
      expect(q.isActive, isTrue);
      expect(events.where(q.matches).map((e) => e.channel), [task]);

      // Empty channel: every channel merged.
      expect(events.where(const TimelineQuery().matches), hasLength(3));
      // Cleared resets the channel too.
      expect(q.cleared().channel, isEmpty);
    });

    test('channel filter combines with the other filters', () {
      const task = 'Microsoft-Windows-TaskScheduler/Operational';
      final events = [
        _ev(channel: task, severity: Severity.error),
        _ev(channel: task, severity: Severity.info),
        _ev(channel: 'System', severity: Severity.error),
      ];
      const q = TimelineQuery(
        channel: task,
        severity: TimelineSeverityFilter.errors,
      );
      expect(events.where(q.matches), hasLength(1));
    });

    test('category crash filter', () {
      const q = TimelineQuery(category: TimelineCategoryFilter.crash);
      expect(q.matches(_ev(category: 'Crash')), isTrue);
      expect(q.matches(_ev(category: 'Service')), isFalse);
    });

    test('provider filter is case-insensitive', () {
      const q = TimelineQuery(providerContains: 'kernel-power');
      expect(
        q.matches(_ev(provider: 'Microsoft-Windows-Kernel-Power')),
        isTrue,
      );
      expect(q.matches(_ev(provider: 'Service Control Manager')), isFalse);
    });

    test('event id exact match', () {
      const q = TimelineQuery(eventIdEquals: '41');
      expect(q.matches(_ev(winEventId: 41)), isTrue);
      expect(q.matches(_ev(winEventId: 42)), isFalse);
      expect(const TimelineQuery(eventIdEquals: 'abc').matches(_ev()), isFalse);
    });

    test('process name and pid', () {
      final withProc = _ev(
        processName: 'explorer.exe',
        hasProcessId: true,
        processId: 4242,
      );
      expect(
        const TimelineQuery(processContains: 'EXPLORER').matches(withProc),
        isTrue,
      );
      expect(
        const TimelineQuery(processContains: '4242').matches(withProc),
        isTrue,
      );
      expect(
        const TimelineQuery(processContains: 'chrome').matches(withProc),
        isFalse,
      );
    });

    test('computer filter', () {
      const q = TimelineQuery(computerContains: 'desk');
      expect(q.matches(_ev(computer: 'DESKTOP-1')), isTrue);
      expect(q.matches(_ev(computer: 'LAPTOP')), isFalse);
    });

    test('date range last 15 minutes', () {
      const now = 1_700_000_360_000;
      final q = TimelineQuery(
        dateRange: TimelineDateRangeFilter.last15Minutes,
        nowUnixMs: now,
      );
      expect(
        q.matches(_ev(timestampUnixMs: now - 10 * 60 * 1000)),
        isTrue,
      );
      expect(
        q.matches(_ev(timestampUnixMs: now - 20 * 60 * 1000)),
        isFalse,
      );
      expect(q.matches(_ev(timestampUnixMs: 0)), isFalse);
    });

    test('date range last hour', () {
      const now = 1_700_000_360_000;
      final q = TimelineQuery(
        dateRange: TimelineDateRangeFilter.lastHour,
        nowUnixMs: now,
      );
      expect(
        q.matches(_ev(timestampUnixMs: now - 30 * 60 * 1000)),
        isTrue,
      );
      expect(
        q.matches(_ev(timestampUnixMs: now - 2 * 60 * 60 * 1000)),
        isFalse,
      );
      expect(q.matches(_ev(timestampUnixMs: 0)), isFalse);
    });

    test('search covers provider eventId computer message xml process pid', () {
      final e = _ev(
        provider: 'Application Error',
        winEventId: 1000,
        computer: 'WORKPC',
        message: 'Faulting application name: notepad.exe',
        processName: 'notepad.exe',
        hasProcessId: true,
        processId: 99,
        rawXml: '<Event><Data>UniqueXmlToken</Data></Event>',
      );
      expect(const TimelineQuery(searchQuery: 'application error').matches(e), isTrue);
      expect(const TimelineQuery(searchQuery: '1000').matches(e), isTrue);
      expect(const TimelineQuery(searchQuery: 'workpc').matches(e), isTrue);
      expect(const TimelineQuery(searchQuery: 'faulting').matches(e), isTrue);
      expect(const TimelineQuery(searchQuery: 'uniquexmltoken').matches(e), isTrue);
      expect(const TimelineQuery(searchQuery: 'notepad').matches(e), isTrue);
      expect(const TimelineQuery(searchQuery: '99').matches(e), isTrue);
      expect(const TimelineQuery(searchQuery: 'no-such').matches(e), isFalse);
    });

    test('AND combines dedicated filters with search', () {
      final e = _ev(provider: 'Kernel-Power', winEventId: 41, category: 'Power');
      final q = const TimelineQuery(
        category: TimelineCategoryFilter.power,
        eventIdEquals: '41',
        searchQuery: 'kernel',
      );
      expect(q.matches(e), isTrue);
      expect(
        q.copyWith(eventIdEquals: '42').matches(e),
        isFalse,
      );
    });
  });
}
