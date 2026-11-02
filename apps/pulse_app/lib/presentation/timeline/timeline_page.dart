import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:pulse_protocol/pulse_wire.dart';

import '../../app/dev_flags.dart';
import '../../app/theme/pulse_theme.dart';
import '../../application/connection_controller.dart';
import '../../application/evtx_import_controller.dart';
import '../../application/settings_controller.dart';
import '../../application/timeline_library_controller.dart';
import '../../application/timeline_session_controller.dart';
import '../../features/channels/channel_display.dart';
import '../../features/timeline/timeline_activity.dart';
import '../../features/privacy/personal_data_redactor.dart';
import '../../features/timeline/evtx_import.dart';
import '../../features/timeline/timeline_display.dart';
import '../../features/timeline/timeline_export.dart';
import '../../features/timeline/timeline_incident_engine.dart';
import '../../features/timeline/timeline_empty_copy.dart';
import '../../features/timeline/timeline_query.dart';
import '../../features/timeline/widgets/timeline_details_panel.dart';
import '../../features/timeline/widgets/timeline_event_tile.dart';
import '../../features/timeline/widgets/timeline_overview_header.dart';
import '../../ipc/pulse_ipc_client.dart';
import '../../platform/evtx_file_reader.dart';
import '../../platform/export_writer.dart';
import '../components/pulse_app_bar.dart';
import '../components/pulse_badge.dart';
import '../components/pulse_empty_state.dart';
import '../components/pulse_loading.dart';
import '../components/safe_hover.dart';
import '../components/service_lifecycle_controls.dart';
import '../utils/pulse_snack.dart';
import '../utils/pulse_user_errors.dart';
import 'manage_channels_dialog.dart';
import 'timeline_date_range_dialog.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key, required this.title});

  final String title;

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  /// Stable IPC event id — selection survives filter changes when still visible.
  String? _selectedEventId;
  TimelineQuery _query = const TimelineQuery();
  final _listScrollController = ScrollController();
  final _providerFilterController = TextEditingController();
  final _eventIdFilterController = TextEditingController();
  final _processFilterController = TextEditingController();
  final _incidentEngine = TimelineIncidentEngine();
  final Set<String> _expandedIncidents = {};
  bool _advancedFiltersOpen = false;

  /// Shows events whose type the user hid (issue #25). Not saved: hidden
  /// types are hidden again next time.
  bool _showHiddenTypes = false;

  TimelineSessionController? _session;
  EvtxImport? _shownImport;
  String? _lastTopEventId;
  int _lastEventCount = 0;

  bool get _filtersActive => _query.isActive;

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_onScroll);
    // Visibility is owned by AppShell (IndexedStack keeps this State alive).
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.read<TimelineSessionController>();
    if (!identical(_session, session)) {
      _session = session;
      final events = session.events;
      _lastEventCount = events.length;
      _lastTopEventId = events.isNotEmpty ? events.first.eventId : null;
    }
  }

  @override
  void dispose() {
    _listScrollController.removeListener(_onScroll);
    _listScrollController.dispose();
    _providerFilterController.dispose();
    _eventIdFilterController.dispose();
    _processFilterController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_listScrollController.hasClients) return;
    final atTop = _listScrollController.position.pixels <= 48;
    context.read<TimelineSessionController>().setStickToTop(atTop);
  }

  void _handleEventsChanged(TimelineSessionController session) {
    final events = session.events;
    final newTopId = events.isNotEmpty ? events.first.eventId : null;
    final isSingleLivePrepend = _lastTopEventId != null &&
        newTopId != null &&
        newTopId != _lastTopEventId &&
        events.length == _lastEventCount + 1 &&
        events.length > 1 &&
        events[1].eventId == _lastTopEventId;

    if (isSingleLivePrepend) {
      final stick = session.stickToTop;
      final beforePixels =
          _listScrollController.hasClients ? _listScrollController.offset : 0.0;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || !_listScrollController.hasClients) return;
        if (stick) {
          await _listScrollController.animateTo(
            0,
            duration: PulseTokens.motionFast,
            curve: PulseTokens.motionCurve,
          );
        } else {
          const estimatedRow = 92.0;
          final target = beforePixels + estimatedRow;
          await _listScrollController.animateTo(
            target,
            duration: PulseTokens.motionFast,
            curve: PulseTokens.motionCurve,
          );
        }
      });
    }

    _lastEventCount = events.length;
    _lastTopEventId = newTopId;
  }

  Future<void> _jumpToNewest() async {
    context.read<TimelineSessionController>().setStickToTop(true);
    if (_listScrollController.hasClients) {
      await _listScrollController.animateTo(
        0,
        duration: PulseTokens.motionSlow,
        curve: PulseTokens.motionEmphasized,
      );
    }
  }

  void _pruneSelection(List<TimelineEvent> events) {
    if (_selectedEventId == null) return;
    final stillVisible = events.any(
      (e) => e.eventId == _selectedEventId && _query.matches(e),
    );
    if (!stillVisible) {
      _selectedEventId = null;
    }
  }

  void _onSeverity(TimelineSeverityFilter f) {
    final events = context.read<TimelineSessionController>().events;
    setState(() {
      _query = _query.copyWith(severity: f);
      _pruneSelection(events);
    });
  }

  void _onSource(TimelineSourceFilter f) {
    final events = context.read<TimelineSessionController>().events;
    setState(() {
      _query = _query.copyWith(source: f);
      _pruneSelection(events);
    });
  }

  void _onChannel(String channel) {
    final events = context.read<TimelineSessionController>().events;
    setState(() {
      _query = _query.copyWith(channel: channel);
      _pruneSelection(events);
    });
  }

  /// Opens Manage channels; reloads the snapshot when the followed logs
  /// changed so their recent history shows up, not only new events.
  Future<void> _openManageChannels() async {
    final session = context.read<TimelineSessionController>();
    final changed = await showManageChannelsDialog(context);
    if (changed && mounted && context.read<EvtxImportController>().current == null) {
      await session.reloadSnapshot();
    }
  }

  void _onCategory(TimelineCategoryFilter f) {
    final events = context.read<TimelineSessionController>().events;
    setState(() {
      _query = _query.copyWith(category: f);
      _pruneSelection(events);
    });
  }

  void _onDateRange(TimelineDateRangeFilter f) {
    if (f == TimelineDateRangeFilter.custom) {
      unawaited(_pickCustomDateRange());
      return;
    }
    final events = context.read<TimelineSessionController>().events;
    setState(() {
      _query = _query.copyWith(dateRange: f);
      _pruneSelection(events);
    });
  }

  /// Opens the from / to picker; keeps the current filter when cancelled.
  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final from = _query.customFromUnixMs;
    final to = _query.customToUnixMs;
    final picked = await showTimelineDateRangeDialog(
      context,
      initialFrom: from != null
          ? DateTime.fromMillisecondsSinceEpoch(from)
          : now.subtract(const Duration(hours: 1)),
      initialTo: to != null ? DateTime.fromMillisecondsSinceEpoch(to) : now,
    );
    if (picked == null || !mounted) return;
    final events = context.read<TimelineSessionController>().events;
    setState(() {
      _query = _query.copyWith(
        dateRange: TimelineDateRangeFilter.custom,
        customFromUnixMs: picked.from.millisecondsSinceEpoch,
        // The picker works in minutes; include the whole "to" minute.
        customToUnixMs: picked.to
                .add(const Duration(minutes: 1))
                .millisecondsSinceEpoch -
            1,
      );
      _pruneSelection(events);
    });
  }

  void _onSearch(String q) {
    final events = context.read<TimelineSessionController>().events;
    setState(() {
      _query = _query.copyWith(searchQuery: q);
      _pruneSelection(events);
    });
  }

  void _onProviderFilter(String v) {
    final events = context.read<TimelineSessionController>().events;
    setState(() {
      _query = _query.copyWith(providerContains: v);
      _pruneSelection(events);
    });
  }

  void _onEventIdFilter(String v) {
    final events = context.read<TimelineSessionController>().events;
    setState(() {
      _query = _query.copyWith(eventIdEquals: v);
      _pruneSelection(events);
    });
  }

  void _onProcessFilter(String v) {
    final events = context.read<TimelineSessionController>().events;
    setState(() {
      _query = _query.copyWith(processContains: v);
      _pruneSelection(events);
    });
  }

  void _clearFilters() {
    final events = context.read<TimelineSessionController>().events;
    setState(() {
      _query = const TimelineQuery();
      _providerFilterController.clear();
      _eventIdFilterController.clear();
      _processFilterController.clear();
      _pruneSelection(events);
    });
  }

  void _selectEvent(TimelineEvent event) {
    setState(() => _selectedEventId = event.eventId);
  }

  void _clearSelection() {
    setState(() => _selectedEventId = null);
  }

  List<TimelineEvent> _visible(List<TimelineEvent> events) {
    final library = context.read<TimelineLibraryController>();
    return pinnedFirst(
      events.where(
        (e) =>
            _query.matches(e) &&
            (_showHiddenTypes || !library.isHiddenType(e)),
      ),
      (e) => library.isPinned(e.eventId),
    );
  }

  /// Events the filters would show but whose type is hidden.
  int _hiddenMatchingCount(List<TimelineEvent> events) {
    final library = context.read<TimelineLibraryController>();
    if (library.hiddenEventTypes.isEmpty) return 0;
    return events
        .where((e) => library.isHiddenType(e) && _query.matches(e))
        .length;
  }

  TimelineEvent? _selectedEvent(List<TimelineEvent> events) {
    final id = _selectedEventId;
    if (id == null) return null;
    for (final e in events) {
      if (e.eventId == id) return e;
    }
    return null;
  }

  String _emptyMessage({
    required List<TimelineEvent> sessionEvents,
    required bool mock,
  }) {
    return timelineEmptyMessage(
      hasSessionEvents: sessionEvents.isNotEmpty,
      filtersActive: _filtersActive,
      query: _query,
      sessionHasSecurityChannelEvents:
          sessionContainsSecurityChannelEvents(sessionEvents),
      mock: mock,
    );
  }

  Future<void> _saveCurrentSearch() async {
    if (!_query.isActive) {
      PulseSnack.info(context, 'Set a search or filter before saving.');
      return;
    }
    final controller = TextEditingController(
      text: _query.searchQuery.trim().isNotEmpty
          ? _query.searchQuery.trim()
          : 'Saved search',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Save search'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Kernel-Power 41',
            ),
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !mounted) return;
    await context.read<TimelineLibraryController>().saveSearch(
          name: name,
          query: _query,
        );
    if (!mounted) return;
    PulseSnack.success(context, 'Saved search “${name.trim()}”.');
  }

  void _applySavedSearch(SavedTimelineSearch saved) {
    final q = context.read<TimelineLibraryController>().queryFromSaved(saved);
    if (q == null) return;
    final events = context.read<TimelineSessionController>().events;
    setState(() {
      _query = q;
      _providerFilterController.text = q.providerContains;
      _eventIdFilterController.text = q.eventIdEquals;
      _processFilterController.text = q.processContains;
      _pruneSelection(events);
    });
  }

  Map<String, TimelineIncidentMeta> _incidentMetaFor(List<TimelineEvent> visible) {
    final items = _incidentEngine.buildItems(visible);
    final map = <String, TimelineIncidentMeta>{};
    for (final item in items) {
      if (item is! TimelineIncidentItem) continue;
      final incident = item.incident;
      for (final e in incident.events) {
        map[e.eventId] = TimelineIncidentMeta(
          incidentId: incident.id,
          title: incident.title,
          ruleId: incident.ruleId,
        );
      }
    }
    return map;
  }

  Future<void> _exportVisible({required bool asCsv}) async {
    final events = context.read<TimelineSessionController>().events;
    final visible = _visible(events);
    final selected = _selectedEvent(visible);
    final toExport = selected != null ? [selected] : visible;
    if (toExport.isEmpty) {
      PulseSnack.info(context, 'Nothing to export — adjust filters or wait for events.');
      return;
    }
    try {
      final note = selected != null
          ? 'selected_event'
          : (_filtersActive ? 'filtered_visible' : 'visible_all');
      final library = context.read<TimelineLibraryController>();
      final incidentMeta = _incidentMetaFor(visible);
      final raw = asCsv
          ? TimelineExport.encodeCsv(
              toExport,
              appliedFilters: _query,
              bookmarkedEventIds: library.bookmarkedEventIds,
              pinnedEventIds: library.pinnedEventIds,
              incidentByEventId: incidentMeta,
            )
          : TimelineExport.encodeEvents(
              toExport,
              note: note,
              appliedFilters: _query,
              bookmarkedEventIds: library.bookmarkedEventIds,
              pinnedEventIds: library.pinnedEventIds,
              incidentByEventId: incidentMeta,
            );
      // Settings → Privacy: mask user / computer names, SIDs and addresses
      // (the clipboard copy is masked too).
      final body = context.read<SettingsController>().maskPersonalDataInExports
          ? PersonalDataRedactor.forThisPc(
              extraComputerNames: toExport.map((e) => e.computerName),
            ).redact(raw)
          : raw;
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final ext = asCsv ? 'csv' : 'json';
      final saved = await ExportWriter().write(
        fileName: 'timeline_$stamp.$ext',
        bytes: utf8.encode(body),
        defaultSubfolder: const ['Pulse', 'exports'],
      );
      await Clipboard.setData(ClipboardData(text: body));
      if (!mounted) return;
      PulseSnack.success(
        context,
        selected != null
            ? 'Exported selected event as $ext (also copied). ${saved.summary}'
            : 'Exported ${toExport.length} events as $ext (also copied). '
                '${saved.summary}',
      );
    } catch (e) {
      if (!mounted) return;
      PulseSnack.error(context, PulseUserErrors.fromObject(e));
    }
  }

  static const _evtxTypeGroup = XTypeGroup(
    label: 'Event log files',
    extensions: ['evtx'],
  );

  Future<void> _openEventLogFile() async {
    final file = await openFile(acceptedTypeGroups: const [_evtxTypeGroup]);
    if (file == null || !mounted) return;
    await _importEventLog(file.path);
  }

  Future<void> _importEventLog(String path) async {
    try {
      final imported = await context.read<EvtxImportController>().open(path);
      if (!mounted) return;
      final count = imported.events.length;
      PulseSnack.success(
        context,
        count == 0
            ? '${imported.fileName} has no events.'
            : 'Opened ${imported.fileName}: $count events.',
      );
    } on EvtxImportException catch (e) {
      if (!mounted) return;
      PulseSnack.error(context, e.message);
    }
  }

  void _closeEventLogFile() {
    context.read<EvtxImportController>().close();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final connectionLabel = context.select<ConnectionController, String>(
      (c) => c.statusLabel,
    );
    final state = context.select<PulseIpcClient, IpcConnectionState>(
      (c) => c.status.state,
    );
    final offline = state == IpcConnectionState.disconnected ||
        state == IpcConnectionState.error;
    final connecting = state == IpcConnectionState.connecting;

    final session = context.watch<TimelineSessionController>();
    final library = context.watch<TimelineLibraryController>();
    final imports = context.watch<EvtxImportController>();
    // An opened .evtx replaces this PC's events until it is closed. It is
    // read without the service, so it also works while PulseService is offline.
    final imported = imports.current;
    if (!identical(imported, _shownImport)) {
      _shownImport = imported;
      _selectedEventId = null;
    }
    final viewingFile = imported != null;
    if (!viewingFile) _handleEventsChanged(session);

    final events = imported?.events ?? session.events;
    final liveActive = !viewingFile && session.liveActive;
    final loadingSnapshot = !viewingFile && session.loadingSnapshot;
    final loadError = viewingFile ? null : session.loadError;
    final pendingNewCount = viewingFile ? 0 : session.pendingNewCount;
    final offlineView = offline && !viewingFile;
    final busy =
        imports.loading || (!viewingFile && (connecting || loadingSnapshot));

    final visible = _visible(events);
    final hiddenCount = _hiddenMatchingCount(events);
    // The overview counts never include hidden types, even while shown.
    final summaryEvents = library.hiddenEventTypes.isEmpty
        ? events
        : events.where((e) => !library.isHiddenType(e)).toList();
    final selectedEvent = _selectedEvent(events);
    final listItems = _incidentEngine.buildItems(visible);
    final selectedRca = selectedEvent == null
        ? null
        : _incidentEngine.hintFromItems(selectedEvent, listItems);
    final channelFilter = _ChannelFilterOptions(
      channels: timelineChannelOptions(events, library.favoriteChannels),
      favorites: library.favoriteChannels,
      onChannel: _onChannel,
      // An opened .evtx file has its own channels; nothing to manage there.
      onManage: viewingFile || offlineView ? null : _openManageChannels,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PulseAppBar(
          title: widget.title,
          connectionState: state,
          connectionLabel: connectionLabel,
          searchEnabled: !offlineView && !busy && loadError == null,
          searchHint: offlineView
              ? 'Connect PulseService to search events'
              : 'Search provider, Event ID, computer, message, process, PID…',
          searchQuery: _query.searchQuery,
          onSearchChanged: _onSearch,
          actions: [
            IconButton(
              tooltip: 'Open an event log file (.evtx) from another PC',
              onPressed: imports.loading ? null : _openEventLogFile,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(LucideIcons.folderOpen, size: 16),
            ),
            if (viewingFile)
              const PulseBadge(
                label: 'File',
                tone: PulseBadgeTone.info,
                icon: LucideIcons.fileText,
                compact: true,
              )
            else if (kUseMockTimeline)
              const PulseBadge(
                label: 'Mock',
                tone: PulseBadgeTone.accent,
                icon: LucideIcons.sparkles,
                compact: true,
              )
            else if (!offline && liveActive)
              const PulseBadge(
                label: 'Live',
                tone: PulseBadgeTone.success,
                icon: LucideIcons.radio,
                compact: true,
              )
            else if (!offline && events.isNotEmpty)
              const PulseBadge(
                label: 'Snapshot',
                tone: PulseBadgeTone.info,
                icon: LucideIcons.history,
                compact: true,
              ),
          ],
        ),
        Expanded(
          child: offlineView
              ? const ServiceOfflineRecovery(
                  titleFallback: 'Ready when Windows is',
                )
              : busy
                  ? const _TimelineSkeletonView()
                  : loadError != null
                      ? PulseEmptyState(
                          useBrandIllustration: true,
                          title: 'Could not load timeline',
                          message:
                              'Pulse connected, but the historical snapshot failed.\n\n'
                              '${PulseUserErrors.fromMessage(loadError)}',
                          actionLabel: 'Retry',
                          onAction: session.reloadSnapshot,
                        )
                      : _TimelineBody(
                          importBanner: imported == null
                              ? null
                              : _ImportBanner(
                                  imported: imported,
                                  onClose: _closeEventLogFile,
                                ),
                          sessionEvents: summaryEvents,
                          selectedEventId: _selectedEventId,
                          selectedEvent: selectedEvent,
                          selectedRca: selectedRca,
                          allVisibleEvents: visible,
                          listItems: listItems,
                          liveActive: liveActive,
                          expandedIncidents: _expandedIncidents,
                          onToggleIncident: (id) {
                            setState(() {
                              if (_expandedIncidents.contains(id)) {
                                _expandedIncidents.remove(id);
                              } else {
                                _expandedIncidents.add(id);
                              }
                            });
                          },
                          query: _query,
                          providerFilterController: _providerFilterController,
                          eventIdFilterController: _eventIdFilterController,
                          processFilterController: _processFilterController,
                          advancedFiltersOpen: _advancedFiltersOpen,
                          onToggleAdvancedFilters: () => setState(
                            () => _advancedFiltersOpen = !_advancedFiltersOpen,
                          ),
                          filtersActive: _filtersActive,
                          hiddenCount: hiddenCount,
                          showHiddenTypes: _showHiddenTypes,
                          onToggleShowHiddenTypes: () => setState(
                            () => _showHiddenTypes = !_showHiddenTypes,
                          ),
                          visible: visible,
                          hasStoredEvents: events.isNotEmpty,
                          emptyMessage: _emptyMessage(
                            sessionEvents: events,
                            mock: kUseMockTimeline,
                          ),
                          showMockBanner: kUseMockTimeline,
                          pendingNewCount: pendingNewCount,
                          scrollController: _listScrollController,
                          onSeverity: _onSeverity,
                          onSource: _onSource,
                          channelFilter: channelFilter,
                          onCategory: _onCategory,
                          onDateRange: _onDateRange,
                          onProviderFilter: _onProviderFilter,
                          onEventIdFilter: _onEventIdFilter,
                          onProcessFilter: _onProcessFilter,
                          onClearFilters: _clearFilters,
                          onSaveSearch: _saveCurrentSearch,
                          onApplySavedSearch: _applySavedSearch,
                          onSelect: _selectEvent,
                          onClear: _clearSelection,
                          onRefresh: imported == null
                              ? session.reloadSnapshot
                              : () => _importEventLog(imported.filePath),
                          onJumpToNewest: _jumpToNewest,
                          onExportJson: () => _exportVisible(asCsv: false),
                          onExportCsv: () => _exportVisible(asCsv: true),
                        ),
        ),
      ],
    );
  }
}

class _TimelineSkeletonView extends StatelessWidget {
  const _TimelineSkeletonView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PulseTokens.pagePadX,
            PulseTokens.pagePadTop,
            PulseTokens.pagePadX,
            8,
          ),
          child: Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                PulseLoadingBlock(
                  width: 64 + (i * 8),
                  height: 30,
                  borderRadius: BorderRadius.circular(PulseTokens.radiusPill),
                ),
              ],
            ],
          ),
        ),
        const Expanded(child: TimelineSkeleton(rows: 5)),
      ],
    );
  }
}

class _TimelineBody extends StatelessWidget {
  const _TimelineBody({
    this.importBanner,
    required this.sessionEvents,
    required this.selectedEventId,
    required this.selectedEvent,
    required this.selectedRca,
    required this.allVisibleEvents,
    required this.listItems,
    required this.liveActive,
    required this.expandedIncidents,
    required this.onToggleIncident,
    required this.query,
    required this.providerFilterController,
    required this.eventIdFilterController,
    required this.processFilterController,
    required this.advancedFiltersOpen,
    required this.onToggleAdvancedFilters,
    required this.filtersActive,
    required this.hiddenCount,
    required this.showHiddenTypes,
    required this.onToggleShowHiddenTypes,
    required this.visible,
    required this.hasStoredEvents,
    required this.emptyMessage,
    required this.showMockBanner,
    required this.pendingNewCount,
    required this.scrollController,
    required this.onSeverity,
    required this.onSource,
    required this.onCategory,
    required this.onDateRange,
    required this.onProviderFilter,
    required this.onEventIdFilter,
    required this.onProcessFilter,
    required this.onClearFilters,
    required this.onSaveSearch,
    required this.onApplySavedSearch,
    required this.onSelect,
    required this.onClear,
    required this.onRefresh,
    required this.onJumpToNewest,
    required this.onExportJson,
    required this.onExportCsv,
    required this.channelFilter,
  });

  /// Shown instead of the "last hour" overview while an .evtx is open.
  final Widget? importBanner;
  final _ChannelFilterOptions channelFilter;

  /// Every event held by the session (unfiltered) — feeds the hero summary.
  final List<TimelineEvent> sessionEvents;
  final String? selectedEventId;
  final TimelineEvent? selectedEvent;
  final TimelineRcaHint? selectedRca;
  final List<TimelineEvent> allVisibleEvents;
  final List<TimelineListItem> listItems;
  final bool liveActive;
  final Set<String> expandedIncidents;
  final ValueChanged<String> onToggleIncident;
  final TimelineQuery query;
  final TextEditingController providerFilterController;
  final TextEditingController eventIdFilterController;
  final TextEditingController processFilterController;
  final bool advancedFiltersOpen;
  final VoidCallback onToggleAdvancedFilters;
  final bool filtersActive;

  /// Events matching the filters whose type the user hid (issue #25).
  final int hiddenCount;
  final bool showHiddenTypes;
  final VoidCallback onToggleShowHiddenTypes;
  final List<TimelineEvent> visible;
  final bool hasStoredEvents;
  final String emptyMessage;
  final bool showMockBanner;
  final int pendingNewCount;
  final ScrollController scrollController;
  final ValueChanged<TimelineSeverityFilter> onSeverity;
  final ValueChanged<TimelineSourceFilter> onSource;
  final ValueChanged<TimelineCategoryFilter> onCategory;
  final ValueChanged<TimelineDateRangeFilter> onDateRange;
  final ValueChanged<String> onProviderFilter;
  final ValueChanged<String> onEventIdFilter;
  final ValueChanged<String> onProcessFilter;
  final VoidCallback onClearFilters;
  final VoidCallback onSaveSearch;
  final ValueChanged<SavedTimelineSearch> onApplySavedSearch;
  final ValueChanged<TimelineEvent> onSelect;
  final VoidCallback onClear;
  final VoidCallback onRefresh;
  final VoidCallback onJumpToNewest;
  final VoidCallback onExportJson;
  final VoidCallback onExportCsv;

  /// Inspector width including its 32 px right gutter.
  static const double _detailsPanelWidth = 452;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final showSideDetail = wide && selectedEvent != null;
        final selectedIsLive = liveActive &&
            selectedEvent != null &&
            selectedEvent!.timestampUnixMs > 0 &&
            DateTime.now().millisecondsSinceEpoch -
                    selectedEvent!.timestampUnixMs <
                120000;

        // "Latest" marks the newest event, not row 0: pinned events sort
        // first and would otherwise be labelled Latest.
        final latestEventId = latestEventIdOf(allVisibleEvents);

        final now = DateTime.now();
        final activity = TimelineActivitySummary.fromEvents(
          sessionEvents,
          nowUnixMs: now.millisecondsSinceEpoch,
        );

        final list = Scrollbar(
          controller: scrollController,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  PulseTokens.pagePadX,
                  4,
                  PulseTokens.pagePadX,
                  8,
                ),
                sliver: SliverToBoxAdapter(
                  child: importBanner ??
                      TimelineOverviewHeader(summary: activity, now: now),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  PulseTokens.pagePadX,
                  12,
                  PulseTokens.pagePadX,
                  4,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CompactFilterToolbar(
                    query: query,
                    advancedOpen: advancedFiltersOpen,
                    onToggleAdvanced: onToggleAdvancedFilters,
                    providerFilterController: providerFilterController,
                    eventIdFilterController: eventIdFilterController,
                    processFilterController: processFilterController,
                    filtersActive: filtersActive,
                    hiddenCount: hiddenCount,
                    showHiddenTypes: showHiddenTypes,
                    onToggleShowHiddenTypes: onToggleShowHiddenTypes,
                    selectedEvent: selectedEvent,
                    onSeverity: onSeverity,
                    onSource: onSource,
                    channelFilter: channelFilter,
                    onCategory: onCategory,
                    onDateRange: onDateRange,
                    onProviderFilter: onProviderFilter,
                    onEventIdFilter: onEventIdFilter,
                    onProcessFilter: onProcessFilter,
                    onClearFilters: onClearFilters,
                    onSaveSearch: onSaveSearch,
                    onApplySavedSearch: onApplySavedSearch,
                    onRefresh: onRefresh,
                    onExportJson: onExportJson,
                    onExportCsv: onExportCsv,
                  ),
                ),
              ),
              if (showMockBanner)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    PulseTokens.pagePadX,
                    10,
                    PulseTokens.pagePadX,
                    8,
                  ),
                  sliver: SliverToBoxAdapter(child: _PreviewBanner()),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  PulseTokens.pagePadX,
                  12,
                  PulseTokens.pagePadX,
                  PulseTokens.pagePadBottom,
                ),
                sliver: visible.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: PulseEmptyState(
                            useBrandIllustration: true,
                            title: hasStoredEvents
                                ? 'Nothing matches'
                                : 'Waiting for Windows',
                            message: hiddenCount > 0
                                ? '$emptyMessage\n\n'
                                    '${_hiddenCountLabel(hiddenCount)} '
                                    'not shown because you hid their type.'
                                : emptyMessage,
                            actionLabel: hiddenCount > 0
                                ? 'Show hidden events'
                                : (filtersActive ? 'Clear filters' : null),
                            onAction: hiddenCount > 0
                                ? onToggleShowHiddenTypes
                                : (filtersActive ? onClearFilters : null),
                          ),
                        ),
                      )
                    : DecoratedSliver(
                        decoration: BoxDecoration(
                          color: PulseTokens.surface,
                          borderRadius:
                              BorderRadius.circular(PulseTokens.radiusCard),
                          border: Border.all(color: PulseTokens.stroke),
                        ),
                        sliver: SliverPadding(
                          padding: const EdgeInsets.all(10),
                          sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final item = listItems[i];
                            if (item is TimelineLoneEventItem) {
                              final event = item.event;
                              return TimelineEventTile(
                                key: ValueKey(
                                  event.eventId.isNotEmpty
                                      ? event.eventId
                                      : 'row-$i',
                                ),
                                event: event,
                                isFirst: i == 0,
                                isLast: i == listItems.length - 1,
                                emphasize: !filtersActive &&
                                    event.eventId == latestEventId,
                                animationIndex: i.clamp(0, 12),
                                selected: selectedEventId != null &&
                                    event.eventId == selectedEventId,
                                onTap: () => onSelect(event),
                              );
                            }
                            final incident =
                                (item as TimelineIncidentItem).incident;
                            final expanded =
                                expandedIncidents.contains(incident.id);
                            return _IncidentGroupTile(
                              key: ValueKey(incident.id),
                              incident: incident,
                              expanded: expanded,
                              selectedEventId: selectedEventId,
                              onToggle: () => onToggleIncident(incident.id),
                              onSelect: onSelect,
                            );
                          },
                          childCount: listItems.length,
                        ),
                      ),
                        ),
                      ),
              ),
            ],
          ),
        );

        return Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: list),
                if (showSideDetail)
                  SizedBox(
                    width: _detailsPanelWidth,
                    child: TimelineDetailsPanel(
                      event: selectedEvent!,
                      onClose: onClear,
                      rcaHint: selectedRca,
                      relatedEvents: allVisibleEvents,
                      onSelectRelated: onSelect,
                      isLive: selectedIsLive,
                    ),
                  ),
              ],
            ),
            if (pendingNewCount > 0)
              Positioned(
                top: 52,
                left: 0,
                right: showSideDetail ? _detailsPanelWidth : 0,
                child: Center(
                  child: _NewEventsButton(
                    count: pendingNewCount,
                    onPressed: onJumpToNewest,
                  ),
                ),
              ),
            if (selectedEvent != null && !wide)
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onClear,
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.38),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth.clamp(300, 420),
                      child: TimelineDetailsPanel(
                        event: selectedEvent!,
                        onClose: onClear,
                        rcaHint: selectedRca,
                        relatedEvents: allVisibleEvents,
                        onSelectRelated: onSelect,
                        isLive: selectedIsLive,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _IncidentGroupTile extends StatelessWidget {
  const _IncidentGroupTile({
    super.key,
    required this.incident,
    required this.expanded,
    required this.selectedEventId,
    required this.onToggle,
    required this.onSelect,
  });

  final TimelineIncident incident;
  final bool expanded;
  final String? selectedEventId;
  final VoidCallback onToggle;
  final ValueChanged<TimelineEvent> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: PulseTokens.surfaceElevated,
          borderRadius: BorderRadius.circular(PulseTokens.radiusLg),
          border: Border.all(color: PulseTokens.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(
                expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                size: 18,
              ),
              title: Text(incident.title),
              subtitle: Text(
                '${incident.memberCount} related · ${incident.rca.confidenceLabel} confidence · rule ${incident.ruleId}',
              ),
              trailing: const PulseBadge(label: 'Correlated', compact: true),
              onTap: onToggle,
            ),
            if (expanded)
              for (final e in incident.events)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: TimelineEventTile(
                    event: e,
                    isFirst: false,
                    isLast: false,
                    emphasize: false,
                    animationIndex: 0,
                    selected: selectedEventId != null &&
                        e.eventId == selectedEventId,
                    onTap: () => onSelect(e),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _CompactFilterToolbar extends StatelessWidget {
  const _CompactFilterToolbar({
    required this.query,
    required this.advancedOpen,
    required this.onToggleAdvanced,
    required this.providerFilterController,
    required this.eventIdFilterController,
    required this.processFilterController,
    required this.filtersActive,
    required this.hiddenCount,
    required this.showHiddenTypes,
    required this.onToggleShowHiddenTypes,
    required this.selectedEvent,
    required this.onSeverity,
    required this.onSource,
    required this.onCategory,
    required this.onDateRange,
    required this.onProviderFilter,
    required this.onEventIdFilter,
    required this.onProcessFilter,
    required this.onClearFilters,
    required this.onSaveSearch,
    required this.onApplySavedSearch,
    required this.onRefresh,
    required this.onExportJson,
    required this.onExportCsv,
    required this.channelFilter,
  });

  final TimelineQuery query;
  final _ChannelFilterOptions channelFilter;
  final bool advancedOpen;
  final VoidCallback onToggleAdvanced;
  final TextEditingController providerFilterController;
  final TextEditingController eventIdFilterController;
  final TextEditingController processFilterController;
  final bool filtersActive;
  final int hiddenCount;
  final bool showHiddenTypes;
  final VoidCallback onToggleShowHiddenTypes;
  final TimelineEvent? selectedEvent;
  final ValueChanged<TimelineSeverityFilter> onSeverity;
  final ValueChanged<TimelineSourceFilter> onSource;
  final ValueChanged<TimelineCategoryFilter> onCategory;
  final ValueChanged<TimelineDateRangeFilter> onDateRange;
  final ValueChanged<String> onProviderFilter;
  final ValueChanged<String> onEventIdFilter;
  final ValueChanged<String> onProcessFilter;
  final VoidCallback onClearFilters;
  final VoidCallback onSaveSearch;
  final ValueChanged<SavedTimelineSearch> onApplySavedSearch;
  final VoidCallback onRefresh;
  final VoidCallback onExportJson;
  final VoidCallback onExportCsv;

  static String _severityLabel(TimelineSeverityFilter v) => switch (v) {
        TimelineSeverityFilter.all => 'All severity',
        TimelineSeverityFilter.errors => 'Errors',
        TimelineSeverityFilter.warnings => 'Warnings',
        TimelineSeverityFilter.info => 'Info',
      };

  static String _sourceLabel(TimelineSourceFilter v) => switch (v) {
        TimelineSourceFilter.all => 'All sources',
        TimelineSourceFilter.system => 'System',
        TimelineSourceFilter.application => 'Application',
        TimelineSourceFilter.security => 'Security',
        TimelineSourceFilter.other => 'Other',
      };

  static String _channelLabel(String channel) =>
      channel.trim().isEmpty ? 'All logs' : shortChannelLabel(channel);

  static String _categoryLabel(TimelineCategoryFilter v) => switch (v) {
        TimelineCategoryFilter.all => 'All types',
        TimelineCategoryFilter.crash => 'Crash',
        TimelineCategoryFilter.service => 'Service',
        TimelineCategoryFilter.power => 'Power',
        TimelineCategoryFilter.update => 'Update',
        TimelineCategoryFilter.device => 'Device',
        TimelineCategoryFilter.boot => 'Boot',
        TimelineCategoryFilter.security => 'Security',
        TimelineCategoryFilter.storage => 'Storage',
      };

  static String _dateLabel(TimelineDateRangeFilter v) => switch (v) {
        TimelineDateRangeFilter.all => 'All time',
        TimelineDateRangeFilter.last15Minutes => '15 minutes',
        TimelineDateRangeFilter.lastHour => '1 hour',
        TimelineDateRangeFilter.last24Hours => '24 hours',
        TimelineDateRangeFilter.last7Days => '7 days',
        TimelineDateRangeFilter.custom => 'Custom…',
      };

  /// Button and chip text: the picked range when a custom range is set.
  String _dateRangeLabel() {
    final from = query.customFromUnixMs;
    final to = query.customToUnixMs;
    if (query.dateRange != TimelineDateRangeFilter.custom ||
        from == null ||
        to == null) {
      return _dateLabel(query.dateRange);
    }
    return formatTimelineCustomRange(
      DateTime.fromMillisecondsSinceEpoch(from),
      DateTime.fromMillisecondsSinceEpoch(to),
    );
  }

  List<_ActiveFilterChip> _activeChips() {
    final chips = <_ActiveFilterChip>[];
    if (query.severity != TimelineSeverityFilter.all) {
      chips.add(_ActiveFilterChip(
        label: _severityLabel(query.severity),
        onRemove: () => onSeverity(TimelineSeverityFilter.all),
      ));
    }
    if (query.source != TimelineSourceFilter.all) {
      chips.add(_ActiveFilterChip(
        label: _sourceLabel(query.source),
        onRemove: () => onSource(TimelineSourceFilter.all),
      ));
    }
    if (query.channel.trim().isNotEmpty) {
      chips.add(_ActiveFilterChip(
        label: 'Log: ${shortChannelLabel(query.channel)}',
        onRemove: () => channelFilter.onChannel(''),
      ));
    }
    if (query.category != TimelineCategoryFilter.all) {
      chips.add(_ActiveFilterChip(
        label: _categoryLabel(query.category),
        onRemove: () => onCategory(TimelineCategoryFilter.all),
      ));
    }
    if (query.dateRange != TimelineDateRangeFilter.all) {
      chips.add(_ActiveFilterChip(
        label: _dateRangeLabel(),
        onRemove: () => onDateRange(TimelineDateRangeFilter.all),
      ));
    }
    final provider = query.providerContains.trim();
    if (provider.isNotEmpty) {
      chips.add(_ActiveFilterChip(
        label: 'Provider: $provider',
        onRemove: () {
          providerFilterController.clear();
          onProviderFilter('');
        },
      ));
    }
    final eventId = query.eventIdEquals.trim();
    if (eventId.isNotEmpty) {
      chips.add(_ActiveFilterChip(
        label: 'Event ID: $eventId',
        onRemove: () {
          eventIdFilterController.clear();
          onEventIdFilter('');
        },
      ));
    }
    final process = query.processContains.trim();
    if (process.isNotEmpty) {
      chips.add(_ActiveFilterChip(
        label: 'Process: $process',
        onRemove: () {
          processFilterController.clear();
          onProcessFilter('');
        },
      ));
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final chips = _activeChips();
    final advancedActive = query.providerContains.trim().isNotEmpty ||
        query.eventIdEquals.trim().isNotEmpty ||
        query.processContains.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterDropdown<TimelineSeverityFilter>(
                      label: _severityLabel(query.severity),
                      value: query.severity,
                      items: TimelineSeverityFilter.values,
                      itemLabel: _severityLabel,
                      onSelected: onSeverity,
                    ),
                    const SizedBox(width: 8),
                    _FilterDropdown<TimelineSourceFilter>(
                      label: _sourceLabel(query.source),
                      value: query.source,
                      items: TimelineSourceFilter.values,
                      itemLabel: _sourceLabel,
                      onSelected: onSource,
                    ),
                    const SizedBox(width: 8),
                    _FilterDropdown<String>(
                      label: _channelLabel(query.channel),
                      value: query.channel,
                      items: ['', ...channelFilter.channels],
                      itemLabel: _channelLabel,
                      onSelected: channelFilter.onChannel,
                    ),
                    for (final favorite in channelFilter.favorites) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: favorite,
                        child: _FilterChip(
                          label: '★ ${shortChannelLabel(favorite)}',
                          selected: sameChannel(query.channel, favorite),
                          onTap: () => channelFilter.onChannel(
                            sameChannel(query.channel, favorite) ? '' : favorite,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    _FilterDropdown<TimelineCategoryFilter>(
                      label: _categoryLabel(query.category),
                      value: query.category,
                      items: TimelineCategoryFilter.values,
                      itemLabel: _categoryLabel,
                      onSelected: onCategory,
                    ),
                    const SizedBox(width: 8),
                    _FilterDropdown<TimelineDateRangeFilter>(
                      label: _dateRangeLabel(),
                      value: query.dateRange,
                      items: TimelineDateRangeFilter.values,
                      itemLabel: _dateLabel,
                      onSelected: onDateRange,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: advancedOpen
                          ? 'Hide advanced'
                          : (advancedActive
                              ? 'Advanced (${[
                                  if (query.providerContains.trim().isNotEmpty)
                                    1,
                                  if (query.eventIdEquals.trim().isNotEmpty) 1,
                                  if (query.processContains.trim().isNotEmpty)
                                    1,
                                ].length})'
                              : 'Advanced'),
                      selected: advancedOpen || advancedActive,
                      onTap: onToggleAdvanced,
                    ),
                    if (hiddenCount > 0) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: showHiddenTypes
                            ? 'Hide them again'
                            : 'Events whose type you hid. Settings lists '
                                'the hidden types.',
                        child: _FilterChip(
                          label: showHiddenTypes
                              ? 'Showing ${_hiddenCountLabel(hiddenCount)}'
                              : _hiddenCountLabel(hiddenCount),
                          selected: showHiddenTypes,
                          onTap: onToggleShowHiddenTypes,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (filtersActive)
              IconButton(
                tooltip: 'Clear filters',
                onPressed: onClearFilters,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(LucideIcons.filterX, size: 16),
              ),
            if (filtersActive)
              IconButton(
                tooltip: 'Save search',
                onPressed: onSaveSearch,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(LucideIcons.save, size: 16),
              ),
            Consumer<TimelineLibraryController>(
              builder: (context, library, _) {
                if (library.savedSearches.isEmpty) {
                  return const SizedBox.shrink();
                }
                return PopupMenuButton<String>(
                  tooltip: 'Saved searches',
                  onSelected: (id) {
                    if (id.startsWith('del:')) {
                      library.deleteSavedSearch(id.substring(4));
                      return;
                    }
                    for (final s in library.savedSearches) {
                      if (s.id == id) {
                        onApplySavedSearch(s);
                        break;
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    for (final s in library.savedSearches) ...[
                      PopupMenuItem(value: s.id, child: Text(s.name)),
                      PopupMenuItem(
                        value: 'del:${s.id}',
                        child: Text(
                          'Delete “${s.name}”',
                          style: TextStyle(
                            color: PulseTokens.severityError,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                  icon: const Icon(LucideIcons.bookmark, size: 16),
                );
              },
            ),
            if (channelFilter.onManage != null)
              IconButton(
                tooltip: 'Manage event logs',
                onPressed: channelFilter.onManage,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(LucideIcons.listPlus, size: 16),
              ),
            PopupMenuButton<String>(
              tooltip: 'Export timeline',
              onSelected: (value) {
                if (value == 'json') onExportJson();
                if (value == 'csv') onExportCsv();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'json',
                  child: Text(
                    selectedEvent != null
                        ? 'Export selected as JSON'
                        : 'Export visible as JSON',
                  ),
                ),
                PopupMenuItem(
                  value: 'csv',
                  child: Text(
                    selectedEvent != null
                        ? 'Export selected as CSV'
                        : 'Export visible as CSV',
                  ),
                ),
              ],
              icon: const Icon(LucideIcons.download, size: 16),
            ),
            IconButton(
              tooltip: 'Refresh snapshot',
              onPressed: onRefresh,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
            ),
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final chip in chips)
                _RemovableFilterChip(
                  label: chip.label,
                  onRemove: chip.onRemove,
                ),
            ],
          ),
        ],
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _AdvancedFilterFields(
              providerController: providerFilterController,
              eventIdController: eventIdFilterController,
              processController: processFilterController,
              onProvider: onProviderFilter,
              onEventId: onEventIdFilter,
              onProcess: onProcessFilter,
            ),
          ),
          crossFadeState: advancedOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: PulseTokens.motionFast,
        ),
      ],
    );
  }
}

class _ActiveFilterChip {
  const _ActiveFilterChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final active = value != items.first;
    return PopupMenuButton<T>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem(
            value: item,
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: item == value
                      ? Icon(
                          LucideIcons.check,
                          size: 14,
                          color: PulseTokens.accent,
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                // Menus are at most 280 px wide; long log names are cut.
                Flexible(
                  child: Text(
                    itemLabel(item),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: AnimatedContainer(
        duration: PulseTokens.motionFast,
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? PulseTokens.accentSoft
              : PulseTokens.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? PulseTokens.accent.withValues(alpha: 0.38)
                : PulseTokens.stroke.withValues(alpha: 0.65),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: active
                        ? PulseTokens.accent
                        : PulseTokens.textSecondary,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12.5,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronDown,
              size: 12,
              color: active ? PulseTokens.accent : PulseTokens.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _RemovableFilterChip extends StatelessWidget {
  const _RemovableFilterChip({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PulseTokens.accentSoft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: PulseTokens.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.x, size: 12, color: PulseTokens.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewEventsButton extends StatelessWidget {
  const _NewEventsButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 new event' : '$count new events';
    return Semantics(
      button: true,
      label: '$label. Jump to newest',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              color: PulseTokens.accent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: PulseTokens.elevationLift,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.arrowUp,
                    size: 14,
                    color: PulseTokens.onAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: PulseTokens.onAccent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Says which file is open and how to get back to this PC's live events.
class _ImportBanner extends StatelessWidget {
  const _ImportBanner({required this.imported, required this.onClose});

  final EvtxImport imported;
  final VoidCallback onClose;

  String get _detail {
    final count = imported.events.length;
    final parts = <String>[
      imported.reachedLimit ? 'Newest $count events' : '$count events',
    ];
    final computers = imported.computerNames;
    if (computers.length == 1) {
      parts.add('from ${computers.first}');
    } else if (computers.length > 1) {
      parts.add('from ${computers.length} computers');
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PulseTokens.accentSoft.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(PulseTokens.radiusMd),
        border: Border.all(color: PulseTokens.accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.fileText, size: 16, color: PulseTokens.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viewing ${imported.fileName}',
                  style: text.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$_detail. Explained the same way as this PC\'s events; '
                  'the file was not changed or uploaded.',
                  style: text.bodySmall?.copyWith(
                    color: PulseTokens.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: onClose,
            icon: const Icon(LucideIcons.radio, size: 15),
            label: const Text('Back to live'),
          ),
        ],
      ),
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PulseTokens.accentSoft.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(PulseTokens.radiusMd),
        border: Border.all(
          color: PulseTokens.accent.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 15, color: PulseTokens.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mock timeline enabled (PULSE_MOCK_TIMELINE). Real multi-channel Event Log snapshots are used when this flag is off.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PulseTokens.textSecondary,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedFilterFields extends StatelessWidget {
  const _AdvancedFilterFields({
    required this.providerController,
    required this.eventIdController,
    required this.processController,
    required this.onProvider,
    required this.onEventId,
    required this.onProcess,
  });

  final TextEditingController providerController;
  final TextEditingController eventIdController;
  final TextEditingController processController;
  final ValueChanged<String> onProvider;
  final ValueChanged<String> onEventId;
  final ValueChanged<String> onProcess;

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label, String hint) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PulseTokens.radiusMd),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: providerController,
            decoration: deco('Provider', 'e.g. Kernel-Power'),
            onChanged: onProvider,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: eventIdController,
            decoration: deco('Event ID', '41'),
            keyboardType: TextInputType.number,
            onChanged: onEventId,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: processController,
            decoration: deco('Process / PID', 'explorer.exe'),
            onChanged: onProcess,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> with SafeHoverState {
  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      child: MouseRegion(
        onEnter: (_) => setHovered(true),
        onExit: (_) => setHovered(false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: PulseTokens.motionFast,
            curve: PulseTokens.motionCurve,
            constraints: const BoxConstraints(minHeight: 28),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? PulseTokens.accentSoft
                  : hover
                      ? PulseTokens.surfaceHover
                      : PulseTokens.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? PulseTokens.accent.withValues(alpha: 0.38)
                    : PulseTokens.stroke.withValues(alpha: 0.65),
              ),
              boxShadow: selected ? PulseTokens.elevationSoft : null,
            ),
            child: AnimatedDefaultTextStyle(
              duration: PulseTokens.motionFast,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: selected
                        ? PulseTokens.accent
                        : PulseTokens.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12.5,
                  ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the toolbar needs for the log (channel) filter and favorites (ADR-016).
class _ChannelFilterOptions {
  const _ChannelFilterOptions({
    required this.channels,
    required this.favorites,
    required this.onChannel,
    required this.onManage,
  });

  /// Favorites first, then the other logs present in the Timeline.
  final List<String> channels;
  final List<String> favorites;

  /// Empty string shows every log merged.
  final ValueChanged<String> onChannel;

  /// Null while a file is open or the service is offline.
  final VoidCallback? onManage;
}

/// "1 hidden event", "12 hidden events".
String _hiddenCountLabel(int count) =>
    count == 1 ? '1 hidden event' : '$count hidden events';
