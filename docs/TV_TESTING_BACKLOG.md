# Android TV testing backlog

This file tracks work deliberately deferred while the TV branch is in physical-device testing. The goal is to avoid destabilizing a usable tester build with unrelated dependency/toolchain churn.

## Next maintenance build

- Upgrade Gradle from 8.14.3 to a Flutter-supported newer release after confirming the matching Android Gradle Plugin requirements.
- Upgrade Android Gradle Plugin from 8.11.1 to the supported target recommended by the current Flutter toolchain.
- Audit the currently reported discontinued Dart/Flutter package and replace it if appropriate.
- Review outdated dependencies selectively. Do not run a blind mass-upgrade; keep upstream Medito compatibility and test each risky dependency change.
- Regression-test both Android phone/tablet and Android TV after the Gradle/AGP/dependency maintenance pass.

## TV donation UX

Keep Medito's donation opportunity on TV, but do not restore the phone payment form/webview.

Planned TV behavior after an eligible completed meditation:

- Show a calm, TV-scaled support card/dialog using the same donation eligibility/cadence logic as the mobile app where possible.
- Explain that Medito is free and donor-supported.
- Render a large QR code containing the configured Medito donation destination.
- The QR code is the donation action; the payment transaction happens on the user's phone.
- Provide one obvious D-pad action such as `Done` / `Continue`, and support the remote Back button.
- Do not put email, amount entry, Stripe controls, browser navigation, or other phone-style payment controls on TV.
- Avoid showing the prompt after every session if the existing mobile cadence says not to ask.
- Prefer a backend/configured donation URL over a hard-coded destination so Medito can change it without redesigning the TV UI.

## Physical-TV testing focus

While testing on NVIDIA Shield / Google TV hardware, prioritize reports for:

- D-pad traversal and focus restoration
- Back-button behavior
- account email/OTP input with the TV keyboard
- pack/path navigation
- player play/pause/seek and media-key behavior
- long meditation playback
- app background/foreground and TV sleep/wake
- audio continuation/interruption behavior
- favorites/account sync once a live-data build is available
- layout/readability at normal couch viewing distance

## Live-data testing

`scripts/run-tv-live.ps1` is the guarded non-mock runner. It intentionally refuses to start when the checkout still contains contributor/mock Firebase configuration.

Live testing requires local, uncommitted Medito configuration from a maintainer:

- `.staging.json` or `.prod.json`
- real `android/app/google-services.json`
- real `lib/firebase_options.dart`

Prefer staging for development when credentials are available. Production should only be used deliberately.
