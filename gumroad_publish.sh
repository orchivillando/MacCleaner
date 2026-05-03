#!/usr/bin/env bash
# gumroad_publish.sh — Publish MacCleaner v2.0.0 ke Gumroad via API
# Cara pakai: bash gumroad_publish.sh
set -euo pipefail

# ── Konfigurasi ────────────────────────────────────────────────────────────────
PRICE_CENTS=999                        # $9.99 USD
PRODUCT_NAME="MacCleaner Enterprise — Professional Mac Cleaner"
CUSTOM_PERMALINK="maccleaner-enterprise"
VERSION="v2.0.0"
GITHUB_DMG_URL="https://github.com/orchivillando/MacCleaner/releases/download/${VERSION}/MacCleaner-${VERSION}.dmg"
LOCAL_DMG="$HOME/Documents/MacCleaner/dist/MacCleaner-${VERSION}.dmg"
API="https://api.gumroad.com/v2"

# ── Colors ─────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

echo ""
echo -e "${BOLD}🧹 MacCleaner — Gumroad Publisher${NC}"
echo "──────────────────────────────────────"

# ── Token ──────────────────────────────────────────────────────────────────────
if [ -z "${GUMROAD_TOKEN:-}" ]; then
  echo -e "${YELLOW}Buka: https://app.gumroad.com/settings/advanced → 'Generate Access Token'${NC}"
  read -rsp "🔑 Masukkan Gumroad Access Token: " GUMROAD_TOKEN
  echo ""
fi

# ── Verify token ───────────────────────────────────────────────────────────────
echo -e "\n⚙️  Memverifikasi token..."
ME=$(curl -sf -H "Authorization: Bearer $GUMROAD_TOKEN" "$API/user" || echo "error")
if echo "$ME" | grep -q '"success":false\|error'; then
  echo -e "${RED}❌ Token tidak valid. Pastikan kamu copy token yang benar dari Gumroad Settings.${NC}"
  exit 1
fi
SELLER_NAME=$(echo "$ME" | python3 -c "import sys,json; print(json.load(sys.stdin)['user']['name'])" 2>/dev/null || echo "Unknown")
echo -e "${GREEN}✅ Login sebagai: $SELLER_NAME${NC}"

# ── Description ────────────────────────────────────────────────────────────────
DESCRIPTION="<h2>🧹 MacCleaner Enterprise — Professional macOS Cleaner</h2>

<p>Aplikasi macOS profesional yang membersihkan dan mengoptimalkan Mac Anda seperti CleanMyMac Pro — dibangun dengan SwiftUI native.</p>

<h3>✨ 9 Fitur Enterprise</h3>
<ul>
  <li>🖥 <strong>Menu Bar Icon</strong> — monitor disk real-time di status bar Mac</li>
  <li>📊 <strong>Dashboard</strong> — ring gauge disk &amp; RAM, quick action tiles</li>
  <li>⚡ <strong>Smart Scan</strong> — scan 9 kategori junk sekaligus dengan progress animasi</li>
  <li>🗑 <strong>System Junk</strong> — User Caches, Logs, Temp, Trash, Mail Attachments, Xcode Caches, iOS Simulator</li>
  <li>📄 <strong>Large Files</strong> — temukan file &gt;50 MB dengan filter tipe &amp; sort</li>
  <li>📱 <strong>App Uninstaller</strong> — hapus app + semua file sisa Library secara tuntas</li>
  <li>🔒 <strong>Privacy Cleaner</strong> — hapus history &amp; cache Safari, Chrome, Firefox</li>
  <li>🧠 <strong>Memory Boost</strong> — reclaim RAM inactive, lihat breakdown penggunaan</li>
  <li>🔧 <strong>Maintenance</strong> — Flush DNS, QuickLook cache, Font cache, LaunchServices, Spotlight re-index, TimeMachine snapshots</li>
</ul>

<h3>📋 Requirements</h3>
<ul>
  <li>macOS 13 Ventura atau lebih baru</li>
  <li>Apple Silicon (M1/M2/M3/M4) atau Intel Mac</li>
</ul>

<h3>📥 Cara Install</h3>
<ol>
  <li>Download <strong>MacCleaner-v2.0.0.dmg</strong></li>
  <li>Buka file DMG</li>
  <li>Drag <strong>MacCleaner.app</strong> ke folder Applications</li>
  <li>Pertama kali membuka: klik kanan → <strong>Open</strong> untuk bypass Gatekeeper</li>
</ol>

<p><em>Built natively with SwiftUI. No subscription. One-time purchase.</em></p>"

# ── Create Product ─────────────────────────────────────────────────────────────
echo -e "\n🚀 Membuat produk di Gumroad..."
CREATE_RESP=$(curl -s -X POST "$API/products" \
  -H "Authorization: Bearer $GUMROAD_TOKEN" \
  --data-urlencode "name=$PRODUCT_NAME" \
  --data-urlencode "description=$DESCRIPTION" \
  -d "price=$PRICE_CENTS" \
  --data-urlencode "custom_permalink=$CUSTOM_PERMALINK" \
  -d "published=true" \
  -d "require_shipping=false" \
  -d "is_recurring_billing=false")

SUCCESS=$(echo "$CREATE_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success','false'))" 2>/dev/null || echo "false")
if [ "$SUCCESS" != "True" ] && [ "$SUCCESS" != "true" ]; then
  echo -e "${RED}❌ Gagal membuat produk:${NC}"
  echo "$CREATE_RESP" | python3 -m json.tool 2>/dev/null || echo "$CREATE_RESP"
  exit 1
fi

PRODUCT_ID=$(echo "$CREATE_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['product']['id'])")
SHORT_URL=$(echo "$CREATE_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['product']['short_url'])")
echo -e "${GREEN}✅ Produk dibuat! ID: $PRODUCT_ID${NC}"
echo -e "   URL: ${BOLD}$SHORT_URL${NC}"

# ── Upload / Link DMG ──────────────────────────────────────────────────────────
echo ""
if [ -f "$LOCAL_DMG" ]; then
  echo "📦 Mengupload DMG lokal (ini bisa memakan waktu)..."
  UPLOAD_RESP=$(curl -s -X POST "$API/products/$PRODUCT_ID/product_files" \
    -H "Authorization: Bearer $GUMROAD_TOKEN" \
    -F "file=@$LOCAL_DMG;type=application/octet-stream")
  UPLOAD_OK=$(echo "$UPLOAD_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success','false'))" 2>/dev/null || echo "false")
  if [ "$UPLOAD_OK" = "True" ] || [ "$UPLOAD_OK" = "true" ]; then
    echo -e "${GREEN}✅ DMG berhasil diupload ke Gumroad!${NC}"
  else
    echo -e "${YELLOW}⚠️  Upload via API gagal. Lakukan manual (lihat instruksi di bawah).${NC}"
    echo "   Response: $UPLOAD_RESP"
    MANUAL_UPLOAD=true
  fi
else
  echo -e "${YELLOW}⚠️  File DMG lokal belum tersedia di: $LOCAL_DMG${NC}"
  echo "   Setelah GitHub Actions selesai build, download DMG dari:"
  echo "   $GITHUB_DMG_URL"
  MANUAL_UPLOAD=true
fi

# ── Update product thumbnail via preview ───────────────────────────────────────
echo ""
echo "🎨 Mengatur tags produk..."
curl -s -X PUT "$API/products/$PRODUCT_ID" \
  -H "Authorization: Bearer $GUMROAD_TOKEN" \
  --data-urlencode "tags[]=macos" \
  --data-urlencode "tags[]=cleaner" \
  --data-urlencode "tags[]=mac" \
  --data-urlencode "tags[]=utility" \
  --data-urlencode "tags[]=swiftui" > /dev/null

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════"
echo -e "${BOLD}🎉 MacCleaner berhasil dipublish ke Gumroad!${NC}"
echo "══════════════════════════════════════════════"
echo ""
echo -e "  Produk  : $PRODUCT_NAME"
echo -e "  Harga   : \$9.99 USD"
echo -e "  Link    : ${BOLD}$SHORT_URL${NC}"
echo -e "  Edit    : https://app.gumroad.com/products/$PRODUCT_ID/edit"
echo ""

if [ "${MANUAL_UPLOAD:-false}" = "true" ]; then
  echo -e "${YELLOW}📋 Langkah manual — upload file DMG:${NC}"
  echo "  1. Buka: https://app.gumroad.com/products/$PRODUCT_ID/edit"
  echo "  2. Scroll ke bagian 'Content'"
  echo "  3. Klik 'Add files' → upload MacCleaner-v2.0.0.dmg"
  echo "  4. Save & Publish"
  echo ""
  echo "  Atau download DMG dari GitHub release dulu:"
  echo "  curl -L '$GITHUB_DMG_URL' -o ~/Downloads/MacCleaner-v2.0.0.dmg"
fi

echo -e "${GREEN}✅ Selesai!${NC}"
