// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

import '../fields.dart';
import '../geometry.dart';
import '../params.dart';
import '../tile_type.dart';
import '../world.dart';

/// Commuting model (docs/model/commute.md).
///
/// Workers of every residential cell are distributed to job cells with a
/// gravity kernel exp(-d / jobDecayM). Jobs that residents cannot fill are
/// taken by in-commuters from outside the map; workers without local jobs
/// commute out. Car trips are assigned to the nearest main road of origin and
/// destination and to road cells on the straight line between them.
void computeCommute(WorldState w, SimParams p, Fields f) {
  final n = w.cellCount;
  final width = w.width;
  final cp = p.commute;
  final cellKm = p.cellSizeM / 1000.0;

  // Nearest road cell per cell (or -1) within the search radius.
  final nearestRoad = Int32List(n);
  final roadOffsets = Offsets.radius(cp.roadSearchRadiusTiles);
  for (var i = 0; i < n; i++) {
    if (w.tiles[i] == TileType.road) {
      nearestRoad[i] = i;
      continue;
    }
    nearestRoad[i] = -1;
    final x = i % width;
    final y = i ~/ width;
    var best = double.infinity;
    for (var k = 0; k < roadOffsets.length; k++) {
      final nx = x + roadOffsets.dx[k];
      final ny = y + roadOffsets.dy[k];
      if (!w.inBounds(nx, ny)) continue;
      final j = ny * width + nx;
      if (w.tiles[j] == TileType.road && roadOffsets.dist[k] < best) {
        best = roadOffsets.dist[k];
        nearestRoad[i] = j;
      }
    }
  }

  // Job cells.
  final jobCells = <int>[];
  final jobCounts = <double>[];
  var jobsCapacity = 0.0;
  for (var i = 0; i < n; i++) {
    final jobs = p.tile(w.tiles[i]).jobsPerHa.value;
    if (jobs > 0) {
      jobCells.add(i);
      jobCounts.add(jobs);
      jobsCapacity += jobs;
    }
  }

  var workers = 0.0;
  for (var i = 0; i < n; i++) {
    workers += w.population[i] * cp.labourParticipation;
  }

  final localFraction = workers > 0 ? math.min(1.0, jobsCapacity / workers) : 0.0;
  final inCommuters = math.max(0.0, jobsCapacity - workers);
  final outCommuters = workers * (1 - localFraction);

  final traffic = f.traffic;
  for (var i = 0; i < n; i++) {
    traffic[i] = w.tiles[i] == TileType.road ? p.noise.baselineThroughTraffic : 0.0;
    f.meanCommuteKm[i] = 0;
    f.carShare[i] = 0;
    f.connected[i] = nearestRoad[i] >= 0 ? 1 : 0;
  }

  var totalCarKm = 0.0;

  void assignTrips(int origin, int dest, double trips) {
    if (trips <= 0) return;
    final ro = origin >= 0 ? nearestRoad[origin] : -1;
    final rd = dest >= 0 ? nearestRoad[dest] : -1;
    if (ro >= 0) traffic[ro] += trips;
    if (rd >= 0 && rd != ro) traffic[rd] += trips;
    if (ro >= 0 && rd >= 0 && ro != rd) {
      for (final c in cellsBetween(ro % width, ro ~/ width, rd % width, rd ~/ width, width)) {
        if (w.tiles[c] == TileType.road) traffic[c] += trips;
      }
    }
  }

  final weights = Float64List(jobCells.length);
  for (var i = 0; i < n; i++) {
    final pop = w.population[i];
    if (pop <= 0) continue;
    final cellWorkers = pop * cp.labourParticipation;
    final x = i % width;
    final y = i ~/ width;
    var wsum = 0.0;
    for (var k = 0; k < jobCells.length; k++) {
      final j = jobCells[k];
      final dx = (j % width) - x;
      final dy = (j ~/ width) - y;
      final dM = math.sqrt((dx * dx + dy * dy).toDouble()) * p.cellSizeM;
      final wk = jobCounts[k] * math.exp(-dM / p.access.jobDecayM);
      weights[k] = wk;
      wsum += wk;
    }
    var meanKm = 0.0;
    var carTrips = 0.0;
    final localWorkers = wsum > 0 ? cellWorkers * localFraction : 0.0;
    if (localWorkers > 0) {
      for (var k = 0; k < jobCells.length; k++) {
        if (weights[k] <= 0) continue;
        final share = weights[k] / wsum;
        final j = jobCells[k];
        final dx = (j % width) - x;
        final dy = (j ~/ width) - y;
        final km = math.max(0.5, math.sqrt((dx * dx + dy * dy).toDouble()) * cellKm);
        final commuters = localWorkers * share;
        meanKm += share * km;
        final cars = commuters * cp.carShare(km);
        carTrips += cars;
        totalCarKm += cars * km * 2;
        assignTrips(i, j, cars * 2);
      }
    }
    final external = cellWorkers - localWorkers;
    if (external > 0) {
      final cars = external * cp.externalCarShare;
      carTrips += cars;
      totalCarKm += cars * cp.externalCommuteKm * 2;
      assignTrips(i, -1, cars * 2);
    }
    final fLocal = cellWorkers > 0 ? localWorkers / cellWorkers : 0.0;
    f.meanCommuteKm[i] = fLocal * meanKm + (1 - fLocal) * cp.externalCommuteKm;
    f.carShare[i] = cellWorkers > 0 ? carTrips / cellWorkers : 0.0;
  }

  // In-commuters from outside fill the remaining jobs and arrive by road.
  if (inCommuters > 0 && jobsCapacity > 0) {
    for (var k = 0; k < jobCells.length; k++) {
      final share = jobCounts[k] / jobsCapacity;
      final cars = inCommuters * share * cp.externalCarShare;
      totalCarKm += cars * cp.externalCommuteKm * 2;
      assignTrips(-1, jobCells[k], cars * 2);
    }
  }

  f.totalCarKmPerDay = totalCarKm;
  f.workers = workers;
  f.jobsCapacity = jobsCapacity;
  f.inCommuters = inCommuters;
  f.outCommuters = outCommuters;
}
