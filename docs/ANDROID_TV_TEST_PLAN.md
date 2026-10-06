# Android TV Mock Acceptance Plan

This checklist defines what contributor mock mode should prove before the TV branch is handed to an internal Google Play test track.

Mock mode is intended to validate the complete television interaction model: 10-foot layout, D-pad focus, navigation, playback controls, local favorites/settings, ambient sound UI, and completion flow. It does **not** prove live Firebase/API credentials, production authentication delivery, or Play-distributed signing.

## Automated CI gate

Every push to `feature/android-tv-support` must:

- pass `flutter analyze`
- build the production-flavor Android TV AAB with mock configuration
- verify the merged manifest contains the Leanback launcher and keeps Leanback/touch features optional for the combined phone/TV bundle
- build an installable debug APK
- boot a Google TV emulator at a 1920x1080 TV viewport
- verify the Leanback launcher resolves to `MainActivity`
- launch Medito without relying on `am start -W`
- keep the Medito process alive while D-pad navigation is exercised
- fail if logcat reports a fatal Medito crash
- upload baseline and post-navigation screenshots/logcat as smoke artifacts

## Manual TV acceptance

Use `scripts/run-tv-mock.ps1` on a physical Android TV / Google TV device when possible.

### Shell and navigation

- [ ] App launches from the television launcher/banner.
- [ ] Home receives predictable initial focus.
- [ ] Up/Down moves through the sidebar; Right enters page content.
- [ ] Focus is always visible from couch distance.
- [ ] Home, Explore, Search, Library, and Settings all use the same bounded adaptive visual language as the tablet/foldable app.
- [ ] Remote Back returns from nested screens without requiring an on-screen Back control.
- [ ] Remote Back from a non-Home root destination returns to Home.

### Home and packs

- [ ] Up Next opens the next mock session.
- [ ] Featured and Quick Access rows scroll with the D-pad and never trap focus.
- [ ] Pack pages remain readable at 10 feet and session rows are reachable in order.
- [ ] Completed session indicators are visible.
- [ ] Mark-all-complete/incomplete works.

### Meditation detail

`Body Scan` is the main mock acceptance session.

- [ ] 16:9 artwork, title and description match the adaptive tablet hierarchy.
- [ ] `Alex` and `Sam` guide choices are selectable.
- [ ] The short mock duration displays as `15 sec`, not `0 min`.
- [ ] Save to favorites is beside the primary action and can be toggled without crossing the screen.
- [ ] Play opens the TV player.

### TV player

- [ ] Layout matches the wide tablet player: metadata left, progress/transport right, blurred artwork background.
- [ ] Play/Pause works from the focused control and from media keys.
- [ ] Back 10 / Forward 10 work.
- [ ] Playback speed cycles correctly.
- [ ] Repeat cycles Off -> Once -> On -> Off.
- [ ] Ambient sound opens a TV-native chooser.
- [ ] Rain / Forest / White Noise can be selected and None stops ambient playback.
- [ ] The 15-second sample reaches the TV completion screen.
- [ ] Done returns to the meditation detail screen.
- [ ] Remote Back exits the player and stops/resets playback.

### Search

- [ ] TV keyboard can enter a query.
- [ ] Pack results are focusable.
- [ ] Track results are focusable.
- [ ] Searching `body` returns Body Scan in mock mode.
- [ ] Selecting a result opens the correct TV detail route.

### Library

- [ ] Mock/local favorites are visible.
- [ ] Saving/removing a meditation updates Library.
- [ ] Pack and meditation favorite cards route correctly.

### Settings and account

- [ ] Theme cards work with the remote.
- [ ] Playback default duration controls work.
- [ ] Analytics/privacy toggle works and its confirmation dialog is fully D-pad navigable.
- [ ] Sign-in form is scaled for TV.
- [ ] In mock mode the account screen explains that no email is sent and any six-digit OTP (for example `123456`) may be used.

## What still requires an internal Play build

After mock acceptance passes, an internal Google Play build should still verify:

- real staging/production API connectivity
- real OTP email delivery and authentication
- Firebase/Crashlytics initialization with real configuration
- Play signing/install/update behavior
- launcher/banner presentation on multiple physical TV OEMs
- long-session playback, audio focus, sleep/wake, and background/foreground transitions

Mock success is a strong UI/runtime signal, but it is not a substitute for this final live-environment pass.
