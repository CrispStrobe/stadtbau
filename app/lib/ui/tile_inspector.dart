// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../game/game_controller.dart';
import '../l10n/generated/app_localizations.dart';
import 'tile_style.dart';

/// Per-cell values of every field for the selected cell.
class TileInspector extends StatelessWidget {
  const TileInspector({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final cell = controller.selectedCell;
        if (cell == null) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(l10n.inspectorEmpty, style: theme.textTheme.bodySmall),
          );
        }
        final sim = controller.sim;
        final f = sim.fields;
        final x = cell % sim.state.width;
        final y = cell ~/ sim.state.width;
        final type = sim.state.tiles[cell];
        final style = TileStyle.of(type);
        final locale = Localizations.localeOf(context).toString();
        final n0 = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 0);
        final n1 = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 1);
        final n2 = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 2);

        final rows = <(String, String)>[
          (l10n.fieldNoise, l10n.dbValue(n0.format(f.noiseDb[cell]))),
          (l10n.fieldAir, n0.format(f.airIndex[cell])),
          (l10n.fieldHeat, l10n.degreesValue(n1.format(f.heatDeltaC[cell]))),
          (l10n.fieldGreen, n2.format(f.greenAccess[cell])),
          (l10n.fieldRetail, n2.format(f.retailAccess[cell])),
          (l10n.fieldJobs, n2.format(f.jobAccess[cell])),
          (l10n.fieldHabitat, n2.format(f.habitatQuality[cell])),
          (l10n.fieldTraffic, l10n.vehiclesValue(n0.format(f.traffic[cell]))),
          (l10n.fieldAttractiveness, n2.format(f.attractiveness[cell])),
          (l10n.fieldResidents, n0.format(sim.state.population[cell])),
          (l10n.fieldCommute, l10n.kmValue(n1.format(f.meanCommuteKm[cell]))),
          (l10n.fieldCarShare, l10n.percentValue(n0.format(f.carShare[cell] * 100))),
          (l10n.fieldConnected, f.connected[cell] == 1 ? l10n.yes : l10n.no),
          (l10n.fieldAge, l10n.months(sim.state.tileAge[cell])),
        ];

        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Row(
              children: [
                Icon(style.icon, color: style.iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${l10n.inspectorTitle(x, y)} · ${l10n.tileName(type.id)}',
                      style: theme.textTheme.titleSmall),
                ),
                IconButton(
                  tooltip: l10n.actionClear,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => controller.clear(x, y),
                ),
              ],
            ),
            Text(l10n.tileDescription(type.id), style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
                    Text(value, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
