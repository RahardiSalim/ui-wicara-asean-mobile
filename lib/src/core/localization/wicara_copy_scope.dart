import 'package:flutter/widgets.dart';

import '../../features/onboarding/domain/onboarding_copy.dart';

/// Makes the learner's [OnboardingCopy] reachable from any widget without
/// threading it through every constructor.
///
/// Widgets that already receive `copy` (or a `preferredLanguage`) as a
/// parameter keep working as-is; this scope exists for the leaf surfaces —
/// review, insights, edge-AI, canvas — that sit far from the profile.
///
/// [WicaraCopyScope.of] falls back to English when no scope is installed so
/// widget tests can pump a page in isolation.
class WicaraCopyScope extends InheritedWidget {
  const WicaraCopyScope({required this.copy, required super.child, super.key});

  final OnboardingCopy copy;

  static final OnboardingCopy _fallback = OnboardingCopy.forLanguage('English');

  static OnboardingCopy of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WicaraCopyScope>();
    return scope?.copy ?? _fallback;
  }

  /// Non-listening lookup for use outside `build` (dialogs, callbacks).
  static OnboardingCopy read(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<WicaraCopyScope>()
        ?.widget;
    return scope is WicaraCopyScope ? scope.copy : _fallback;
  }

  @override
  bool updateShouldNotify(WicaraCopyScope oldWidget) =>
      oldWidget.copy.isIndonesian != copy.isIndonesian;
}
