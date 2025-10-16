import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const shouldFail = bool.fromEnvironment('shouldFail');

void main() {
  test('test add 1', () async {
    expect(1 + 1, 3);
  });

  test('test asserts', () async {
    assert(!shouldFail);
  });

  test(
    'file access',
    () async {
      final file = File('file.txt');
      final contents = file.readAsStringSync();
      expect(contents, 'test');
    },
    tags: ["File"],
  );
}
