// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

import '../fields.dart';
import '../geometry.dart';
import '../params.dart';
import '../tile_type.dart';
import '../world.dart';

/// Air pollution (docs/model/air.md).
///
/// Every emitter spreads its emission E over its neighbourhood with the
/// kernel exp(−d / L) (isotropic near-field approximation of a Gaussian
/// plume, L = 300 m), normalised so that the kernel sums to one: a uniform
/// field of emitters yields a concentration equal to the emission rate, and
/// a single emitter dilutes with distance. Road emissions scale with
/// traffic. Vegetation in the receiver's 300 m neighbourhood removes a share
/// of the local concentration (deposition, magnitudes after Nowak et al.).
/// The index is 100 · exp(−C / scale).
void computeAir(WorldState w, SimParams p, Fields f) {
  final n = w.cellCount;
  final width = w.width;
  final ap = p.air;
  final offsets = Offsets.radius(ap.radiusTiles);
  final conc = f.airConcentration;
  for (var i = 0; i < n; i++) {
    conc[i] = 0;
  }
  // Kernel normalisation: self (1.0) plus all offsets within the radius.
  var kernelSum = 1.0;
  final kernel = Float64List(offsets.length);
  for (var k = 0; k < offsets.length; k++) {
    kernel[k] = math.exp(-offsets.dist[k] * p.cellSizeM / ap.decayLengthM);
    kernelSum += kernel[k];
  }

  for (var s = 0; s < n; s++) {
    final t = w.tiles[s];
    var e = p.tile(t).airEmission.value;
    if (e <= 0) continue;
    if (t == TileType.road) {
      e *= f.traffic[s] / ap.trafficReferenceVehiclesPerDay;
    }
    e /= kernelSum;
    conc[s] += e;
    final sx = s % width;
    final sy = s ~/ width;
    for (var k = 0; k < offsets.length; k++) {
      final rx = sx + offsets.dx[k];
      final ry = sy + offsets.dy[k];
      if (!w.inBounds(rx, ry)) continue;
      conc[ry * width + rx] += e * kernel[k];
    }
  }

  // Local deposition: mean sink coefficient in the neighbourhood.
  final sinkOffsets = Offsets.radius(ap.sinkRadiusTiles);
  for (var i = 0; i < n; i++) {
    final x = i % width;
    final y = i ~/ width;
    var sink = p.tile(w.tiles[i]).airSink.value;
    var count = 1;
    for (var k = 0; k < sinkOffsets.length; k++) {
      final nx = x + sinkOffsets.dx[k];
      final ny = y + sinkOffsets.dy[k];
      if (!w.inBounds(nx, ny)) continue;
      sink += p.tile(w.tiles[ny * width + nx]).airSink.value;
      count++;
    }
    final factor = 1 - sink / count;
    conc[i] *= factor;
    f.airIndex[i] = 100 * math.exp(-conc[i] / ap.indexScale);
  }
}
