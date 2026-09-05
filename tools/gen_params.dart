// SPDX-License-Identifier: AGPL-3.0-or-later
// Mirrors data/params/tiles.json and data/levels/*.json into Dart constants
// so the pure-Dart sim package (and the web build) can load them without
// file I/O.
// Usage: dart run tools/gen_params.dart   (from the repository root)
import 'dart:convert';
import 'dart:io';

void main() {
  final src = File('data/params/tiles.json');
  final out = File('packages/stadtbau_sim/lib/src/generated/default_params.dart');
  final raw = src.readAsStringSync();
  // Validate that it is JSON before embedding.
  jsonDecode(raw);
  if (raw.contains("'''")) {
    stderr.writeln('tiles.json must not contain triple quotes');
    exit(1);
  }
  final buffer = StringBuffer()
    ..writeln('// SPDX-License-Identifier: AGPL-3.0-or-later')
    ..writeln('// GENERATED FILE - do not edit. Source: data/params/tiles.json')
    ..writeln('// Regenerate with: dart run tools/gen_params.dart')
    ..writeln()
    ..writeln('/// Default simulation parameters as JSON (mirror of data/params/tiles.json).')
    ..writeln("const String defaultParamsJson = r'''")
    ..write(raw)
    ..writeln("''';");
  out.writeAsStringSync(buffer.toString());
  stdout.writeln('wrote ${out.path} (${raw.length} bytes)');

  final levelFiles = Directory('data/levels')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final levels = StringBuffer()
    ..writeln('// SPDX-License-Identifier: AGPL-3.0-or-later')
    ..writeln('// GENERATED FILE - do not edit. Source: data/levels/*.json')
    ..writeln('// Regenerate with: dart run tools/gen_params.dart')
    ..writeln()
    ..writeln('/// Built-in levels as JSON, in file order (mirror of data/levels/).')
    ..writeln('const List<String> defaultLevelsJson = [');
  for (final f in levelFiles) {
    final text = f.readAsStringSync();
    jsonDecode(text);
    if (text.contains("'''")) {
      stderr.writeln('${f.path} must not contain triple quotes');
      exit(1);
    }
    levels
      ..writeln("  r'''")
      ..write(text)
      ..writeln("''',");
  }
  levels.writeln('];');
  final levelsOut = File('packages/stadtbau_sim/lib/src/generated/default_levels.dart');
  levelsOut.writeAsStringSync(levels.toString());
  stdout.writeln('wrote ${levelsOut.path} (${levelFiles.length} levels)');
}
