import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriscan/router/router.dart';
import 'package:nutriscan/providers/providers.dart';
import 'package:nutriscan/models/models.dart';

void main() {
  testWidgets('Router forces /onboarding/profile for new user', (WidgetTester tester) async {
    // 1. We mock the auth state to simulate a newly signed up user.
    // 2. We mock the profile state to be empty.
    
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => MockAuthNotifier()),
        profileProvider.overrideWith((ref) => MockProfileNotifier()),
      ],
    );

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the router pushed to the health profile page.
    // We expect it to redirect there instantly.
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    expect(currentPath, '/onboarding/profile');
  });
}

class MockAuthNotifier extends AuthNotifier {
  @override
  Future<void> _init() async {} // prevent API calls

  @override
  AuthState get state => const AuthState(
    isLoading: false,
    isAuthenticated: true,
    isNewUser: true,
  );
}

class MockProfileNotifier extends ProfileNotifier {
  @override
  Future<void> load() async {} // prevent API calls

  @override
  AsyncValue<HealthProfile?> get state => const AsyncValue.data(null);
}
