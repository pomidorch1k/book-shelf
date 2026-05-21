$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "=== Книжная полка: сборка APK ===" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter не найден. Установите: https://docs.flutter.dev/get-started/install"
}

flutter pub get
flutter build apk --release

$apk = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    Write-Host "`nГотово: $apk" -ForegroundColor Green
} else {
    Write-Error "APK не найден после сборки"
}
