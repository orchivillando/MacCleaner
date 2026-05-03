#!/usr/bin/swift
// Jalankan di Terminal: swift ~/Documents/MacCleaner/generate_icon.swift
import AppKit
import Foundation

func drawStar(ctx: CGContext, cx: CGFloat, cy: CGFloat,
              outer: CGFloat, inner: CGFloat, rotation: CGFloat = 0) {
    let path = CGMutablePath()
    for i in 0..<8 {
        let a = rotation + CGFloat(i) * .pi / 4.0
        let r: CGFloat = i % 2 == 0 ? outer : inner
        let pt = CGPoint(x: cx + r * cos(a), y: cy + r * sin(a))
        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
    }
    path.closeSubpath()
    ctx.addPath(path); ctx.fillPath()
}

func makeIcon(size: Int) -> NSImage? {
    let f  = CGFloat(size)
    let cs = CGColorSpaceCreateDeviceRGB()
    let bi = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard let ctx = CGContext(data: nil, width: size, height: size,
                              bitsPerComponent: 8, bytesPerRow: 0,
                              space: cs, bitmapInfo: bi.rawValue) else { return nil }

    // Squircle clip
    let sq = CGPath(roundedRect: CGRect(x: 0, y: 0, width: f, height: f),
                    cornerWidth: f * 0.2237, cornerHeight: f * 0.2237, transform: nil)
    ctx.addPath(sq); ctx.clip()

    // Gradient navy → violet (top-left → bottom-right)
    let c1 = CGColor(red: 0.08, green: 0.20, blue: 0.70, alpha: 1)
    let c2 = CGColor(red: 0.52, green: 0.14, blue: 0.92, alpha: 1)
    guard let grad = CGGradient(colorsSpace: cs,
                                colors: [c1, c2] as CFArray,
                                locations: [0.0, 1.0] as [CGFloat]) else { return nil }
    ctx.drawLinearGradient(grad,
                           start: CGPoint(x: 0, y: f), end: CGPoint(x: f, y: 0),
                           options: [])

    // Scale helpers — design space 1024pt, CG y-axis is bottom→up
    let s = f / 1024.0
    func Y(_ d: CGFloat) -> CGFloat { f - d * s }

    // Soft glow behind big star
    for i in 0..<4 {
        let gr    = (150 + CGFloat(i) * 40) * s
        let alpha = 0.09 - CGFloat(i) * 0.018
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: alpha))
        ctx.fillEllipse(in: CGRect(x: 590*s - gr, y: Y(440) - gr, width: gr*2, height: gr*2))
    }

    // Big sparkle — upper-right
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1.0))
    drawStar(ctx: ctx, cx: 600*s, cy: Y(430), outer: 208*s, inner: 26*s)

    // Medium sparkle — upper-left
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.80))
    drawStar(ctx: ctx, cx: 310*s, cy: Y(325), outer: 136*s, inner: 17*s, rotation: 0.30)

    // Small sparkle — lower-right
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.70))
    drawStar(ctx: ctx, cx: 635*s, cy: Y(705), outer: 80*s, inner: 10*s, rotation: -0.20)

    // Tiny sparkle — lower-left
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.58))
    drawStar(ctx: ctx, cx: 398*s, cy: Y(628), outer: 48*s, inner: 6*s)

    guard let img = ctx.makeImage() else { return nil }
    return NSImage(cgImage: img, size: NSSize(width: f, height: f))
}

// ── Output directory ───────────────────────────────────────
let dir = URL(fileURLWithPath: NSHomeDirectory()
    + "/Documents/MacCleaner/MacCleaner/Assets.xcassets/AppIcon.appiconset")

let specs: [(String, Int)] = [
    ("icon_16.png",   16),  ("icon_32.png",   32),
    ("icon_64.png",   64),  ("icon_128.png",  128),
    ("icon_256.png",  256), ("icon_512.png",  512),
    ("icon_1024.png", 1024),
]

for (file, px) in specs {
    guard let img  = makeIcon(size: px),
          let tiff = img.tiffRepresentation,
          let rep  = NSBitmapImageRep(data: tiff),
          let png  = rep.representation(using: .png, properties: [:]) else {
        print("❌ Gagal: \(file)"); continue
    }
    try! png.write(to: dir.appendingPathComponent(file))
    print("✅ \(file)  (\(px)×\(px)px)")
}

// ── Update Contents.json ───────────────────────────────────
let json = """
{
  "images" : [
    { "filename":"icon_16.png",   "idiom":"mac","scale":"1x","size":"16x16"   },
    { "filename":"icon_32.png",   "idiom":"mac","scale":"2x","size":"16x16"   },
    { "filename":"icon_32.png",   "idiom":"mac","scale":"1x","size":"32x32"   },
    { "filename":"icon_64.png",   "idiom":"mac","scale":"2x","size":"32x32"   },
    { "filename":"icon_128.png",  "idiom":"mac","scale":"1x","size":"128x128" },
    { "filename":"icon_256.png",  "idiom":"mac","scale":"2x","size":"128x128" },
    { "filename":"icon_256.png",  "idiom":"mac","scale":"1x","size":"256x256" },
    { "filename":"icon_512.png",  "idiom":"mac","scale":"2x","size":"256x256" },
    { "filename":"icon_512.png",  "idiom":"mac","scale":"1x","size":"512x512" },
    { "filename":"icon_1024.png", "idiom":"mac","scale":"2x","size":"512x512" }
  ],
  "info" : { "author":"xcode", "version":1 }
}
"""
try! json.write(to: dir.appendingPathComponent("Contents.json"),
                atomically: true, encoding: .utf8)
print("✅ Contents.json diperbarui")
print("🎉 Selesai! Rebuild project di Xcode (Cmd+B)")
