import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pulse_protocol/pulse_wire.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/timeline/hidden_event_types.dart';
import '../features/timeline/timeline_query.dart';
import '../logging/app_logger.dart';

/// A named Timeline filter snapshot the user can re-apply.
class SavedTimelineSearch {
  const SavedTimelineSearch({
    required this.id,
    required this.name,
    required this.queryJson,
    required this.createdUnixMs,
  });

  final String id;
  final String name;
  final Map<String, dynamic> queryJson;
  final int createdUnixMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'query': queryJson,
        'created_unix_ms': createdUnixMs,
      };

  static SavedTimelineSearch? fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final query = json['query'];
    if (id.isEmpty || name.isEmpty || query is! Map) return null;
    return SavedTimelineSearch(
      id: id,
      name: name,
      queryJson: Map<String, dynamic>.from(query),
      createdUnixMs: (json['created_unix_ms'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Local-only bookmarks, pins, saved Timeline searches and hidden event
/// types.
class TimelineLibraryController extends ChangeNotifier {
  TimelineLibraryController({required this.logger});

  final AppLogger logger;

  static const _kBookmarks = 'timeline.bookmarks';
  static const _kPins = 'timeline.pins';
  static const _kSavedSearches = 'timeline.saved_searches';
  static const _kHiddenEventTypes = 'timeline.hidden_event_types';
  static const _kFavoriteChannels = 'timeline.favorite_channels';

  SharedPreferences? _prefs;
  final Set<String> _bookmarkedEventIds = {};
  final Set<String> _pinnedEventIds = {};
  final List<SavedTimelineSearch> _savedSearches = [];
  final Map<String, HiddenEventType> _hiddenEventTypes = {};
  final List<String> _favoriteChannels = [];

  /// Channels pinned for one-click filtering (ADR-016), in the order pinned.
  List<String> get favoriteChannels => List.unmodifiable(_favoriteChannels);

  bool isFavoriteChannel(String channel) =>
      _favoriteChannels.any((c) => sameChannel(c, channel));

  /// Pins [channel], or unpins it when already pinned.
  Future<void> toggleFavoriteChannel(String channel) async {
    final name = channel.trim();
    if (name.isEmpty) return;
    final before = _favoriteChannels.length;
    _favoriteChannels.removeWhere((c) => sameChannel(c, name));
    final pinned = _favoriteChannels.length == before;
    if (pinned) _favoriteChannels.add(name);
    notifyListeners();
    await _prefs?.setStringList(_kFavoriteChannels, _favoriteChannels);
    logger.info(
      'TimelineLibrary',
      '${pinned ? 'pinned' : 'unpinned'} channel $name',
    );
  }

  Set<String> get bookmarkedEventIds => Set.unmodifiable(_bookmarkedEventIds);
  Set<String> get pinnedEventIds => Set.unmodifiable(_pinnedEventIds);
  List<SavedTimelineSearch> get savedSearches =>
      List.unmodifiable(_savedSearches);

  bool isBookmarked(String eventId) =>
      eventId.isNotEmpty && _bookmarkedEventIds.contains(eventId);

  bool isPinned(String eventId) =>
      eventId.isNotEmpty && _pinnedEventIds.contains(eventId);

  /// Hidden types, most recently hidden first (issue #25).
  List<HiddenEventType> get hiddenEventTypes =>
      _hiddenEventTypes.values.toList()
        ..sort((a, b) => b.hiddenAtUnixMs.compareTo(a.hiddenAtUnixMs));

  /// Whether the user hid [event]'s type (provider + Event ID).
  bool isHiddenType(TimelineEvent event) {
    if (_hiddenEventTypes.isEmpty) return false;
    final key = hiddenEventTypeKeyOf(event);
    return key != null && _hiddenEventTypes.containsKey(key);
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    _bookmarkedEventIds
      ..clear()
      ..addAll(p.getStringList(_kBookmarks) ?? const []);
    _pinnedEventIds
      ..clear()
      ..addAll(p.getStringList(_kPins) ?? const []);
    _savedSearches
      ..clear()
      ..addAll(_decodeSearches(p.getString(_kSavedSearches)));
    _hiddenEventTypes
      ..clear()
      ..addEntries(_decodeHiddenTypes(p.getString(_kHiddenEventTypes))
          .map((t) => MapEntry(t.key, t)));
    _favoriteChannels.clear();
    for (final c in p.getStringList(_kFavoriteChannels) ?? const <String>[]) {
      final name = c.trim();
      if (name.isNotEmpty && !isFavoriteChannel(name)) {
        _favoriteChannels.add(name);
      }
    }
    notifyListeners();
  }

  /// Hides every event with [event]'s provider and Event ID. Returns false
  /// when the event has no provider to match on.
  Future<bool> hideEventType(TimelineEvent event, {required String title}) async {
    final key = hiddenEventTypeKeyOf(event);
    if (key == null) return false;
    _hiddenEventTypes[key] = HiddenEventType(
      provider: event.providerName.trim(),
      eventId: event.winEventId,
      title: title.trim(),
      hiddenAtUnixMs: DateTime.now().millisecondsSinceEpoch,
    );
    notifyListeners();
    await _persistHiddenTypes();
    logger.info('TimelineLibrary', 'hid event type $key');
    return true;
  }

  /// Shows a hidden type again; [key] is [HiddenEventType.key].
  Future<void> showEventType(String key) async {
    if (_hiddenEventTypes.remove(key) == null) return;
    notifyListeners();
    await _persistHiddenTypes();
    logger.info('TimelineLibrary', 'showing event type $key again');
  }

  Future<void> _persistHiddenTypes() async {
    final encoded =
        jsonEncode([for (final t in _hiddenEventTypes.values) t.toJson()]);
    await _prefs?.setString(_kHiddenEventTypes, encoded);
  }

  List<HiddenEventType> _decodeHiddenTypes(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [
        for (final item in decoded)
          if (item is Map)
            ?HiddenEventType.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (e) {
      // A damaged list must not stop Pulse from starting: hide nothing.
      logger.warn('TimelineLibrary', 'hidden event types unreadable, ignored: $e');
      return [];
    }
  }

  Future<void> toggleBookmark(String eventId) async {
    if (eventId.isEmpty) return;
    if (_bookmarkedEventIds.contains(eventId)) {
      _bookmarkedEventIds.remove(eventId);
    } else {
      _bookmarkedEventIds.add(eventId);
    }
    notifyListeners();
    await _prefs?.setStringList(_kBookmarks, _bookmarkedEventIds.toList());
  }

  Future<void> togglePin(String eventId) async {
    if (eventId.isEmpty) return;
    if (_pinnedEventIds.contains(eventId)) {
      _pinnedEventIds.remove(eventId);
    } else {
      _pinnedEventIds.add(eventId);
    }
    notifyListeners();
    await _prefs?.setStringList(_kPins, _pinnedEventIds.toList());
  }

  Future<void> saveSearch({
    required String name,
    required TimelineQuery query,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final entry = SavedTimelineSearch(
      id: 's-${DateTime.now().millisecondsSinceEpoch}',
      name: trimmed,
      queryJson: timelineQueryToJson(query),
      createdUnixMs: DateTime.now().millisecondsSinceEpoch,
    );
    _savedSearches.insert(0, entry);
    // Cap local library size.
    if (_savedSearches.length > 50) {
      _savedSearches.removeRange(50, _savedSearches.length);
    }
    notifyListeners();
    await _persistSearches();
  }

  Future<void> deleteSavedSearch(String id) async {
    _savedSearches.removeWhere((s) => s.id == id);
    notifyListeners();
    await _persistSearches();
  }

  TimelineQuery? queryFromSaved(SavedTimelineSearch saved) {
    return timelineQueryFromJson(saved.queryJson);
  }

  Future<void> _persistSearches() async {
    final encoded = jsonEncode([for (final s in _savedSearches) s.toJson()]);
    await _prefs?.setString(_kSavedSearches, encoded);
  }

  static List<SavedTimelineSearch> _decodeSearches(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final out = <SavedTimelineSearch>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final s = SavedTimelineSearch.fromJson(item);
          if (s != null) out.add(s);
        } else if (item is Map) {
          final s = SavedTimelineSearch.fromJson(Map<String, dynamic>.from(item));
          if (s != null) out.add(s);
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  }
}

Map<String, dynamic> timelineQueryToJson(TimelineQuery q) {
  return {
    'severity': q.severity.name,
    'source': q.source.name,
    if (q.channel.trim().isNotEmpty) 'channel': q.channel.trim(),
    'category': q.category.name,
    'date_range': q.dateRange.name,
    if (q.customFromUnixMs != null) 'custom_from_unix_ms': q.customFromUnixMs,
    if (q.customToUnixMs != null) 'custom_to_unix_ms': q.customToUnixMs,
    'search_query': q.searchQuery,
    'provider_contains': q.providerContains,
    'event_id_equals': q.eventIdEquals,
    'process_contains': q.processContains,
    'computer_contains': q.computerContains,
  };
}

TimelineQuery timelineQueryFromJson(Map<String, dynamic> json) {
  TimelineSeverityFilter sev = TimelineSeverityFilter.all;
  for (final v in TimelineSeverityFilter.values) {
    if (v.name == json['severity']) sev = v;
  }
  TimelineSourceFilter source = TimelineSourceFilter.all;
  for (final v in TimelineSourceFilter.values) {
    if (v.name == json['source']) source = v;
  }
  TimelineCategoryFilter category = TimelineCategoryFilter.all;
  for (final v in TimelineCategoryFilter.values) {
    if (v.name == json['category']) category = v;
  }
  TimelineDateRangeFilter dateRange = TimelineDateRangeFilter.all;
  for (final v in TimelineDateRangeFilter.values) {
    if (v.name == json['date_range']) dateRange = v;
  }
  return TimelineQuery(
    severity: sev,
    source: source,
    channel: json['channel']?.toString() ?? '',
    category: category,
    dateRange: dateRange,
    customFromUnixMs: _optionalInt(json['custom_from_unix_ms']),
    customToUnixMs: _optionalInt(json['custom_to_unix_ms']),
    searchQuery: json['search_query']?.toString() ?? '',
    providerContains: json['provider_contains']?.toString() ?? '',
    eventIdEquals: json['event_id_equals']?.toString() ?? '',
    processContains: json['process_contains']?.toString() ?? '',
    computerContains: json['computer_contains']?.toString() ?? '',
  );
}

int? _optionalInt(Object? value) =>
    value is int ? value : (value is num ? value.toInt() : null);
