#!/bin/bash
# ================================================================
# setup.sh — Jalankan sekali dari Terminal:
#   cd ~/Documents/MacCleaner && bash setup.sh
# ================================================================
set -e
cd "$(dirname "$0")"

echo "🚀 Mac Cleaner — Setup Script"
echo "================================"

# ── 1. Generate Icons ─────────────────────────────────────────
echo ""
echo "🎨 [1/4] Generating app icons..."
swift generate_icon.swift
echo "✅ Icons generated"

# ── 2. Create GitHub Actions workflow ─────────────────────────
echo ""
echo "⚙️  [2/4] Creating GitHub Actions workflow..."
mkdir -p .github/workflows

cat > .github/workflows/release.yml << 'YAML'
name: Build & Release DMG

on:
  push:
    tags:
      - 'v*.*.*'
  workflow_dispatch:

jobs:
  build:
    name: Build and Package
    runs-on: macos-14

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app

      - name: Build MacCleaner
        run: |
          xcodebuild \
            -project MacCleaner.xcodeproj \
            -target MacCleaner \
            -configuration Release \
            CONFIGURATION_BUILD_DIR="${PWD}/build" \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGNING_REQUIRED=YES \
            MACOSX_DEPLOYMENT_TARGET=13.0 \
            build

      - name: Create DMG
        run: |
          VERSION="${GITHUB_REF_NAME:-dev}"
          mkdir -p dmg_staging dist

          cp -R "build/MacCleaner.app" dmg_staging/
          ln -s /Applications "dmg_staging/Applications"

          hdiutil create \
            -volname "Mac Cleaner" \
            -srcfolder dmg_staging \
            -ov \
            -format UDZO \
            "dist/MacCleaner-${VERSION}.dmg"

          echo "DMG_FILE=dist/MacCleaner-${VERSION}.dmg" >> $GITHUB_ENV

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: MacCleaner-dmg
          path: dist/*.dmg

      - name: Create GitHub Release
        if: startsWith(github.ref, 'refs/tags/')
        uses: softprops/action-gh-release@v2
        with:
          name: "Mac Cleaner ${{ github.ref_name }}"
          body: |
            ## 🧹 Mac Cleaner ${{ github.ref_name }}

            Aplikasi macOS SwiftUI untuk membersihkan file sampah di Mac Anda.

            ### ✨ Fitur
            - 🗂 User Caches (`~/Library/Caches`)
            - 📝 User Logs (`~/Library/Logs`)
            - ⏰ Temp Files (`/tmp`)
            - 🗑 Sampah/Trash (`~/.Trash`)

            ### 📥 Cara Install
            1. Download **MacCleaner-${{ github.ref_name }}.dmg** di bawah
            2. Buka DMG → drag **MacCleaner.app** ke **Applications**
            3. Pertama kali buka: klik kanan → **Open** (bypass Gatekeeper)

            > ⚠️ Aplikasi tidak di-code-sign, gunakan klik kanan → Open pada pertama kali.
          files: dist/*.dmg
          draft: false
          prerelease: false
YAML

echo "✅ GitHub Actions workflow created"

# ── 3. Initialize Git & commit ────────────────────────────────
echo ""
echo "📦 [3/4] Initializing git repository..."
git init
git add .
git commit -m "Initial commit: Mac Cleaner v1.0.0

- SwiftUI macOS app (macOS 13+)
- Scan & clean User Caches, Logs, Temp Files, Trash
- Sidebar navigation with file size indicators
- GitHub Actions workflow for automatic DMG release

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
echo "✅ Git repository initialized"

# ── 4. Push to GitHub ─────────────────────────────────────────
echo ""
echo "☁️  [4/4] Pushing to GitHub (orchivillando/MacCleaner)..."

# Check if gh CLI is available
if command -v gh &> /dev/null; then
  echo "Using GitHub CLI..."
  gh repo create orchivillando/MacCleaner \
    --public \
    --description "🧹 Aplikasi macOS SwiftUI untuk membersihkan file sampah" \
    --source=. \
    --remote=origin \
    --push
else
  echo "⚠️  GitHub CLI (gh) tidak ditemukan."
  echo ""
  echo "Jalankan perintah berikut secara manual:"
  echo ""
  echo "  1. Buat repo di https://github.com/new"
  echo "     Nama: MacCleaner | Public | Jangan tambah README"
  echo ""
  echo "  2. Kemudian jalankan:"
  echo "     git remote add origin https://github.com/orchivillando/MacCleaner.git"
  echo "     git branch -M main"
  echo "     git push -u origin main"
fi

# ── 5. Create & push tag to trigger release ───────────────────
echo ""
echo "🏷️  Creating release tag v1.0.0..."
git tag v1.0.0
if git remote get-url origin &> /dev/null; then
  git push origin v1.0.0
  echo ""
  echo "🎉 SELESAI!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Kode: https://github.com/orchivillando/MacCleaner"
  echo "✅ DMG akan tersedia di Releases setelah"
  echo "   GitHub Actions selesai build (~3-5 menit)"
  echo "   https://github.com/orchivillando/MacCleaner/releases"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
  echo "⚠️  Push tag manual setelah set remote:"
  echo "     git push origin v1.0.0"
fi
