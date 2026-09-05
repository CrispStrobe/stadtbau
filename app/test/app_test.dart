// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stadtbau/game/game_controller.dart';
import 'package:stadtbau/game/save_store.dart';
import 'package:stadtbau/main.dart';
import 'package:stadtbau_sim/stadtbau_sim.dart';

void main() {
  testWidgets('app renders palette, map and indicators', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const StadtbauApp());
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byIcon(Icons.forest), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  test('autosave round trip restores the world', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SaveStore();
    final c = GameController(size: 8, store: store);
    c.place(2, 2, TileType.forest);
    c.step();
    await store.save(c.sim);
    final restored = GameController(size: 8, store: store);
    await restored.restore();
    expect(restored.sim.state.tileAt(2, 2), TileType.forest);
    expect(restored.sim.state.tick, 1);
    c.dispose();
    restored.dispose();
  });

  test('controller places tiles with the brush and advances time', () {
    final c = GameController(size: 8);
    c.setBrush(TileType.road);
    expect(c.place(1, 1, TileType.road), isTrue);
    expect(c.sim.state.tileAt(1, 1), TileType.road);
    c.step();
    expect(c.sim.state.tick, 1);
    c.dispose();
  });
}
