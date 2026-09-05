// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stadtbau_sim/stadtbau_sim.dart';

import '../game/game_controller.dart';
import '../l10n/generated/app_localizations.dart';

/// Ten gauges with a detail line each. Compact mode renders a horizontal strip.
class IndicatorPanel extends StatelessWidget {
  const IndicatorPanel({super.key, required this.controller, this.compact = false});

  final GameController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final ind = controller.sim.indicators;
        final locale = Localizations.localeOf(context).toString();
        final n0 = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 0);
        final n1 = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 1);
        final n2 = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 2);

        String detail(Indicator i) => switch (i) {
              Indicator.biodiversity => l10n.statsHabitat(n0.format(ind.habitatAreaEff), n2.format(ind.habitatConnectivity)),
              Indicator.air => l10n.statsPopulation(n0.format(ind.population)),
              Indicator.noise => l10n.statsNoise(l10n.dbValue(n0.format(ind.meanNoiseDb))),
              Indicator.housing => l10n.statsPopulation(n0.format(ind.population)),
              Indicator.economy => l10n.statsJobs(n0.format(ind.jobsFilled), n0.format(ind.jobsCapacity)),
              Indicator.shopping => l10n.statsPopulation(n0.format(ind.population)),
              Indicator.recreation => l10n.statsHeat(l10n.degreesValue(n1.format(ind.meanHeatDeltaC))),
              Indicator.commuting => l10n.statsCommute(
                  l10n.kmValue(n1.format(ind.meanCommuteKm)), l10n.percentValue(n0.format(ind.carShare * 100))),
              Indicator.climate => l10n.tonsPerYear(n0.format(ind.co2TonsPerYear)),
              Indicator.budget => l10n.statsBudgetDelta(l10n.kEur(n0.format(ind.budgetDeltaKEur))),
            };

        final tiles = [
          for (final i in Indicator.values)
            _Gauge(
              label: l10n.indicatorName(i.name),
              hint: l10n.indicatorHint(i.name),
              detail: detail(i),
              value: ind.score(i),
              compact: compact,
            ),
        ];

        if (compact) {
          return SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: tiles,
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Text(l10n.indicatorsTitle, style: Theme.of(context).textTheme.titleMedium),
            ...tiles,
          ],
        );
      },
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.label,
    required this.hint,
    required this.detail,
    required this.value,
    required this.compact,
  });

  final String label;
  final String hint;
  final String detail;
  final double value;
  final bool compact;

  Color _color(BuildContext context) {
    final v = value.clamp(0, 100) / 100;
    return Color.lerp(const Color(0xFFD95F0E), const Color(0xFF2C7FB8), v)!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rounded = value.clamp(0, 100).round();
    if (compact) {
      return Tooltip(
        message: '$hint\n$detail',
        child: Container(
          width: 96,
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
              Text('$rounded', style: theme.textTheme.titleMedium?.copyWith(color: _color(context))),
            ],
          ),
        ),
      );
    }
    return Tooltip(
      message: hint,
      waitDuration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
                Text('$rounded', style: theme.textTheme.titleMedium?.copyWith(color: _color(context))),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value.clamp(0, 100) / 100,
                minHeight: 8,
                color: _color(context),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            Text(detail, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
