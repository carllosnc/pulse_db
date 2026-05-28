import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_db_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );
  });

  testWidgets('Todo app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pump();

    expect(find.text('Todo List'), findsOneWidget);
  });

  testWidgets('loading then empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('No todos yet'), findsOneWidget);
  });
}
