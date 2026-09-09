# Android TV / Google TV progress

_Last updated: 2026-09-09_

## Scope and branch

- Working branch: `feature/android-tv-support`
- Base branch: `develop`
- Do not open the pull request until the Android TV build is functionally usable.
- PWA/web work is intentionally shelved on the separate `feature/pwa-tv-foundation` branch. Do not merge that branch into this work unless a specific reusable change is deliberately selected.
- Goal for this branch: add Google Play TV / Android TV support while preserving the existing Android phone/tablet behavior and keeping upstream Medito merges as low-conflict as practical.

## Current stopping point

The project has moved past the initial audit and into functional Android TV implementation. The Play/launcher foundation, runtime TV capability detection, first TV navigation adaptation, and TV-specific AAB CI gate are implemented.

At the last code checkpoint before this documentation update, `feature/android-tv-support` was 11 commits ahead of `develop` and 0 commits behind it. The base commit was `987403182ab28a83b88ac115655a3ef48849f159`.

The latest code CI run at the time of this checkpoint is GitHub Actions run `34409997037` (`Android TV Build`). It had passed checkout, Java/Flutter setup, and `flutter pub get`, and was running `build_runner`. The previous CI failure was not an Android TV code failure; it stopped before compilation because the fork did not have Medito production secrets. That dependency has been removed from the TV CI workflow by generating compile-only configuration locally in the runner.

When resuming, check the newest `Android TV Build` run first. If it failed, fix that failure before adding more TV UI work.

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

This is only the first navigation adaptation. Individual screens still need a focus/D-pad audit.

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
9. Uploads the generated AAB as a workflow artifact.
10. Uses workflow concurrency so newer branch pushes supersede obsolete TV builds.

The CI AAB is a compile/manifest validation artifact, not a production-signed release artifact.

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

### D-pad and focus audit

Still needs explicit testing/fixes for:

- Home
- Explore/search
- pack/path screens
- meditation/player screen
- Favorites/downloads as applicable
- Settings
- authentication/onboarding screens
- dialogs, sheets, and confirmation prompts

Requirements include:

- predictable four-way focus movement
- clear visible focused state
- no focus traps
- focus restoration after navigating back
- correct scrolling when focused content moves off screen
- no touch-only interactions required for core flows

### Player / media remote behavior

Still needs validation for:

- center/select play/pause
- hardware/media play-pause
- seek/skip behavior
- D-pad interaction with player controls
- Back behavior
- background playback/media session behavior on TV

The existing Android Media3/audio infrastructure is a useful base, but TV remote behavior has not yet been proven end-to-end.

### TV layout / 10-foot UI

The app is not yet fully adapted for TV viewing distance. Individual screens still need review for:

- landscape composition
- readable text sizes
- focus-target size
- horizontal/vertical spacing
- safe areas/overscan-like margins where appropriate
- avoiding phone-centric layouts that look sparse or narrow on a television

Do not globally force landscape on the entire shared Android app until the TV-only behavior has been tested; phone behavior must remain unchanged.

### Phone-only features need capability gating review

Review whether these should be hidden, disabled, or left alone on TV:

- Health Connect
- home-screen widgets
- dynamic app icons
- payment/donation flows where the UX is unsuitable for TV
- reminder/exact-alarm flows
- notification permission prompts
- sharing flows

Do not remove these from the Android phone application.

### Android TV emulator CI

The current TV workflow validates the AAB and merged manifest but does not yet boot an Android TV / Google TV emulator.

A later CI job should validate at minimum:

1. TV launcher can discover/start Medito.
2. Home renders.
3. D-pad can reach top-level navigation.
4. User can browse to meditation content.
5. User can enter the player.
6. Play/pause works.
7. Back returns to the expected screen.
8. Focus does not become lost/trapped.

Keep the existing Pixel 6 phone smoke test separate rather than replacing it.

### Production release path

Still needed:

- add production `flutter build appbundle --flavor prod --release ...`
- retain current APK output if useful
- update Fastlane/Play upload to support the AAB
- determine whether the same AAB is used for phone + TV or Play form-factor targeting is configured separately
- run final production-signing validation

### Play Console work

After the application is functionally TV-ready:

- enable/configure the TV form factor in Google Play Console
- provide TV screenshots/listing assets as required
- validate current Play TV quality/policy checks
- submit to an internal/closed test track before production

Re-check current Play Console UI/instructions at release time because those steps can change.

## Recommended next steps when resuming

1. **Check the latest `Android TV Build` result.** Fix CI until the AAB and merged-manifest checks are green.
2. **Add Android TV / Google TV emulator smoke testing.** This gives us a real remote/focus feedback loop.
3. **Audit Home and Explore first.** They are the first screens needed for the primary browse flow.
4. **Audit pack/path -> player.** Establish the complete `Home/Explore -> meditation -> player` route with D-pad only.
5. **Fix player remote/media-key behavior.** This is the core functional TV experience.
6. **Then address secondary settings/features and 10-foot layout polish.**
7. **Only after the app is functionally usable, integrate production AAB release/Play Console work and open the PR.**

## Definition of the next functional milestone

The next meaningful milestone is not “all TV screens polished.” It is:

> On an Android TV / Google TV emulator, Medito launches from the TV launcher and can be operated with only a remote from Home/Explore through selecting a meditation, entering the player, starting/pausing playback, and navigating Back without losing focus.

Until that works, remain on `feature/android-tv-support` and do not open the PR.
