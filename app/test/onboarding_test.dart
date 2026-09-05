// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stadtbau/game/save_store.dart';
import 'package:stadtbau/l10n/generated/app_localizations.dart';
import 'package:stadtbau/main.dart';
import 'package:stadtbau/ui/onboarding.dart';

void main() {
  Future<AppLocalizations> l10n() => AppLocalizations.delegate.load(const Locale('en'));

  void sizeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets('first launch shows step one, Next twice reaches Done, and Done persists the flag',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    sizeSurface(tester);
    final t = await l10n();

    await tester.pumpWidget(const HectopolisApp());
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingDialog), findsOneWidget);
    expect(find.text(t.onboardingStepTitle('tiles')), findsOneWidget);
    expect(find.text(t.onboardingStepCounter(1, 3)), findsOneWidget);
    expect(find.text(t.onboardingSkip), findsOneWidget);

    await tester.tap(find.text(t.onboardingNext));
    await tester.pumpAndSettle();
    expect(find.text(t.onboardingStepTitle('overlays')), findsOneWidget);

    await tester.tap(find.text(t.onboardingNext));
    await tester.pumpAndSettle();
    expect(find.text(t.onboardingStepTitle('loop')), findsOneWidget);
    expect(find.text(t.onboardingLoopNode('homes')), findsOneWidget);
    expect(find.text(t.onboardingNext), findsNothing);

    await tester.tap(find.text(t.onboardingDone));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingDialog), findsNothing);
    expect(await SaveStore().onboardingSeen(), isTrue);

    // A rebuild of the app must not show the overlay again.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const HectopolisApp());
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingDialog), findsNothing);
  });

  testWidgets('Skip closes the overlay and marks it seen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    sizeSurface(tester);
    final t = await l10n();

    await tester.pumpWidget(const HectopolisApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.onboardingSkip));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingDialog), findsNothing);
    expect(await SaveStore().onboardingSeen(), isTrue);
  });

  testWidgets('Escape dismisses the overlay and the help button brings it back', (tester) async {
    SharedPreferences.setMockInitialValues({});
    sizeSurface(tester);
    final t = await l10n();

    await tester.pumpWidget(const HectopolisApp());
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingDialog), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingDialog), findsNothing);

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingDialog), findsOneWidget);
    expect(find.text(t.onboardingTitle), findsOneWidget);
  });

  testWidgets('German texts render', (tester) async {
    SharedPreferences.setMockInitialValues({});
    sizeSurface(tester);
    tester.platformDispatcher.localeTestValue = const Locale('de');
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const HectopolisApp());
    await tester.pumpAndSettle();
    final de = await AppLocalizations.delegate.load(const Locale('de'));
    expect(find.text(de.onboardingStepTitle('tiles')), findsOneWidget);
    expect(find.text(de.onboardingSkip), findsOneWidget);
  });

  test('the onboarding flag round-trips through SaveStore', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SaveStore();
    expect(await store.onboardingSeen(), isFalse);
    await store.markOnboardingSeen();
    expect(await store.onboardingSeen(), isTrue);
  });
}
