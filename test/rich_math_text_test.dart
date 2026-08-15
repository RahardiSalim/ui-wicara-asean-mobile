import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wicara_mobile/src/features/pretest/presentation/widgets/rich_math_text.dart';

void main() {
  testWidgets('renders an unwrapped caret expression as math', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RichMathText('The function is f(x)=x^2.')),
    );

    expect(find.byType(Math), findsOneWidget);
    expect(find.text('^'), findsNothing);
  });
}
