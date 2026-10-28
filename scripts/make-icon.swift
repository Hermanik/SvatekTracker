// Generates assets/SvatekTracker.icns — a tear-off calendar page with a flower
// (name days are for flowers) on the Big Sur grid (squircle ~80 % of the
// canvas), in the same dark palette family as the other *Tracker apps. Pure
// CoreGraphics so the only requirement is the Xcode CLT already needed for
// the build:
//
//   swift scripts/make-icon.swift
//
// The .icns is committed; rerun only when the design changes.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

func color(_ hex: UInt32) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: 1
    )
}

let paper = color(0xf7f4ee)
let headerRed = color(0xe5484d)
let ring = color(0x3a3f5c)
let petal = color(0xff8fab)
let flowerCenter = color(0xffcc00)
let stem = color(0x3fae6a)

/// Draw in 1024-canvas coordinates (y down) regardless of the output size.
func draw(into ctx: CGContext, pixels: Int) {
    let scale = CGFloat(pixels) / 1024
    ctx.scaleBy(x: scale, y: scale)
    // Flip to y-down so smaller y reads as "top".
    ctx.translateBy(x: 0, y: 1024)
    ctx.scaleBy(x: 1, y: -1)

    // Big Sur grid: an ~824 pt squircle centered on the 1024 canvas; everything
    // outside stays transparent.
    let shape = CGRect(x: 100, y: 100, width: 824, height: 824)
    ctx.addPath(CGPath(roundedRect: shape, cornerWidth: 185, cornerHeight: 185, transform: nil))
    ctx.clip()

    // Background: indigo → near-black gradient (the *Tracker family look).
    let bg = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [color(0x2b2f4a), color(0x141620)] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(bg, start: CGPoint(x: 512, y: 100), end: CGPoint(x: 512, y: 924), options: [])

    // Calendar page with a red header band, clipped to its rounded rect.
    let page = CGRect(x: 232, y: 250, width: 560, height: 560)
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: page, cornerWidth: 56, cornerHeight: 56, transform: nil))
    ctx.clip()
    ctx.setFillColor(paper)
    ctx.fill(page)
    ctx.setFillColor(headerRed)
    ctx.fill(CGRect(x: page.minX, y: page.minY, width: page.width, height: 140))
    ctx.restoreGState()

    // Two binder rings poking above the page.
    ctx.setFillColor(ring)
    for x in [372.0, 652.0] {
        ctx.addPath(CGPath(roundedRect: CGRect(x: x - 22, y: 206, width: 44, height: 110),
                           cornerWidth: 22, cornerHeight: 22, transform: nil))
    }
    ctx.fillPath()

    // Flower: stem and leaf first, then five petals around a yellow center.
    ctx.setStrokeColor(stem)
    ctx.setLineCap(.round)
    ctx.setLineWidth(22)
    ctx.move(to: CGPoint(x: 512, y: 590))
    ctx.addLine(to: CGPoint(x: 512, y: 740))
    ctx.strokePath()
    ctx.setFillColor(stem)
    ctx.saveGState()
    ctx.translateBy(x: 560, y: 690)
    ctx.rotate(by: -.pi / 5)
    ctx.fillEllipse(in: CGRect(x: -52, y: -22, width: 104, height: 44))
    ctx.restoreGState()

    let center = CGPoint(x: 512, y: 530)
    ctx.setFillColor(petal)
    for i in 0 ..< 5 {
        let angle = CGFloat(i) * 2 * .pi / 5 - .pi / 2
        let c = CGPoint(x: center.x + cos(angle) * 62, y: center.y + sin(angle) * 62)
        ctx.fillEllipse(in: CGRect(x: c.x - 54, y: c.y - 54, width: 108, height: 108))
    }
    ctx.setFillColor(flowerCenter)
    ctx.fillEllipse(in: CGRect(x: center.x - 44, y: center.y - 44, width: 88, height: 88))
}

func render(pixels: Int) -> CGImage {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    draw(into: ctx, pixels: pixels)
    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

let fm = FileManager.default
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let root = scriptDir.deletingLastPathComponent()
let iconset = fm.temporaryDirectory.appendingPathComponent("SvatekTracker.iconset")
let assets = root.appendingPathComponent("assets")
try? fm.removeItem(at: iconset)
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)
try fm.createDirectory(at: assets, withIntermediateDirectories: true)

// (file name, pixels) per Apple's iconset contract.
let entries: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, pixels) in entries {
    writePNG(render(pixels: pixels), to: iconset.appendingPathComponent("\(name).png"))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", assets.appendingPathComponent("SvatekTracker.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
try? fm.removeItem(at: iconset)
guard iconutil.terminationStatus == 0 else {
    fatalError("iconutil failed with status \(iconutil.terminationStatus)")
}
print("wrote assets/SvatekTracker.icns")
