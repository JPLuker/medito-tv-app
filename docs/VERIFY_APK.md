# How to verify Medito APK before installing to your devices

## Using keytool

```
keytool -printcert -jarfile medito.apk
```
The output certificate fingerprints should match:
```
Signer #1:

Signature:

Owner: OU=Medito Foundation
Issuer: OU=Medito Foundation
Serial number: 3d33b57b
Valid from: Mon May 24 20:00:02 CEST 2021 until: Fri May 18 20:00:02 CEST 2046
Certificate fingerprints:
	 SHA1: 4F:55:86:C3:E5:97:6B:8C:4B:FB:C4:3C:5D:64:EF:F3:62:C5:13:91
	 SHA256: 49:CD:5F:E2:57:DA:4B:DC:AB:20:0E:17:23:F0:4F:18:BB:CD:E2:D3:49:DE:14:50:44:76:0E:CC:79:0A:63:D3
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions: 

#1: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: A9 A3 8F 23 30 75 E3 14   6F FC 9B B3 35 6D 4E F2  ...#0u..o...5mN.
0010: 7F F2 DB 9F                                        ....
]
]

```

## Using apksigner

```
apksigner verify --print-certs medito.apk
```

The output certificate fingerprints should match:
```
// TODO: add Medito certificate fingerprints
```

---

# Android App Bundle / Android TV verification

Google Play TV distribution uses an Android App Bundle (`.aab`) rather than the APK-only release path used by older Medito workflows.

The Android TV work is tracked in `docs/ANDROID_TV_PROGRESS.md`.

## Build an AAB

For a real release, use the normal production configuration and signing material:

```bash
flutter build appbundle --flavor prod --release \
  --dart-define-from-file=.prod.json \
  --dart-define=MOCK_MODE=false \
  --obfuscate --split-debug-info=./symbols
```

Expected output is under:

```text
build/app/outputs/bundle/
```

The `feature/android-tv-support` CI workflow also builds a compile-only/mock AAB. That artifact is intended to prove the code and manifest merge; it is **not** a production release artifact and uses throwaway CI signing/configuration.

## Verify the AAB signature container

An AAB is JAR-signed. To inspect/verify the local bundle container:

```bash
jarsigner -verify -verbose -certs path/to/app.aab
```

For Play-distributed installs, remember that Google Play App Signing may sign generated APKs with the Play app-signing key rather than the local/upload key used for the AAB. Do not assume the final device APK fingerprint will necessarily equal the local AAB upload-key fingerprint.

## Verify the Android TV manifest declarations

Using `bundletool`:

```bash
bundletool dump manifest \
  --bundle=path/to/app.aab \
  --module=base > /tmp/medito-tv-manifest.xml
```

Then confirm the TV requirements:

```bash
grep 'android.software.leanback' /tmp/medito-tv-manifest.xml
grep 'android.hardware.touchscreen' /tmp/medito-tv-manifest.xml
grep 'android.hardware.faketouch' /tmp/medito-tv-manifest.xml
grep 'android.intent.category.LEANBACK_LAUNCHER' /tmp/medito-tv-manifest.xml
grep 'tv_banner' /tmp/medito-tv-manifest.xml
```

For the combined phone + TV application, the expected feature policy is:

```text
android.software.leanback      required=false
android.hardware.touchscreen   required=false
android.hardware.faketouch     required=false
```

`MainActivity` must expose `android.intent.category.LEANBACK_LAUNCHER` for TV launcher discovery.

## Verify the TV banner source asset

The current launcher banner is:

```text
android/app/src/main/res/drawable-xhdpi/tv_banner.png
```

Expected dimensions:

```text
320x180
```

The release/debug TV manifest overlays should reference it as:

```xml
android:banner="@drawable/tv_banner"
```

## CI verification

`.github/workflows/android-tv-build.yml` automatically:

1. builds a release-mode `prod` AAB with mock/compile-only configuration,
2. finds the merged manifest,
3. checks for the Leanback/touch/faketouch/launcher/banner declarations, and
4. uploads the resulting AAB artifact.

A green Android TV CI build is required before treating the TV manifest/AAB foundation as complete.
