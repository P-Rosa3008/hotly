# Hotly

Hotly is a Flutter package that provides a lightweight **test runner widget** for running unit, widget, or integration tests within your app. It supports both **in-process testing** and **isolated execution** via Dart isolates, giving you flexibility to run tests without blocking your main app.

---

## Features

- ✅ Run tests in-process or in a separate isolate
- ✅ Visual test indicator overlay for quick feedback
- ✅ View detailed test results with errors and stack traces
- ✅ Compatible with Flutter apps, integrates with `WidgetsBinding`
- ✅ Easy to integrate into existing apps without modifying test code

---

## Installation

Add this to your package’s `pubspec.yaml`:

```yaml
dependencies:
  hotly: ^0.1.0
