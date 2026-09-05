# Store screenshots — App Store and Play (T-402 / T-403)

Every store screenshot Hectopolis ships is a **real render of the real app**,
produced by a scripted tour that a simulator or emulator runs in CI. Nothing is
mocked up, nothing is hand-cropped, and no human has to touch a device:

| | |
|---|---|
| The tour | [`app/integration_test/screenshots_test.dart`](../../app/integration_test/screenshots_test.dart) |
| The host side | [`app/test_driver/integration_test.dart`](../../app/test_driver/integration_test.dart) |
| The workflow | [`.github/workflows/screenshots.yml`](../../.github/workflows/screenshots.yml) |
| The ASC upload | [`tools/asc/upload_screenshots.py`](../../tools/asc/upload_screenshots.py) |
| Output | `app/screenshots/<device>/<locale>_<stop>.png` — uploaded as the `screenshots-ios` / `screenshots-android` artifacts, force-pushed to the orphan branch [`screenshots`](../../../../tree/screenshots), and (iOS) pushed into the editable App Store version |

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
iPhone 17 Pro Max,iPad Pro 13-inch (M5)
```

Four jobs run. The two capture jobs are independent of each other (no `needs:`
between them, so an Android failure never costs the iOS artifact); the two
delivery jobs hang off whatever they produced:

* **ios** — `macos-latest`: flutter-action 3.44.1,
  `flutter config --no-enable-swift-package-manager`, `flutter pub get`,
  `flutter gen-l10n`, resolve each requested simulator name to a UDID via
  `xcrun simctl list devices available -j`, boot it, then one `flutter drive`
  per device. The captured pixel sizes are printed into the job summary.
* **android** — `ubuntu-latest`: `reactivecircus/android-emulator-runner@v2`,
  API 34, `google_apis`/`x86_64`, `pixel_7` profile, software GPU, and the same
  `flutter drive`.
* **publish** — `ubuntu-latest`, `needs: [ios, android]`, runs when *either*
  capture job succeeded. §2.1.
* **appstore** — `ubuntu-latest`, `needs: ios`, runs when the iOS job succeeded
  *and* the repo has an `ASC_APP_ID`. §5.

Nothing here is ever submitted for App Review, and there is still no Play
upload (§6).

### 2.1 The `screenshots` branch — looking at a run without downloading it

The **publish** job downloads every `screenshots-*` artifact that exists
(`actions/download-artifact@v4`, `pattern: screenshots-*`,
`merge-multiple: false`, so each artifact keeps its own directory), flattens the
artifact level away and force-pushes the result to the orphan branch
**`screenshots`**:

```
screenshots (orphan, one commit, force-pushed by every run)
├── README.md                  metadata + a Markdown gallery of every image
├── iPhone_17_Pro_Max/en_01_levels.png …
├── iPad_Pro_13-inch_M5/…
└── pixel_7_api34/…
```

`README.md` names the source commit sha, the run id (as a link to the run) and
the result of each capture job, then embeds every PNG in a per-device table with
one column per language — so browsing to the branch on GitHub *is* the review
step that used to mean downloading a zip.

The job builds the commit in a throwaway `git init` directory and pushes with
the default `GITHUB_TOKEN` (`permissions: contents: write`) under a bot
identity. It never checks out or pushes `main`, and the branch has no history to
inherit: each run's commit *is* the branch. The `if:` guard
(`always() && (needs.ios.result == 'success' || needs.android.result ==
'success')`) exists so that a run in which **both** capture jobs failed leaves
the previous, good branch content alone instead of emptying it.

### 2.2 Re-running

* **A full re-capture**: Actions → **screenshots** → *Run workflow*. Both
  delivery jobs follow automatically; `publish` replaces the branch and
  `appstore` replaces the screenshots in the store (§5), so a re-run is always
  safe to repeat.
* **One platform only**: use *Re-run failed jobs* on the run. `publish` and
  `appstore` re-run with it and pick up the artifacts that are still attached to
  that run.
* **Only the App Store upload, from a laptop**: download the artifact (or clone
  the `screenshots` branch) and run the script by hand — see §5.

### On a Mac, by hand

```bash
export PATH="…/flutter/bin:$PATH"
flutter config --no-enable-swift-package-manager
flutter pub get
cd app && flutter gen-l10n

xcrun simctl list devices available | grep -E 'iPhone 17 Pro Max|iPad Pro 13'
xcrun simctl boot <udid>; xcrun simctl bootstatus <udid> -b
xcrun simctl uninstall <udid> com.crispstrobe.hectopolis   # never drive a stale build

SCREENSHOT_DEVICE="iPhone 17 Pro Max" flutter drive \
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
| 6.9" iPhone | iPhone 17 Pro Max (or 17 Pro Max) | **1320 × 2868** portrait | `APP_IPHONE_67` |
| 13" iPad | iPad Pro 13-inch (M5) | **2064 × 2752** portrait | `APP_IPAD_PRO_3GEN_129` |

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

The **appstore** job does this on every run that captured iOS screenshots, with
[`tools/asc/upload_screenshots.py`](../../tools/asc/upload_screenshots.py) —
`tools/asc/client.py` plus the standard library, nothing else. By hand it is:

```bash
export ASC_API_KEY_P8_BASE64=$(base64 -i AuthKey_9RMU3C7422.p8)   # or ~/.appstoreconnect/private_keys/
export ASC_KEY_ID=… ASC_ISSUER_ID=… ASC_APP_ID=…

python3 tools/asc/upload_screenshots.py --dry-run app/screenshots   # the plan, no writes
python3 tools/asc/upload_screenshots.py --replace app/screenshots   # do it
```

**What the file names decide.** The device directory picks the size class and
the file name picks the store language and the position — nothing is configured
twice:

| Path | Set | Locale | Position |
|---|---|---|---|
| `iPhone_17_Pro_Max/en_02_map.png` | `APP_IPHONE_67` (dir matches `/iPhone/`) | `en-US` (`en_`) | 2 |
| `iPad_Pro_13-inch_M5/de_05_inspector.png` | `APP_IPAD_PRO_3GEN_129` (`/iPad/`) | `de-DE` (`de_`) | 5 |

Android directories (`pixel_7_api34/…`) match neither pattern and are skipped
with a printed reason, so pointing the script at a directory holding both
platforms is fine.

**The call sequence**, per (locale × display type) group, in order:

1. `GET /v1/apps/{app}/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED,WAITING_FOR_REVIEW,READY_FOR_REVIEW`
   — the editable version. If there is none,
   `POST /v1/appStoreVersions` with `versionString` from `app/pubspec.yaml`
   (`--version` overrides) and `platform: IOS`. A 409 there means one appeared
   in the meantime: the script re-reads instead of failing.
2. `GET /v1/appStoreVersions/{version}/appStoreVersionLocalizations`, else
   `POST /v1/appStoreVersionLocalizations` for `en-US` / `de-DE`. Re-POSTing an
   existing locale 409s with *There is an entity with same 'locale'* — again
   answered by re-reading, not by failing.
3. `GET /v1/appStoreVersionLocalizations/{loc}/appScreenshotSets`, else
   `POST /v1/appScreenshotSets` with `screenshotDisplayType`. A 409 whose body
   lists every valid enum value means Apple renamed the display type — the
   error is printed verbatim, because that list *is* the answer.
4. With `--replace`: `GET /v1/appScreenshotSets/{set}/appScreenshots` then
   `DELETE /v1/appScreenshots/{id}` for each. Without it, existing images are
   kept and the script warns when existing + new would break Apple's limit of
   ten per set.
5. Per image, in numeric order:
   `POST /v1/appScreenshots` (`fileName`, `fileSize`, the set as relationship)
   → for each entry of the returned `attributes.uploadOperations`, the raw bytes
   `[offset, offset+length)` are PUT to its `url` with exactly the
   `requestHeaders` Apple returned → `PATCH /v1/appScreenshots/{id}` with
   `{"uploaded": true, "sourceFileChecksum": "<md5 hex of the whole file>"}` →
   `GET /v1/appScreenshots/{id}` every 3 s until
   `attributes.assetDeliveryState.state` is `COMPLETE` (`UPLOAD_COMPLETE` on
   older responses). A `FAILED` state or an `errors` array means the checksum or
   a byte range was wrong; the script stops there rather than leaving a
   half-uploaded asset looking fine.
6. `PATCH /v1/appScreenshotSets/{set}/relationships/appScreenshots` with the ids
   in the wanted order (falling back to `POST`, the verb this endpoint used to
   take). Ordering is cosmetic and never fails the run — with `--replace` the
   upload order is already the display order.

Every collection read goes through `client.paged`, so a set with more images
than one page still gets fully listed and fully deleted.

**Traps worth keeping.**

* The presigned PUT has been seen dying mid-stream under `urllib` on some
  machines. The script tries `urllib` first and falls back to
  `curl -X PUT --data-binary @chunk -H '<the header Apple returned>'` per chunk.
* `filter[...]` query parameters are percent-encoded (`filter%5Bplatform%5D`);
  passing raw brackets works until it doesn't.
* The script never touches `whatsNew`, never attaches a build and **never
  submits for review** — that stays a deliberate human decision.
* App Store Connect wants 3–10 images per set, PNG or JPEG, **no alpha
  channel**. The simulator captures are opaque, so this has not bitten yet; a
  future translucent screen would need a flatten step.

**Gating.** GitHub rejects `if: ${{ secrets.X != '' }}` (*Unrecognized
named-value: 'secrets'*), so the job computes
`HAS_APP_ID: ${{ secrets.ASC_APP_ID != '' }}` at job level and every step is
`if: env.HAS_APP_ID == 'true'`. Without the secret the job prints a notice and
ends green; **with** `ASC_APP_ID` but without the API key secrets it fails
loudly, because that combination is a misconfiguration, not a choice. The job
runs its own `--dry-run` first, so the log always shows the intended mapping
directly above the writes that acted on it.

## 6. Uploading to Play

There is no screenshot upload in the current `android-release.yml`. Until the
Play service account is wired up (see [`android.md`](android.md) §6), attach the
`screenshots-android` artifact — or the `pixel_7_api34/` directory of the
`screenshots` branch, which needs no zip — by hand in Play Console →
*Store presence* → *Main store listing*, per language. With the service account, the Publishing API
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
*Look at the images* — now one click away on the [`screenshots`
branch](../../../../tree/screenshots) — before they go anywhere near a store
listing.

The App Store half is unverifiable here for a second reason: there is no app
record to talk to. `upload_screenshots.py`'s file→locale→set mapping, its
ordering and its plan output are unit-tested offline, and `--dry-run` without an
API key prints the whole plan and stops; but the version/localization/set
lookups, the reserve→PUT→commit→poll dance and every 409 path have only been
exercised against Apple's documented behaviour and the playbook in
`/mnt/volume1/appstore.md`, never against this app. Run the **appstore** job
once with the secrets set and read its log before trusting it unattended.
