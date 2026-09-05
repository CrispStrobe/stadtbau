# Store screenshots — App Store and Play (T-402 / T-403)

Every store screenshot Hectopolis ships is a **real render of the real app**,
produced by a scripted tour that a simulator or emulator runs in CI. Nothing is
mocked up, nothing is hand-cropped, and no human has to touch a device:

| | |
|---|---|
| The tour | [`app/integration_test/screenshots_test.dart`](../../app/integration_test/screenshots_test.dart) |
| The host side | [`app/test_driver/integration_test.dart`](../../app/test_driver/integration_test.dart) |
| The workflow | [`.github/workflows/screenshots.yml`](../../.github/workflows/screenshots.yml) |
| Output | `app/screenshots/<device>/<locale>_<stop>.png`, uploaded as the `screenshots-ios` / `screenshots-android` artifacts |

## 1. What the tour captures

Six stops, run once in English and once in German (12 PNGs per device):

| Stop | Screen |
|---|---|
| `01_levels` | level select with the five built-in levels |
| `02_map` | the "quarter" level after a showcase city is built and 24 months are simulated |
| `03_noise_overlay` | the same city under the noise overlay |
| `04_air_overlay` | …under the air-quality overlay |
| `05_inspector` | an apartment block selected, with the per-cell field inspector |
| `06_goals` | 36 further months, the recreation overlay, goals panel showing progress |

The city is not tapped together tile by tile: after tapping the level card the
test reaches into `GameScreen.controller` and places tiles through the
`GameController` API, using the same plan that
`packages/stadtbau_sim/test/level_solutions_test.dart` solves "quarter" with —
so it is known to fit the money and tile budget. The clock is left at speed 0
throughout, so no tick timer can fire between the last pump and the capture.

State is made deterministic with `SharedPreferences.setMockInitialValues`
(no autosave, no stars, onboarding flag pre-set), and anything modal that shows
up anyway is closed generically by tapping the first `TextButton` in it, so a
new first-run overlay cannot silently ruin a run.

**Localisation.** `HectopolisApp` has no `locale` constructor argument, so the
tour switches language the way a player does: it taps the translate action in
the app bar until `Localizations.localeOf` reports the wanted language. Each
locale gets a fresh app instance (a per-locale widget key), so the German pass
starts from the level select with empty preferences, exactly like the English one.

## 2. Running it

### In CI (the normal path)

GitHub → Actions → **screenshots** → *Run workflow*. The one input is the
comma-separated list of iOS simulator names, default:

```
iPhone 16 Pro Max,iPad Pro 13-inch (M4)
```

Two independent jobs run (no `needs:` between them, so an Android failure never
costs the iOS artifact):

* **ios** — `macos-latest`: flutter-action 3.44.1,
  `flutter config --no-enable-swift-package-manager`, `flutter pub get`,
  `flutter gen-l10n`, resolve each requested simulator name to a UDID via
  `xcrun simctl list devices available -j`, boot it, then one `flutter drive`
  per device. The captured pixel sizes are printed into the job summary.
* **android** — `ubuntu-latest`: `reactivecircus/android-emulator-runner@v2`,
  API 34, `google_apis`/`x86_64`, `pixel_7` profile, software GPU, and the same
  `flutter drive`.

### On a Mac, by hand

```bash
export PATH="…/flutter/bin:$PATH"
flutter config --no-enable-swift-package-manager
flutter pub get
cd app && flutter gen-l10n

xcrun simctl list devices available | grep -E 'iPhone 16 Pro Max|iPad Pro 13'
xcrun simctl boot <udid>; xcrun simctl bootstatus <udid> -b
xcrun simctl uninstall <udid> com.crispstrobe.hectopolis   # never drive a stale build

SCREENSHOT_DEVICE="iPhone 16 Pro Max" flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshots_test.dart \
  -d <udid>
```

The PNGs appear under `app/screenshots/iPhone_16_Pro_Max/`. `SCREENSHOT_DEVICE`
only names the output directory; `-d` decides what actually runs.

## 3. Why `flutter drive`, and not `flutter test`

`IntegrationTestWidgetsFlutterBinding.takeScreenshot()` **writes no files**. It
hands the PNG bytes back to whatever drives the test, inside the test's report
data. Only the `flutter drive` adaptor —
`integrationDriver(onScreenshot: …)` in `test_driver/integration_test.dart` —
ever sees them; that callback is what writes `screenshots/<device>/<name>.png`.
`flutter test integration_test/screenshots_test.dart -d <udid>` runs the very
same tour correctly but drops the bytes on the floor.

Two known runner tradeoffs, worth remembering when a run looks wrong:

* **`flutter drive` can run the wrong thing.** It has been observed ignoring
  `--target` and, when a fresh build failed, silently connecting to the
  *already installed* binary and driving that — confidently wrong screenshots of
  old code. The workflow therefore `xcrun simctl uninstall`s the bundle id
  before every drive. Eyeball one capture for something that only the current
  build has.
* **`flutter test -d <udid>` targets reliably** but its on-device test binary has
  been seen rendering every text glyph as tofu (`?`) while Material icons render
  fine — a font-loading artifact of that binary, not an app bug. It is
  app-dependent and did not reproduce everywhere.

### Fallback: raw framebuffer captures

If the driver path ever breaks, the proven fallback is to hold each screen from
inside the test and grab the native framebuffer from outside:

```bash
xcrun simctl io <udid> screenshot out.png     # iOS simulator
adb exec-out screencap -p > out.png           # Android emulator
```

`simctl io` talks to the simulator's framebuffer directly and needs no macOS
Screen Recording grant (the host's own `screencapture` does, and an agent cannot
grant itself one). To synchronise it, `debugPrint('SHOT_MARKER <name>')` just
before each stop, run the test with `flutter test … -d <udid>` piped to a log,
and have a `tail -f` watcher grep for the marker and shoot during the hold
window. There is **no** tap injection from outside — `simctl` has no
`tap`/`sendevent`, and AppleScript cannot see inside the simulated screen — so
the navigation always has to come from the integration test either way.

## 4. Sizes the stores require

**Apple.** Since 2024 only two sizes are mandatory for a universal app; every
other size is derived by Apple from these.

| Set | Device to capture | Pixels | ASC `screenshotDisplayType` |
|---|---|---|---|
| 6.9" iPhone | iPhone 16 Pro Max (or 17 Pro Max) | **1320 × 2868** portrait | `APP_IPHONE_67` |
| 13" iPad | iPad Pro 13-inch (M4) | **2064 × 2752** portrait | `APP_IPAD_PRO_3GEN_129` |

Simulator screenshots of those devices come out at exactly those pixel sizes,
unscaled — so if `sips -g pixelWidth -g pixelHeight` reports anything else, the
wrong device was captured; do not rescale. Apple's enum names still carry the
old marketing sizes (`…_67`, `…_129`); that is expected, not a mismatch. 3–10
images per set, PNG or JPEG, no alpha channel, no device frame required.

**Google Play.** Phone screenshots: 2–8 images, PNG or JPEG, 16:9 or 9:16, each
edge between 320 px and 3840 px, the long edge at most twice the short one — the
Pixel 7 emulator's 1080 × 2400 fits. Tablet screenshots (7" and 10") are needed
if the app is offered on tablets, up to 8 each. Also required, and *not*
produced by this pipeline: the 512 × 512 app icon and the 1024 × 500 feature
graphic (see [`icon.md`](icon.md) and [`android.md`](android.md)).

Both stores require screenshots to show the actual app — which is the entire
point of driving the real binary rather than drawing marketing art.

## 5. Uploading to App Store Connect

Screenshots are the one genuinely multi-step upload in the ASC API: reserve →
PUT the bytes to a presigned URL → commit with a checksum → poll. Per locale and
per size class, using `tools/asc/client.py` (or any HTTP client with the same
JWT):

1. **`POST /v1/appScreenshotSets`** — create the set, related to the
   `appStoreVersionLocalizations` id of the locale, with
   `attributes.screenshotDisplayType` = `APP_IPHONE_67` or
   `APP_IPAD_PRO_3GEN_129`. Posting a deliberately bogus display type first is
   the quickest way to make the 409 list every valid enum value.
2. **`POST /v1/appScreenshots`** — one per image, with `fileName` and `fileSize`
   and the set as its relationship. The response carries
   `attributes.uploadOperations` — a presigned `url`, `method`, `requestHeaders`
   and, for large files, an `offset`/`length` per chunk.
3. **PUT the raw bytes** to each `uploadOperations[].url` with exactly the
   headers Apple returned. `urllib.request` works; `curl -X PUT --data-binary
   @file -H '<the one header>'` is the proven fallback if it breaks mid-stream.
4. **`PATCH /v1/appScreenshots/<id>`** with
   `{"uploaded": true, "sourceFileChecksum": "<md5 hex of the file>"}` to commit.
5. **`GET /v1/appScreenshots/<id>`** until `attributes.assetDeliveryState.state`
   is `COMPLETE` (`UPLOAD_COMPLETE` on older responses). A stuck or `FAILED`
   state means the checksum or the byte range was wrong — delete the resource
   and redo steps 2–4.

Order within a set is `POST /v1/appScreenshotSets/<id>/relationships/appScreenshots`
with the ids in the wanted order. Screenshots belong to a *version localization*,
so they must be uploaded once per store language (de-DE and en-US here) — which
is exactly why the tour runs in both locales.

## 6. Uploading to Play

There is no screenshot upload in the current `android-release.yml`. Until the
Play service account is wired up (see [`android.md`](android.md) §6), attach the
`screenshots-android` artifact by hand in Play Console → *Store presence* →
*Main store listing*, per language. With the service account, the Publishing API
route is `edits.insert` → `edits.images.upload` (`imageType`
`phoneScreenshots` / `sevenInchScreenshots` / `tenInchScreenshots`) →
`edits.commit`.

## 7. Prerequisites and known traps

* **The DEBUG banner must be off.** `flutter build ios --simulator` refuses
  `--release` and `--profile`, so simulator and emulator builds are always
  debug, and `MaterialApp` paints the red DEBUG ribbon over the corner of every
  screenshot unless `debugShowCheckedModeBanner: false` is set in
  `app/lib/main.dart`. The flag only ever has an effect in debug builds, so
  setting it changes nothing for released binaries. **Both jobs fail loudly in a
  preflight step if it is missing** — that is deliberate; a ribboned screenshot
  is worse than a red run.
* **`integration_test` is a dev dependency** of `app/`, from the Flutter SDK. It
  is also a plugin: the first build after adding it needs a `pod install` on iOS
  (`flutter drive` does that itself) and an unmodified `android/` Gradle setup.
* **Simulator boot lies about failing.** `xcrun simctl boot` can outlive its own
  timeout while succeeding; the workflow confirms with `xcrun simctl bootstatus
  <udid> -b` rather than trusting the exit code.
* **Android needs `convertFlutterSurfaceToImage()`** before `takeScreenshot()`,
  which the test calls unconditionally (it is a no-op on iOS). On a runner with
  no GPU this only works with a software renderer, hence
  `-gpu swiftshader_indirect` in the emulator options.
* **Never `pumpAndSettle` past a looping animation.** The tour holds each screen
  with a bounded `pumpAndSettle` plus ten fixed 50 ms pumps. If the app ever
  gains a permanently animating element, drop the `pumpAndSettle` in `_settle`
  and keep only the fixed pumps, or the test will hang instead of failing.
* **Disk.** Each simulator/emulator build is several hundred MB. On a constrained
  machine, `flutter clean` and
  `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*` between rounds.

## 8. What cannot be checked on the Linux dev box

`xcrun`, `simctl`, `sips`, `xcodebuild` and the iOS Simulator do not exist here,
and neither does an Android emulator with KVM. The test compiles and analyses
clean, and the workflow's shell and YAML are validated, but the first real proof
that the tour navigates correctly, that the captures are ribbon-free and that the
pixel sizes match the table in §4 is a run of the **screenshots** workflow.
Download the artifact and *look at the images* before uploading them anywhere.
