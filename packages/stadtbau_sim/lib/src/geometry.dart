// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

/// Precomputed neighbourhood offsets within a Euclidean radius (in tiles),
/// excluding the centre cell. Shared across fields for speed.
class Offsets {
  Offsets._(this.dx, this.dy, this.dist);

  final Int32List dx;
  final Int32List dy;

  /// Euclidean distance in tiles for each offset.
  final Float64List dist;

  int get length => dx.length;

  /// For offset k, the relative cells strictly between the centre and the
  /// offset on a Bresenham line, as interleaved (dx, dy) pairs. Computed once.
  late final List<Int32List> pathOffsets = _buildPaths();

  List<Int32List> _buildPaths() {
    final result = <Int32List>[];
    for (var k = 0; k < length; k++) {
      final cells = cellsBetween(0, 0, dx[k], dy[k], 1 << 16);
      final packed = Int32List(cells.length * 2);
      for (var i = 0; i < cells.length; i++) {
        // cellsBetween packs y * width + x with width 2^16 and negative x
        // wrapping; decode with the same width.
        final v = cells[i];
        final y = (v / (1 << 16)).round();
        final x = v - y * (1 << 16);
        packed[2 * i] = x;
        packed[2 * i + 1] = y;
      }
      result.add(packed);
    }
    return result;
  }

  static final Map<int, Offsets> _cache = {};

  static Offsets radius(int r) => _cache[r] ??= _build(r);

  static Offsets _build(int r) {
    final xs = <int>[];
    final ys = <int>[];
    final ds = <double>[];
    for (var y = -r; y <= r; y++) {
      for (var x = -r; x <= r; x++) {
        if (x == 0 && y == 0) continue;
        final d = math.sqrt((x * x + y * y).toDouble());
        if (d <= r + 1e-9) {
          xs.add(x);
          ys.add(y);
          ds.add(d);
        }
      }
    }
    return Offsets._(Int32List.fromList(xs), Int32List.fromList(ys), Float64List.fromList(ds));
  }
}

/// Cells strictly between two grid cells on a Bresenham line, as indices into
/// a row-major grid of [width]. Endpoints are excluded.
List<int> cellsBetween(int x0, int y0, int x1, int y1, int width) {
  final result = <int>[];
  final dx = (x1 - x0).abs();
  final dy = -(y1 - y0).abs();
  final sx = x0 < x1 ? 1 : -1;
  final sy = y0 < y1 ? 1 : -1;
  var err = dx + dy;
  var x = x0;
  var y = y0;
  while (true) {
    if (x == x1 && y == y1) break;
    final e2 = 2 * err;
    if (e2 >= dy) {
      err += dy;
      x += sx;
    }
    if (e2 <= dx) {
      err += dx;
      y += sy;
    }
    if (x == x1 && y == y1) break;
    result.add(y * width + x);
  }
  return result;
}

/// Union-find over cell indices, used for habitat and green patches.
class DisjointSet {
  DisjointSet(int n)
      : _parent = Int32List(n),
        _size = Int32List(n) {
    for (var i = 0; i < n; i++) {
      _parent[i] = i;
      _size[i] = 1;
    }
  }

  final Int32List _parent;
  final Int32List _size;

  int find(int i) {
    var root = i;
    while (_parent[root] != root) {
      root = _parent[root];
    }
    while (_parent[i] != root) {
      final next = _parent[i];
      _parent[i] = root;
      i = next;
    }
    return root;
  }

  void union(int a, int b) {
    var ra = find(a);
    var rb = find(b);
    if (ra == rb) return;
    if (_size[ra] < _size[rb]) {
      final t = ra;
      ra = rb;
      rb = t;
    }
    _parent[rb] = ra;
    _size[ra] += _size[rb];
  }
}

double clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// Lookup table of exp(−sqrt(d²) · cellSizeM / decayM) indexed by squared
/// tile distance, so that gravity kernels avoid exp() in inner loops.
class DecayTable {
  DecayTable({required int maxDist2, required double cellSizeM, required double decayM})
      : values = Float64List(maxDist2 + 1) {
    for (var d2 = 0; d2 <= maxDist2; d2++) {
      values[d2] = math.exp(-math.sqrt(d2.toDouble()) * cellSizeM / decayM);
    }
  }

  final Float64List values;

  double operator [](int d2) => values[d2];
}
