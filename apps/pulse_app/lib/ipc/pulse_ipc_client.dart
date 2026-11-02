import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:pulse_protocol/pulse_constants.dart';
import 'package:pulse_protocol/pulse_wire.dart';
import 'package:win32/win32.dart';

import '../app/dev_flags.dart';

enum IpcConnectionState { disconnected, connecting, connected, error }

/// How long [PulseIpcClient.disposeClient] waits for the worker to close its
/// pipe before force-killing the isolate.
const Duration _kWorkerShutdownTimeout = Duration(seconds: 2);

/// One IPC reconnect transition recorded on the Flutter client.
class IpcReconnectEvent {
  const IpcReconnectEvent({
    required this.unixMs,
    required this.reason,
  });

  final int unixMs;
  final String reason;
}

class IpcStatus {
  const IpcStatus({
    required this.state,
    this.message = '',
    this.serviceVersion = '',
    this.lastPongNonce,
    this.lastError = '',
    this.reconnectCount = 0,
    this.messagesSent = 0,
    this.messagesFailed = 0,
    this.lastPingLatencyMs,
    this.avgPingLatencyMs,
    this.pingCount = 0,
  });

  final IpcConnectionState state;
  final String message;
  final String serviceVersion;
  final int? lastPongNonce;
  final String lastError;
  final int reconnectCount;
  final int messagesSent;
  final int messagesFailed;
  final int? lastPingLatencyMs;
  final double? avgPingLatencyMs;
  final int pingCount;

  IpcStatus copyWith({
    IpcConnectionState? state,
    String? message,
    String? serviceVersion,
    int? lastPongNonce,
    String? lastError,
    int? reconnectCount,
    int? messagesSent,
    int? messagesFailed,
    int? lastPingLatencyMs,
    double? avgPingLatencyMs,
    int? pingCount,
  }) {
    return IpcStatus(
      state: state ?? this.state,
      message: message ?? this.message,
      serviceVersion: serviceVersion ?? this.serviceVersion,
      lastPongNonce: lastPongNonce ?? this.lastPongNonce,
      lastError: lastError ?? this.lastError,
      reconnectCount: reconnectCount ?? this.reconnectCount,
      messagesSent: messagesSent ?? this.messagesSent,
      messagesFailed: messagesFailed ?? this.messagesFailed,
      lastPingLatencyMs: lastPingLatencyMs ?? this.lastPingLatencyMs,
      avgPingLatencyMs: avgPingLatencyMs ?? this.avgPingLatencyMs,
      pingCount: pingCount ?? this.pingCount,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IpcStatus &&
        other.state == state &&
        other.message == message &&
        other.serviceVersion == serviceVersion &&
        other.lastPongNonce == lastPongNonce &&
        other.lastError == lastError &&
        other.reconnectCount == reconnectCount &&
        other.messagesSent == messagesSent &&
        other.messagesFailed == messagesFailed &&
        other.lastPingLatencyMs == lastPingLatencyMs &&
        other.avgPingLatencyMs == avgPingLatencyMs &&
        other.pingCount == pingCount;
  }

  @override
  int get hashCode => Object.hash(
        state,
        message,
        serviceVersion,
        lastPongNonce,
        lastError,
        reconnectCount,
        messagesSent,
        messagesFailed,
        lastPingLatencyMs,
        avgPingLatencyMs,
        pingCount,
      );
}

/// UI-facing IPC client. Pipe I/O runs on a dedicated isolate (ADR-008 / P0-5).
/// PulseService answered a request with an error, e.g. an older service that
/// does not know the request yet ("Unsupported message").
abstract class ServiceRequestUnavailable implements Exception {
  const ServiceRequestUnavailable(this.message, this.technicalDetail);

  final String message;
  final String technicalDetail;

  bool get serviceTooOld => message.toLowerCase().contains('unsupported');

  @override
  String toString() => technicalDetail.isEmpty
      ? message
      : '$message: $technicalDetail';
}

/// A crash history request failed (doc 43).
class CrashHistoryUnavailable extends ServiceRequestUnavailable {
  const CrashHistoryUnavailable(super.message, super.technicalDetail);
}

/// A channel list or tracked channel request failed (ADR-016).
class ChannelsUnavailable extends ServiceRequestUnavailable {
  const ChannelsUnavailable(super.message, super.technicalDetail);
}

class PulseIpcClient extends ChangeNotifier {
  PulseIpcClient({this.reconnectHistoryCapacity = 12, String? pipeName})
      : pipeName = pipeName ??
            (kPipeNameOverride.isEmpty ? kPipeName : kPipeNameOverride);

  /// Reserved for ClientHello only — must stay out of UI RPC id space (>= 1000).
  static const int kHandshakeRequestId = 1;

  final int reconnectHistoryCapacity;

  /// Named pipe of PulseService (overridable for tests and development).
  final String pipeName;

  IpcStatus _status = const IpcStatus(state: IpcConnectionState.disconnected);
  IpcStatus get status => _status;

  final List<IpcReconnectEvent> _reconnectHistory = [];
  List<IpcReconnectEvent> get reconnectHistory =>
      List.unmodifiable(_reconnectHistory);

  SendPort? _cmdPort;
  Isolate? _isolate;
  final _pending = <int, Completer<Envelope>>{};
  /// RPC ids for UI requests. 1 is reserved for the isolate ClientHello handshake.
  int _nextRequestId = 1000;
  bool _started = false;
  final _liveEvents = StreamController<TimelineEvent>.broadcast();
  final _healthUpdates = StreamController<HealthUpdate>.broadcast();
  double _pingLatencySumMs = 0;
  IpcConnectionState? _prevTrackedState;

  /// Live TimelineEvent pushes from EvtSubscribe (request_id = 0).
  Stream<TimelineEvent> get liveEvents => _liveEvents.stream;

  /// Live HealthSample pushes (1 Hz, request_id = 0).
  Stream<HealthUpdate> get healthUpdates => _healthUpdates.stream;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final ready = Completer<SendPort>();
    final response = ReceivePort();
    response.listen((message) {
      if (message is SendPort) {
        ready.complete(message);
        return;
      }
      if (message is Map) {
        _onIsolateMessage(message);
      }
    });
    _isolate = await Isolate.spawn(
      _ipcIsolateMain,
      (response.sendPort, pipeName),
    );
    _cmdPort = await ready.future;
    _cmdPort!.send({'cmd': 'connect'});
    _setStatus(_status.copyWith(
      state: IpcConnectionState.connecting,
      message: 'Connecting to PulseService…',
    ));
  }

  Future<void> disposeClient() async {
    final isolate = _isolate;
    final cmdPort = _cmdPort;
    _isolate = null;
    _cmdPort = null;
    if (isolate != null) {
      // Let the worker close its pipe handle before the isolate goes away.
      // Killing it first leaked the open handle (handles are per process),
      // so PulseService kept one pipe instance per restart until all 32
      // were in use.
      final exited = ReceivePort();
      isolate.addOnExitListener(exited.sendPort);
      cmdPort?.send({'cmd': 'shutdown'});
      await exited.first.timeout(_kWorkerShutdownTimeout, onTimeout: () {
        isolate.kill(priority: Isolate.immediate);
        return null;
      });
      exited.close();
    }
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(StateError('IPC shut down'));
      }
    }
    _pending.clear();
    _started = false;
    // Keep liveEvents stream open across reconnects within the same client.
  }

  Future<Pong> ping() async {
    final nonce = Random().nextInt(1 << 30);
    final env = Envelope(
      requestId: _nextRequestId++,
      body: Ping(nonce: nonce, unixMs: DateTime.now().millisecondsSinceEpoch),
    );
    final started = DateTime.now();
    try {
      final reply = await _request(env);
      final latency =
          DateTime.now().difference(started).inMilliseconds.clamp(0, 60000);
      final body = reply.body;
      if (body is! Pong) {
        _bumpFailed();
        throw StateError('Expected Pong, got ${body.runtimeType}');
      }
      final pingCount = _status.pingCount + 1;
      _pingLatencySumMs += latency;
      _setStatus(_status.copyWith(
        lastPongNonce: body.nonce,
        lastPingLatencyMs: latency,
        pingCount: pingCount,
        avgPingLatencyMs: _pingLatencySumMs / pingCount,
        messagesSent: _status.messagesSent + 1,
      ));
      return body;
    } catch (e) {
      _bumpFailed();
      rethrow;
    }
  }

  void resetDiagnosticsCounters() {
    _pingLatencySumMs = 0;
    _reconnectHistory.clear();
    _status = IpcStatus(
      state: _status.state,
      message: _status.message,
      serviceVersion: _status.serviceVersion,
      lastPongNonce: _status.lastPongNonce,
      lastError: _status.lastError,
    );
    notifyListeners();
  }

  Future<void> restartConnection() async {
    await disposeClient();
    await start();
  }

  /// Historical System Event Log snapshot (newest first). TASK-002.2.
  Future<TimelineSnapshot> getTimelineSnapshot({
    int limit = 100,
    String channel = 'System',
  }) async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: GetTimelineSnapshot(limit: limit, channel: channel),
    );
    final reply = await _request(
      env,
      timeout: const Duration(seconds: 90),
    );
    final body = reply.body;
    if (body is ErrorResponse) {
      throw StateError('${body.message}: ${body.technicalDetail}');
    }
    if (body is! TimelineSnapshot) {
      throw StateError('Expected TimelineSnapshot, got ${body.runtimeType}');
    }
    return body;
  }

  /// Lazy Level 3: re-fetch by channel + record id (includes raw Event XML).
  Future<TimelineEventDetail> getTimelineEventDetail({
    required String channel,
    required int recordId,
  }) async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: GetTimelineEventDetail(channel: channel, recordId: recordId),
    );
    final reply = await _request(
      env,
      timeout: const Duration(seconds: 30),
    );
    final body = reply.body;
    if (body is ErrorResponse) {
      throw StateError('${body.message}: ${body.technicalDetail}');
    }
    if (body is! TimelineEventDetail) {
      throw StateError('Expected TimelineEventDetail, got ${body.runtimeType}');
    }
    return body;
  }

  /// R3 Inventory Engine — lazy domain catalog (never blocks startup).
  Future<InventoryDomainSnapshot> getInventoryDomain({
    required InventoryDomainId domain,
    bool forceRefresh = false,
    int sinceGeneration = 0,
    int limit = 0,
  }) async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: GetInventoryDomain(
        domain: domain,
        forceRefresh: forceRefresh,
        sinceGeneration: sinceGeneration,
        limit: limit,
      ),
    );
    final reply = await _request(
      env,
      timeout: const Duration(seconds: 30),
    );
    final body = reply.body;
    if (body is ErrorResponse) {
      throw StateError('${body.message}: ${body.technicalDetail}');
    }
    if (body is! InventoryDomainSnapshot) {
      throw StateError(
        'Expected InventoryDomainSnapshot, got ${body.runtimeType}',
      );
    }
    return body;
  }

  /// Crash events of the last [days] (service default 30, at most 90),
  /// grouped by cause (doc 43).
  Future<CrashHistory> getCrashHistory({int days = 30}) async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: GetCrashHistory(days: days),
    );
    final reply = await _request(
      env,
      timeout: const Duration(seconds: 60),
    );
    final body = reply.body;
    if (body is ErrorResponse) {
      throw CrashHistoryUnavailable(body.message, body.technicalDetail);
    }
    if (body is! CrashHistory) {
      throw StateError('Expected CrashHistory, got ${body.runtimeType}');
    }
    return body;
  }

  /// Admin and Operational Event Log channels on this PC (ADR-016).
  Future<EventLogChannelList> listEventLogChannels() async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: ListEventLogChannels(),
    );
    final reply = await _request(env, timeout: const Duration(seconds: 30));
    final body = reply.body;
    if (body is ErrorResponse) {
      throw ChannelsUnavailable(body.message, body.technicalDetail);
    }
    if (body is! EventLogChannelList) {
      throw StateError('Expected EventLogChannelList, got ${body.runtimeType}');
    }
    return body;
  }

  /// Replaces the channels the service follows with [channels] (ADR-016).
  /// The reply says, per channel, whether it was accepted.
  Future<TrackedChannels> setTrackedChannels(List<String> channels) async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: SetTrackedChannels(channels: List.of(channels)),
    );
    final reply = await _request(env, timeout: const Duration(seconds: 15));
    final body = reply.body;
    if (body is ErrorResponse) {
      throw ChannelsUnavailable(body.message, body.technicalDetail);
    }
    if (body is! TrackedChannels) {
      throw StateError('Expected TrackedChannels, got ${body.runtimeType}');
    }
    return body;
  }

  /// Explicit live subscribe — call only after the historical snapshot finishes.
  Future<void> startLiveMonitoring({String channel = 'System'}) async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: StartLiveMonitoring(channel: channel),
    );
    await _request(env, timeout: const Duration(seconds: 10));
  }

  Future<void> stopLiveMonitoring() async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: StopLiveMonitoring(),
    );
    await _request(env, timeout: const Duration(seconds: 5));
  }

  /// Static info + first sample; service also enables 1 Hz HealthUpdate pushes.
  Future<HealthSnapshot> getHealthSnapshot() async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: GetHealthSnapshot(),
    );
    final reply = await _request(env, timeout: const Duration(seconds: 15));
    final body = reply.body;
    if (body is ErrorResponse) {
      throw StateError('${body.message}: ${body.technicalDetail}');
    }
    if (body is! HealthSnapshot) {
      throw StateError('Expected HealthSnapshot, got ${body.runtimeType}');
    }
    return body;
  }

  Future<void> startHealthMonitoring() async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: StartHealthMonitoring(),
    );
    await _request(env, timeout: const Duration(seconds: 10));
  }

  Future<void> stopHealthMonitoring() async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: StopHealthMonitoring(),
    );
    await _request(env, timeout: const Duration(seconds: 5));
  }

  Future<ProcessDetails> getProcessDetails(int pid) async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: GetProcessDetails(pid: pid),
    );
    final reply = await _request(env, timeout: const Duration(seconds: 10));
    final body = reply.body;
    if (body is ErrorResponse) {
      throw StateError('${body.message}: ${body.technicalDetail}');
    }
    if (body is! ProcessDetails) {
      throw StateError('Expected ProcessDetails, got ${body.runtimeType}');
    }
    return body;
  }

  Future<DiagnosticsSnapshot> getDiagnosticsSnapshot() async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: GetDiagnosticsSnapshot(),
    );
    final reply = await _request(env, timeout: const Duration(seconds: 10));
    final body = reply.body;
    if (body is ErrorResponse) {
      _bumpFailed();
      throw StateError('${body.message}: ${body.technicalDetail}');
    }
    if (body is! DiagnosticsSnapshot) {
      _bumpFailed();
      throw StateError('Expected DiagnosticsSnapshot, got ${body.runtimeType}');
    }
    _setStatus(_status.copyWith(messagesSent: _status.messagesSent + 1));
    return body;
  }

  Future<void> injectDiagnosticsTestEvent() async {
    final env = Envelope(
      requestId: _nextRequestId++,
      body: InjectDiagnosticsTestEvent(),
    );
    final reply = await _request(env, timeout: const Duration(seconds: 10));
    final body = reply.body;
    if (body is ErrorResponse && body.code != 0) {
      _bumpFailed();
      throw StateError('${body.message}: ${body.technicalDetail}');
    }
    _setStatus(_status.copyWith(messagesSent: _status.messagesSent + 1));
  }

  void _bumpFailed() {
    _setStatus(_status.copyWith(
      messagesFailed: _status.messagesFailed + 1,
      messagesSent: _status.messagesSent + 1,
    ));
  }

  Future<Envelope> _request(
    Envelope env, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final c = Completer<Envelope>();
    _pending[env.requestId] = c;
    _cmdPort?.send({'cmd': 'send', 'bytes': encodeFrame(encodeEnvelope(env))});
    return c.future.timeout(timeout);
  }

  void _onIsolateMessage(Map message) {
    final type = message['type'] as String?;
    if (type == 'status') {
      final stateName = message['state'] as String? ?? 'disconnected';
      final state = IpcConnectionState.values.firstWhere(
        (e) => e.name == stateName,
        orElse: () => IpcConnectionState.disconnected,
      );
      _setStatus(_status.copyWith(
        state: state,
        message: message['message'] as String? ?? '',
        serviceVersion:
            message['serviceVersion'] as String? ?? _status.serviceVersion,
        lastError: message['error'] as String? ?? '',
      ));
      return;
    }
    if (type == 'envelope') {
      final bytes = Uint8List.fromList(List<int>.from(message['bytes'] as List));
      try {
        final env = decodeEnvelope(bytes);
        final body = env.body;

        // Server push: live TimelineEvent (request_id == 0).
        if (env.requestId == 0 && body is TimelineEvent) {
          if (!_liveEvents.isClosed) {
            _liveEvents.add(body);
          }
          return;
        }

        // Server push: HealthUpdate (1 Hz) — sample + process inventory.
        if (env.requestId == 0 && body is HealthUpdate) {
          if (!_healthUpdates.isClosed) {
            _healthUpdates.add(body);
          }
          return;
        }

        // Handshake ServerHello (request_id == 1) must never satisfy RPC waiters.
        // Isolate ClientHello and UI GetTimelineSnapshot previously collided on id=1,
        // which surfaced as: Expected TimelineSnapshot, got ServerHello.
        if (body is ServerHello) {
          if (env.requestId != kHandshakeRequestId) {
            // Ignore unexpected ServerHello frames; do not complete RPC waiters.
            return;
          }
          _setStatus(_status.copyWith(
            state: IpcConnectionState.connected,
            serviceVersion: body.serviceVersion,
            message: 'Connected',
            lastError: '',
          ));
          return;
        }

        final pending = _pending.remove(env.requestId);
        if (pending != null && !pending.isCompleted) {
          pending.complete(env);
        }
      } catch (e) {
        // Complete all waiters so the UI does not hang until timeout.
        for (final entry in _pending.entries.toList()) {
          if (!entry.value.isCompleted) {
            entry.value.completeError(e);
          }
        }
        _pending.clear();
        _setStatus(_status.copyWith(
          lastError: e.toString(),
          message: 'Protocol decode failed',
        ));
      }
    }
  }

  /// Test-only: force IPC connection state without opening a pipe.
  @visibleForTesting
  void debugSetStatusForTest(IpcStatus status) {
    _prevTrackedState = status.state;
    _status = status;
    notifyListeners();
  }

  void _setStatus(IpcStatus s) {
    if (_status == s) return;

    // Count reconnect transitions: disconnected/error → connecting/connected
    // after we were previously online or mid-retry.
    var reconnectCount = s.reconnectCount;
    final prev = _prevTrackedState ?? _status.state;
    if ((prev == IpcConnectionState.disconnected ||
            prev == IpcConnectionState.error ||
            prev == IpcConnectionState.connecting) &&
        s.state == IpcConnectionState.connected &&
        prev != IpcConnectionState.connected) {
      // First connect should not count as reconnect.
      if (_prevTrackedState != null) {
        reconnectCount = _status.reconnectCount + 1;
        s = s.copyWith(reconnectCount: reconnectCount);
        final reason = _status.lastError.isNotEmpty
            ? _status.lastError
            : (prev == IpcConnectionState.error
                ? 'Recovered after connection error'
                : 'Reconnected after disconnect');
        _reconnectHistory.add(IpcReconnectEvent(
          unixMs: DateTime.now().millisecondsSinceEpoch,
          reason: reason,
        ));
        while (_reconnectHistory.length > reconnectHistoryCapacity) {
          _reconnectHistory.removeAt(0);
        }
      }
    }
    _prevTrackedState = s.state;

    final stateChanged = _status.state != s.state;
    final versionChanged = _status.serviceVersion != s.serviceVersion;
    final pongChanged = _status.lastPongNonce != s.lastPongNonce;
    final statsChanged = _status.reconnectCount != s.reconnectCount ||
        _status.messagesSent != s.messagesSent ||
        _status.messagesFailed != s.messagesFailed ||
        _status.lastPingLatencyMs != s.lastPingLatencyMs ||
        _status.avgPingLatencyMs != s.avgPingLatencyMs;

    _status = s;

    // UI only cares about connection state, service version, ping, and stats.
    if (!stateChanged && !versionChanged && !pongChanged && !statsChanged) {
      return;
    }
    notifyListeners();
  }
}

void _ipcIsolateMain((SendPort, String) args) {
  _IpcWorker(args.$1, args.$2).start();
}

class _IpcWorker {
  _IpcWorker(this.uiPort, this.pipeName);

  final SendPort uiPort;
  final String pipeName;
  final cmd = ReceivePort();
  int? handle;
  final buffer = BytesBuilder(copy: false);
  Timer? reconnectTimer;
  Timer? heartbeatTimer;
  Timer? readPoll;
  var shuttingDown = false;

  void start() {
    uiPort.send(cmd.sendPort);
    cmd.listen(_onCmd);
  }

  void _onCmd(dynamic message) {
    if (message is! Map) return;
    final c = message['cmd'];
    if (c == 'connect') {
      connect();
    } else if (c == 'send') {
      final bytes = Uint8List.fromList(List<int>.from(message['bytes'] as List));
      writeAll(bytes);
    } else if (c == 'shutdown') {
      shuttingDown = true;
      reconnectTimer?.cancel();
      readPoll?.cancel();
      closePipe();
      cmd.close();
      Isolate.exit();
    }
  }

  void setStatus(
    String state, {
    String message = '',
    String error = '',
    String serviceVersion = '',
  }) {
    uiPort.send({
      'type': 'status',
      'state': state,
      'message': message,
      'error': error,
      'serviceVersion': serviceVersion,
    });
  }

  void scheduleReconnect([Duration delay = const Duration(milliseconds: 500)]) {
    if (shuttingDown) return;
    reconnectTimer?.cancel();
    // Silent retries — do not spam UI with connecting↔disconnected flips.
    reconnectTimer = Timer(delay, () => connect(announce: false));
  }

  void closePipe() {
    heartbeatTimer?.cancel();
    heartbeatTimer = null;
    readPoll?.cancel();
    readPoll = null;
    if (handle != null && handle != INVALID_HANDLE_VALUE) {
      CloseHandle(handle!);
    }
    handle = null;
  }

  bool writeAll(Uint8List bytes) {
    final h = handle;
    if (h == null) return false;
    final ptr = calloc<Uint8>(bytes.length);
    ptr.asTypedList(bytes.length).setAll(0, bytes);
    var sent = 0;
    final written = calloc<DWORD>();
    try {
      while (sent < bytes.length) {
        final ok = WriteFile(
          h,
          (ptr + sent).cast(),
          bytes.length - sent,
          written,
          nullptr,
        );
        if (ok == 0 || written.value == 0) return false;
        sent += written.value;
      }
      return true;
    } finally {
      calloc.free(written);
      calloc.free(ptr);
    }
  }

  void pumpReads() {
    final h = handle;
    if (h == null) return;

    final avail = calloc<DWORD>();
    try {
      final peekOk = PeekNamedPipe(h, nullptr, 0, nullptr, avail, nullptr);
      if (peekOk == 0) {
        final err = GetLastError();
        if (err == ERROR_BROKEN_PIPE || err == ERROR_PIPE_NOT_CONNECTED) {
          closePipe();
          setStatus('disconnected', message: 'Disconnected', error: 'Peek $err');
          scheduleReconnect();
        }
        return;
      }
      if (avail.value == 0) return;
    } finally {
      calloc.free(avail);
    }

    final tmp = calloc<Uint8>(4096);
    final read = calloc<DWORD>();
    try {
      final ok = ReadFile(h, tmp.cast(), 4096, read, nullptr);
      if (ok == 0) {
        final err = GetLastError();
        closePipe();
        setStatus('disconnected', message: 'Disconnected', error: 'ReadFile $err');
        scheduleReconnect();
        return;
      }
      if (read.value == 0) return;
      buffer.add(tmp.asTypedList(read.value));
      var data = Uint8List.fromList(buffer.takeBytes());
      while (true) {
        try {
          final frame = tryDecodeFrame(data);
          if (frame == null) {
            buffer.add(data);
            break;
          }
          uiPort.send({'type': 'envelope', 'bytes': frame.payload});
          data = data.sublist(frame.consumed);
        } on FormatException catch (e) {
          setStatus('error', message: 'Protocol error', error: e.message);
          closePipe();
          break;
        }
      }
    } finally {
      calloc.free(tmp);
      calloc.free(read);
    }
  }

  void startReadPoll() {
    readPoll?.cancel();
    readPoll = Timer.periodic(const Duration(milliseconds: 16), (_) => pumpReads());
  }

  /// [announce] — when false (background retry), keep the last offline UI
  /// state instead of flickering through "Connecting…".
  void connect({bool announce = true}) {
    if (shuttingDown) return;
    if (announce) {
      setStatus('connecting', message: 'Connecting…');
    }
    closePipe();
    final name = pipeName.toNativeUtf16();
    try {
      handle = CreateFile(
        name,
        GENERIC_READ | GENERIC_WRITE,
        0,
        nullptr,
        OPEN_EXISTING,
        0,
        NULL,
      );
    } finally {
      calloc.free(name);
    }
    if (handle == INVALID_HANDLE_VALUE) {
      setStatus(
        'disconnected',
        message: 'PulseService is not running',
        error: 'CreateFile ${GetLastError()}',
      );
      scheduleReconnect(const Duration(seconds: 2));
      return;
    }

    final hello = Envelope(
      requestId: PulseIpcClient.kHandshakeRequestId,
      body: ClientHello(
        protocolVersion: kProtocolVersion,
        clientName: 'Pulse',
        clientVersion: kAppVersion,
      ),
    );
    if (!writeAll(encodeFrame(encodeEnvelope(hello)))) {
      closePipe();
      setStatus('error', message: 'Failed to send ClientHello');
      scheduleReconnect(const Duration(seconds: 2));
      return;
    }
    startReadPoll();
    heartbeatTimer?.cancel();
    heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final hb = Envelope(
        requestId: 0,
        body: Heartbeat(unixMs: DateTime.now().millisecondsSinceEpoch),
      );
      writeAll(encodeFrame(encodeEnvelope(hb)));
    });
    // Stay connecting until UI receives ServerHello — avoids racing snapshot RPC.
    setStatus('connecting', message: 'Waiting for ServerHello…');
  }
}
