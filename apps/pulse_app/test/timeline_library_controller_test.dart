import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/application/timeline_library_controller.dart';
import 'package:pulse/features/timeline/timeline_query.dart';
import 'package:pulse/logging/app_logger.dart';
import 'package:pulse_protocol/pulse_wire.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimelineLibraryController', () {
    test('persists bookmarks and pins across reload', () async {
      SharedPreferences.setMockInitialValues({});
      final logger = AppLogger();
      final a = TimelineLibraryController(logger: logger);
      await a.load();
      await a.toggleBookmark('System|1|1000');
      await a.togglePin('System|2|41');
      expect(a.isBookmarked('System|1|1000'), isTrue);
      expect(a.isPinned('System|2|41'), isTrue);

      final b = TimelineLibraryController(logger: logger);
      await b.load();
      expect(b.isBookmarked('System|1|1000'), isTrue);
      expect(b.isPinned('System|2|41'), isTrue);
      expect(b.isBookmarked('missing'), isFalse);
    });

    test('saved search roundtrips query fields', () async {
      SharedPreferences.setMockInitialValues({});
      final c = TimelineLibraryController(logger: AppLogger());
      await c.load();
      const q = TimelineQuery(
        severity: TimelineSeverityFilter.errors,
        category: TimelineCategoryFilter.power,
        searchQuery: 'kernel',
        eventIdEquals: '41',
        providerContains: 'Kernel-Power',
      );
      await c.saveSearch(name: 'Kernel 41', query: q);
      expect(c.savedSearches, hasLength(1));
      final restored = c.queryFromSaved(c.savedSearches.first)!;
      expect(restored.severity, TimelineSeverityFilter.errors);
      expect(restored.category, TimelineCategoryFilter.power);
      expect(restored.searchQuery, 'kernel');
      expect(restored.eventIdEquals, '41');
      expect(restored.providerContains, 'Kernel-Power');

      final d = TimelineLibraryController(logger: AppLogger());
      await d.load();
      expect(d.savedSearches, hasLength(1));
      expect(d.savedSearches.first.name, 'Kernel 41');
    });

    test('saved search keeps the channel filter', () async {
      SharedPreferences.setMockInitialValues({});
      final c = TimelineLibraryController(logger: AppLogger());
      await c.load();
      const channel = 'Microsoft-Windows-TaskScheduler/Operational';
      await c.saveSearch(
        name: 'Tasks',
        query: const TimelineQuery(channel: channel),
      );
      expect(c.queryFromSaved(c.savedSearches.first)!.channel, channel);

      // Searches saved before channels existed restore with all channels.
      final legacy = timelineQueryFromJson({'severity': 'errors'});
      expect(legacy.channel, isEmpty);
    });

    test('favorite channels persist in pin order, case-insensitive', () async {
      SharedPreferences.setMockInitialValues({});
      final a = TimelineLibraryController(logger: AppLogger());
      await a.load();
      expect(a.favoriteChannels, isEmpty);

      await a.toggleFavoriteChannel('Microsoft-Windows-TaskScheduler/Operational');
      await a.toggleFavoriteChannel('System');
      expect(a.isFavoriteChannel('system'), isTrue);
      expect(a.favoriteChannels, [
        'Microsoft-Windows-TaskScheduler/Operational',
        'System',
      ]);

      final b = TimelineLibraryController(logger: AppLogger());
      await b.load();
      expect(b.favoriteChannels, a.favoriteChannels);

      // Toggling again (any case) unpins.
      await b.toggleFavoriteChannel('SYSTEM');
      expect(b.favoriteChannels, ['Microsoft-Windows-TaskScheduler/Operational']);
      await b.toggleFavoriteChannel('   ');
      expect(b.favoriteChannels, hasLength(1));
    });

    test('hiding an event type works for events from added channels', () async {
      SharedPreferences.setMockInitialValues({});
      final c = TimelineLibraryController(logger: AppLogger());
      await c.load();
      final fromTaskScheduler = TimelineEvent(
        eventId: 'Microsoft-Windows-TaskScheduler/Operational|10|201',
        channel: 'Microsoft-Windows-TaskScheduler/Operational',
        providerName: 'Microsoft-Windows-TaskScheduler',
        winEventId: 201,
        title: 'TaskScheduler · Event 201',
      );
      expect(
        await c.hideEventType(fromTaskScheduler, title: fromTaskScheduler.title),
        isTrue,
      );
      expect(c.isHiddenType(fromTaskScheduler), isTrue);
      // Same provider and Event ID on another record: hidden as well.
      expect(
        c.isHiddenType(TimelineEvent(
          channel: 'Microsoft-Windows-TaskScheduler/Operational',
          providerName: 'Microsoft-Windows-TaskScheduler',
          winEventId: 201,
        )),
        isTrue,
      );
    });
  });
}
