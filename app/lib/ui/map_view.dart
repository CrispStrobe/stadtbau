// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stadtbau_sim/stadtbau_sim.dart';

import '../game/game_controller.dart';
import '../l10n/generated/app_localizations.dart';
import 'tile_style.dart';

/// Zoom and pan state of the map (task T-202).
///
/// Owned by the widget layer, not by [GameController], so that the controller
/// stays free of Flutter widget imports. The map is a square whose unscaled
/// size equals the viewport, so scale 1 fits the whole map and is the minimum;
/// the translation is clamped so that the map always covers the viewport.
class MapViewController {
  static const double minScale = 1;
  static const double maxScale = 4;
  static const double _step = 1.5;

  final TransformationController transformation = TransformationController();

  /// Side length of the square viewport, written by [MapView] on every layout.
  double viewportSide = 0;

  /// The current uniform scale factor.
  double get scale => transformation.value.getMaxScaleOnAxis();

  Offset get _translation {
    final t = transformation.value.getTranslation();
    return Offset(t.x, t.y);
  }

  void zoomIn() => zoomBy(_step);

  void zoomOut() => zoomBy(1 / _step);

  /// Multiply the current scale by [factor], keeping the viewport centre.
  void zoomBy(double factor) => zoomTo(scale * factor);

  /// Scale to [target] (clamped) around the centre of the viewport.
  void zoomTo(double target) {
    final side = viewportSide;
    if (side <= 0) return;
    final next = target.clamp(minScale, maxScale);
    final old = scale;
    final t = _translation;
    final focus = Offset(side / 2, side / 2);
    // Scene point currently under the focus stays under the focus.
    final sx = (focus.dx - t.dx) / old;
    final sy = (focus.dy - t.dy) / old;
    _apply(next, Offset(focus.dx - next * sx, focus.dy - next * sy));
  }

  /// Back to "whole map visible".
  void reset() {
    transformation.value = Matrix4.identity();
  }

  /// Pan so that [rect] (in scene/map coordinates) is inside the viewport.
  /// Used to follow the keyboard cursor while zoomed in.
  void revealScene(Rect rect) {
    final side = viewportSide;
    if (side <= 0) return;
    final s = scale;
    final t = _translation;
    double fit(double value, double lo, double hi) {
      var v = value;
      if (s * lo + v < 0) v = -s * lo;
      if (s * hi + v > side) v = side - s * hi;
      return v;
    }

    _apply(s, Offset(fit(t.dx, rect.left, rect.right), fit(t.dy, rect.top, rect.bottom)));
  }

  /// Write scale and translation, clamping the translation so that the map
  /// cannot be dragged (partly) out of the viewport.
  void _apply(double scale, Offset translation) {
    final side = viewportSide;
    final limit = side * (1 - scale); // <= 0
    final tx = translation.dx.clamp(limit, 0.0);
    final ty = translation.dy.clamp(limit, 0.0);
    transformation.value = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, tx)
      ..setEntry(1, 3, ty);
  }

  void dispose() => transformation.dispose();
}

/// The playing field: a square grid painted with a CustomPainter inside an
/// [InteractiveViewer] (pinch / wheel zoom, drag pan), accepting drops from the
/// palette, taps (brush placement / inspection), long-presses (clear) and
/// keyboard input (task T-203).
class MapView extends StatefulWidget {
  const MapView({super.key, required this.controller, this.mapController});

  final GameController controller;

  /// Zoom/pan state; created internally when not supplied.
  final MapViewController? mapController;

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final _viewportKey = GlobalKey();
  final _focus = FocusNode(debugLabel: 'map');
  MapViewController? _own;

  GameController get c => widget.controller;

  MapViewController get m => widget.mapController ?? (_own ??= MapViewController());

  /// Physical keyboards are the norm on desktop and web, so grab focus there;
  /// on touch platforms focus follows the first tap instead.
  static bool get _autofocus =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;

  @override
  void dispose() {
    _focus.dispose();
    _own?.dispose();
    super.dispose();
  }

  /// Global pointer position -> cell index, through the zoom/pan transform.
  int? _cellAtGlobal(Offset global, Size size) {
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return _cellAtLocal(m.transformation.toScene(box.globalToLocal(global)), size);
  }

  /// Position in map (scene) coordinates -> cell index.
  int? _cellAtLocal(Offset local, Size size) {
    final cell = size.width / c.width;
    final x = (local.dx / cell).floor();
    final y = (local.dy / cell).floor();
    if (!c.sim.state.inBounds(x, y)) return null;
    return c.sim.state.index(x, y);
  }

  void _follow(Size size) {
    final cursor = c.cursorCell;
    if (cursor == null) return;
    final cell = size.width / c.width;
    m.revealScene(Rect.fromLTWH((cursor % c.width) * cell, (cursor ~/ c.width) * cell, cell, cell));
  }

  KeyEventResult _onKey(KeyEvent event, Size size) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final delta = _arrows[key];
    if (delta != null) {
      c.moveCursor(delta.dx.round(), delta.dy.round());
      _follow(size);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      c.activateCursor();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace) {
      c.clearCursor();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      c.clearBrush();
      return KeyEventResult.handled;
    }
    final digit = _digits[key];
    if (digit != null) {
      c.selectBrushByIndex(digit);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static final _arrows = <LogicalKeyboardKey, Offset>{
    LogicalKeyboardKey.arrowLeft: const Offset(-1, 0),
    LogicalKeyboardKey.arrowRight: const Offset(1, 0),
    LogicalKeyboardKey.arrowUp: const Offset(0, -1),
    LogicalKeyboardKey.arrowDown: const Offset(0, 1),
  };

  /// 1–9 select the first nine allowed tiles, 0 the tenth.
  static final _digits = <LogicalKeyboardKey, int>{
    LogicalKeyboardKey.digit1: 0,
    LogicalKeyboardKey.digit2: 1,
    LogicalKeyboardKey.digit3: 2,
    LogicalKeyboardKey.digit4: 3,
    LogicalKeyboardKey.digit5: 4,
    LogicalKeyboardKey.digit6: 5,
    LogicalKeyboardKey.digit7: 6,
    LogicalKeyboardKey.digit8: 7,
    LogicalKeyboardKey.digit9: 8,
    LogicalKeyboardKey.digit0: 9,
    LogicalKeyboardKey.numpad1: 0,
    LogicalKeyboardKey.numpad2: 1,
    LogicalKeyboardKey.numpad3: 2,
    LogicalKeyboardKey.numpad4: 3,
    LogicalKeyboardKey.numpad5: 4,
    LogicalKeyboardKey.numpad6: 5,
    LogicalKeyboardKey.numpad7: 6,
    LogicalKeyboardKey.numpad8: 7,
    LogicalKeyboardKey.numpad9: 8,
    LogicalKeyboardKey.numpad0: 9,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final size = Size(side, side);
        m.viewportSide = side;
        return Center(
          child: SizedBox(
            key: _viewportKey,
            width: side,
            height: side,
            child: Focus(
              focusNode: _focus,
              autofocus: _autofocus,
              onKeyEvent: (node, event) => _onKey(event, size),
              child: DragTarget<TileType>(
                onMove: (details) => c.setHover(_cellAtGlobal(details.offset, size)),
                onLeave: (_) => c.setHover(null),
                onAcceptWithDetails: (details) {
                  final cell = _cellAtGlobal(details.offset, size);
                  c.setHover(null);
                  if (cell != null) {
                    c.place(cell % c.width, cell ~/ c.width, details.data);
                  }
                },
                builder: (context, candidates, rejected) {
                  return InteractiveViewer(
                    transformationController: m.transformation,
                    minScale: MapViewController.minScale,
                    maxScale: MapViewController.maxScale,
                    boundaryMargin: EdgeInsets.zero,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // Inside the InteractiveViewer, so localPosition is
                      // already in map coordinates at any zoom level.
                      onTapUp: (d) {
                        _focus.requestFocus();
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
                        _focus.requestFocus();
                        final cell = _cellAtLocal(d.localPosition, size);
                        if (cell != null) c.clear(cell % c.width, cell ~/ c.width);
                      },
                      child: ListenableBuilder(
                        listenable: Listenable.merge([c, m.transformation]),
                        builder: (context, _) => Semantics(
                          label: l10n.keyboardHint,
                          child: CustomPaint(
                            size: size,
                            painter: _MapPainter(c, Theme.of(context), m.scale),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.c, this.theme, this.scale);

  final GameController c;
  final ThemeData theme;

  /// Zoom factor; the canvas is in unscaled map coordinates, so line widths
  /// and the "is the cell big enough for an icon" test have to account for it.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final state = c.sim.state;
    final cell = size.width / c.width;
    final hair = 1 / scale;
    final fill = Paint();
    final grid = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair;
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
        if (cell * scale >= 18) {
          _drawIcon(canvas, style, rect.center, iconSize, c.overlay == MapOverlay.none ? 1 : 0.55);
        }
      }
    }

    Rect cellRect(int cellIndex) =>
        Rect.fromLTWH((cellIndex % c.width) * cell, (cellIndex ~/ c.width) * cell, cell, cell);

    void outline(int cellIndex, Color color, double width) {
      canvas.drawRect(
        cellRect(cellIndex).deflate(width / 2),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      );
    }

    final hover = c.hoverCell;
    if (hover != null) outline(hover, theme.colorScheme.primary, 3 * hair);
    final selected = c.selectedCell;
    if (selected != null) outline(selected, theme.colorScheme.onSurface, 2 * hair);
    final cursor = c.cursorCell;
    if (cursor != null) {
      // Double outline, distinct from the single selection outline.
      final rect = cellRect(cursor);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * hair;
      canvas.drawRect(rect.deflate(hair), stroke..color = theme.colorScheme.onSurface);
      canvas.drawRect(rect.deflate(4 * hair), stroke..color = theme.colorScheme.surface);
    }
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
