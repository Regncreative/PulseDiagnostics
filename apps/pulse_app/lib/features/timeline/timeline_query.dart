import 'package:pulse_protocol/pulse_wire.dart';

import 'timeline_display.dart';

/// Severity chip filter for Timeline (R2).
enum TimelineSeverityFilter { all, errors, warnings, info }

/// Channel/source chip filter for Timeline (R2).
enum TimelineSourceFilter { all, system, application, security, other }

/// Intelligence category chip filter for Timeline (R2).
enum TimelineCategoryFilter {
  all,
  crash,
  service,
  power,
  update,
  device,
  boot,
  security,
  storage,
}

/// Date-range preset for Timeline (R2). Absolute bounds use event timestamps.
enum TimelineDateRangeFilter {
  all,
  last15Minutes,
  lastHour,
  last24Hours,
  last7Days,

  /// From / to chosen by the user ([TimelineQuery.customFromUnixMs],
  /// [TimelineQuery.customToUnixMs]).
  custom,
}

/// Windows channel names are case-insensitive.
bool sameChannel(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

/// Client-side Timeline filter + search criteria.
///
/// Matching is case-insensitive. Empty / "all" fields do not constrain.
/// Never invents data — only compares fields present on [TimelineEvent].
class TimelineQuery {
  const TimelineQuery({
    this.severity = TimelineSeverityFilter.all,
    this.source = TimelineSourceFilter.all,
    this.category = TimelineCategoryFilter.all,
    this.dateRange = TimelineDateRangeFilter.all,
    this.searchQuery = '',
    this.providerContains = '',
    this.eventIdEquals = '',
    this.processContains = '',
    this.computerContains = '',
    this.channel = '',
    this.nowUnixMs,
    this.customFromUnixMs,
    this.customToUnixMs,
  });

  final TimelineSeverityFilter severity;
  final TimelineSourceFilter source;

  /// One Event Log channel (e.g. "Microsoft-Windows-TaskScheduler/Operational"),
  /// matched exactly and case-insensitively; empty shows every channel merged.
  final String channel;
  final TimelineCategoryFilter category;
  final TimelineDateRangeFilter dateRange;

  /// Free-text search over provider, Event ID, computer, message, XML,
  /// keyword/category, process, PID, and display fields.
  final String searchQuery;

  /// Dedicated provider substring filter (AND with search).
  final String providerContains;

  /// Exact Event ID match when non-empty (digits only compared to [TimelineEvent.winEventId]).
  final String eventIdEquals;

  /// Process name or PID substring.
  final String processContains;

  /// Computer name substring.
  final String computerContains;

  /// Clock for date-range filters (injectable for tests). Defaults to wall clock.
  final int? nowUnixMs;

  /// Inclusive bounds (UTC milliseconds) for [TimelineDateRangeFilter.custom].
  /// A missing bound leaves that side open.
  final int? customFromUnixMs;
  final int? customToUnixMs;

  bool get isActive =>
      severity != TimelineSeverityFilter.all ||
      source != TimelineSourceFilter.all ||
      channel.trim().isNotEmpty ||
      category != TimelineCategoryFilter.all ||
      dateRange != TimelineDateRangeFilter.all ||
      searchQuery.trim().isNotEmpty ||
      providerContains.trim().isNotEmpty ||
      eventIdEquals.trim().isNotEmpty ||
      processContains.trim().isNotEmpty ||
      computerContains.trim().isNotEmpty;

  TimelineQuery copyWith({
    TimelineSeverityFilter? severity,
    TimelineSourceFilter? source,
    TimelineCategoryFilter? category,
    TimelineDateRangeFilter? dateRange,
    String? searchQuery,
    String? providerContains,
    String? eventIdEquals,
    String? processContains,
    String? computerContains,
    String? channel,
    int? nowUnixMs,
    bool clearNowUnixMs = false,
    int? customFromUnixMs,
    int? customToUnixMs,
  }) {
    return TimelineQuery(
      severity: severity ?? this.severity,
      source: source ?? this.source,
      channel: channel ?? this.channel,
      category: category ?? this.category,
      dateRange: dateRange ?? this.dateRange,
      searchQuery: searchQuery ?? this.searchQuery,
      providerContains: providerContains ?? this.providerContains,
      eventIdEquals: eventIdEquals ?? this.eventIdEquals,
      processContains: processContains ?? this.processContains,
      computerContains: computerContains ?? this.computerContains,
      nowUnixMs: clearNowUnixMs ? null : (nowUnixMs ?? this.nowUnixMs),
      customFromUnixMs: customFromUnixMs ?? this.customFromUnixMs,
      customToUnixMs: customToUnixMs ?? this.customToUnixMs,
    );
  }

  TimelineQuery cleared() => const TimelineQuery();

  bool matches(TimelineEvent e) {
    if (!_matchesSeverity(e)) return false;
    if (!_matchesSource(e)) return false;
    if (!_matchesChannel(e)) return false;
    if (!_matchesCategory(e)) return false;
    if (!_matchesDateRange(e)) return false;
    if (!_matchesProvider(e)) return false;
    if (!_matchesEventId(e)) return false;
    if (!_matchesProcess(e)) return false;
    if (!_matchesComputer(e)) return false;
    return _matchesSearch(e);
  }

  bool _matchesSeverity(TimelineEvent e) {
    final sev = e.severity;
    return switch (severity) {
      TimelineSeverityFilter.all => true,
      TimelineSeverityFilter.errors =>
        sev == Severity.error || sev == Severity.critical,
      TimelineSeverityFilter.warnings => sev == Severity.warning,
      TimelineSeverityFilter.info =>
        sev == Severity.info ||
            sev == Severity.verbose ||
            sev == Severity.unknown,
    };
  }

  bool _matchesSource(TimelineEvent e) {
    final ch = e.displayChannel.toLowerCase();
    return switch (source) {
      TimelineSourceFilter.all => true,
      TimelineSourceFilter.system => ch == 'system',
      TimelineSourceFilter.application => ch == 'application',
      TimelineSourceFilter.security => ch == 'security',
      TimelineSourceFilter.other =>
        ch != 'system' && ch != 'application' && ch != 'security',
    };
  }

  bool _matchesChannel(TimelineEvent e) {
    final wanted = channel.trim();
    if (wanted.isEmpty) return true;
    return sameChannel(e.displayChannel, wanted);
  }

  bool _matchesCategory(TimelineEvent e) {
    final c = e.category.toLowerCase();
    return switch (category) {
      TimelineCategoryFilter.all => true,
      TimelineCategoryFilter.crash => c == 'crash',
      TimelineCategoryFilter.service => c == 'service',
      TimelineCategoryFilter.power => c == 'power',
      TimelineCategoryFilter.update => c == 'update',
      TimelineCategoryFilter.device => c == 'device' || c == 'driver',
      TimelineCategoryFilter.boot => c == 'boot',
      TimelineCategoryFilter.security => c == 'security',
      TimelineCategoryFilter.storage => c == 'storage',
    };
  }

  bool _matchesDateRange(TimelineEvent e) {
    if (dateRange == TimelineDateRangeFilter.all) return true;
    if (e.timestampUnixMs <= 0) return false;
    if (dateRange == TimelineDateRangeFilter.custom) {
      final from = customFromUnixMs;
      final to = customToUnixMs;
      return (from == null || e.timestampUnixMs >= from) &&
          (to == null || e.timestampUnixMs <= to);
    }
    final now = nowUnixMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    final windowMs = switch (dateRange) {
      TimelineDateRangeFilter.all => 0,
      TimelineDateRangeFilter.last15Minutes => 15 * 60 * 1000,
      TimelineDateRangeFilter.lastHour => 60 * 60 * 1000,
      TimelineDateRangeFilter.last24Hours => 24 * 60 * 60 * 1000,
      TimelineDateRangeFilter.last7Days => 7 * 24 * 60 * 60 * 1000,
      TimelineDateRangeFilter.custom => 0,
    };
    return e.timestampUnixMs >= now - windowMs;
  }

  bool _matchesProvider(TimelineEvent e) {
    final needle = providerContains.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return e.providerName.toLowerCase().contains(needle);
  }

  bool _matchesEventId(TimelineEvent e) {
    final raw = eventIdEquals.trim();
    if (raw.isEmpty) return true;
    final id = int.tryParse(raw);
    if (id == null) return false;
    return e.winEventId == id;
  }

  bool _matchesProcess(TimelineEvent e) {
    final needle = processContains.trim().toLowerCase();
    if (needle.isEmpty) return true;
    if (e.processName.toLowerCase().contains(needle)) return true;
    if (e.hasProcessId && e.processId.toString().contains(needle)) return true;
    return false;
  }

  bool _matchesComputer(TimelineEvent e) {
    final needle = computerContains.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return e.computerName.toLowerCase().contains(needle);
  }

  bool _matchesSearch(TimelineEvent e) {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      e.displayTitle,
      e.displaySummary,
      e.message,
      e.technicalSummary,
      e.providerName,
      e.displayChannel,
      e.category,
      e.computerName,
      e.processName,
      e.userSid,
      e.activityId,
      e.relatedActivityId,
      e.levelName,
      e.rawXml,
      e.winEventId.toString(),
      e.recordId.toString(),
      if (e.hasProcessId) e.processId.toString(),
      if (e.hasKeywords) e.keywords.toUnsigned(64).toRadixString(16),
      if (e.hasTask) e.task.toString(),
      if (e.hasOpcode) e.opcode.toString(),
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }
}
