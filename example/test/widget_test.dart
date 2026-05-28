import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_db_example/main.dart';

void main() {
  testWidgets('Todo app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    expect(find.text('Todo List'), findsOneWidget);
    expect(find.text('No todos yet'), findsOneWidget);
  });
}