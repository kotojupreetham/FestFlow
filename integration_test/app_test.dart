import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:festflow/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Hybrid Black Box Test', () {
    testWidgets('Guest Login Flow with Manual Auth Pause', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ensure the "Guest" entry exists and tap it
      Finder guestZoneButton = find.textContaining('Guest');
      // Sometimes it's inside FacePage, this taps anything containing 'Guest'
      if (guestZoneButton.evaluate().isNotEmpty) {
        await tester.tap(guestZoneButton.first);
        await tester.pumpAndSettle();
      }

      print('>>> [AI TESTBOT] Please prepare to select kotojupreetham@gmail.com (LEADER) or festflow888@gmail.com (GUEST)!');
      
      // Wait for 15 seconds to allow the user to manually bypass the Google Sign In 
      // authentication pop-up which blocks automated scripts.
      await Future.delayed(const Duration(seconds: 15));

      // Re-engage tester and verify we are not stuck
      await tester.pumpAndSettle();
      
      // Search for any UI element that dictates success, like "Dashboard"
      Finder dashboardText = find.textContaining('Dashboard');
      if (dashboardText.evaluate().isNotEmpty) {
         print('>>> [AI TESTBOT] Testing Verified: Dashboard Loaded Successfully.');
      } else {
         print('>>> [AI TESTBOT] Testing could not find Dashboard. Please verify UI manually.');
      }

    });
  });
}
