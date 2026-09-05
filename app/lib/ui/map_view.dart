// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:stadtbau_sim/stadtbau_sim.dart';

import '../game/game_controller.dart';
import 'tile_style.dart';

/// The playing field: a square grid painted with a CustomPainter, accepting
/// drops from the palette, taps (brush placement / inspection) and
/// long-presses (clear).
class MapView extends StatefulWidget {
  const MapView({super.key, required this.controller});

  final GameController controller;

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final _key = GlobalKey();

  GameController get c => widget.controller;

  int? _cellAt(Offset global, Size size) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(global);
    return _cellAtLocal(local, size);
  }

  int? _cellAtLocal(Offset local, Size size) {
    final cell = size.width / c.width;
    final x = (local.dx / cell).floor();
    final y = (local.dy / cell).floor();
    if (!c.sim.state.inBounds(x, y)) return null;
    return c.sim.state.index(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final size = Size(side, side);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: DragTarget<TileType>(
              onMove: (details) => c.setHover(_cellAt(details.offset, size)),
              onLeave: (_) => c.setHover(null),
              onAcceptWithDetails: (details) {
                final cell = _cellAt(details.offset, size);
                c.setHover(null);
                if (cell != null) {
                  c.place(cell % c.width, cell ~/ c.width, details.data);
                }
              },
              builder: (context, candidates, rejected) {
                return GestureDetector(
                  key: _key,
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    final cell = _cellAtLocal(d.localPosition, size);
                    if (cell == null) return;
                    final brush = c.brush;
                    if (brush != null) {
                      c.place(cell % c.width, cell ~/ c.width, brush);
                    } else {
                      c.select(cell);
                    }
                  },
                  onLongPressStart: (d) {
                    final cell = _cellAtLocal(d.localPosition, size);
                    if (cell != null) c.clear(cell % c.width, cell ~/ c.width);
                  },
                  child: ListenableBuilder(
                    listenable: c,
                    builder: (context, _) => CustomPaint(
                      size: size,
                      painter: _MapPainter(c, Theme.of(context)),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.c, this.theme);

  final GameController c;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final state = c.sim.state;
    final cell = size.width / c.width;
    final fill = Paint();
    final grid = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final iconSize = cell * 0.55;

    for (var y = 0; y < c.height; y++) {
      for (var x = 0; x < c.width; x++) {
        final i = state.index(x, y);
        final rect = Rect.fromLTWH(x * cell, y * cell, cell, cell);
        final style = TileStyle.of(state.tiles[i]);
        fill.color = style.color;
        canvas.drawRect(rect, fill);
        if (c.overlay != MapOverlay.none) {
          fill.color = overlayColor(c.overlayValue(i), highIsBad: c.overlayHighIsBad).withValues(alpha: 0.72);
          canvas.drawRect(rect, fill);
        }
        canvas.drawRect(rect, grid);
        if (cell >= 18) {
          _drawIcon(canvas, style, rect.center, iconSize, c.overlay == MapOverlay.none ? 1 : 0.55);
        }
      }
    }

    void outline(int cellIndex, Color color, double width) {
      final x = cellIndex % c.width;
      final y = cellIndex ~/ c.width;
      canvas.drawRect(
        Rect.fromLTWH(x * cell, y * cell, cell, cell).deflate(width / 2),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      );
    }

    final hover = c.hoverCell;
    if (hover != null) outline(hover, theme.colorScheme.primary, 3);
    final selected = c.selectedCell;
    if (selected != null) outline(selected, theme.colorScheme.onSurface, 2);
  }

  void _drawIcon(Canvas canvas, TileStyle style, Offset center, double size, double opacity) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(style.icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: style.icon.fontFamily,
          package: style.icon.fontPackage,
          color: style.iconColor.withValues(alpha: opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => true;
}
