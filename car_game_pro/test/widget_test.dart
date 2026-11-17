import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:car_game_pro/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{'high_score': 12});
  });

  testWidgets('starts a game and moves between lanes with touch controls', (
    tester,
  ) async {
    await tester.pumpWidget(const CarGameApp());
    expect(find.text('SUPER CAR RACER'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('start-game')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
    expect(find.byKey(const ValueKey('player-lane-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('move-left')));
    await tester.pump();
    expect(find.byKey(const ValueKey('player-lane-0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('move-left')));
    await tester.pump();
    expect(find.byKey(const ValueKey('player-lane-0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('move-right')));
    await tester.pump();
    expect(find.byKey(const ValueKey('player-lane-1')), findsOneWidget);
  });

  testWidgets('keyboard controls move the player', (tester) async {
    await tester.pumpWidget(const CarGameApp());
    await tester.tap(find.byKey(const ValueKey('start-game')));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.byKey(const ValueKey('player-lane-2')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
    expect(find.byKey(const ValueKey('player-lane-1')), findsOneWidget);
  });

  testWidgets('game layout fits a small mobile screen', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CarGameApp());
    await tester.tap(find.byKey(const ValueKey('start-game')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('move-left')), findsOneWidget);
    expect(find.byKey(const ValueKey('move-right')), findsOneWidget);
  });
}
