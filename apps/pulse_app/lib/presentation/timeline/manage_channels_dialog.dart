import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:pulse_protocol/pulse_wire.dart';

import '../../app/theme/pulse_theme.dart';
import '../../application/channels_controller.dart';
import '../../application/timeline_library_controller.dart';
import '../../features/channels/channel_display.dart';
import '../components/pulse_badge.dart';
import '../components/pulse_empty_state.dart';
import '../components/pulse_segmented_control.dart';

/// Lists this PC's event logs so the user can add them to the Timeline and pin
/// favorites (ADR-016). Returns true when the followed logs changed.
Future<bool> showManageChannelsDialog(BuildContext context) async {
  final channels = context.read<ChannelsController>();
  await showDialog<void>(
    context: context,
    builder: (context) => const ManageChannelsDialog(),
  );
  return channels.takeTrackedChanged();
}

class ManageChannelsDialog extends StatefulWidget {
  const ManageChannelsDialog({super.key});

  static const double _maxWidth = 880;
  static const double _maxHeight = 720;
  static const double _screenMargin = 48;

  @override
  State<ManageChannelsDialog> createState() => _ManageChannelsDialogState();
}

class _ManageChannelsDialogState extends State<ManageChannelsDialog> {
  final _searchController = TextEditingController();
  String _search = '';
  ChannelListFilter _filter = ChannelListFilter.all;

  /// Disabled channels whose "turn on" command is shown.
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChannelsController>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final controller = context.watch<ChannelsController>();
    final library = context.watch<TimelineLibraryController>();
    final visible = filterChannels(
      controller.channels,
      search: _search,
      filter: _filter,
      isFavorite: library.isFavoriteChannel,
    );

    return Dialog(
      backgroundColor: PulseTokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PulseTokens.radiusCard),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ManageChannelsDialog._maxWidth
              .clamp(0, size.width - ManageChannelsDialog._screenMargin),
          maxHeight: ManageChannelsDialog._maxHeight
              .clamp(0, size.height - ManageChannelsDialog._screenMargin),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(controller: controller),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('channels-search'),
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Search logs',
                        prefixIcon: Icon(LucideIcons.search, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  PulseSegmentedControl<ChannelListFilter>(
                    selected: _filter,
                    onChanged: (v) => setState(() => _filter = v),
                    segments: const [
                      PulseSegment(value: ChannelListFilter.all, label: 'All'),
                      PulseSegment(
                        value: ChannelListFilter.added,
                        label: 'In Timeline',
                      ),
                      PulseSegment(
                        value: ChannelListFilter.favorites,
                        label: 'Favorites',
                      ),
                    ],
                  ),
                ],
              ),
              if (controller.error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: controller.error!),
              ],
              const SizedBox(height: 12),
              Expanded(child: _body(controller, library, visible)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    ChannelsController controller,
    TimelineLibraryController library,
    List<EventLogChannelInfo> visible,
  ) {
    if (controller.loading && controller.list == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.list == null) {
      return const SizedBox.shrink();
    }
    if (visible.isEmpty) {
      return PulseEmptyState(
        icon: LucideIcons.search,
        title: 'No matching logs',
        message: _filter == ChannelListFilter.favorites
            ? 'Pin a log with the star to find it here.'
            : 'Try another search.',
      );
    }
    return ListView.builder(
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final channel = visible[index];
        return _ChannelRow(
          key: ValueKey(channel.path),
          channel: channel,
          favorite: library.isFavoriteChannel(channel.path),
          problem: switch (controller.resultFor(channel.path)) {
            final r? => trackedChannelProblem(r),
            null => null,
          },
          enabled: !controller.saving &&
              canTrackChannel(channel) &&
              (channel.tracked || !controller.atLimit),
          commandShown: _expanded.contains(channel.path),
          onTracked: (v) => controller.setTracked(channel.path, v),
          onFavorite: () => library.toggleFavoriteChannel(channel.path),
          onToggleCommand: () => setState(() {
            if (!_expanded.remove(channel.path)) _expanded.add(channel.path);
          }),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final ChannelsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final max = controller.maxTracked;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Event logs', style: theme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Add a log to follow it live in the Timeline. Pulse only '
                'reads logs; it never turns them on, off or clears them.',
                style: theme.bodySmall
                    ?.copyWith(color: PulseTokens.textSecondary),
              ),
              if (max > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${controller.trackedChannels.length} of $max added'
                  '${controller.atLimit ? ' — remove one to add another' : ''}',
                  key: const ValueKey('channels-count'),
                  style: theme.labelMedium?.copyWith(
                    color: controller.atLimit
                        ? PulseTokens.warning
                        : PulseTokens.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (controller.saving || controller.loading)
          const Padding(
            padding: EdgeInsets.all(10),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.x, size: 18),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PulseTokens.errorSoft,
        borderRadius: BorderRadius.circular(PulseTokens.radiusMd),
      ),
      child: Text(message, style: TextStyle(color: PulseTokens.error)),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    super.key,
    required this.channel,
    required this.favorite,
    required this.problem,
    required this.enabled,
    required this.commandShown,
    required this.onTracked,
    required this.onFavorite,
    required this.onToggleCommand,
  });

  final EventLogChannelInfo channel;
  final bool favorite;
  final String? problem;
  final bool enabled;
  final bool commandShown;
  final ValueChanged<bool> onTracked;
  final VoidCallback onFavorite;
  final VoidCallback onToggleCommand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final state = channelStateOf(channel);
    final checked = channel.builtIn || channel.tracked;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: checked,
            onChanged: enabled ? (v) => onTracked(v ?? false) : null,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(channel.path, style: theme.bodyMedium),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (channel.builtIn)
                        const PulseBadge(label: 'Built in', compact: true),
                      if (channel.tracked)
                        const PulseBadge(
                          label: 'In Timeline',
                          tone: PulseBadgeTone.accent,
                          compact: true,
                        ),
                      ..._stateBadges(state),
                      Text(
                        _detailLine(channel),
                        style: theme.labelSmall
                            ?.copyWith(color: PulseTokens.textTertiary),
                      ),
                    ],
                  ),
                  if (state == ChannelState.disabled) ...[
                    const SizedBox(height: 4),
                    _DisabledHelp(
                      channel: channel.path,
                      shown: commandShown,
                      onToggle: onToggleCommand,
                    ),
                  ],
                  if (state == ChannelState.accessDenied) ...[
                    const SizedBox(height: 4),
                    Text(
                      'PulseService runs as Local Service, which this log '
                      'does not allow to read.',
                      style: theme.labelSmall
                          ?.copyWith(color: PulseTokens.textSecondary),
                    ),
                  ],
                  if (problem != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      problem!,
                      style: theme.labelSmall
                          ?.copyWith(color: PulseTokens.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: onFavorite,
            icon: Icon(
              LucideIcons.star,
              size: 16,
              color: favorite ? PulseTokens.accent : PulseTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  static List<Widget> _stateBadges(ChannelState state) => switch (state) {
        ChannelState.ready => const [],
        ChannelState.empty =>
          const [PulseBadge(label: 'Empty', compact: true)],
        ChannelState.disabled => const [
            PulseBadge(
              label: 'Turned off',
              tone: PulseBadgeTone.warning,
              compact: true,
            ),
          ],
        ChannelState.accessDenied => const [
            PulseBadge(
              label: 'Access denied',
              tone: PulseBadgeTone.error,
              compact: true,
            ),
          ],
        ChannelState.notFound => const [
            PulseBadge(
              label: 'Not found',
              tone: PulseBadgeTone.error,
              compact: true,
            ),
          ],
        ChannelState.error => const [
            PulseBadge(
              label: 'Unreadable',
              tone: PulseBadgeTone.error,
              compact: true,
            ),
          ],
      };

  static String _detailLine(EventLogChannelInfo c) {
    final type = switch (c.type) {
      EventLogChannelType.admin => 'Admin',
      EventLogChannelType.operational => 'Operational',
      _ => '',
    };
    final count = c.hasRecordCount
        ? '${c.recordCount} event${c.recordCount == 1 ? '' : 's'}'
        : '';
    return [type, count].where((s) => s.isNotEmpty).join(' · ');
  }
}

/// A turned-off log: Pulse can follow it, but Windows writes nothing to it
/// until someone turns it on. Shows the command without ever running it.
class _DisabledHelp extends StatelessWidget {
  const _DisabledHelp({
    required this.channel,
    required this.shown,
    required this.onToggle,
  });

  final String channel;
  final bool shown;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final command = enableChannelCommand(channel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(PulseTokens.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              shown ? 'Hide how to turn it on' : 'How to turn it on',
              style: theme.labelSmall?.copyWith(color: PulseTokens.accent),
            ),
          ),
        ),
        if (shown) ...[
          const SizedBox(height: 4),
          Text(
            'Windows records nothing in this log while it is off. To turn it '
            'on, run this in a terminal opened as administrator:',
            style: theme.labelSmall?.copyWith(color: PulseTokens.textSecondary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
            decoration: BoxDecoration(
              color: PulseTokens.surface,
              borderRadius: BorderRadius.circular(PulseTokens.radiusSm),
              border: Border.all(color: PulseTokens.strokeSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    command,
                    style: theme.bodySmall
                        ?.copyWith(fontFamily: 'Consolas'),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy command',
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: command)),
                  icon: const Icon(LucideIcons.copy, size: 14),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
