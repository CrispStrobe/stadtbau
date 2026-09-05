// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stadtbau_sim/stadtbau_sim.dart';

import '../game/game_controller.dart';
import '../l10n/generated/app_localizations.dart';

/// Level goals with live progress and the remaining time.
class GoalsPanel extends StatelessWidget {
  const GoalsPanel({super.key, required this.controller, this.compact = false});

  final GameController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final level = controller.level;
        final progress = controller.progress;
        if (level == null || progress == null) return const SizedBox.shrink();
        final ind = controller.sim.indicators;
        final locale = Localizations.localeOf(context).toString();
        final n0 = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 0);
        final rows = [
          for (var i = 0; i < level.goals.length; i++)
            _GoalRow(
              text: goalText(l10n, level.goals[i], n0),
              current: n0.format(level.goals[i].current(ind)),
              met: progress.goalsMet[i],
              compact: compact,
            ),
        ];
        final left = progress.monthsLeft;
        final header = Row(
          children: [
            Expanded(child: Text(l10n.goalsTitle, style: theme.textTheme.titleMedium)),
            if (left != null) Text(l10n.monthsLeft(left), style: theme.textTheme.bodySmall),
          ],
        );
        if (compact) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Wrap(spacing: 8, runSpacing: 2, children: [header, ...rows]),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [header, ...rows]),
        );
      },
    );
  }

  static String goalText(AppLocalizations l10n, LevelGoal g, NumberFormat n0) {
    final ind = g.indicator;
    if (ind != null) return l10n.goalIndicator(l10n.indicatorName(ind.name), n0.format(g.min));
    return l10n.goalMetric(g.metric ?? '', n0.format(g.min));
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.text, required this.current, required this.met, required this.compact});

  final String text;
  final String current;
  final bool met;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = met ? const Color(0xFF2C7FB8) : theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Icon(met ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: color),
        const SizedBox(width: 4),
        if (compact)
          Text('$text ($current)', style: theme.textTheme.bodySmall)
        else ...[
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
          Text(current, style: theme.textTheme.bodySmall?.copyWith(color: color)),
        ],
      ],
    );
  }
}
