// lib/main_dev.dart
import 'package:example/main.dart';
import 'package:example/test.g.hotly/all_tests.dart';
import 'package:flutter/material.dart';
import 'package:hotly/hotly.dart';

@pragma('vm:entry-point')
void hottie() => hottieInner();

void main() {
  hottie();
  runApp(
    HotlyTestRunner(
      key: Key('key'),
      child: MyApp(),
      main: allTests,
      showIndicator: true,
    ),
  );
}
