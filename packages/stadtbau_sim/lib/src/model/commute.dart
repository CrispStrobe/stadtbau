// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:collection';
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
/// commute out. Car trips enter the road network at the nearest main road of
/// origin and destination and are routed along the shortest road path
/// (breadth-first over 4-connected road cells). External trips leave through
/// the nearest road cell on the map border.
void computeCommute(WorldState w, SimParams p, Fields f) {
  final n = w.cellCount;
  final width = w.width;
  final cp = p.commute;
  final cellKm = p.cellSizeM / 1000.0;

  final network = _RoadNetwork(w, cp.roadSearchRadiusTiles);

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
    f.connected[i] = network.nearestRoad[i] >= 0 ? 1 : 0;
  }

  var totalCarKm = 0.0;

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
        network.assign(traffic, i, j, cars * 2);
      }
    }
    final external = cellWorkers - localWorkers;
    if (external > 0) {
      final cars = external * cp.externalCarShare;
      carTrips += cars;
      totalCarKm += cars * cp.externalCommuteKm * 2;
      network.assignExternal(traffic, i, cars * 2);
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
      network.assignExternal(traffic, jobCells[k], cars * 2);
    }
  }

  f.totalCarKmPerDay = totalCarKm;
  f.workers = workers;
  f.jobsCapacity = jobsCapacity;
  f.inCommuters = inCommuters;
  f.outCommuters = outCommuters;
}

/// Road cells as a 4-connected graph with all-pairs shortest paths (BFS from
/// every road cell). Sized for a few hundred road cells.
class _RoadNetwork {
  _RoadNetwork(this.w, int searchRadius)
      : n = w.cellCount,
        width = w.width,
        nearestRoad = Int32List(w.cellCount) {
    for (var i = 0; i < n; i++) {
      if (w.tiles[i] == TileType.road) {
        roadIndex[i] = roads.length;
        roads.add(i);
      }
    }
    final offsets = Offsets.radius(searchRadius);
    for (var i = 0; i < n; i++) {
      if (w.tiles[i] == TileType.road) {
        nearestRoad[i] = i;
        continue;
      }
      nearestRoad[i] = -1;
      final x = i % width;
      final y = i ~/ width;
      var best = double.infinity;
      for (var k = 0; k < offsets.length; k++) {
        final nx = x + offsets.dx[k];
        final ny = y + offsets.dy[k];
        if (!w.inBounds(nx, ny)) continue;
        final j = ny * width + nx;
        if (w.tiles[j] == TileType.road && offsets.dist[k] < best) {
          best = offsets.dist[k];
          nearestRoad[i] = j;
        }
      }
    }
    // BFS parents from every road cell (lazy, cached).
    _parents = List<Int32List?>.filled(roads.length, null);
    for (final r in roads) {
      final x = r % width;
      final y = r ~/ width;
      if (x == 0 || y == 0 || x == width - 1 || y == w.height - 1) exits.add(r);
    }
  }

  final WorldState w;
  final int n;
  final int width;
  final Int32List nearestRoad;
  final List<int> roads = [];
  final Map<int, int> roadIndex = {};
  final List<int> exits = [];
  late final List<Int32List?> _parents;

  /// BFS tree rooted at road cell [root]; parent[cell] = previous cell or -1.
  Int32List _tree(int root) {
    final ri = roadIndex[root]!;
    final cached = _parents[ri];
    if (cached != null) return cached;
    final parent = Int32List(n)..fillRange(0, n, -2); // -2 = unvisited
    parent[root] = -1;
    final queue = Queue<int>()..add(root);
    while (queue.isNotEmpty) {
      final c = queue.removeFirst();
      final x = c % width;
      final y = c ~/ width;
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = x + dx;
        final ny = y + dy;
        if (!w.inBounds(nx, ny)) continue;
        final j = ny * width + nx;
        if (w.tiles[j] != TileType.road || parent[j] != -2) continue;
        parent[j] = c;
        queue.add(j);
      }
    }
    _parents[ri] = parent;
    return parent;
  }

  /// Add [trips] to every road cell on the shortest road path between the
  /// nearest roads of [origin] and [dest]. Unreachable pairs load only the
  /// two access cells.
  void assign(Float64List traffic, int origin, int dest, double trips) {
    if (trips <= 0) return;
    final ro = nearestRoad[origin];
    final rd = nearestRoad[dest];
    if (ro < 0 && rd < 0) return;
    if (ro < 0 || rd < 0) {
      traffic[ro >= 0 ? ro : rd] += trips;
      return;
    }
    if (ro == rd) {
      traffic[ro] += trips;
      return;
    }
    final parent = _tree(ro);
    if (parent[rd] == -2) {
      traffic[ro] += trips;
      traffic[rd] += trips;
      return;
    }
    var c = rd;
    while (c != -1) {
      traffic[c] += trips;
      c = parent[c];
    }
  }

  /// Trips that leave or enter the map: routed to the nearest border road.
  void assignExternal(Float64List traffic, int cell, double trips) {
    if (trips <= 0) return;
    final r = nearestRoad[cell];
    if (r < 0) return;
    if (exits.isEmpty) {
      traffic[r] += trips;
      return;
    }
    final parent = _tree(r);
    var best = -1;
    var bestLen = 1 << 30;
    for (final e in exits) {
      if (parent[e] == -2) continue;
      var len = 0;
      var c = e;
      while (c != -1 && len < bestLen) {
        len++;
        c = parent[c];
      }
      if (len < bestLen) {
        bestLen = len;
        best = e;
      }
    }
    if (best < 0) {
      traffic[r] += trips;
      return;
    }
    var c = best;
    while (c != -1) {
      traffic[c] += trips;
      c = parent[c];
    }
  }
}
