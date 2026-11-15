# Android TV / Google TV progress

_Last updated: 2026-11-15_

## Scope and branch

- Working branch: `feature/android-tv-upstream-sync` (continues `feature/android-tv-support`, merged with upstream `develop` at `e3ebef11`, 2026-11-12)
- Base branch: `develop`
- PWA/web work is intentionally shelved on the separate `feature/pwa-tv-foundation` branch.
- Goal: add Google Play TV / Android TV support while preserving the existing Android phone/tablet behavior and keeping upstream Medito merges as low-conflict as practical.

## Current state

The TV app is feature-complete for a first internal test in mock mode:

- Leanback manifest overlays, TV banner and runtime Leanback detection.
- A dedicated remote-first presentation layer under `lib/views/tv/`: navigation
  shell, Home, Explore, Search, Library (favorites), pack and meditation detail,
  player with its own completion screen, Settings, playback defaults,
  analytics/privacy and account sign-in. See `TV_UI_ARCHITECTURE.md`.
- Phone-only behavior is gated on Leanback at the service level: reminders and
  notifications, Meta SDK, home-screen widgets, Health Connect, review prompts,
  browser/donation/shop/timer routes and onboarding.
- CI (`Android TV Build`) analyzes, builds a mock-mode production-flavor AAB and
  verifies the merged manifest on every push. The Google TV emulator smoke test
  is a manual `workflow_dispatch` job.

### What changed in the upstream sync (2026-11-15)

Upstream reworked navigation, settings, sign-in and the end screen around an
adaptive tablet layout. The merge was resolved with one rule: **shared
phone/tablet screens stay identical to upstream; TV differences live in
`lib/views/tv/` or behind a capability check in a service.**

- Earlier TV focus tweaks inside phone screens that TV no longer builds (Home
  widgets, `PackView`, `PlayerView`, Settings, Downloads, end screen,
  onboarding) were dropped in favor of upstream's versions.
- `BottomNavigationBarView` keeps upstream's adaptive layout and returns
  `TvNavigationShell` on Leanback devices.
- Sign-in uses upstream's new form; TV adds only its frame, a
  remote-reachable back button and the onboarding bypass.
- The TV shop shelf was removed: upstream replaced the products API, and the
  shelf opened a browser.
- The diff against upstream is now 55 files, of which 29 are new.

## Completed work

### 1. Android TV / Google TV manifest support

TV support is implemented with Android manifest overlays instead of rewriting the large upstream `src/main/AndroidManifest.xml`. This is intentional to reduce future merge conflicts with `meditohq/medito-app`.

Files:

- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/release/AndroidManifest.xml`

Implemented declarations:

- `android.software.leanback` with `android:required="false"`
- `android.hardware.touchscreen` with `android:required="false"`
- `android.hardware.faketouch` with `android:required="false"`
- `android.intent.category.LEANBACK_LAUNCHER` on `MainActivity`

The Leanback feature is deliberately optional because the same Android application is intended to remain installable on phones/tablets as well as Android TV / Google TV.

The release overlay retains the existing Medito behavior that removes the direct phone `LAUNCHER` filter from `MainActivity`; the existing dynamic phone launcher aliases remain responsible for phone launcher behavior. The TV launcher is added separately through `LEANBACK_LAUNCHER`.

### 2. TV banner

Added:

- `android/app/src/main/res/drawable-xhdpi/tv_banner.png`

The banner is 320x180 and uses the current Medito purple (`#917DF0`) and white Medito mark/branding. The TV manifest overlays reference it through `android:banner="@drawable/tv_banner"`.

This satisfies the basic Android TV launcher banner requirement. A later design review can replace the banner without changing the architecture.

### 3. Runtime form-factor detection

Added:

- `lib/services/device_capabilities_service.dart`
- `lib/providers/device_capabilities_provider.dart`

`DeviceCapabilitiesService` uses the existing `device_info_plus` dependency and Android `systemFeatures` rather than screen-size heuristics.

Current capability model:

- `isAndroidTv`: true when `android.software.leanback` is reported
- `hasTouchscreen`
- `hasFakeTouch`
- `requiresRemoteNavigation`: currently aliases `isAndroidTv`

Design rule: use capability detection rather than device model lists, screen dimensions, or scattered TV booleans.

### 4. First remote-friendly navigation adaptation

Modified:

- `lib/views/bottom_navigation/bottom_navigation_bar_view.dart`

Behavior:

- Existing phone/tablet bottom navigation remains the normal path.
- Android TV / Google TV devices use a left-side `NavigationRail` with visible labels.
- The rail participates in Flutter focus traversal and gives D-pad users a usable top-level navigation surface.

This first adaptation was later replaced by `TvNavigationShell` (see `TV_UI_ARCHITECTURE.md`).

### 5. Android TV AAB CI

Added:

- `.github/workflows/android-tv-build.yml`

The workflow:

1. Checks out the branch.
2. Uses Java 17 and Flutter 3.47.2, matching the existing project workflows.
3. Runs `flutter pub get`.
4. Runs `build_runner`.
5. Runs Pigeon generation.
6. Generates compile-only Android configuration inside CI rather than requiring production secrets.
7. Builds a release `prod` Android App Bundle in `MOCK_MODE=true`.
8. Finds the merged Android manifest and verifies the TV declarations are present.
9. Builds an installable debug APK for runtime smoke testing.
10. Boots a Google TV API 36 x86_64 emulator.
11. Verifies the device exposes Leanback, resolves Medito through the Leanback launcher, launches the app, sends D-pad events, and fails if the app process dies/crashes.
12. Uploads the emulator screenshot/UI hierarchy/logcat and the generated AAB as artifacts.
13. Uses workflow concurrency so newer branch pushes supersede obsolete TV builds.

The CI AAB is a compile/manifest validation artifact, not a production-signed release artifact.

### 7. TV onboarding bypass

Modified:

- `lib/views/splash_view.dart`

Android TV / Google TV devices now skip `OnboardingPagerScreen` completely
after a new anonymous/guest sign-in. The TV path no longer shows the
experience question, donation flow, notification prompt, battery optimization,
tracking permission, or onboarding result screens.

After guest/account initialization, Leanback devices navigate directly to the
normal root application:

`RootPageView(firstChild: BottomNavigationBarView())`

Phone/tablet behavior is unchanged and still uses the existing onboarding flow.

The earlier focusable onboarding-option change remains harmless shared UI
accessibility work, but onboarding is no longer part of the TV product path and
is no longer a TV CI gate.

### 6. Reproducible Windows TV development setup

Added:

- `scripts/setup-tv-dev.ps1`
- `scripts/run-tv-mock.ps1`
- `docs/LOCAL_TV_DEVELOPMENT.md`

The setup script auto-detects JDK 17, configures Flutter to use it, creates the
gitignored local debug signing/Firebase files required by Gradle, runs
`flutter pub get`, runs build_runner, runs Pigeon, and shows Flutter-visible
devices.

The run script selects a supported Android TV/Google TV emulator and launches
Medito with `.mock.json` and `MOCK_MODE=true`. It does not use
`--start-paused`, so local TV testing launches normally.

This keeps contributor setup out of committed production configuration while
making the local environment reproducible.

## Important decisions and resolutions

### Keep the phone and TV app in one Android project

Do not fork the Dart application into a separate Android-TV codebase. Use the existing Flutter application with adaptive/capability-driven behavior.

### Do not use screen size to detect a TV

Use `PackageManager`/system-feature-equivalent information exposed by `device_info_plus`, specifically `android.software.leanback`.

### Keep Leanback optional in the combined app

`android.software.leanback` is declared with `required=false`. Making it required would exclude normal Android devices from the same application package.

### Touch must not be required

Both touchscreen and faketouch are explicitly `required=false`, because a TV application cannot depend on touch input.

### Avoid unnecessary edits to upstream files

Prefer additive files, manifest overlays, capability services, and adaptive widgets. This is specifically to make future upstream Medito updates easier to merge.

### Keep APK workflows for existing uses; add AAB for Play TV

Do not remove the existing APK build merely because TV requires an AAB. APK remains useful for current phone smoke tests/sideloading. The production release pipeline still needs a proper AAB upload path before Play TV release.

### TV CI must not depend on Medito production secrets

The fork does not have upstream production secrets. The first TV CI run failed while trying to read `PROD_ENV`, before it reached Android compilation. The TV workflow was changed to create throwaway/compile-only configuration and build with `MOCK_MODE=true`.

### PWA work is not part of the current TV branch

The earlier PWA experiments remain isolated. Current priority is Android TV / Google TV. Do not continue web compatibility work while this TV milestone is active unless a change directly supports the shared TV architecture.

## Known gaps / not yet complete

### Verification on real hardware

`ANDROID_TV_TEST_PLAN.md` is the acceptance checklist. It has to be re-run on a
physical Android TV / Google TV after the upstream sync, because the merge
changed the shared sign-in form and navigation host.

### Live-data testing

The fork has no Medito keys. Per Medito, live testing happens through a Google
Play internal-track build once mock mode is accepted.

### TV donation prompt

Donations are hidden on TV. The planned QR-code support card is described in
`TV_TESTING_BACKLOG.md` and is not built.

### Downloads on TV

Library shows favorites only. There is no TV surface for downloading or for
playing downloaded sessions offline.

### Automated TV journey test

The emulator smoke test proves launch and liveness under D-pad input, not the
Home -> meditation -> player -> Back journey, and it does not run on push.

### Production release path

- confirm the same AAB serves phone and TV, or configure Play form-factor targeting
- enable the TV form factor in Play Console and supply TV listing assets
- run production-signing validation on an internal track
