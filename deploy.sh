#!/usr/bin/env bash

# ================================================
# DEPLOY APK KE FIREBASE APP DISTRIBUTION
# ================================================
# Script ini otomatis:
# 1. Build APK release mode
# 2. Ambil release notes dari git commit HEAD
# 3. Upload ke Firebase App Distribution
#
# Cara penggunaan:
#   ./deploy.sh <FIREBASE_APP_ID> [GROUPS] [RELEASE_NOTES]
#
# Contoh:
#   ./deploy.sh "1:1234567890:android:abcdef123456" "qa-team"
#   ./deploy.sh "1:1234567890:android:abcdef123456" "internal-testers,qa-team" "Custom notes"
#
# Jika RELEASE_NOTES tidak diberikan, diambil dari git commit HEAD otomatis.

set -e  # Exit on error

# ================================================
# PARAMETER VALIDATION
# ================================================

if [ $# -lt 1 ]; then
    echo "❌ Error: Firebase App ID wajib diisi"
    echo ""
    echo "Cara penggunaan:"
    echo "  ./deploy.sh <FIREBASE_APP_ID> [GROUPS] [RELEASE_NOTES]"
    echo ""
    echo "Contoh:"
    echo "  ./deploy.sh \"1:1234567890:android:abcdef123456\" \"qa-team\""
    echo "  ./deploy.sh \"1:1234567890:android:abcdef123456\" \"internal-testers\""
    echo ""
    echo "Firebase App ID didapat dari:"
    echo "  Firebase Console > Project Settings > General > Your Apps"
    echo "  Format: 1:1234567890:android:abcdef123456"
    exit 1
fi

FIREBASE_APP_ID="$1"

# Default groups jika tidak diberi parameter
DEFAULT_GROUPS="qa-team"
DIST_GROUPS="${2:-$DEFAULT_GROUPS}"

# Release notes: jika tidak diberikan, ambil dari git HEAD
if [ $# -ge 3 ]; then
    RELEASE_NOTES="$3"
else
    echo "📝 Mengambil release notes dari git commit HEAD..."
    RELEASE_NOTES=$(git log -1 --pretty=format:"%s")
    if [ $? -ne 0 ] || [ -z "$RELEASE_NOTES" ]; then
        echo "❌ Error: Tidak bisa mendapatkan git commit message"
        echo "   Pastikan Anda berada di git repository"
        echo "   Atau berikan release notes manual sebagai parameter ketiga"
        exit 1
    fi
    echo "✅ Release notes: \"$RELEASE_NOTES\""
fi

# ================================================
# DEBUG: Tampilkan parameter
# ================================================
echo ""
echo "🔧 Parameter yang akan digunakan:"
echo "   Firebase App ID: $FIREBASE_APP_ID"
echo "   Groups: $DIST_GROUPS"
echo "   Release Notes: $RELEASE_NOTES"
echo ""

# ================================================
# BUILD APK
# ================================================

echo ""
echo "================================================"
echo "  [1/2] BUILDING APK (Flutter Release)"
echo "================================================"
echo ""

cd mobile

flutter build apk --release

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Build APK gagal! Cek log error di atas."
    exit 1
fi

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "$APK_PATH" ]; then
    echo ""
    echo "❌ File APK tidak ditemukan di: $APK_PATH"
    exit 1
fi

APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo ""
echo "✅ APK berhasil dibuild: $APK_PATH ($APK_SIZE)"

# ================================================
# FIREBASE DISTRIBUTION
# ================================================

echo ""
echo "================================================"
echo "  [2/2] UPLOAD KE FIREBASE APP DISTRIBUTION"
echo "================================================"
echo ""
echo "App ID:    $FIREBASE_APP_ID"
echo "Groups:    $DIST_GROUPS"
echo "Notes:     $RELEASE_NOTES"
echo ""

# Cek apakah firebase CLI tersedia
if ! command -v npx &> /dev/null; then
    echo "❌ Error: npx tidak ditemukan. Pastikan Node.js terinstal."
    exit 1
fi

# Check Firebase login
if ! npx firebase --version &> /dev/null; then
    echo "⚠️  Firebase CLI belum terinstal atau tidak dapat diakses"
    echo "   Installing Firebase CLI..."
    npm install -g firebase-tools
fi

echo "🚀 Mengupload APK ke Firebase App Distribution..."
echo ""

npx firebase appdistribution:distribute "$APK_PATH" \
    --app "$FIREBASE_APP_ID" \
    --release-notes "$RELEASE_NOTES" \
    --groups "$DIST_GROUPS"

if [ $? -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "  ✅ DISTRIBUSI BERHASIL!"
    echo "================================================"
    echo ""
    echo "APK berhasil diupload ke Firebase App Distribution"
    echo "Tester di grup \"$DIST_GROUPS\" akan menerima notifikasi."
else
    echo ""
    echo "================================================"
    echo "  ❌ DISTRIBUSI GAGAL!"
    echo "================================================"
    echo ""
    echo "Possible causes:"
    echo "  1. Firebase CLI belum login (jalankan: firebase login)"
    echo "  2. App ID tidak valid"
    echo "  3. Groups tidak ditemukan di Firebase Console"
    echo "  4. Network error"
    echo ""
    echo "Cek error di atas untuk detail lebih lanjut."
    exit 1
fi
