#requires -Version 5.1
<#
.SYNOPSIS
Prepares a Windows checkout of Medito for local Android TV / Google TV development.

.DESCRIPTION
Creates only local, gitignored development files. It does not use production
secrets and does not modify committed Android signing configuration.

Run from anywhere:
  .\scripts\setup-tv-dev.ps1
#>

[CmdletBinding()]
param(
    [string]$FlutterSdk = "C:\src\flutter",
    [string]$JdkDir,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$AndroidDir = Join-Path $RepoRoot "android"
$FlutterBat = Join-Path $FlutterSdk "bin\flutter.bat"

function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Require-Path([string]$Path, [string]$Description) {
    if (-not (Test-Path $Path)) {
        throw "$Description not found: $Path"
    }
}

function Find-Jdk17 {
    param([string]$Requested)

    if ($Requested) {
        if (Test-Path (Join-Path $Requested "bin\java.exe")) {
            return (Resolve-Path $Requested).Path
        }
        throw "The requested JDK does not contain bin\java.exe: $Requested"
    }

    $roots = @(
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Java",
        (Join-Path $env:USERPROFILE ".jdks")
    )

    $candidates = foreach ($root in $roots) {
        if (Test-Path $root) {
            Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Name -match '^jdk-17' -or
                    $_.Name -match '^temurin-17' -or
                    $_.Name -match '^17'
                } |
                Where-Object { Test-Path (Join-Path $_.FullName "bin\java.exe") }
        }
    }

    $best = $candidates |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($best) {
        return $best.FullName
    }

    throw @"
JDK 17 was not found.

Install it with:
  winget install EclipseAdoptium.Temurin.17.JDK

Then rerun this script, or pass its folder explicitly:
  .\scripts\setup-tv-dev.ps1 -JdkDir "C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot"
"@
}

Require-Path $FlutterBat "Flutter"
Require-Path $AndroidDir "Android project"

Push-Location $RepoRoot
try {
    $branch = (& git branch --show-current 2>$null).Trim()
    if ($LASTEXITCODE -eq 0 -and $branch -ne "feature/android-tv-support") {
        Write-Warning "Current branch is '$branch'. TV development is expected on 'feature/android-tv-support'."
    }

    Write-Step "Locating JDK 17"
    $ResolvedJdk = Find-Jdk17 -Requested $JdkDir
    Write-Host "Using JDK: $ResolvedJdk"

    $env:JAVA_HOME = $ResolvedJdk
    if ($env:Path -notlike "*$ResolvedJdk\bin*") {
        $env:Path = "$ResolvedJdk\bin;$env:Path"
    }

    & (Join-Path $ResolvedJdk "bin\java.exe") -version
    if ($LASTEXITCODE -ne 0) {
        throw "JDK 17 validation failed."
    }

    Write-Step "Configuring Flutter to use JDK 17"
    & $FlutterBat config --jdk-dir="$ResolvedJdk"
    if ($LASTEXITCODE -ne 0) {
        throw "flutter config failed."
    }

    $AndroidHome = if ($env:ANDROID_HOME) {
        $env:ANDROID_HOME
    } elseif ($env:ANDROID_SDK_ROOT) {
        $env:ANDROID_SDK_ROOT
    } else {
        Join-Path $env:LOCALAPPDATA "Android\sdk"
    }

    if (-not (Test-Path $AndroidHome)) {
        Write-Warning "Android SDK not found at '$AndroidHome'. Install it from Android Studio > Tools > SDK Manager."
    } else {
        $cmdlineTools = @(
            (Join-Path $AndroidHome "cmdline-tools\latest\bin\sdkmanager.bat"),
            (Join-Path $AndroidHome "cmdline-tools\latest\bin\android.bat"),
            (Join-Path $AndroidHome "cmdline-tools\latest\bin\android.exe")
        )
        if (-not ($cmdlineTools | Where-Object { Test-Path $_ })) {
            Write-Warning "Android SDK Command-line Tools were not detected. Install 'Android SDK Command-line Tools (latest)' in Android Studio > Tools > SDK Manager > SDK Tools."
        }
    }

    Write-Step "Preparing local debug signing"
    $AndroidUserDir = Join-Path $env:USERPROFILE ".android"
    $DebugKeystore = Join-Path $AndroidUserDir "debug.keystore"
    New-Item -ItemType Directory -Path $AndroidUserDir -Force | Out-Null

    if (-not (Test-Path $DebugKeystore)) {
        Write-Host "Creating standard Android debug keystore..."
        $keytoolArgs = @(
            "-genkeypair",
            "-keystore", $DebugKeystore,
            "-storepass", "android",
            "-alias", "androiddebugkey",
            "-keypass", "android",
            "-keyalg", "RSA",
            "-keysize", "2048",
            "-validity", "10000",
            "-dname", "CN=Android Debug,O=Android,C=US"
        )
        & (Join-Path $ResolvedJdk "bin\keytool.exe") @keytoolArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Could not create the Android debug keystore."
        }
    } else {
        Write-Host "Debug keystore already exists: $DebugKeystore"
    }

    $KeystoreProperties = Join-Path $AndroidDir "keystore.properties"
    $DebugKeystoreForGradle = $DebugKeystore.Replace("\", "/")
    @"
storePassword=android
keyPassword=android
keyAlias=androiddebugkey
storeFile=$DebugKeystoreForGradle
appId=meditofoundation.medito
versionCode=1
versionName=1.0.0
"@ | Set-Content -Path $KeystoreProperties -Encoding UTF8
    Write-Host "Wrote gitignored local config: android/keystore.properties"

    Write-Step "Preparing dummy Firebase config for mock mode"
    $GoogleServices = Join-Path $AndroidDir "app\google-services.json"
    @'
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "medito-tv-local",
    "storage_bucket": "medito-tv-local.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:0000000000000000",
        "android_client_info": {
          "package_name": "meditofoundation.medito"
        }
      },
      "api_key": [
        { "current_key": "mock-api-key" }
      ]
    },
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:0000000000000001",
        "android_client_info": {
          "package_name": "meditofoundation.medito.dev"
        }
      },
      "api_key": [
        { "current_key": "mock-api-key" }
      ]
    }
  ],
  "configuration_version": "1"
}
'@ | Set-Content -Path $GoogleServices -Encoding UTF8
    Write-Host "Wrote gitignored mock config: android/app/google-services.json"

    if ($Clean) {
        Write-Step "Cleaning Flutter build outputs"
        & $FlutterBat clean
        if ($LASTEXITCODE -ne 0) {
            throw "flutter clean failed."
        }
    }

    Write-Step "Resolving Flutter dependencies"
    & $FlutterBat pub get
    if ($LASTEXITCODE -ne 0) {
        throw "flutter pub get failed."
    }

    Write-Step "Generating Riverpod / Freezed / JSON code"
    & $FlutterBat pub run build_runner build
    if ($LASTEXITCODE -ne 0) {
        throw "build_runner failed."
    }

    Write-Step "Generating Pigeon Android/audio bindings"
    & $FlutterBat pub run pigeon --input pigeon_conf.dart --package_name=medito
    if ($LASTEXITCODE -ne 0) {
        throw "Pigeon generation failed."
    }

    Write-Step "Flutter-visible devices"
    & $FlutterBat devices

    Write-Host ""
    Write-Host "TV development setup is ready." -ForegroundColor Green
    Write-Host "Next: .\scripts\run-tv-mock.ps1"
}
finally {
    Pop-Location
}
