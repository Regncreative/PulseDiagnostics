import 'package:pulse_protocol/pulse_wire.dart';

import '../timeline/timeline_query.dart';

/// What the Manage channels screen shows for one channel (ADR-016).
enum ChannelState { ready, empty, disabled, accessDenied, notFound, error }

ChannelState channelStateOf(EventLogChannelInfo c) {
  switch (c.access) {
    case EventLogChannelAccess.denied:
      return ChannelState.accessDenied;
    case EventLogChannelAccess.notFound:
      return ChannelState.notFound;
    case EventLogChannelAccess.error:
    case EventLogChannelAccess.unknown:
      return ChannelState.error;
    case EventLogChannelAccess.readable:
      break;
  }
  if (!c.enabled) return ChannelState.disabled;
  if (c.hasRecordCount && c.recordCount == 0) return ChannelState.empty;
  return ChannelState.ready;
}

/// Whether the user may check the channel. Built-in channels are always read;
/// unreadable ones would never deliver events.
bool canTrackChannel(EventLogChannelInfo c) =>
    !c.builtIn &&
    c.access == EventLogChannelAccess.readable;

/// The command a user can run in an elevated terminal to turn [channel] on.
/// Pulse shows it and never runs it: enabling a log changes Windows.
String enableChannelCommand(String channel) =>
    'wevtutil sl "$channel" /e:true';

/// Short label for chips: "TaskScheduler/Operational" instead of
/// "Microsoft-Windows-TaskScheduler/Operational".
String shortChannelLabel(String channel) {
  const prefix = 'Microsoft-Windows-';
  final c = channel.trim();
  if (c.length > prefix.length &&
      c.substring(0, prefix.length).toLowerCase() == prefix.toLowerCase()) {
    return c.substring(prefix.length);
  }
  return c;
}

enum ChannelListFilter { all, added, favorites }

/// Channels matching [search] (case-insensitive substring of the path) and
/// [filter]. Keeps the service's order (sorted by path).
List<EventLogChannelInfo> filterChannels(
  List<EventLogChannelInfo> channels, {
  String search = '',
  ChannelListFilter filter = ChannelListFilter.all,
  bool Function(String channel)? isFavorite,
}) {
  final needle = search.trim().toLowerCase();
  return [
    for (final c in channels)
      if ((needle.isEmpty || c.path.toLowerCase().contains(needle)) &&
          switch (filter) {
            ChannelListFilter.all => true,
            ChannelListFilter.added => c.tracked || c.builtIn,
            ChannelListFilter.favorites => isFavorite?.call(c.path) ?? false,
          })
        c,
  ];
}

/// Plain-language reason a tracked channel request was refused, or null when
/// the channel was accepted.
String? trackedChannelProblem(TrackedChannelResult r) {
  return switch (r.status) {
    TrackedChannelStatus.tracked ||
    TrackedChannelStatus.disabled ||
    TrackedChannelStatus.builtIn =>
      null,
    TrackedChannelStatus.accessDenied =>
      'PulseService is not allowed to read this log.',
    TrackedChannelStatus.notFound => 'This log no longer exists on this PC.',
    TrackedChannelStatus.unsupportedType =>
      'Analytic and Debug logs cannot be followed.',
    TrackedChannelStatus.overLimit =>
      r.detail.isNotEmpty ? r.detail : 'Too many logs added.',
    TrackedChannelStatus.failed ||
    TrackedChannelStatus.unspecified =>
      r.detail.isNotEmpty ? r.detail : 'The log could not be added.',
  };
}

/// Channels to offer in the Timeline's channel filter: favorites first (pin
/// order), then every other channel present in [events], sorted.
List<String> timelineChannelOptions(
  Iterable<TimelineEvent> events,
  List<String> favorites,
) {
  final others = <String, String>{};
  for (final e in events) {
    final name = e.channel.isNotEmpty ? e.channel : 'System';
    if (favorites.any((f) => sameChannel(f, name))) continue;
    others.putIfAbsent(name.toLowerCase(), () => name);
  }
  final sorted = others.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return [...favorites, ...sorted];
}
