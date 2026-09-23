import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medito/widgets/onboarding/onboarding_option_button.dart';

void main() {
  testWidgets('moves focus with arrow keys and activates the focused option',
      (tester) async {
    final firstFocus = FocusNode();
    final secondFocus = FocusNode();
    addTearDown(firstFocus.dispose);
    addTearDown(secondFocus.dispose);

    var selected = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              OnboardingOptionButton(
                label: 'New to meditation',
                selected: false,
                focusNode: firstFocus,
                onTap: () => selected = 'first',
              ),
              const SizedBox(height: 12),
              OnboardingOptionButton(
                label: 'A little experience',
                selected: false,
                focusNode: secondFocus,
                onTap: () => selected = 'second',
              ),
            ],
          ),
        ),
      ),
    );

    firstFocus.requestFocus();
    await tester.pump();

    expect(firstFocus.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(secondFocus.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, 'second');
  });

  testWidgets('keeps touch activation working', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingOptionButton(
            label: 'New to meditation',
            selected: false,
            onTap: () => tapCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('New to meditation'));
    await tester.pump();

    expect(tapCount, 1);
  });
}
