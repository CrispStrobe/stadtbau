// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:stadtbau_sim/stadtbau_sim.dart';

/// Colours and glyphs per tile type. Icons are Material Symbols (Apache-2.0).
class TileStyle {
  const TileStyle(this.color, this.icon, this.iconColor);

  final Color color;
  final IconData icon;
  final Color iconColor;

  static const _styles = <TileType, TileStyle>{
    TileType.meadow: TileStyle(Color(0xFFA5D6A7), Icons.grass, Color(0xFF2E7D32)),
    TileType.cropland: TileStyle(Color(0xFFE6CE8A), Icons.agriculture, Color(0xFF795548)),
    TileType.forest: TileStyle(Color(0xFF388E3C), Icons.forest, Color(0xFF1B5E20)),
    TileType.water: TileStyle(Color(0xFF64B5F6), Icons.water, Color(0xFF0D47A1)),
    TileType.park: TileStyle(Color(0xFF81C784), Icons.park, Color(0xFF1B5E20)),
    TileType.housingLow: TileStyle(Color(0xFFFFE0B2), Icons.house, Color(0xFFE65100)),
    TileType.housingHigh: TileStyle(Color(0xFFFFAB91), Icons.apartment, Color(0xFFBF360C)),
    TileType.commercial: TileStyle(Color(0xFFB39DDB), Icons.storefront, Color(0xFF4527A0)),
    TileType.industry: TileStyle(Color(0xFFB0BEC5), Icons.factory, Color(0xFF37474F)),
    TileType.road: TileStyle(Color(0xFF757575), Icons.add_road, Color(0xFFEEEEEE)),
  };

  static TileStyle of(TileType t) => _styles[t]!;
}

/// Colour-blind-safe sequential ramp (light yellow → teal → dark blue) for
/// "good" overlays and (light yellow → orange → dark red) for "bad" ones.
Color overlayColor(double v, {required bool highIsBad}) {
  final t = v.clamp(0.0, 1.0);
  final stops = highIsBad
      ? const [Color(0xFFFFF7BC), Color(0xFFFEC44F), Color(0xFFD95F0E), Color(0xFF7F2704)]
      : const [Color(0xFFFFFFCC), Color(0xFFA1DAB4), Color(0xFF2C7FB8), Color(0xFF253494)];
  final pos = t * (stops.length - 1);
  final i = pos.floor().clamp(0, stops.length - 2);
  return Color.lerp(stops[i], stops[i + 1], pos - i)!;
}
