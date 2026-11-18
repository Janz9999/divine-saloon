// Basic smoke test: the app builds and shows its first screen.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salon_app/main.dart';

void main() {
  testWidgets('App starts on the welcome screen', (WidgetTester tester) async {
    // Tests have no internet, so network photos fail to load — ignore only those errors.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(const SalonApp());
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  // Tests have no real device, so Firebase can't start here — the app must
  // show the error screen with "Try again", never a blank white screen.
  testWidgets('Shows an error screen instead of a blank screen when Firebase fails to start',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AppBootstrap());
    await tester.pumpAndSettle();
    expect(find.text('Couldn\'t start the app'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
