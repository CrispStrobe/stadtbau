// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

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

  // Per-tile attenuation contribution, looked up by tile type.
  final attenuationOf = List<double>.filled(TileType.values.length, 0);
  for (final t in TileType.values) {
    final cat = p.tile(t).category;
    if (t == TileType.forest || t == TileType.park) {
      attenuationOf[t.index] = np.foliageAttenuationDbPerTile;
    } else if (cat == TileCategory.work || t == TileType.housingHigh) {
      attenuationOf[t.index] = np.buildingScreeningDbPerTile;
    }
  }

  double pathAttenuation(int sx, int sy, int k) {
    var att = 0.0;
    final path = offsets.pathOffsets[k];
    for (var i = 0; i < path.length; i += 2) {
      final c = (sy + path[i + 1]) * width + sx + path[i];
      att += attenuationOf[w.tiles[c].index];
      if (att >= np.maxPathAttenuationDb) return np.maxPathAttenuationDb;
    }
    return att;
  }

  // Free-field level per offset is the same for every source: precompute.
  final divergence = Float64List(offsets.length);
  for (var k = 0; k < offsets.length; k++) {
    final dM = offsets.dist[k] * p.cellSizeM;
    divergence[k] =
        np.areaDecayDbPerDecade * _log10(math.max(dM, np.areaReferenceDistanceM) / np.areaReferenceDistanceM);
  }
  final cutoff = np.backgroundDb - 15;

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
      var level = e - divergence[k];
      if (level <= cutoff) continue;
      level -= pathAttenuation(sx, sy, k);
      if (level <= cutoff) continue;
      energy[ry * width + rx] += math.pow(10, level / 10).toDouble();
    }
  }
  for (var i = 0; i < n; i++) {
    f.noiseDb[i] = 10 * _log10(energy[i]);
  }
}

/// One row of a per-cell breakdown: how much a tile type contributes.
class Contribution {
  const Contribution({required this.type, required this.count, required this.nearestTiles, required this.value});

  final TileType type;

  /// Number of source tiles of this type that reach the cell.
  final int count;

  /// Distance in tiles to the nearest of them.
  final double nearestTiles;

  /// Contribution in the field's unit (dB for noise, concentration for air).
  final double value;
}

/// Noise at [cell] broken down by source tile type (energetic sums), sorted
/// by level, for the tile inspector. Uses the same formulas as [computeNoise].
List<Contribution> explainNoise(WorldState w, SimParams p, Fields f, int cell) {
  final width = w.width;
  final np = p.noise;
  final offsets = Offsets.radius(np.radiusTiles);
  final rx = cell % width;
  final ry = cell ~/ width;
  final energy = <TileType, double>{};
  final count = <TileType, int>{};
  final nearest = <TileType, double>{};

  void add(TileType t, double level, double dist) {
    energy[t] = (energy[t] ?? 0) + math.pow(10, level / 10).toDouble();
    count[t] = (count[t] ?? 0) + 1;
    nearest[t] = math.min(nearest[t] ?? double.infinity, dist);
  }

  double emissionOf(int i) {
    final t = w.tiles[i];
    final base = p.tile(t).noiseEmissionDb.value;
    if (base <= 0) return 0;
    if (t == TileType.road) return base + 10 * _log10(math.max(f.traffic[i], 1.0) / np.trafficReferenceVehiclesPerDay);
    return base;
  }

  final own = emissionOf(cell);
  if (own > 0) add(w.tiles[cell], own, 0);
  for (var k = 0; k < offsets.length; k++) {
    // Source at the mirrored offset so that the path runs source → receiver.
    final sx = rx - offsets.dx[k];
    final sy = ry - offsets.dy[k];
    if (!w.inBounds(sx, sy)) continue;
    final s = sy * width + sx;
    final e = emissionOf(s);
    if (e <= 0) continue;
    final dM = offsets.dist[k] * p.cellSizeM;
    var level = e -
        np.areaDecayDbPerDecade * _log10(math.max(dM, np.areaReferenceDistanceM) / np.areaReferenceDistanceM);
    var att = 0.0;
    final path = offsets.pathOffsets[k];
    for (var i = 0; i < path.length; i += 2) {
      final c = (sy + path[i + 1]) * width + sx + path[i];
      final t = w.tiles[c];
      if (t == TileType.forest || t == TileType.park) {
        att += np.foliageAttenuationDbPerTile;
      } else if (p.tile(t).category == TileCategory.work || t == TileType.housingHigh) {
        att += np.buildingScreeningDbPerTile;
      }
    }
    level -= math.min(att, np.maxPathAttenuationDb);
    if (level <= np.backgroundDb - 15) continue;
    add(w.tiles[s], level, offsets.dist[k]);
  }
  final rows = [
    for (final t in energy.keys)
      Contribution(type: t, count: count[t]!, nearestTiles: nearest[t]!, value: 10 * _log10(energy[t]!)),
  ]..sort((a, b) => b.value.compareTo(a.value));
  return rows;
}

double _log10(double v) => math.log(v) / math.ln10;
