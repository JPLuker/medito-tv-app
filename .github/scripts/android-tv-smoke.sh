#!/usr/bin/env bash
set -euo pipefail

APK="build/app/outputs/flutter-apk/app-prod-debug.apk"
PACKAGE="meditofoundation.medito"
ARTIFACT_DIR="/tmp/android-tv-smoke"

mkdir -p "$ARTIFACT_DIR"
test -f "$APK"

capture_diagnostics() {
  adb exec-out screencap -p > "$ARTIFACT_DIR/screenshot-final.png" 2>/dev/null || true
  adb shell uiautomator dump /sdcard/window.xml >/dev/null 2>&1 || true
  adb pull /sdcard/window.xml "$ARTIFACT_DIR/window.xml" >/dev/null 2>&1 || true
  adb logcat -d > "$ARTIFACT_DIR/logcat.txt" 2>/dev/null || true
}
trap capture_diagnostics EXIT

echo "Waiting for a stable Google TV ADB connection..."
adb wait-for-device
for _ in $(seq 1 30); do
  STATE=$(adb get-state 2>/dev/null || true)
  BOOTED=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
  if [ "$STATE" = "device" ] && [ "$BOOTED" = "1" ]; then
    break
  fi
  sleep 2
done

test "$(adb get-state 2>/dev/null)" = "device"
test "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1"

# The stock headless Google TV AVD can boot with a 320x640 generic skin. That
# is not representative of the app's target and makes screenshots/focus tests
# meaningless, so force a normal 1080p television viewport before launch.
adb shell wm size 1920x1080
adb shell wm density 320
sleep 2

echo "Effective display geometry:"
adb shell wm size
adb shell wm density

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

# Do not use `am start -W` here. On the headless Google TV image it can return
# a timeout even when MainActivity has launched and the app process is healthy.
adb shell am start \
  -a android.intent.action.MAIN \
  -c android.intent.category.LEANBACK_LAUNCHER \
  -n "$PACKAGE/.MainActivity" || true

PID=""
for _ in $(seq 1 30); do
  PID=$(adb shell pidof "$PACKAGE" 2>/dev/null | tr -d '\r' || true)
  if [ -n "$PID" ]; then
    break
  fi
  sleep 2
done

if [ -z "$PID" ]; then
  echo "Medito process never became available after launch"
  exit 1
fi

echo "Medito PID: $PID"

# Give Flutter enough time to paint its first frame, then preserve a baseline
# screenshot before exercising D-pad traversal.
sleep 8
adb exec-out screencap -p > "$ARTIFACT_DIR/home.png" 2>/dev/null || true

# Exercise the TV focus graph without making exact screen coordinates a brittle
# CI requirement. A later process check catches navigation-triggered crashes.
adb shell input keyevent KEYCODE_DPAD_RIGHT || true
sleep 1
adb shell input keyevent KEYCODE_DPAD_DOWN || true
sleep 1
adb shell input keyevent KEYCODE_DPAD_LEFT || true
sleep 1
adb shell input keyevent KEYCODE_DPAD_UP || true
sleep 1
adb shell input keyevent KEYCODE_DPAD_RIGHT || true
sleep 1
adb shell input keyevent KEYCODE_DPAD_CENTER || true
sleep 4
adb exec-out screencap -p > "$ARTIFACT_DIR/after-navigation.png" 2>/dev/null || true

PID_AFTER=$(adb shell pidof "$PACKAGE" 2>/dev/null | tr -d '\r' || true)
if [ -z "$PID_AFTER" ]; then
  echo "Medito process died while exercising D-pad navigation"
  exit 1
fi

adb logcat -d > "$ARTIFACT_DIR/logcat.txt" 2>/dev/null || true

if grep -E 'FATAL EXCEPTION|Process: meditofoundation\.medito.*has died' \
  "$ARTIFACT_DIR/logcat.txt"; then
  echo "Medito crashed during Google TV smoke test"
  exit 1
fi

echo "Google TV smoke test passed"
