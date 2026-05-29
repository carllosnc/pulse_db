import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_db_example/home_page.dart';
import 'package:pulse_db_example/todo/todo_page.dart';
import 'package:pulse_db_example/notes/notes_page.dart';
import 'package:pulse_db_example/counter/counter_page.dart';

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

  testWidgets('home page shows example list', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: const HomePage()));

    expect(find.text('PulseDb Examples'), findsOneWidget);
    expect(find.text('Todo List'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Counters'), findsOneWidget);
  });

  testWidgets('todo page: loading then empty state', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: const TodoPage()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('No todos yet'), findsOneWidget);
  });

  testWidgets('notes page: loading then empty state', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: const NotesPage()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('No notes yet'), findsOneWidget);
  });

  testWidgets('counters page: loading then empty state', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: const CounterPage()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('No counters yet'), findsOneWidget);
  });
}
