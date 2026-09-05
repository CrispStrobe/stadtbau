// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

import '../fields.dart';
import '../geometry.dart';
import '../params.dart';
import '../world.dart';

/// Urban heat (docs/model/heat.md), after the InVEST Urban Cooling model.
///
/// Cooling capacity CC = 0.6·shade + 0.2·albedo + 0.2·ETI per land cover.
/// Green patches of at least 2 ha cool cells within the cooling distance;
/// the heat mitigation index is max(own CC, distance-weighted green CC).
/// Temperature excess ΔT = UHI_max · (1 − HM).
void computeHeat(WorldState w, SimParams p, Fields f) {
  final n = w.cellCount;
  final width = w.width;
  final hp = p.heat;

  final cc = f.coolingCapacity;
  final isGreen = Uint8List(n);
  for (var i = 0; i < n; i++) {
    final tp = p.tile(w.tiles[i]);
    cc[i] = hp.shadeWeight * tp.shade.value + hp.albedoWeight * tp.albedo.value + hp.etiWeight * tp.eti.value;
    isGreen[i] = tp.category.isGreen ? 1 : 0;
  }

  // Label connected green patches (8-neighbourhood) and count their size.
  final ds = DisjointSet(n);
  for (var i = 0; i < n; i++) {
    if (isGreen[i] == 0) continue;
    final x = i % width;
    final y = i ~/ width;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = x + dx;
        final ny = y + dy;
        if (!w.inBounds(nx, ny)) continue;
        final j = ny * width + nx;
        if (isGreen[j] == 1) ds.union(i, j);
      }
    }
  }
  final patchSize = Int32List(n);
  for (var i = 0; i < n; i++) {
    if (isGreen[i] == 1) patchSize[ds.find(i)]++;
  }

  final offsets = Offsets.radius(hp.coolingDistanceTiles);
  for (var i = 0; i < n; i++) {
    final x = i % width;
    final y = i ~/ width;
    var hm = cc[i];
    for (var k = 0; k < offsets.length; k++) {
      final nx = x + offsets.dx[k];
      final ny = y + offsets.dy[k];
      if (!w.inBounds(nx, ny)) continue;
      final j = ny * width + nx;
      if (isGreen[j] == 0) continue;
      if (patchSize[ds.find(j)] < hp.greenPatchMinHa) continue;
      final weight = 1 - offsets.dist[k] / (hp.coolingDistanceTiles + 1);
      hm = math.max(hm, cc[j] * weight);
    }
    f.heatDeltaC[i] = hp.uhiMaxC * (1 - clamp01(hm));
  }
}
