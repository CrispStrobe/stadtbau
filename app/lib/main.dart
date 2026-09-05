// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'game/game_controller.dart';
import 'game/save_store.dart';
import 'l10n/generated/app_localizations.dart';
import 'ui/level_select_screen.dart';

void main() {
  runApp(const StadtbauApp());
}

class StadtbauApp extends StatefulWidget {
  const StadtbauApp({super.key});

  @override
  State<StadtbauApp> createState() => _StadtbauAppState();
}

class _StadtbauAppState extends State<StadtbauApp> {
  final SaveStore _store = SaveStore();
  late final GameController _controller = GameController(store: _store);
  Locale? _locale;

  void _toggleLocale() {
    setState(() {
      final current = _locale ?? WidgetsBinding.instance.platformDispatcher.locale;
      _locale = current.languageCode == 'de' ? const Locale('en') : const Locale('de');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2E7D32), useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: const Color(0xFF2E7D32), brightness: Brightness.dark, useMaterial3: true),
      home: LevelSelectScreen(controller: _controller, store: _store, onLocaleToggle: _toggleLocale),
    );
  }
}
