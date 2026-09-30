import 'package:flutter_test/flutter_test.dart';

import 'package:smart_expense_ai/main.dart';

void main() {
  testWidgets('Smart Expense AI app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartExpenseAI());

    expect(find.text('SmartExpense AI'), findsOneWidget);
  });
}