// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stadtbau_sim/stadtbau_sim.dart';

import '../game/game_controller.dart';
import '../l10n/generated/app_localizations.dart';
import 'goals_panel.dart';
import 'indicator_panel.dart';
import 'map_view.dart';
import 'palette.dart';
import 'tile_inspector.dart';
import 'tile_style.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller, required this.onLocaleToggle});

  final GameController controller;
  final VoidCallback onLocaleToggle;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameController get c => widget.controller;
  CommandError? _shownError;

  @override
  void initState() {
    super.initState();
    c.addListener(_onChanged);
  }

  @override
  void dispose() {
    c.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (c.endPending) {
      c.acknowledgeEnd();
      WidgetsBinding.instance.addPostFrameCallback((_) => _showEnd());
    }
    final err = c.lastError;
    if (err != null && err != _shownError) {
      _shownError = err;
      final l10n = AppLocalizations.of(context);
      final text = switch (err) {
        CommandError.outOfBounds => l10n.errorOutOfBounds,
        CommandError.sameTile => l10n.errorSameTile,
        CommandError.insufficientBudget => l10n.errorInsufficientBudget,
        CommandError.tileNotAllowed => l10n.errorTileNotAllowed,
        CommandError.tileExhausted => l10n.errorTileExhausted,
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
      c.lastError = null;
      _shownError = null;
    }
  }

  Future<void> _showEnd() async {
    final l10n = AppLocalizations.of(context);
    final level = c.level;
    final progress = c.progress;
    if (level == null || progress == null) return;
    final back = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(progress.allMet ? l10n.endTitleSuccess : l10n.endTitleTimeUp),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(i < progress.stars ? Icons.star : Icons.star_border, color: Colors.amber.shade700, size: 32),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.endGoalsMet(progress.metCount, progress.goalsMet.length)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.actionKeepPlaying)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.actionBackToLevels)),
        ],
      ),
    );
    if (back == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _newGame() async {
    final l10n = AppLocalizations.of(context);
    var size = c.width;
    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.newGameTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.newGameSize(size)),
              Slider(
                value: size.toDouble(),
                min: 8,
                max: 24,
                divisions: 4,
                label: '$size',
                onChanged: (v) => setState(() => size = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, size), child: Text(l10n.ok)),
          ],
        ),
      ),
    );
    if (result != null) c.startSandbox(result);
  }

  void _about() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aboutTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(l10n.aboutText), const SizedBox(height: 8), Text(l10n.aboutLicense)],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: l10n.actionBackToLevels,
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(c.level == null ? l10n.levelTitle('sandbox') : l10n.levelTitle(c.level!.id)),
            actions: [
              _Clock(controller: c),
              const SizedBox(width: 8),
              _Transport(controller: c),
              _OverlayMenu(controller: c),
              if (c.level == null)
                IconButton(tooltip: l10n.actionNewGame, icon: const Icon(Icons.restart_alt), onPressed: _newGame),
              IconButton(tooltip: l10n.actionLanguage, icon: const Icon(Icons.translate), onPressed: widget.onLocaleToggle),
              IconButton(tooltip: l10n.actionAbout, icon: const Icon(Icons.info_outline), onPressed: _about),
            ],
          ),
          body: wide ? _wide() : _narrow(),
        );
      },
    );
  }

  Widget _wide() => Row(
        children: [
          SizedBox(width: 260, child: Palette(controller: c)),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(child: Padding(padding: const EdgeInsets.all(8), child: MapView(controller: c))),
                _Legend(controller: c),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          SizedBox(
            width: 320,
            child: Column(
              children: [
                GoalsPanel(controller: c),
                if (c.level != null) const Divider(height: 1),
                Expanded(flex: 3, child: IndicatorPanel(controller: c)),
                const Divider(height: 1),
                Expanded(flex: 2, child: TileInspector(controller: c)),
              ],
            ),
          ),
        ],
      );

  Widget _narrow() => Column(
        children: [
          GoalsPanel(controller: c, compact: true),
          IndicatorPanel(controller: c, compact: true),
          Expanded(child: Padding(padding: const EdgeInsets.all(4), child: MapView(controller: c))),
          _Legend(controller: c),
          SizedBox(height: 140, child: TileInspector(controller: c)),
          Palette(controller: c, horizontal: true),
        ],
      );
}

class _Clock extends StatelessWidget {
  const _Clock({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final n0 = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 0);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.sim.state;
        final ind = controller.sim.indicators;
        final year = s.tick ~/ 12 + 1;
        final month = s.tick % 12 + 1;
        return Row(
          children: [
            Text(l10n.yearMonthLabel(year, month)),
            const SizedBox(width: 12),
            Tooltip(message: l10n.budgetLabel, child: Text(l10n.kEur(n0.format(s.budgetKEur)))),
            const SizedBox(width: 12),
            Tooltip(message: l10n.populationLabel, child: Text('${n0.format(ind.population)} 👥')),
          ],
        );
      },
    );
  }
}

class _Transport extends StatelessWidget {
  const _Transport({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Row(
        children: [
          IconButton(
            tooltip: controller.speed == 0 ? l10n.actionPlay : l10n.actionPause,
            icon: Icon(controller.speed == 0 ? Icons.play_arrow : Icons.pause),
            onPressed: controller.togglePlay,
          ),
          IconButton(tooltip: l10n.actionStep, icon: const Icon(Icons.skip_next), onPressed: controller.step),
          for (final s in GameController.speeds)
            IconButton(
              tooltip: l10n.actionSpeed(s),
              isSelected: controller.speed == s,
              icon: Text('$s×'),
              onPressed: () => controller.setSpeed(s),
            ),
        ],
      ),
    );
  }
}

class _OverlayMenu extends StatelessWidget {
  const _OverlayMenu({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => PopupMenuButton<MapOverlay>(
        tooltip: l10n.overlayLabel,
        icon: Icon(controller.overlay == MapOverlay.none ? Icons.layers_outlined : Icons.layers),
        initialValue: controller.overlay,
        onSelected: controller.setOverlay,
        itemBuilder: (context) => [
          for (final o in MapOverlay.values) PopupMenuItem(value: o, child: Text(l10n.overlayName(o.name))),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.overlay == MapOverlay.none) return const SizedBox(height: 4);
        final bad = controller.overlayHighIsBad;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Text('${l10n.overlayName(controller.overlay.name)} (${l10n.overlayUnit(controller.overlay.name)})'),
              const SizedBox(width: 12),
              Text(l10n.legendLow, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 4),
              Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [for (var i = 0; i <= 4; i++) overlayColor(i / 4, highIsBad: bad)]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(l10n.legendHigh, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}
