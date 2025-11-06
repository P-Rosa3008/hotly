// model.dart

class TestResultError {
  final String message;

  TestResultError(this.message);

  Map<String, dynamic> toMap() => {'message': message};

  factory TestResultError.fromMap(Map<String, dynamic> map) => TestResultError(map['message'] as String);
}

class TestResult {
  final String name;
  final List<TestResultError> errors;

  TestResult(this.name, this.errors);

  Map<String, dynamic> toMap() => {
        'name': name,
        'errors': errors.map((e) => e.toMap()).toList(),
      };

  factory TestResult.fromMap(Map<String, dynamic> map) => TestResult(
        map['name'] as String,
        (map['errors'] as List<dynamic>).map((e) => TestResultError.fromMap(e as Map<String, dynamic>)).toList(),
      );
}

class TestGroupResults {
  final int skipped;
  final List<TestResult> failed;
  final List<TestResult> passed;

  const TestGroupResults({
    this.skipped = 0,
    this.failed = const [],
    this.passed = const [],
  });

  int get totalCount => passed.length + failed.length + skipped;
  int get passedCount => passed.length;
  bool get noFailures => failed.isEmpty;
  bool get ok => noFailures;

  Map<String, dynamic> toMap() => {
        'skipped': skipped,
        'failed': failed.map((e) => e.toMap()).toList(),
        'passed': passed.map((e) => e.toMap()).toList(),
      };
  factory TestGroupResults.fromMap(Map<String, dynamic> map) => TestGroupResults(
        skipped: map['skipped'] as int? ?? 0,
        failed:
            (map['failed'] as List<dynamic>?)?.map((e) => TestResult.fromMap(e as Map<String, dynamic>)).toList() ?? [],
        passed:
            (map['passed'] as List<dynamic>?)?.map((e) => TestResult.fromMap(e as Map<String, dynamic>)).toList() ?? [],
      );

  @override
  String toString() => '🧪 $passedCount / $totalCount';
}
