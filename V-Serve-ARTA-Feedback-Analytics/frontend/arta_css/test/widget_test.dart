// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arta_css/main.dart';

void main() {
  testWidgets('LandingScreen displays "It works!"', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Verify that "It works!" text appears on the screen.
    expect(find.text('It works!'), findsOneWidget);
  });
}
