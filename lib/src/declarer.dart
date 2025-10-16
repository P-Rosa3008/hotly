import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:test_api/src/backend/declarer.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/group.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/group_entry.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/test.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/suite.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/live_test.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/suite_platform.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/invoker.dart'; // ignore: implementation_imports
import 'package:flutter_test/flutter_test.dart';

import 'logger.dart';
import 'model.dart';
import 'service.dart';

var _hasTestDirectory = false;

void setTestDirectory(String root) {
  logHotly('current directory: $root');
  Directory.current = root;
  _hasTestDirectory = true;
}

class MyReporter extends _Reporter {}

/*Future<TestGroupResults> runTestsFromRawCallback(int input) {
  final callback = PluginUtilities.getCallbackFromHandle(
    CallbackHandle.fromRawHandle(input),
  ) as TestMain?;
  if (callback == null) {
    throw ArgumentError('CallbackHandle could not be resolved');
  }
  return runTests(callback);
}*/

class _HotlyBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  void scheduleWarmUpFrame() {}
}

Future<TestGroupResults> runTests(TestMain input) async {
  // Ensure a WidgetsBinding exists in this isolate. The instance getter throws
// if not yet initialized, so we catch that and create our _HotlyBinding.
  try {
    // Attempt to access the instance to see if it's initialized.
    WidgetsBinding.instance;
  } catch (_) {
    _HotlyBinding();
  }

  final sw = Stopwatch()..start();
  final reporter = MyReporter();

  await Invoker.guard<Future<void>>(() async {
    final declarer = Declarer()..declare(input);
    final Group group = declarer.build();
    final Suite suite = Suite(group, SuitePlatform(Runtime.vm));
    await _runGroup(suite, group, <Group>[], reporter);
    reporter._onDone();
  });

  sw.stop();

  return TestGroupResults(
    skipped: reporter.skipped.length,
    failed: reporter.failed.map(_mapResult).toList(),
    passed: reporter.passed.map(_mapResult).toList(),
  );
}

TestResultError _mapError(AsyncError error) {
  return TestResultError(error.toString());
}

TestResult _mapResult(LiveTest test) {
  return TestResult(test.test.name, test.errors.map(_mapError).toList());
}

Future<void> _runGroup(
    Suite suiteConfig,
    Group group,
    List<Group> parents,
    _Reporter reporter,
    ) async {
  parents.add(group);
  try {
    final bool skipGroup = group.metadata.skip;
    bool setUpAllSucceeded = true;

    if (!skipGroup && group.setUpAll != null) {
      final LiveTest liveTest =
      group.setUpAll!.load(suiteConfig, groups: parents);
      await _runLiveTest(suiteConfig, liveTest, reporter, countSuccess: false);
      setUpAllSucceeded = liveTest.state.result.isPassing;
    }

    if (setUpAllSucceeded) {
      for (final GroupEntry entry in group.entries) {
        if (entry is Group) {
          await _runGroup(suiteConfig, entry, parents, reporter);
        } else if (entry.metadata.skip) {
          await _runSkippedTest(suiteConfig, entry as Test, parents, reporter);
        } else {
          final Test test = entry as Test;
          await _runLiveTest(
            suiteConfig,
            test.load(suiteConfig, groups: parents),
            reporter,
          );
        }
      }
    }

    if (!skipGroup && group.tearDownAll != null) {
      final LiveTest liveTest =
      group.tearDownAll!.load(suiteConfig, groups: parents);
      await _runLiveTest(suiteConfig, liveTest, reporter, countSuccess: false);
    }
  } finally {
    parents.remove(group);
  }
}

Future<void> _runSkippedTest(
    Suite suiteConfig,
    Test test,
    List<Group> parents,
    _Reporter reporter,
    ) async {
  final LocalTest skipped =
  LocalTest(test.name, test.metadata, () {}, trace: test.trace);
  if (skipped.metadata.skipReason != null) {
    // Optionally log skip reason
  }
  final LiveTest liveTest = skipped.load(suiteConfig);
  reporter._onTestStarted(liveTest);
  reporter.skipped.add(skipped);
}

Future<void> _runLiveTest(
    Suite suiteConfig,
    LiveTest liveTest,
    _Reporter reporter, {
      bool countSuccess = true,
    }) async {
  if (!_hasTestDirectory && liveTest.test.metadata.tags.contains('File')) {
    reporter.skipped.add(liveTest.test);
    return;
  }

  reporter._onTestStarted(liveTest);
  await Future<void>.microtask(liveTest.run);
  await null;

  final bool isSuccess = liveTest.state.result.isPassing;
  if (isSuccess && countSuccess) {
    reporter.passed.add(liveTest);
  } else if (!isSuccess) {
    reporter.failed.add(liveTest);
  }
}

abstract class _Reporter {
  final List<LiveTest> passed = <LiveTest>[];
  final List<LiveTest> failed = <LiveTest>[];
  final List<Test> skipped = <Test>[];

  void _onTestStarted(LiveTest liveTest) {}
  void _onDone() {}
}
