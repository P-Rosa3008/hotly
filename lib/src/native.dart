import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'logger.dart';
import 'declarer.dart';

const _channel = MethodChannel('com.szotp.Hottie');

typedef IsolatedWorker<Input, Output> = Future<Output> Function(Input);

class NativeService {
  static final instance = NativeService();

  static const fromIsolateName = 'com.szotp.Hottie.fromIsolate';
  static const toIsolateName = 'com.szotp.Hottie.toIsolate';

  ReceivePort fromIsolate = ReceivePort();
  SendPort? toIsolate;
  Completer? _completer;
  bool _initialized = false;

  /// Ensures the background isolate is ready
  Future<void> ensureInitialized() async {
    if (_initialized && toIsolate != null) return;
    await _initialize();
    _initialized = true;
  }

  Future<void> _initialize() async {
    if (_initialized && toIsolate != null) return;

    // Close old ReceivePort if exists
    try {
      fromIsolate.close();
    } catch (_) {}

    fromIsolate = ReceivePort();
    _registerPort(fromIsolate.sendPort, fromIsolateName);
    fromIsolate.listen(_onMessage);

    toIsolate = IsolateNameServer.lookupPortByName(toIsolateName);
    final alreadyRunning = toIsolate != null;

    if (!alreadyRunning) {
      final handle = PluginUtilities.getCallbackHandle(hottieInner);
      if (handle == null) throw Exception('Failed to get hottieInner handle');

      Map<dynamic, dynamic> results = {};
      try {
        results = await _channel.invokeMethod(
          'initialize',
          {'handle': handle.toRawHandle()},
        );
      } on MissingPluginException {
        logHottie('[hottie] ⚠️ No native plugin found, using fallback initialization');
        results = {'root': Directory.current.path};
      }

      final root = results['root'] as String?;

      while (toIsolate == null) {
        toIsolate = IsolateNameServer.lookupPortByName(toIsolateName);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      if (root != null) {
        final msg = _SetCurrentDirectoryMessage(root);
        toIsolate!.send(msg);

        assert(Directory(msg.root).existsSync(),
        "Directory ${msg.root} doesn't exist");
      } else {
        logHottie('running without file access');
      }
    }

    _initialized = true;
  }

  /// Execute a top-level/static function in the background isolate
  Future<O> execute<I, O>(IsolatedWorker<I, O> method, I payload) async {
    await ensureInitialized();

    final handle = PluginUtilities.getCallbackHandle(method);
    if (handle == null) {
      throw ArgumentError('Worker must be top-level or static');
    }

    final completer = Completer<O>();

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError(StateError('Cancelled by new request'));
    }
    _completer = completer;

    toIsolate!.send({
      'type': 'execute',
      'handle': handle.toRawHandle(),
      'payload': payload,
    });

    return completer.future;
  }

  void _onMessage(dynamic message) {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(message);
      _completer = null;
    }
  }
}

void _registerPort(SendPort port, String name) {
  var ok = IsolateNameServer.registerPortWithName(port, name);
  if (!ok) {
    IsolateNameServer.removePortNameMapping(name);
    ok = IsolateNameServer.registerPortWithName(port, name);
  }
  assert(ok);
}

@pragma('vm:entry-point')
Future<void> hottieInner() async {
  logHottie('🔥 hottieInner started');
  window.setIsolateDebugName('hottie');

  final toIsolate = ReceivePort();
  _registerPort(toIsolate.sendPort, NativeService.toIsolateName);

  if (Platform.isMacOS) await Future.delayed(const Duration(milliseconds: 500));

  logHottie('✅ hottieInner waiting for events...');

  await for (final event in toIsolate) {
    try {
      if (event is Map && event['type'] == 'execute') {
        final rawHandle = event['handle'] as int;
        final payload = event['payload'];

        final handle = CallbackHandle.fromRawHandle(rawHandle);
        final worker = PluginUtilities.getCallbackFromHandle(handle);

        final result = await worker!(payload);

        final fromIsolate =
        IsolateNameServer.lookupPortByName(NativeService.fromIsolateName);
        fromIsolate?.send(result);
      } else if (event is _SetCurrentDirectoryMessage) {
        setTestDirectory(event.root);
      }
    } catch (e, st) {
      logHottie('❌ hottieInner error: $e\n$st');
    }
  }
}

class _SetCurrentDirectoryMessage {
  final String root;
  _SetCurrentDirectoryMessage(this.root);
}
