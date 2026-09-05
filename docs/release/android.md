<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->

# Android release checklist (T-402)

Everything a human has to do once, plus what CI does on every tag.

* Package name: `com.crispstrobe.hectopolis` (also the Gradle `namespace`)
* Build: `.github/workflows/android-release.yml`
* Signing: `app/android/app/build.gradle.kts` reads `app/android/key.properties`
* Version: `version:` in `app/pubspec.yaml` (`<build-name>+<build-number>`, e.g. `1.2.3+45`)

The keystore and `key.properties` **never** enter the repository. Both are covered by
`.gitignore` (`app/android/.gitignore`: `key.properties`, `**/*.keystore`, `**/*.jks`; the
root `.gitignore` repeats the same patterns for the other platform folders). Verify with
`git check-ignore -v app/android/key.properties` before you ever `git add -A`.

---

## 1. Create the upload keystore (once, on a trusted machine)

Google Play uses *Play App Signing*: the key below is the **upload key**, Google holds the
app signing key. If the upload key is lost it can be reset through the Play Console; if you
opt out of Play App Signing it cannot, so do not opt out.

```bash
keytool -genkeypair -v \
  -keystore ~/keys/hectopolis-upload.jks \
  -storetype PKCS12 \
  -keyalg RSA -keysize 4096 \
  -validity 10000 \
  -alias upload \
  -dname "CN=Hectopolis, O=crispstrobe, C=DE"
```

`keytool` asks twice for a password; use the **same** value for the store and the key
password (Gradle expects both, and the workflow passes both from separate secrets — set
them to the same string unless you deliberately used two).

Keep the `.jks` and the passwords in a password manager plus one offline backup. Losing
them means a new upload key request at Google and a broken sideload upgrade path for
everyone who installed the APK directly.

Check what you produced:

```bash
keytool -list -v -keystore ~/keys/hectopolis-upload.jks -alias upload
```

Note the SHA-256 fingerprint; the Play Console shows the same value for the upload
certificate once the first bundle is uploaded.

## 2. Base64 the keystore into a GitHub secret

The secret must be a single line, so use `-w0` (macOS: `base64 -i file | tr -d '\n'`):

```bash
base64 -w0 ~/keys/hectopolis-upload.jks > /tmp/keystore.b64
wc -c /tmp/keystore.b64            # sanity check: a few thousand bytes
gh secret set ANDROID_KEYSTORE_BASE64 < /tmp/keystore.b64
shred -u /tmp/keystore.b64
```

Or paste the file contents into *Settings → Secrets and variables → Actions → New
repository secret*.

## 3. The four repository secrets

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | base64 of `hectopolis-upload.jks`, one line |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore (store) password |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | the key password (usually the same as the store password) |

```bash
gh secret set ANDROID_KEYSTORE_PASSWORD
gh secret set ANDROID_KEY_ALIAS --body upload
gh secret set ANDROID_KEY_PASSWORD
```

The workflow decodes the keystore into `$RUNNER_TEMP`, verifies it with
`keytool -list` before building, writes `app/android/key.properties`, and deletes both
again in an `always()` step.

If `ANDROID_KEYSTORE_BASE64` is unset the build still runs and produces artifacts, but
Gradle falls back to the **debug** key: the files are named `…-unsigned` and no GitHub
release is created. Never distribute those.

## 4. Local release build

Optional — CI is the normal path. Write `app/android/key.properties` by hand:

```properties
storeFile=/home/you/keys/hectopolis-upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

`storeFile` may be absolute (recommended) or relative to `app/android/`. A backslash in a
password has to be doubled — `key.properties` is a `java.util.Properties` file.

```bash
cd app
flutter build appbundle --release      # app/build/app/outputs/bundle/release/app-release.aab
flutter build apk --release            # app/build/app/outputs/flutter-apk/app-release.apk
```

Without the file both commands still work and sign with the debug key; Gradle prints a
warning saying so. That is what keeps the `check` workflow and contributor clones green.

Verify the signature of a finished artifact:

```bash
$ANDROID_HOME/build-tools/<version>/apksigner verify --print-certs app-release.apk
```

## 5. Dry run

*Actions → android-release → Run workflow*, leave `dry_run` at **true**.

Builds the AAB and the APK from the current branch, uploads them as the workflow artifact
`android-<build-name>-<build-number>`, and creates **no** GitHub release. Use this to check
a toolchain or dependency change before tagging.

Setting `dry_run` to false only publishes something when the workflow is run on a `v*`
tag ref; on a branch it is still build-only.

## 6. Tag release

1. Bump `version:` in `app/pubspec.yaml` (`1.2.3+45` — increase the build number on
   *every* upload to Play, it must be strictly monotonic).
2. Commit, then tag with the matching name:

   ```bash
   git tag -a v1.2.3 -m "Hectopolis 1.2.3"
   git push origin main --follow-tags
   ```

   The tag without the leading `v` must equal the build name; the workflow fails the
   release otherwise.
3. The workflow builds, attaches `hectopolis-v1.2.3-build45.apk`, `.aab` and
   `SHA256SUMS.txt` to the GitHub release for the tag, and marks it a pre-release if the
   tag contains a `-` (`v1.2.3-rc1`).

Pre-flight before tagging: `tools/check.sh` green, `THIRD_PARTY.md` current, and the About
screen (T-405) shows the AGPL text, the section 7 app-store exception and the link to the
source repository — the exception is what makes distributing through Play compatible with
the license, and the offer of source has to be reachable from inside the app.

## 7. Google Play — the steps that need a human

Not automated, and the first ones cannot be. The workflow carries a commented-out
`r0adkll/upload-google-play` step (secret `PLAY_SERVICE_ACCOUNT_JSON`) that can be enabled
once step 7.6 is done.

1. **Developer account.** One-off fee, identity verification (for an individual account
   Google verifies name, address and phone; this takes days, not minutes). A personal
   developer account also has its address shown publicly on the store listing.
2. **Create the app** in the Play Console: name, default language, app-or-game, free/paid.
   Free cannot be changed to paid later. Reserve the package name by uploading the first
   bundle to the internal test track by hand.
3. **Play App Signing**: accept it when uploading the first bundle. Our key becomes the
   upload key (see step 1).
4. **Store listing**: short and full description (DE and EN — same languages the app
   ships), app icon 512×512, feature graphic 1024×500, at least two phone screenshots,
   category, contact e-mail. Screenshots must show the real app.
5. **Policy declarations**, all mandatory before release:
   * **Content rating** questionnaire (IARC). A city-building simulation with no violence,
     no ads, no user-generated content, no purchases rates PEGI 3 / ESRB Everyone.
   * **Data safety** form: declare what is collected and shared. Hectopolis stores level
     progress locally via `shared_preferences` and has no analytics, no accounts and no
     network calls, so the honest answer is "no data collected, no data shared"; that
     claim has to stay true — any later telemetry means updating the form *before* the
     release that adds it.
   * **Privacy policy URL** — required even for a no-data app.
   * Target audience and content, ads declaration (none), news app (no), government app
     (no), financial features (none), health (none).
   * **Target API level**: Play enforces a minimum for new uploads. We build against
     `flutter.targetSdkVersion` (36 with Flutter 3.44), which satisfies it.
6. **Service account for automated uploads** (only after a first manual upload):
   Google Cloud → service account → grant it access in Play Console under *Users and
   permissions* with the *Release apps to testing tracks* permission → download the JSON
   key → `gh secret set PLAY_SERVICE_ACCOUNT_JSON < key.json` → uncomment the upload step
   in `.github/workflows/android-release.yml`.
7. **Review** takes days for a new app; test-track promotions are faster. Roll out through
   internal → closed → production rather than straight to production.

## 8. License note

Distribution through an app store relies on the additional permission under section 7 of
the AGPL granted in `LICENSE-EXCEPTION.md`, which only the copyright holders can invoke.
The published binary must keep the About screen with the license texts and the repository
link intact; the corresponding source for the exact released commit is the tag the release
was built from.
