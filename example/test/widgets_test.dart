import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty widgets', (x) async {});

  test('test add 2', () async {
    expect(add(1, 1), 2);
  });

  testWidgets('find', (tester) async {
    await tester.pumpWidget(
      SizedBox(),
    );

    expect(find.byType(Container), findsWidgets);
  });
}
