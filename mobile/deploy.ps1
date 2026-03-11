<#
.SYNOPSIS
Deploy APK ke Firebase App Distribution

.DESCRIPTION
Script ini mem-build file APK menggunakan Flutter versi Release,
kemudian meng-upload-nya ke Firebase App Distribution menggunakan Firebase CLI.

.PARAMETER AppId
Firebase App ID (didapat dari Firebase Console > Project Settings > General)
Contoh: 1:1234567890:android:abcdef123456

.PARAMETER ReleaseNotes
Catatan rilis (Release Notes) untuk versi ini.
Default: "Minor updates and bug fixes."

.PARAMETER Groups
Grup tester yang dituju. Bisa dipisahkan dengan koma.
Default: "qa-team" (pastikan grup ini sudah dibuat di Firebase Console)

.EXAMPLE
.\deploy.ps1 -AppId "1:1234567890:android:abcdef123456" -ReleaseNotes "Fitur transaksi ditambahkan"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$AppId,

    [string]$ReleaseNotes = "Update terbaru",
    
    [string]$Groups = "qa-team"
)

$ErrorActionPreference = "Stop"
$CurrentDir = Get-Location

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " MENGAMBIL BUILD APK (Flutter Build Release)   " -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build APK Gagal! Cek log error di atas." -ForegroundColor Red
    exit 1
}

$ApkPath = "build\app\outputs\flutter-apk\app-release.apk"

if (-Not (Test-Path $ApkPath)) {
    Write-Host "File APK tidak ditemukan di $ApkPath" -ForegroundColor Red
    exit 1
}

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host " UPLOAD KE FIREBASE APP DISTRIBUTION           " -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

Write-Host "App ID: $AppId"
Write-Host "Groups: $Groups"
Write-Host "Notes : $ReleaseNotes"

npx firebase appdistribution:distribute $ApkPath --app $AppId --release-notes "$ReleaseNotes" --groups "$Groups"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Distribusi Berhasil!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Distribusi Gagal! Pastikan Firebase CLI sudah login ('firebase login')." -ForegroundColor Red
}
