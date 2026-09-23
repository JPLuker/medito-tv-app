#requires -Version 5.1
<#
.SYNOPSIS
Runs Medito in mock mode on a connected Android TV / Google TV emulator.

.EXAMPLE
  .\scripts\run-tv-mock.ps1

.EXAMPLE
  .\scripts\run-tv-mock.ps1 -DeviceId emulator-5554

.EXAMPLE
  .\scripts\run-tv-mock.ps1 -Flavor prod
#>

[CmdletBinding()]
param(
    [string]$FlutterSdk = "C:\src\flutter",
    [string]$DeviceId,
    [ValidateSet("dev", "prod")]
    [string]$Flavor = "dev",
    [switch]$RefreshSetup
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$FlutterBat = Join-Path $FlutterSdk "bin\flutter.bat"
$SetupScript = Join-Path $PSScriptRoot "setup-tv-dev.ps1"

if (-not (Test-Path $FlutterBat)) {
    throw "Flutter not found at '$FlutterSdk'. Pass -FlutterSdk with the Flutter SDK directory."
}

Push-Location $RepoRoot
try {
    $requiredLocalFiles = @(
        "android\keystore.properties",
        "android\app\google-services.json",
        "lib\src\audio_pigeon.g.dart"
    )

    $needsSetup = $RefreshSetup
    foreach ($file in $requiredLocalFiles) {
        if (-not (Test-Path (Join-Path $RepoRoot $file))) {
            $needsSetup = $true
            break
        }
    }

    if ($needsSetup) {
        Write-Host "Local TV build prerequisites are missing or refresh was requested." -ForegroundColor Yellow
        & $SetupScript -FlutterSdk $FlutterSdk
        if ($LASTEXITCODE -ne 0) {
            throw "TV setup failed."
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
                    $_.name -match "(?i)tv|atv|television|amati" -or
                    $_.id -match "^emulator-"
                )
            }
        )

        if ($tvCandidates.Count -eq 0) {
            Write-Host "Flutter can currently see these devices:" -ForegroundColor Yellow
            & $FlutterBat devices
            throw "No supported Android TV emulator was detected. Start an x86_64 Android TV / Google TV AVD and retry, or pass -DeviceId explicitly."
        }

        $DeviceId = $tvCandidates[0].id
        if ($tvCandidates.Count -gt 1) {
            Write-Warning "Multiple Android emulator candidates were found. Using '$DeviceId'. Pass -DeviceId to choose another."
        }
    }

    Write-Host ""
    Write-Host "Launching Medito TV mock build" -ForegroundColor Cyan
    Write-Host "  Branch : $((& git branch --show-current).Trim())"
    Write-Host "  Device : $DeviceId"
    Write-Host "  Flavor : $Flavor"
    Write-Host ""

    $runArgs = @(
        "run",
        "--device-id=$DeviceId",
        "--flavor", $Flavor,
        "--dart-define-from-file=.mock.json",
        "--dart-define=MOCK_MODE=true",
        "--debug",
        "lib\main.dart"
    )

    & $FlutterBat @runArgs
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
