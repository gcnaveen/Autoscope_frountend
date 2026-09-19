# Autoscope (carwebapp)

A Flutter **web** app for vehicle inspection management — admin, inspector, and customer dashboards backed by a REST API on AWS API Gateway + Lambda.

> **This app is web-only.** It uses `dart:html`/`dart:js` directly (camera capture, file pickers, PDF report printing) and will not build for Android, iOS, Windows, macOS, or Linux even though those platform folders exist in the repo (default Flutter scaffolding, unused). Always target Chrome/web.

---

## Prerequisites

- **Flutter SDK 3.47.4** (stable channel) / **Dart 3.13.3** — this exact version is what the project was last verified against; a nearby stable version should also work, but if you hit unexpected analyzer errors, check `flutter --version` first.
- **Google Chrome** — the only browser target used for development (`flutter doctor` also detects Edge, but Chrome is the standard target here).
- **Windows only — Developer Mode must be enabled** before `flutter pub get` will succeed. Flutter's plugin build step needs symlink support:
  - Settings → Privacy & security → For developers → turn on **Developer Mode**, or
  - Admin PowerShell: `New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowDevelopmentWithoutDevLicense -PropertyType DWord -Value 1 -Force`

If Flutter isn't already on your PATH, install it by cloning the stable branch and adding `<clone-path>\bin` to your PATH:
```bash
git clone -b stable --depth 1 https://github.com/flutter/flutter.git
# then add <path-to-flutter>/bin to your PATH (setx PATH on Windows, or edit ~/.bashrc/.zshrc)
```

---

## Setup

```bash
flutter doctor          # confirm Chrome is detected under "Connected device"
flutter pub get         # install dependencies
```

---

## Running the app

```bash
flutter run -d chrome
```

Pin a specific port (useful if the default port is already in use, or you want a stable URL to bookmark):
```bash
flutter run -d chrome --web-port=5050
```

Once running, keyboard shortcuts in the terminal:
| Key | Action |
|---|---|
| `r` | Hot reload |
| `R` | Hot restart |
| `q` | Quit |
| `d` | Detach (leaves the app running in the browser, stops the CLI session) |

---

## Building for production

```bash
flutter build web
```
Output goes to `build/web/` — deploy that folder's contents to your static host (S3, etc.). Add `--release` explicitly if you want to be sure (it's the default for `build web`), or `--profile` for a profiling build.

---

## Code quality

```bash
flutter analyze          # static analysis — run this before committing
dart format lib/         # auto-format Dart source
flutter test              # run the test suite (note: test/widget_test.dart is a stale default
                           # template referencing a non-existent MyApp class — this is a
                           # pre-existing issue unrelated to app code, not a real regression)
```

---

## Backend configuration

The API base URL is hardcoded in [`lib/config/api_config.dart`](lib/config/api_config.dart):
```dart
static const String host = 'https://6k651yup6b.execute-api.ap-south-1.amazonaws.com';
```
There's no `.env`/`--dart-define` split between environments today — to point at a different backend, edit this file directly.

---

## Troubleshooting

**`flutter pub get` fails with a permissions/symlink error**
→ Enable Windows Developer Mode (see Prerequisites above), then retry.

**`flutter run` fails with "Flutter failed to delete a directory at ...build\flutter_assets"**
→ This project commonly lives inside a OneDrive-synced folder, which intermittently locks files mid-build. Fix:
```bash
rm -rf build
flutter run -d chrome
```

**`SocketException: ... Only one usage of each socket address ...` on `flutter run`**
→ A previous `flutter run` process is still holding that port. Either kill it or pick a different port with `--web-port=<other-port>`.

**Chrome opens but the page is blank / stuck loading**
→ Usually a stale `build/` directory (see the OneDrive fix above), or the backend API being unreachable — check the Network tab for failed requests to the host in `api_config.dart`.

---

## Project structure (brief)

```
lib/
  app/           # router (go_router) + app shell/theme
  config/        # API base URL
  features/      # screens, grouped by role: auth, dashboards/{admin,inspector,user}, public, report, shared
  models/        # plain data classes
  services/      # API client + one service class per backend resource (service-locator pattern, no DI framework)
  utils/         # small cross-platform helpers (conditional web/stub imports)
```

State management is plain `StatefulWidget`/`setState` with a manual service-locator (`lib/services/service_locator.dart`) — no Provider/Riverpod/Bloc.

See [`API_DOCUMENTATION.md`](API_DOCUMENTATION.md) for the backend REST API reference.
