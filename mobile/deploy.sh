#!/bin/bash
# Deploy APK to Firebase App Distribution (Bash version for Mac/Linux)

set -e

APP_ID=$1
RELEASE_NOTES=${2:-"Update terbaru"}
GROUPS=${3:-"qa-team"}

if [ -z "$APP_ID" ]; then
    echo "Usage: ./deploy.sh <AppId> [ReleaseNotes] [Groups]"
    exit 1
fi

echo "==============================================="
echo " MENGAMBIL BUILD APK (Flutter Build Release)   "
echo "==============================================="

flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "$APK_PATH" ]; then
    echo "File APK tidak ditemukan di $APK_PATH"
    exit 1
fi

echo -e "\n==============================================="
echo " UPLOAD KE FIREBASE APP DISTRIBUTION           "
echo "==============================================="

echo "App ID: $APP_ID"
echo "Groups: $GROUPS"
echo "Notes : $RELEASE_NOTES"

npx firebase-tools appdistribution:distribute "$APK_PATH" --app "$APP_ID" --release-notes "$RELEASE_NOTES" --groups "$GROUPS"

if [ $? -eq 0 ]; then
    echo -e "\n✅ Distribusi Berhasil!"
else
    echo -e "\n❌ Distribusi Gagal! Pastikan Firebase CLI sudah login ('npx firebase-tools login')."
fi
