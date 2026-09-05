// SPDX-License-Identifier: AGPL-3.0-or-later
/// `flutter drive` host side of `integration_test/screenshots_test.dart`
/// (tasks T-402 / T-403).
///
/// `IntegrationTestWidgetsFlutterBinding.takeScreenshot` does not write files:
/// it ships the PNG bytes back to whatever drives the test. This adaptor is
/// that driver — it saves every screenshot under
/// `app/screenshots/<device>/<name>.png`, where `<device>` comes from the
/// `SCREENSHOT_DEVICE` environment variable so that one run per simulator or
/// emulator lands in its own directory.
///
/// ```sh
/// cd app
/// SCREENSHOT_DEVICE="iPhone 16 Pro Max" flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/screenshots_test.dart \
///   -d <device-id>
/// ```
library;

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Where the PNGs go, relative to `app/`.
const String _outputRoot = 'screenshots';

Future<void> main() async {
  final device = _slug(Platform.environment['SCREENSHOT_DEVICE'] ?? 'device');
  final directory = Directory('$_outputRoot/$device');
  await directory.create(recursive: true);
  stdout.writeln('screenshots -> ${directory.absolute.path}');

  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      if (bytes.isEmpty) {
        stderr.writeln('screenshot "$name" came back empty');
        return false;
      }
      final file = File('${directory.path}/${_slug(name)}.png');
      await file.writeAsBytes(bytes);
      stdout.writeln('screenshot ${file.path} (${bytes.length} bytes)');
      return true;
    },
  );
}

/// Device and screenshot names become path segments, so keep them boring:
/// `iPad Pro 13-inch (M4)` -> `iPad_Pro_13-inch_M4`.
String _slug(String value) =>
    value.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
