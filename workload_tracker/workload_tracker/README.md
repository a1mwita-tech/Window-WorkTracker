# Workload — Personal Workload Tracker

Flutter app: Categories → Projects → Tasks, with an urgency-ranked Daily
Review. Runs on Windows, macOS (Intel + Apple Silicon, universal binary),
and Android.

## 1. What's included vs. what you generate locally

This package contains all **application code** (`lib/`, `pubspec.yaml`) and
a ready-made **Android** platform folder (`android/`).

It does **not** include the `macos/`, `windows/`, `ios/`, `web/`, or
`linux/` platform folders. Those are thousands of lines of
Anthropic-unrelated, auto-generated Xcode-project / Visual-Studio-project
boilerplate that Flutter itself generates deterministically from your
`pubspec.yaml` — hand-writing them would just make them stale the moment
you run a different Flutter version. You generate them in one command
(step 2 below) and they'll be correctly matched to your installed Flutter
SDK and Xcode/Visual Studio versions.

## 2. One-time setup

```bash
# Install Flutter (if you don't have it): https://docs.flutter.dev/get-started/install
flutter --version   # confirm it works; this project targets Flutter 3.22+ / Dart 3.3+

# From inside the unzipped project folder:
cd workload_tracker

# Generate the missing platform folders (macOS, Windows; skip ios/web/linux
# if you don't need them) INTO this existing project without touching lib/:
flutter create --platforms=macos,windows .

# Fetch packages
flutter pub get

# Sanity check
flutter doctor
```

`flutter create --platforms=... .` is safe to run on an existing project —
it only adds the missing platform folders, it does not overwrite `lib/` or
`pubspec.yaml`.

For Android, the `android/` folder is already included and configured
(package `com.example.workload_tracker`, minSdk 21, targetSdk 34). If you
want Flutter to regenerate/verify it instead, run
`flutter create --platforms=android .` — it will merge, not clobber, your
existing config.

Rename the package/bundle ID before you ship (see §6).

## 3. Run in development

```bash
flutter devices              # list available targets

flutter run -d macos         # macOS (native window, current Mac's arch)
flutter run -d windows       # Windows
flutter run -d <android-id>  # Android device/emulator, id from `flutter devices`
```

Hot reload (`r`) and hot restart (`R`) work as usual while `flutter run` is
active.

## 4. Build for release

### Windows

```bash
flutter build windows --release
```

Output: `build\windows\x64\runner\Release\workload_tracker.exe` plus its
DLLs — zip that folder or wrap it with an installer (Inno Setup, MSIX) to
distribute.

To package as MSIX for the Microsoft Store or sideloading:

```bash
flutter pub add msix --dev
flutter pub run msix:create
```

### macOS — Intel + Apple Silicon universal binary

```bash
flutter build macos --release
```

Since Flutter 2.8+, `flutter build macos` links against a **universal
(fat) Flutter engine framework** containing both `arm64` and `x86_64`
slices, so the resulting `.app` runs natively on both Apple Silicon and
Intel Macs without any extra flags. Verify it:

```bash
lipo -info "build/macos/Build/Products/Release/workload_tracker.app/Contents/Frameworks/App.framework/Versions/A/App"
# Expect: Architectures in the fat file: ... are: x86_64 arm64
```

If that ever reports a single architecture (e.g. after changing Xcode
build settings), open `macos/Runner.xcodeproj` in Xcode and confirm
**Build Settings → Architectures** is set to `Standard Architectures
(Apple Silicon, Intel)` and `ONLY_ACTIVE_ARCH = NO` for the Release
configuration, then rebuild.

To distribute outside the App Store you'll need to code-sign and notarize:

```bash
# Sign (replace with your Developer ID Application identity)
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  "build/macos/Build/Products/Release/workload_tracker.app"

# Zip and notarize with Apple (requires an app-specific password / API key)
ditto -c -k --keepParent \
  "build/macos/Build/Products/Release/workload_tracker.app" workload_tracker.zip
xcrun notarytool submit workload_tracker.zip --keychain-profile "AC_PROFILE" --wait
xcrun stapler staple "build/macos/Build/Products/Release/workload_tracker.app"
```

### Android

```bash
flutter build apk --release            # single APK, for direct install/testing
flutter build appbundle --release      # .aab, required for Play Store upload
```

Output: `build/app/outputs/flutter-apk/app-release.apk` or
`build/app/outputs/bundle/release/app-release.aab`.

## 5. Android release signing

The included `android/app/build.gradle` signs release builds with the
**debug key** so `flutter build apk --release` works out of the box for
testing. Before publishing:

1. Generate a key: `keytool -genkey -v -keystore ~/workload-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias workload`
2. Create `android/key.properties`:
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=workload
   storeFile=/absolute/path/to/workload-release.jks
   ```
3. In `android/app/build.gradle`, replace `signingConfig signingConfigs.debug`
   with a `signingConfigs.release` block that reads `key.properties`, and
   point the `release` build type at it (standard Flutter pattern — see
   [Flutter's Android signing docs](https://docs.flutter.dev/deployment/android#signing-the-app)).

## 6. Rename the app / bundle identifiers before shipping

- Android: change `namespace` and `applicationId` in
  `android/app/build.gradle` from `com.example.workload_tracker` to your
  own (e.g. `com.yourcompany.workload`).
- macOS: in Xcode (`macos/Runner.xcodeproj`), update the Bundle Identifier
  under Runner target → Signing & Capabilities.
- Windows: update `CompanyName` / `ProductName` in
  `windows/runner/Runner.rc`.

## 7. Project structure

```
workload_tracker/
├── pubspec.yaml
├── android/                     # included, configured
├── macos/ windows/               # generate via `flutter create` (§2)
└── lib/
    ├── main.dart                 # entry point, MaterialApp, theme wiring
    ├── app_shell.dart             # top toolbar nav, keyboard shortcuts
    ├── models/
    │   ├── category.dart          # Category, Project + Hive adapters
    │   └── task.dart               # Task, Priority, TaskStatus, urgency logic
    ├── data/
    │   ├── hive_boxes.dart         # local DB init + adapter registration
    │   └── seed_data.dart          # pre-loaded categories/projects
    ├── providers/
    │   └── app_providers.dart      # Riverpod state, repository, filters,
    │                                # urgency ranking, archive sweep
    ├── theme/
    │   └── app_theme.dart          # Apple HIG-inspired light/dark theme
    ├── widgets/
    │   ├── top_toolbar.dart        # blurred header + section switcher
    │   ├── task_card.dart          # red/yellow/grey visual cues
    │   └── task_form_dialog.dart   # add/edit task, cascading dropdowns
    └── screens/
        ├── daily_review_screen.dart
        ├── tasks_screen.dart
        ├── lists_screen.dart
        └── how_to_use_screen.dart
```

## 8. How the requirements map to code

- **Urgency formula** (Priority 30/20/10 + Deadline 40/35/20, overdue Low
  beats no-deadline High): `Task.urgency()` in `lib/models/task.dart`,
  covered by a comment explaining the intentional ranking behavior.
- **Daily Review** (counts, Top 30, Done drops off automatically):
  `dailyReviewProvider` in `lib/providers/app_providers.dart` filters out
  `TaskStatus.done` and archived tasks before ranking.
- **Cascading Category → Project dropdown**: `lib/widgets/task_form_dialog.dart`
  filters the Project list to `p.categoryId == _categoryId` and resets the
  Project selection whenever Category changes.
- **Visual cues** (red overdue / yellow due-today / grey Done):
  `lib/widgets/task_card.dart`.
- **Archive** (manual + auto after Done 30+ days, hidden but retrievable,
  Unarchive): `Task.shouldAutoArchive()` in `task.dart`, swept in
  `tasksProvider`; manual archive via swipe-to-archive on the Tasks screen;
  Unarchive via the Archive bottom sheet.
- **All controls moved to a top horizontal header** (not a right-side
  panel): `lib/widgets/top_toolbar.dart` — a single blurred, translucent
  bar with the app title, dark-mode toggle, primary "New Task" action, and
  a segmented control for the four views. The Tasks screen's own filters
  (search / category / project / show-done / archive) sit in a compact
  horizontal row directly under that header, not in a sidebar.
- **Pre-loaded categories**: `lib/data/seed_data.dart` — Subtitles (Giant
  Creatives, Euphoria 360, Inkblot), Dubbing (Zacu TV series/movies, BBC,
  Iyuno–Disney, Zee TV, Arewa 24, Avante, Dambe), Internal Requests,
  Pending Confirmation, Billing, Teams.

## 9. Design notes

- **Persistence**: [Hive](https://pub.dev/packages/hive), a pure-Dart,
  fast, embedded key-value store with no native binary dependency per
  platform — chosen specifically because it works identically on Windows,
  macOS, and Android without platform-specific SQLite plugin setup. Data
  lives in the app's local documents directory on each platform; there's
  no sync between devices (out of scope here, but the repository layer in
  `app_providers.dart` is the seam where you'd add e.g. a backend sync
  later).
- **State management**: [Riverpod](https://riverpod.dev). Hive boxes are
  wrapped in `StreamProvider`s so every screen reacts live to writes —
  add a task on the Tasks screen and Daily Review's counts/ranking update
  immediately, no manual refresh.
- **Typography**: SF Pro on macOS (referenced via Apple's private system
  font family, no bundling needed) with Cupertino-style type ramps; Inter
  (via `google_fonts`) everywhere else, matching your "SF Pro on Apple
  platforms, Inter/Roboto elsewhere" spec. See
  `AppTheme._fontFamily` / `_textTheme` in `lib/theme/app_theme.dart`.
- **Responsive layout**: stat cards and filter rows use `LayoutBuilder`/
  `MediaQuery` breakpoints (`lib/screens/daily_review_screen.dart`,
  `tasks_screen.dart`) so the grid collapses from 3 columns on desktop to
  1 on a phone; the top toolbar's segmented control scrolls horizontally
  on narrow widths instead of wrapping awkwardly.
- **Touch targets**: buttons, dropdowns, and list rows are constrained to
  a 44×44pt minimum via the theme's button styles, meeting both Apple HIG
  and Android accessibility guidance.
- **Keyboard shortcuts**: `Cmd/Ctrl+N` new task, `Cmd/Ctrl+1..4` switch
  views — wired in `lib/app_shell.dart` via `Shortcuts`/`Actions`, active
  on Windows and macOS.
- **Accent color / grays**: Apple's system blue (#0A84FF) and system
  gray scale, defined once in `AppColors` (`lib/theme/app_theme.dart`) and
  reused everywhere rather than hardcoded per-widget, so retheming is a
  one-file change.

## 10. Known follow-ups you may want next

- Cloud sync / multi-device (currently local-only per install).
- CSV/Excel import to migrate your existing prototype's rows in bulk.
- Notifications for tasks becoming overdue.
- A Settings screen to customize the urgency weights instead of the fixed
  30/20/10 + 40/35/20 constants (kept fixed here per your "preserve this
  exact logic" instruction).
