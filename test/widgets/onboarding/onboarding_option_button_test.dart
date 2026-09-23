import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medito/widgets/onboarding/onboarding_option_button.dart';

void main() {
  testWidgets('supports focus and keyboard/D-pad style activation',
      (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingOptionButton(
            label: 'A little experience',
            selected: false,
            focusNode: focusNode,
            onTap: () => tapCount++,
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(tapCount, 1);
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
