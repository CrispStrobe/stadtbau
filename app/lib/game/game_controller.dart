// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stadtbau_sim/stadtbau_sim.dart';

import 'save_store.dart';

/// Colour overlays the player can toggle on the map.
enum MapOverlay { none, noise, air, heat, green, retail, jobs, habitat, traffic, attractiveness }

/// UI-facing state around the simulation: brush, overlay, selection, clock.
class GameController extends ChangeNotifier {
  GameController({int size = 16, SaveStore? store})
      : sim = Simulation.sandbox(width: size, height: size),
        _store = store; // ignore: prefer_initializing_formals

  final SaveStore? _store;
  Timer? _saveTimer;

  Simulation sim;
  TileType? brush;
  MapOverlay overlay = MapOverlay.none;
  int? selectedCell;
  int? hoverCell;
  CommandError? lastError;

  /// 0 = paused, otherwise months per second.
  int speed = 0;
  Timer? _timer;

  static const speeds = [1, 3, 10];

  int get width => sim.state.width;
  int get height => sim.state.height;

  /// Restore the autosave, if any. Call once after construction.
  Future<void> restore() async {
    final saved = await _store?.load();
    if (saved == null) return;
    _stopTimer();
    sim = Simulation(state: saved);
    speed = 0;
    selectedCell = null;
    notifyListeners();
  }

  void _scheduleSave() {
    final store = _store;
    if (store == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () => store.save(sim));
  }

  void newGame(int size) {
    _stopTimer();
    _saveTimer?.cancel();
    _store?.clear();
    sim = Simulation.sandbox(width: size, height: size);
    brush = null;
    selectedCell = null;
    hoverCell = null;
    lastError = null;
    speed = 0;
    notifyListeners();
  }

  void setBrush(TileType? t) {
    brush = brush == t ? null : t;
    notifyListeners();
  }

  void setOverlay(MapOverlay o) {
    overlay = o;
    notifyListeners();
  }

  void select(int? cell) {
    selectedCell = cell;
    notifyListeners();
  }

  void setHover(int? cell) {
    if (hoverCell == cell) return;
    hoverCell = cell;
    notifyListeners();
  }

  bool place(int x, int y, TileType t) {
    final result = sim.apply(PlaceTile(x, y, t));
    lastError = result.error;
    selectedCell = sim.state.index(x, y);
    if (result.ok) _scheduleSave();
    notifyListeners();
    return result.ok;
  }

  bool clear(int x, int y) {
    final result = sim.apply(RemoveTile(x, y));
    lastError = result.error;
    if (result.ok) _scheduleSave();
    notifyListeners();
    return result.ok;
  }

  void step() {
    sim.apply(const AdvanceTick());
    _scheduleSave();
    notifyListeners();
  }

  void setSpeed(int monthsPerSecond) {
    speed = monthsPerSecond;
    _stopTimer();
    if (speed > 0) {
      _timer = Timer.periodic(Duration(milliseconds: 1000 ~/ speed), (_) => step());
    }
    notifyListeners();
  }

  void togglePlay() => setSpeed(speed == 0 ? speeds.first : 0);

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Value of the active overlay at [cell], normalised to 0–1 for colouring,
  /// together with the raw value for the legend.
  double overlayValue(int cell) {
    final f = sim.fields;
    switch (overlay) {
      case MapOverlay.none:
        return 0;
      case MapOverlay.noise:
        return ((f.noiseDb[cell] - 35) / 40).clamp(0, 1);
      case MapOverlay.air:
        return (1 - f.airIndex[cell] / 100).clamp(0, 1);
      case MapOverlay.heat:
        return (f.heatDeltaC[cell] / sim.params.heat.uhiMaxC).clamp(0, 1);
      case MapOverlay.green:
        return f.greenAccess[cell];
      case MapOverlay.retail:
        return f.retailAccess[cell];
      case MapOverlay.jobs:
        return f.jobAccess[cell];
      case MapOverlay.habitat:
        return f.habitatQuality[cell];
      case MapOverlay.traffic:
        return (f.traffic[cell] / 20000).clamp(0, 1);
      case MapOverlay.attractiveness:
        return f.attractiveness[cell];
    }
  }

  /// Whether high overlay values are "bad" (drawn warm) or "good" (drawn cool).
  bool get overlayHighIsBad => switch (overlay) {
        MapOverlay.noise || MapOverlay.air || MapOverlay.heat || MapOverlay.traffic => true,
        _ => false,
      };

  @override
  void dispose() {
    _stopTimer();
    _saveTimer?.cancel();
    super.dispose();
  }
}
