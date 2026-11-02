import 'package:flutter/foundation.dart';
import 'package:pulse_protocol/pulse_wire.dart';

import '../features/timeline/timeline_query.dart';
import '../ipc/pulse_ipc_client.dart';
import '../logging/app_logger.dart';
import '../presentation/utils/pulse_user_errors.dart';

/// Lists this PC's Event Log channels and changes which ones PulseService
/// follows (ADR-016). Nothing is read until [load]; the service owns the
/// tracked list, so this controller only mirrors its replies.
class ChannelsController extends ChangeNotifier {
  ChannelsController({required this.ipc, required this.logger});

  final PulseIpcClient ipc;
  final AppLogger logger;

  EventLogChannelList? _list;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  bool _trackedChanged = false;
  int _requestSerial = 0;

  /// Last answer per channel (lower-cased path), shown next to the row.
  final Map<String, TrackedChannelResult> _results = {};

  EventLogChannelList? get list => _list;
  List<EventLogChannelInfo> get channels => _list?.channels ?? const [];
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  int get maxTracked => _list?.maxTracked ?? 0;

  List<String> get trackedChannels =>
      [for (final c in channels) if (c.tracked) c.path];

  bool get atLimit => maxTracked > 0 && trackedChannels.length >= maxTracked;

  TrackedChannelResult? resultFor(String channel) =>
      _results[channel.toLowerCase()];

  Future<void> load() async {
    if (ipc.status.state != IpcConnectionState.connected) {
      _error = 'PulseService is not connected.';
      notifyListeners();
      return;
    }
    final serial = ++_requestSerial;
    _loading = true;
    _error = null;
    notifyListeners();
    final watch = Stopwatch()..start();
    try {
      final list = await ipc.listEventLogChannels();
      if (serial != _requestSerial) return;
      _list = list;
      logger.info(
        'Channels',
        'Listed channels=${list.channels.length} '
            'skipped=${list.skippedChannels} '
            'tracked=${trackedChannels.length} ms=${watch.elapsedMilliseconds}',
      );
    } on ChannelsUnavailable catch (e) {
      if (serial != _requestSerial) return;
      _error = _messageFor(e);
      logger.warn('Channels', 'List failed: $e');
    } catch (e) {
      if (serial != _requestSerial) return;
      _error = PulseUserErrors.fromObject(e);
      logger.warn('Channels', 'List failed: $e');
    } finally {
      if (serial == _requestSerial) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Follows or stops following [channel]. The full new list goes to the
  /// service, which answers per channel; the screen shows a refusal inline.
  Future<void> setTracked(String channel, bool tracked) async {
    if (_saving || _list == null) return;
    final next = [
      for (final c in trackedChannels)
        if (!sameChannel(c, channel)) c,
      if (tracked) channel,
    ];
    _saving = true;
    _error = null;
    _results.remove(channel.toLowerCase());
    notifyListeners();
    try {
      final reply = await ipc.setTrackedChannels(next);
      for (final r in reply.results) {
        _results[r.path.toLowerCase()] = r;
      }
      for (final c in channels) {
        if (!c.builtIn) {
          c.tracked = reply.tracked.any((t) => sameChannel(t, c.path));
        }
      }
      _trackedChanged = true;
      logger.info(
        'Channels',
        '${tracked ? 'add' : 'remove'} $channel -> '
            'tracked=${reply.tracked.length}',
      );
    } on ChannelsUnavailable catch (e) {
      _error = _messageFor(e);
      logger.warn('Channels', 'Set tracked failed: $e');
    } catch (e) {
      _error = PulseUserErrors.fromObject(e);
      logger.warn('Channels', 'Set tracked failed: $e');
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// True once after the tracked list changed, so the Timeline can reload
  /// its snapshot and show the new channels' recent history.
  bool takeTrackedChanged() {
    final changed = _trackedChanged;
    _trackedChanged = false;
    return changed;
  }

  static String _messageFor(ChannelsUnavailable e) => e.serviceTooOld
      ? 'PulseService is older than this version of Pulse and cannot list '
          'event logs yet. Update or reinstall Pulse so both match.'
      : PulseUserErrors.fromMessage(e.toString());
}
