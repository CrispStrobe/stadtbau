// SPDX-License-Identifier: AGPL-3.0-or-later
// Mirrors data/params/tiles.json into a Dart constant so the pure-Dart sim
// package (and the web build) can load parameters without file I/O.
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
}
