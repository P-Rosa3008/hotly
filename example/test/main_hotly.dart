import 'package:flutter/widgets.dart';
import 'package:hotly/hotly.dart';
import 'package:hotly_example/main.dart';

import 'standard_test.dart' as t1;
import 'widgets_test.dart' as t2;

Future<void> main() async {
  runApp(
    TestRunner(main: testAll, child: MyApp()),
  );
}

@pragma('vm:entry-point')
void hotly() => hotlyInner();

void testAll() {
  t1.main();
  t2.main();
}
