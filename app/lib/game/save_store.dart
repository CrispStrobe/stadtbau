// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stadtbau_sim/stadtbau_sim.dart';

/// Persists the current game locally (shared_preferences: browser storage on
/// web, platform preferences elsewhere). One autosave slot for now.
class SaveStore {
  static const _key = 'stadtbau.autosave.v1';

  Future<void> save(Simulation sim) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(sim.state.toJson()));
  }

  Future<WorldState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return WorldState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
