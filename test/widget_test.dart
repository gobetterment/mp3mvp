// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mp3_player/main.dart';
import 'package:mp3_player/services/playlist_service.dart';

void main() {
  testWidgets('Main screen displays home tab', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final playlistService = PlaylistService(prefs);

    await tester.pumpWidget(MyApp(playlistService: playlistService));

    // Verify that the HOME screen is shown by default
    expect(find.text('HOME'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
