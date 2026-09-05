// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;

import '../fields.dart';
import '../geometry.dart';
import '../params.dart';
import '../world.dart';

/// Accessibility fields (docs/model/access.md).
///
/// Green access: best recreational green within 300 m (WHO, 3-30-300), plus a
/// variety bonus. Retail access: Huff gravity with λ = 2 within 700 m.
/// Job access: gravity kernel exp(−d / 2 km), normalised to a reference.
void computeAccess(WorldState w, SimParams p, Fields f) {
  final n = w.cellCount;
  final width = w.width;
  final ap = p.access;

  final greenOffsets = Offsets.radius(ap.greenRadiusTiles);
  final retailOffsets = Offsets.radius(ap.retailRadiusTiles);

  // Job access uses the whole map (kernel decays smoothly).
  final jobCells = <int>[];
  final jobCounts = <double>[];
  for (var i = 0; i < n; i++) {
    final jobs = p.tile(w.tiles[i]).jobsPerHa.value;
    if (jobs > 0) {
      jobCells.add(i);
      jobCounts.add(jobs);
    }
  }
  final decay = DecayTable(
    maxDist2: w.width * w.width + w.height * w.height,
    cellSizeM: p.cellSizeM,
    decayM: ap.jobDecayM,
  );

  for (var i = 0; i < n; i++) {
    final x = i % width;
    final y = i ~/ width;

    var bestGreen = 0.0;
    var greenCount = 0;
    for (var k = 0; k < greenOffsets.length; k++) {
      final nx = x + greenOffsets.dx[k];
      final ny = y + greenOffsets.dy[k];
      if (!w.inBounds(nx, ny)) continue;
      final gw = p.tile(w.tiles[ny * width + nx]).greenWeight.value;
      if (gw > 0) {
        greenCount++;
        if (gw > bestGreen) bestGreen = gw;
      }
    }
    final own = p.tile(w.tiles[i]).greenWeight.value;
    if (own > bestGreen) bestGreen = own;
    var green = bestGreen;
    if (greenCount >= ap.greenVarietyMinTiles) green += ap.greenVarietyBonus;
    f.greenAccess[i] = clamp01(green);

    var supply = 0.0;
    for (var k = 0; k < retailOffsets.length; k++) {
      final nx = x + retailOffsets.dx[k];
      final ny = y + retailOffsets.dy[k];
      if (!w.inBounds(nx, ny)) continue;
      final floor = p.tile(w.tiles[ny * width + nx]).retailFloorM2.value;
      if (floor <= 0) continue;
      supply += floor / math.pow(math.max(retailOffsets.dist[k], 0.5), ap.huffLambda);
    }
    final ownFloor = p.tile(w.tiles[i]).retailFloorM2.value;
    if (ownFloor > 0) supply += ownFloor / math.pow(0.5, ap.huffLambda);
    f.retailAccess[i] = clamp01(supply / ap.retailReferenceSupply);

    var jobs = 0.0;
    for (var k = 0; k < jobCells.length; k++) {
      final j = jobCells[k];
      final dx = (j % width) - x;
      final dy = (j ~/ width) - y;
      jobs += jobCounts[k] * decay[dx * dx + dy * dy];
    }
    f.jobAccess[i] = clamp01(jobs / ap.jobReferenceJobs);
  }
}
