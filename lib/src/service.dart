// service.dart

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'declarer.dart';
import 'model.dart';
import 'native.dart';

/// Called from a native isolate. Reconstructs the callback from handle.
Future<Map<String, dynamic>> runTestsFromRawCallback(int handle) async {
  final callback = PluginUtilities.getCallbackFromHandle(
      CallbackHandle.fromRawHandle(handle)) as void Function();

  final result = await runTests(callback);
  return result.toMap();
}


typedef TestMain = void Function();

abstract class TestService extends ValueNotifier<TestGroupResults> {
  final void Function() main;
  final _stopwatch = Stopwatch();

  TestService(this.main) : super(const TestGroupResults());

  factory TestService.create(TestMain main, {bool isolated = false}) {
    if (isolated) {
      return _SeparateEngineService(main);
    } else {
      return _RegularTestService(main);
    }
  }

  void retest() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  @protected
  void update(TestGroupResults message) {
    value = message;

    _stopwatch.stop();
    final ms = _stopwatch.elapsed.inMicroseconds / 1000;
    debugPrint('$message, took ${ms}ms');
  }
}

class _SeparateEngineService extends TestService {
  final _native = NativeService.instance;

  _SeparateEngineService(void Function() main) : super(main);

  @override
  Future<void> retest() async {
    super.retest();

    try {
      // Wait until NativeService is ready
      await _native.ensureInitialized();

      final handle = PluginUtilities.getCallbackHandle(main);
      if (handle == null) {
        debugPrint('[hottie] ❌ Failed to get callback handle for test main');
        return;
      }

      final rawHandle = handle.toRawHandle();
      final resultMap = await _native.execute(runTestsFromRawCallback, rawHandle);

      update(TestGroupResults.fromMap(resultMap));
    } catch (e, st) {
      debugPrint('[hottie] ❌ retest() crashed: $e\n$st');
    }
  }
}

class _RegularTestService extends TestService {
  _RegularTestService(TestMain main) : super(main);

  @override
  void retest() {
    super.retest();
    runTests(main).then(update);
  }
}
