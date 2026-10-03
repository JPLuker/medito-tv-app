#requires -Version 5.1
<#
.SYNOPSIS
Runs Medito TV against the real staging or production backend.

.DESCRIPTION
Unlike run-tv-mock.ps1, this script never creates or overwrites Firebase or
other local credential files. It expects the real Medito environment config to
already exist on the machine.

.EXAMPLE
  .\scripts\run-tv-live.ps1 -Environment production -DeviceId 192.168.86.171:5555

.EXAMPLE
  .\scripts\run-tv-live.ps1 -Environment staging
#>

[CmdletBinding()]
param(
    [string]$FlutterSdk = "C:\src\flutter",
    [ValidateSet("staging", "production")]
    [string]$Environment = "staging",
    [string]$DeviceId
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$FlutterBat = Join-Path $FlutterSdk "bin\flutter.bat"

if (-not (Test-Path $FlutterBat)) {
    throw "Flutter not found at '$FlutterSdk'. Pass -FlutterSdk with the Flutter SDK directory."
}

$Flavor = if ($Environment -eq "production") { "prod" } else { "dev" }
$ConfigFile = if ($Environment -eq "production") { ".prod.json" } else { ".staging.json" }

Push-Location $RepoRoot
try {
    $configPath = Join-Path $RepoRoot $ConfigFile
    if (-not (Test-Path $configPath)) {
        throw @"
Real Medito environment config is missing: $ConfigFile

Mock mode can run without secrets, but live mode needs the real values for:
  APP_KEY
  CONTENT_BASE_URL
  AUTH_URL
  EDIT_STATS_URL
  DONATION_BASE_URL
  DONATION_TOKEN
  ENVIRONMENT

Obtain the appropriate $ConfigFile contents from a Medito maintainer and keep
that file local / uncommitted.
"@
    }

    $googleServices = Join-Path $RepoRoot "android\app\google-services.json"
    if (-not (Test-Path $googleServices)) {
        throw "android/app/google-services.json is missing. Live mode needs Medito's real Firebase Android config."
    }

    $googleServicesText = Get-Content $googleServices -Raw
    if ($googleServicesText -match '000000000000|123456789|medito-tv-local|medito-tv-ci|mock-api-key|dummy-api-key') {
        throw @"
android/app/google-services.json is still the mock/CI placeholder.
Live mode needs the real Medito Firebase Android configuration.
Do not run setup-tv-dev.ps1 after installing the real file unless that script
has first been updated not to overwrite existing local config.
"@
    }

    $firebaseOptions = Join-Path $RepoRoot "lib\firebase_options.dart"
    if (-not (Test-Path $firebaseOptions)) {
        throw "lib/firebase_options.dart is missing. Live mode needs Medito's real Firebase options file."
    }

    $firebaseOptionsText = Get-Content $firebaseOptions -Raw
    if ($firebaseOptionsText -match 'Dummy firebase_options|mock-api-key|mock-app-id|mock-project-id') {
        throw @"
lib/firebase_options.dart is still the contributor/mock placeholder.
Live mode needs Medito's real Firebase options file.
Obtain it from a Medito maintainer and keep production credentials out of git.
"@
    }

    foreach ($generatedFile in @(
        "lib\src\audio_pigeon.g.dart"
    )) {
        if (-not (Test-Path (Join-Path $RepoRoot $generatedFile))) {
            throw "Generated file '$generatedFile' is missing. Run the normal code-generation steps first."
        }
    }

    if (-not $DeviceId) {
        $deviceJson = & $FlutterBat devices --machine
        if ($LASTEXITCODE -ne 0) {
            throw "Could not list Flutter devices."
        }

        $devices = $deviceJson | ConvertFrom-Json
        $tvCandidates = @(
            $devices | Where-Object {
                $_.isSupported -ne $false -and
                $_.targetPlatform -like "android-*" -and
                (
                    $_.name -match "(?i)tv|shield|atv|television|amati" -or
                    $_.id -match "^emulator-"
                )
            }
        )

        if ($tvCandidates.Count -eq 0) {
            & $FlutterBat devices
            throw "No supported Android TV / Google TV device was detected. Pass -DeviceId explicitly if ADB is already connected."
        }

        $DeviceId = $tvCandidates[0].id
    }

    Write-Host ""
    Write-Host "Launching Medito TV live-data build" -ForegroundColor Cyan
    Write-Host "  Environment : $Environment"
    Write-Host "  Config      : $ConfigFile"
    Write-Host "  Flavor      : $Flavor"
    Write-Host "  Device      : $DeviceId"
    Write-Host ""

    $runArgs = @(
        "run",
        "--device-id=$DeviceId",
        "--flavor", $Flavor,
        "--dart-define-from-file=$ConfigFile",
        "--debug",
        "lib\main.dart"
    )

    & $FlutterBat @runArgs
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
