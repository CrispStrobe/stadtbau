// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;

import '../fields.dart';
import '../geometry.dart';
import '../params.dart';
import '../tile_type.dart';
import '../world.dart';

/// Noise propagation (docs/model/noise.md).
///
/// Every emitting tile is a point/area source with −20 dB per decade of
/// distance from the tile boundary (ISO 9613-2 geometric divergence). Roads
/// are treated as 100 m segments the way CNOSSOS-EU splits a line into point
/// sources; their energetic sum reproduces the 3 dB per doubling of a line.
/// Road emission scales with traffic (10·log10(Q/Q_ref), RLS-19). Foliage and
/// building rows on the straight path attenuate further. Contributions are
/// summed energetically over a rural background.
void computeNoise(WorldState w, SimParams p, Fields f) {
  final n = w.cellCount;
  final width = w.width;
  final np = p.noise;
  final offsets = Offsets.radius(np.radiusTiles);
  final energy = List<double>.filled(n, math.pow(10, np.backgroundDb / 10).toDouble());

  double emissionOf(int i) {
    final t = w.tiles[i];
    final base = p.tile(t).noiseEmissionDb.value;
    if (base <= 0) return 0;
    if (t == TileType.road) {
      final q = math.max(f.traffic[i], 1.0);
      return base + 10 * _log10(q / np.trafficReferenceVehiclesPerDay);
    }
    return base;
  }

  double pathAttenuation(int sx, int sy, int rx, int ry) {
    var att = 0.0;
    for (final c in cellsBetween(sx, sy, rx, ry, width)) {
      final cat = p.tile(w.tiles[c]).category;
      final t = w.tiles[c];
      if (t == TileType.forest || t == TileType.park) {
        att += np.foliageAttenuationDbPerTile;
      } else if (cat == TileCategory.work || t == TileType.housingHigh) {
        att += np.buildingScreeningDbPerTile;
      }
      if (att >= np.maxPathAttenuationDb) return np.maxPathAttenuationDb;
    }
    return att;
  }

  for (var s = 0; s < n; s++) {
    final e = emissionOf(s);
    if (e <= 0) continue;
    final sx = s % width;
    final sy = s ~/ width;
    energy[s] += math.pow(10, e / 10).toDouble();
    for (var k = 0; k < offsets.length; k++) {
      final rx = sx + offsets.dx[k];
      final ry = sy + offsets.dy[k];
      if (!w.inBounds(rx, ry)) continue;
      final dM = offsets.dist[k] * p.cellSizeM;
      var level = e -
          np.areaDecayDbPerDecade *
              _log10(math.max(dM, np.areaReferenceDistanceM) / np.areaReferenceDistanceM);
      level -= pathAttenuation(sx, sy, rx, ry);
      if (level <= np.backgroundDb - 15) continue;
      energy[ry * width + rx] += math.pow(10, level / 10).toDouble();
    }
  }
  for (var i = 0; i < n; i++) {
    f.noiseDb[i] = 10 * _log10(energy[i]);
  }
}

double _log10(double v) => math.log(v) / math.ln10;
