# Local Android TV / Google TV development (Windows)

This guide is for contributors who want to run Medito locally on an Android TV
or Google TV emulator without Medito production credentials.

## Recommended setup

Use:

- Windows 11
- Android Studio
- Flutter stable compatible with the repository
- JDK 17
- an **x86_64** Android TV / Google TV emulator
- the branch `feature/android-tv-support`

Do not use a 32-bit Android `x86` TV image for Flutter runtime testing.
Flutter supports Android x86_64, ARM32, and ARM64, but not legacy 32-bit x86.

## One-time repository bootstrap

From the repository root:

```powershell
git fetch origin
git switch feature/android-tv-support
git pull

.\scripts\setup-tv-dev.ps1
```

The setup script is designed to replace the manual local setup steps that were
previously required.

It will:

1. Locate Flutter (defaults to `C:\src\flutter`).
2. Locate an installed JDK 17.
3. Configure Flutter to use JDK 17 for Gradle.
4. Set `JAVA_HOME` for the script process.
5. Check for Android SDK command-line tools.
6. Verify/install the required NDK `28.2.13676358`.
7. Create the standard Android debug keystore if needed.
8. Create a gitignored `android/keystore.properties`.
9. Create a gitignored dummy `android/app/google-services.json` containing
   mock entries for both the prod and dev package IDs.
10. Run `flutter pub get`.
11. Run build_runner to generate Riverpod / Freezed / JSON code.
12. Run Pigeon to generate Medito's native audio bindings.
13. Print devices visible to Flutter.

The generated signing/Firebase files are for local mock development only and
must never be treated as production configuration.

### If Flutter is installed somewhere else

```powershell
.\scripts\setup-tv-dev.ps1 -FlutterSdk "D:\tools\flutter"
```

### If JDK 17 must be specified manually

```powershell
.\scripts\setup-tv-dev.ps1 -JdkDir "C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot"
```

### Clean rebuild

```powershell
.\scripts\setup-tv-dev.ps1 -Clean
```

## Run Medito on the TV emulator

Start the x86_64 TV AVD in Android Studio, then run:

```powershell
.\scripts\run-tv-mock.ps1
```

The launcher automatically looks for a supported Android emulator and runs:

- mock configuration from `.mock.json`
- `MOCK_MODE=true`
- debug build
- `dev` flavor by default

It deliberately does **not** use `--start-paused`, so the app should launch
normally on the emulator.

### Choose a specific emulator

```powershell
.\scripts\run-tv-mock.ps1 -DeviceId emulator-5554
```

### Test the prod package shape with mock data

```powershell
.\scripts\run-tv-mock.ps1 -Flavor prod
```

### Force setup/code generation again

```powershell
.\scripts\run-tv-mock.ps1 -RefreshSetup
```

## Android Studio

The scripts do not replace Android Studio. Android Studio is still useful for:

- creating/starting the TV AVD
- viewing the Running Devices window
- debugging
- hot reload
- Logcat

After running `setup-tv-dev.ps1`, the normal Flutter run configuration can
also be used. For mock TV work, use:

```text
Entrypoint: lib/main.dart
Flavor: dev
Additional args:
--dart-define-from-file=.mock.json --dart-define=MOCK_MODE=true
```

## Keyboard controls

When the emulator has focus:

- Arrow keys: D-pad
- Enter: center/select
- Escape: Back

The TV implementation must remain usable with these controls without requiring
touch or mouse input for the core flow.

## Common failures

### `Unsupported class file major version 69`

Flutter/Gradle is using Java 25. Run the setup script; it configures Flutter to
use JDK 17.

### `JAVA_HOME is set to an invalid directory`

The configured JDK folder no longer exists or was guessed incorrectly. The
setup script auto-detects the installed JDK 17, or pass `-JdkDir`.

### `keystore.properties file not found`

Run:

```powershell
.\scripts\setup-tv-dev.ps1
```

The project currently reads `keystore.properties` even for debug builds, so
the script creates a safe local debug configuration.

### Hundreds of missing `.g.dart` / `.freezed.dart` errors

Generated code is missing. Run:

```powershell
.\scripts\setup-tv-dev.ps1
```

That runs both build_runner and Pigeon.

### `cmdline-tools component is missing`

In Android Studio:

```text
Tools -> SDK Manager -> SDK Tools
-> Android SDK Command-line Tools (latest)
```

Install it, then rerun the setup script.


### `Package ndk not found` / Gradle fails while auto-installing NDK

The project currently requires NDK `28.2.13676358`. New Android command-line
tools deprecate `sdkmanager` in favor of the Android CLI, and the compatibility
shim can fail while Gradle tries the legacy `ndk;28.2.13676358` syntax.

Pull the latest TV branch and rerun:

```powershell
.\scripts\setup-tv-dev.ps1
```

The setup script installs the NDK before Gradle runs. It prefers the current
Android CLI and falls back to legacy `sdkmanager` when appropriate. The script
validates success from the installed NDK files rather than relying only on the
installer process exit code, because current Android tooling can occasionally
return a non-zero status even after a package has been unpacked successfully.

If automatic installation still fails, use Android Studio:

```text
Tools -> SDK Manager -> SDK Tools
-> Show Package Details
-> NDK (Side by side)
-> 28.2.13676358
-> Apply
```

Then rerun the setup script.

### Emulator appears as `unsupported` in `flutter devices`

The emulator is probably a 32-bit Android `x86` image. Create an x86_64 TV
AVD instead.

## CI relationship

Local development and CI intentionally use the same model:

- Java 17
- generated Riverpod/Freezed/JSON code
- generated Pigeon bindings
- mock configuration
- no Medito production credentials
- Android TV / Google TV runtime validation

CI uses a Google TV x86_64 system image. Local developers should also prefer
x86_64 so CI and local behavior are comparable.
