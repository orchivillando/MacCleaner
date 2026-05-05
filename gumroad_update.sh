#!/usr/bin/env bash
# gumroad_update.sh — Update MacCleaner product listing to full English
PRODUCT_ID="jakqsx"
TOKEN="${GUMROAD_TOKEN:-IjZ3vEOeFsg1GZKwYnGsBZaCIdkJ-i8mg8wmdA8xRCA}"
API="https://api.gumroad.com/v2"

echo ""
echo "🧹 MacCleaner — Gumroad Listing Updater"
echo "─────────────────────────────────────────"

# Write description to temp file
TMPDIR_CUSTOM=$(mktemp -d)
cat > "$TMPDIR_CUSTOM/desc.html" << 'HTMLEOF'
<p style="font-size:16px;"><strong>MacCleaner</strong> is a native macOS app built with SwiftUI that keeps your Mac clean, fast, and private — inspired by CleanMyMac Pro, at a fraction of the cost.</p>
<hr/>
<h2>✨ 9 Enterprise Features</h2>
<table style="width:100%;border-collapse:collapse;">
<tr><td style="padding:8px 12px;width:36px;">🖥</td><td style="padding:8px 0;"><strong>Menu Bar Monitor</strong><br/>Live disk usage percentage always visible in your macOS status bar. One-click access to all features.</td></tr>
<tr style="background:#f9f9f9;"><td style="padding:8px 12px;">📊</td><td style="padding:8px 0;"><strong>Dashboard</strong><br/>Real-time ring gauges for disk &amp; RAM. Quick-action tiles for every module. Low disk warning banner.</td></tr>
<tr><td style="padding:8px 12px;">⚡</td><td style="padding:8px 0;"><strong>Smart Scan</strong><br/>Scan all 9 junk categories at once with animated progress. Select what to keep, delete the rest in one click.</td></tr>
<tr style="background:#f9f9f9;"><td style="padding:8px 12px;">🗑</td><td style="padding:8px 0;"><strong>System Junk Cleaner</strong><br/>Removes User Caches, System Logs, Temp Files, Trash, Mail Attachments, Xcode Derived Data &amp; iOS Simulator files.</td></tr>
<tr><td style="padding:8px 12px;">📄</td><td style="padding:8px 0;"><strong>Large Files Finder</strong><br/>Scans Downloads, Documents, Desktop, Movies &amp; Developer folders for files over 50 MB. Filter by type, sort by size.</td></tr>
<tr style="background:#f9f9f9;"><td style="padding:8px 12px;">📱</td><td style="padding:8px 0;"><strong>App Uninstaller</strong><br/>Completely remove apps and all their leftover files in Library (Application Support, Preferences, Caches, Containers, Logs).</td></tr>
<tr><td style="padding:8px 12px;">🔒</td><td style="padding:8px 0;"><strong>Privacy Cleaner</strong><br/>Permanently delete browsing history, cookies &amp; cache for Safari, Chrome, and Firefox.</td></tr>
<tr style="background:#f9f9f9;"><td style="padding:8px 12px;">🧠</td><td style="padding:8px 0;"><strong>Memory Boost</strong><br/>Reclaim inactive RAM with one click. Visual breakdown of wired, active, inactive &amp; free memory.</td></tr>
<tr><td style="padding:8px 12px;">🔧</td><td style="padding:8px 0;"><strong>Maintenance Tools</strong><br/>Flush DNS, clear QuickLook &amp; Font caches, rebuild LaunchServices, re-index Spotlight, delete TimeMachine snapshots.</td></tr>
</table>
<hr/>
<h2>📋 Requirements</h2>
<ul>
  <li>macOS 13 Ventura or later</li>
  <li>Apple Silicon (M1/M2/M3/M4) or Intel Mac</li>
  <li>~8 MB disk space</li>
</ul>
<hr/>
<h2>📥 Installation</h2>
<ol>
  <li>Download <strong>MacCleaner-v2.0.0.dmg</strong></li>
  <li>Open the DMG and drag <strong>MacCleaner.app</strong> to Applications</li>
  <li>First launch: <strong>Right-click → Open</strong> to bypass macOS Gatekeeper (one-time only)</li>
</ol>
<hr/>
<h2>💡 Why MacCleaner?</h2>
<ul>
  <li>✅ <strong>One-time purchase</strong> — no monthly subscription</li>
  <li>✅ <strong>Native SwiftUI</strong> — fast, built for Apple Silicon</li>
  <li>✅ <strong>Privacy-first</strong> — no telemetry, no internet required</li>
  <li>✅ <strong>9 tools in 1 app</strong> — replaces multiple utilities</li>
  <li>✅ <strong>Open source</strong> — <a href="https://github.com/orchivillando/MacCleaner">github.com/orchivillando/MacCleaner</a></li>
</ul>
<p style="color:#888;font-size:13px;">Built by <a href="https://github.com/orchivillando">@orchivillando</a> with SwiftUI &amp; ❤️ · Questions? Open an issue on GitHub.</p>
HTMLEOF

cat > "$TMPDIR_CUSTOM/receipt.html" << 'RECEIPTEOF'
<h2>🎉 Thank you for purchasing MacCleaner!</h2>
<p>Your Mac is about to get a lot cleaner. Here's how to get started:</p>
<h3>📥 Installation</h3>
<ol>
  <li>Download <strong>MacCleaner-v2.0.0.dmg</strong> using the button above</li>
  <li>Open the DMG → drag <strong>MacCleaner.app</strong> to your Applications folder</li>
  <li><strong>First launch only:</strong> Right-click the app → <strong>Open</strong>, then click Open in the dialog. You only need to do this once.</li>
</ol>
<h3>🚀 Quick Start Tips</h3>
<ul>
  <li>Run <strong>Smart Scan</strong> first — it checks all 9 categories at once</li>
  <li>The <strong>Menu Bar icon</strong> shows your disk usage at a glance</li>
  <li>Use <strong>Maintenance</strong> monthly for optimal performance</li>
</ul>
<h3>🐛 Need help?</h3>
<p>Open an issue on GitHub: <a href="https://github.com/orchivillando/MacCleaner/issues">github.com/orchivillando/MacCleaner/issues</a></p>
<p style="color:#888;">Enjoy a clean Mac! — @orchivillando</p>
RECEIPTEOF

echo "📝 Updating product..."

RESP=$(curl -s -X PUT "$API/products/$PRODUCT_ID" \
  -H "Authorization: Bearer $TOKEN" \
  --data-urlencode "name=MacCleaner — Professional Mac Cleaner for macOS" \
  --data-urlencode "description@$TMPDIR_CUSTOM/desc.html" \
  --data-urlencode "custom_summary=Clean, optimize & protect your Mac. 9 enterprise features: Smart Scan, App Uninstaller, Privacy Cleaner, Memory Boost & Menu Bar monitor. One-time purchase — no subscription." \
  --data-urlencode "custom_receipt@$TMPDIR_CUSTOM/receipt.html" \
  --data-urlencode "tags[]=macos" \
  --data-urlencode "tags[]=mac cleaner" \
  --data-urlencode "tags[]=disk cleaner" \
  --data-urlencode "tags[]=swiftui" \
  --data-urlencode "tags[]=memory optimizer" \
  --data-urlencode "tags[]=privacy" \
  --data-urlencode "tags[]=mac utility")

rm -rf "$TMPDIR_CUSTOM"

echo "$RESP" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if d.get('success'):
    p = d['product']
    print('✅ Updated successfully!')
    print(f'   Name : {p[\"name\"]}')
    print(f'   URL  : {p[\"short_url\"]}')
    print(f'   Price: \${p[\"price\"]/100:.2f}')
else:
    print('❌ Failed:', d.get('message', d))
" 2>/dev/null || echo "Raw response: $RESP"


PRODUCT_ID="jakqsx"
TOKEN="${GUMROAD_TOKEN:-IjZ3vEOeFsg1GZKwYnGsBZaCIdkJ-i8mg8wmdA8xRCA}"
API="https://api.gumroad.com/v2"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

echo ""
echo -e "${BOLD}🧹 MacCleaner — Gumroad Listing Updater${NC}"
echo "─────────────────────────────────────────"

# ── Product Name ───────────────────────────────────────────────────────────────
NAME="MacCleaner — Professional Mac Cleaner for macOS"

# ── Summary (shown under title on product page) ────────────────────────────────
SUMMARY="Clean, optimize & protect your Mac. 9 enterprise-grade features including Smart Scan, App Uninstaller, Privacy Cleaner, Memory Boost & Menu Bar monitor. One-time purchase — no subscription."

# ── Description (HTML, shown on product page) ──────────────────────────────────
read -r -d '' DESCRIPTION << 'HTMLEOF'
<p style="font-size:16px;color:#333;">
  <strong>MacCleaner</strong> is a native macOS app built with SwiftUI that keeps your Mac clean, fast, and private — inspired by CleanMyMac Pro, at a fraction of the cost.
</p>

<hr/>

<h2>✨ 9 Enterprise Features</h2>

<table style="width:100%;border-collapse:collapse;">
  <tr>
    <td style="padding:8px 12px;vertical-align:top;width:32px;">🖥</td>
    <td style="padding:8px 0;"><strong>Menu Bar Monitor</strong><br/>Live disk usage percentage always visible in your macOS status bar. One-click access to all features.</td>
  </tr>
  <tr style="background:#f9f9f9;">
    <td style="padding:8px 12px;vertical-align:top;">📊</td>
    <td style="padding:8px 0;"><strong>Dashboard</strong><br/>Real-time ring gauges for disk &amp; RAM usage. Quick-action tiles for every cleaning module. Low disk warning banner.</td>
  </tr>
  <tr>
    <td style="padding:8px 12px;vertical-align:top;">⚡</td>
    <td style="padding:8px 0;"><strong>Smart Scan</strong><br/>Scan all 9 junk categories at once with animated progress. Select what to keep, delete the rest in one click.</td>
  </tr>
  <tr style="background:#f9f9f9;">
    <td style="padding:8px 12px;vertical-align:top;">🗑</td>
    <td style="padding:8px 0;"><strong>System Junk Cleaner</strong><br/>Removes User Caches, System Logs, Temp Files, Trash, Mail Attachments, Xcode Derived Data &amp; iOS Simulator files.</td>
  </tr>
  <tr>
    <td style="padding:8px 12px;vertical-align:top;">📄</td>
    <td style="padding:8px 0;"><strong>Large Files Finder</strong><br/>Scans Downloads, Documents, Desktop, Movies &amp; Developer folders for files over 50 MB. Filter by type, sort by size.</td>
  </tr>
  <tr style="background:#f9f9f9;">
    <td style="padding:8px 12px;vertical-align:top;">📱</td>
    <td style="padding:8px 0;"><strong>App Uninstaller</strong><br/>Completely remove apps and all their leftover files in Library (Application Support, Preferences, Caches, Containers, Logs).</td>
  </tr>
  <tr>
    <td style="padding:8px 12px;vertical-align:top;">🔒</td>
    <td style="padding:8px 0;"><strong>Privacy Cleaner</strong><br/>Permanently delete browsing history, cookies &amp; cache for Safari, Chrome, and Firefox. Also clears recent documents &amp; system logs.</td>
  </tr>
  <tr style="background:#f9f9f9;">
    <td style="padding:8px 12px;vertical-align:top;">🧠</td>
    <td style="padding:8px 0;"><strong>Memory Boost</strong><br/>Reclaim inactive RAM with one click. Visual breakdown of wired, active, inactive &amp; free memory usage.</td>
  </tr>
  <tr>
    <td style="padding:8px 12px;vertical-align:top;">🔧</td>
    <td style="padding:8px 0;"><strong>Maintenance Tools</strong><br/>Flush DNS cache, clear QuickLook &amp; Font caches, rebuild LaunchServices database, re-index Spotlight, delete TimeMachine local snapshots.</td>
  </tr>
</table>

<hr/>

<h2>📋 System Requirements</h2>
<ul>
  <li>macOS 13 Ventura or later</li>
  <li>Apple Silicon (M1 / M2 / M3 / M4) or Intel Mac</li>
  <li>~8 MB disk space</li>
</ul>

<hr/>

<h2>📥 Installation</h2>
<ol>
  <li>Download <strong>MacCleaner-v2.0.0.dmg</strong> from your purchase</li>
  <li>Open the DMG file</li>
  <li>Drag <strong>MacCleaner.app</strong> into your <strong>Applications</strong> folder</li>
  <li>First launch only: <strong>Right-click → Open</strong> to bypass macOS Gatekeeper<br/>
      <em>(This is normal for apps distributed outside the Mac App Store)</em></li>
</ol>

<hr/>

<h2>💡 Why MacCleaner?</h2>
<ul>
  <li>✅ <strong>One-time purchase</strong> — no monthly subscription</li>
  <li>✅ <strong>Native SwiftUI</strong> — blazing fast, built for Apple Silicon</li>
  <li>✅ <strong>Privacy-first</strong> — no telemetry, no internet connection required</li>
  <li>✅ <strong>9 tools in 1 app</strong> — replaces multiple utilities</li>
  <li>✅ <strong>Open source</strong> — <a href="https://github.com/orchivillando/MacCleaner">github.com/orchivillando/MacCleaner</a></li>
</ul>

<hr/>

<p style="color:#888;font-size:13px;">
  Built by <a href="https://github.com/orchivillando">@orchivillando</a> with SwiftUI &amp; ❤️ on macOS.
  Questions? Open an issue on GitHub.
</p>
HTMLEOF

# ── Custom Receipt Email ────────────────────────────────────────────────────────
read -r -d '' RECEIPT << 'RECEIPTEOF'
<h2>🎉 Thank you for purchasing MacCleaner!</h2>

<p>Your Mac is about to get a lot cleaner. Here's how to get started:</p>

<h3>📥 How to Install</h3>
<ol>
  <li>Download <strong>MacCleaner-v2.0.0.dmg</strong> from the link above</li>
  <li>Open the DMG and drag <strong>MacCleaner.app</strong> to your Applications folder</li>
  <li><strong>Important — first launch:</strong> Right-click the app → <strong>Open</strong><br/>
      macOS will ask "Are you sure you want to open it?" — click <strong>Open</strong><br/>
      You only need to do this once.</li>
</ol>

<h3>🚀 Quick Start</h3>
<ul>
  <li>Use <strong>Smart Scan</strong> first — it checks all categories at once</li>
  <li>The <strong>Menu Bar icon</strong> shows disk usage at a glance</li>
  <li>Run <strong>Maintenance</strong> monthly for best performance</li>
</ul>

<h3>🐛 Issues or Questions?</h3>
<p>
  Open an issue on GitHub: <a href="https://github.com/orchivillando/MacCleaner/issues">github.com/orchivillando/MacCleaner/issues</a>
</p>

<p style="color:#888;">Enjoy a clean Mac! — @orchivillando</p>
RECEIPTEOF

# ── Update Product ─────────────────────────────────────────────────────────────
echo -e "\n📝 Updating product name & description..."
UPDATE_RESP=$(curl -s -X PUT "$API/products/$PRODUCT_ID" \
  -H "Authorization: Bearer $TOKEN" \
  --data-urlencode "name=$NAME" \
  --data-urlencode "description=$DESCRIPTION" \
  --data-urlencode "custom_summary=$SUMMARY" \
  --data-urlencode "custom_receipt=$RECEIPT" \
  --data-urlencode "tags[]=macos" \
  --data-urlencode "tags[]=cleaner" \
  --data-urlencode "tags[]=mac utility" \
  --data-urlencode "tags[]=swiftui" \
  --data-urlencode "tags[]=disk cleaner" \
  --data-urlencode "tags[]=memory" \
  --data-urlencode "tags[]=privacy")

SUCCESS=$(echo "$UPDATE_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))" 2>/dev/null || echo "false")

if [ "$SUCCESS" = "True" ] || [ "$SUCCESS" = "true" ]; then
  echo -e "${GREEN}✅ Product updated successfully!${NC}"
  echo ""
  echo -e "  View product : ${BOLD}https://gumroad.com/l/$PRODUCT_ID${NC}"
  echo -e "  Edit product : https://app.gumroad.com/products/$PRODUCT_ID/edit"
  echo ""
  echo -e "${GREEN}Changes applied:${NC}"
  echo "  ✓ Product name → English"
  echo "  ✓ Description  → Full English with feature table"
  echo "  ✓ Summary      → Short English tagline"
  echo "  ✓ Receipt email → English with install guide"
  echo "  ✓ Tags         → macos, cleaner, mac utility, swiftui, disk cleaner, memory, privacy"
else
  echo -e "${YELLOW}⚠️  Update response:${NC}"
  echo "$UPDATE_RESP" | python3 -m json.tool 2>/dev/null || echo "$UPDATE_RESP"
fi
