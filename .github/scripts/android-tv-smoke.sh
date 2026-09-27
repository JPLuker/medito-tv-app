#!/usr/bin/env bash
set -euo pipefail

APK="build/app/outputs/flutter-apk/app-prod-debug.apk"
PACKAGE="meditofoundation.medito"

test -f "$APK"
adb install -r "$APK"

echo "Google TV system features:"
adb shell pm list features | grep -E 'leanback|television|touchscreen|faketouch' || true
adb shell pm list features | grep -q 'feature:android.software.leanback'

echo "Resolving Leanback launcher activity:"
RESOLVED=$(adb shell cmd package resolve-activity --brief \
  -a android.intent.action.MAIN \
  -c android.intent.category.LEANBACK_LAUNCHER \
  "$PACKAGE" | tr -d '\r')
echo "$RESOLVED"
echo "$RESOLVED" | grep -q 'meditofoundation.medito/.MainActivity'

adb logcat -c
adb shell am start -W \
  -a android.intent.action.MAIN \
  -c android.intent.category.LEANBACK_LAUNCHER \
  -n "$PACKAGE/.MainActivity"
sleep 10

adb shell input keyevent KEYCODE_DPAD_RIGHT
adb shell input keyevent KEYCODE_DPAD_DOWN
adb shell input keyevent KEYCODE_DPAD_LEFT
adb shell input keyevent KEYCODE_DPAD_UP
sleep 2

adb shell pidof "$PACKAGE"

mkdir -p /tmp/android-tv-smoke
adb exec-out screencap -p > /tmp/android-tv-smoke/screenshot.png
adb shell uiautomator dump /sdcard/window.xml || true
adb pull /sdcard/window.xml /tmp/android-tv-smoke/window.xml || true
adb logcat -d > /tmp/android-tv-smoke/logcat.txt

if grep -E 'FATAL EXCEPTION|Process: meditofoundation.medito.*has died' \
  /tmp/android-tv-smoke/logcat.txt; then
  echo "Medito crashed during Google TV smoke test"
  exit 1
fi
