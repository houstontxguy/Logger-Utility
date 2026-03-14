#!/usr/bin/swift

import AppKit
import Foundation

// MARK: - Icon Generator for Logger Utility

/// Generates a macOS app icon depicting a terminal-style log viewer window
/// with colored log-level dots, truncated text lines, and a magnifying glass overlay.

struct LogLine {
    let color: NSColor
    let textWidth: CGFloat // fraction of available width (0.0–1.0)
}

let logLines: [LogLine] = [
    LogLine(color: NSColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1.0), textWidth: 0.85), // debug - gray
    LogLine(color: NSColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1.0), textWidth: 0.70), // default - white/light
    LogLine(color: NSColor(red: 0.30, green: 0.60, blue: 1.00, alpha: 1.0), textWidth: 0.92), // info - blue
    LogLine(color: NSColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1.0), textWidth: 0.55), // debug - gray
    LogLine(color: NSColor(red: 1.00, green: 0.60, blue: 0.20, alpha: 1.0), textWidth: 0.78), // error - orange
    LogLine(color: NSColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 1.0), textWidth: 0.65), // fault - red
]

func drawIcon(in context: CGContext, size: CGFloat) {
    let scale = size / 1024.0

    // -- Background: dark rounded rectangle --
    let cornerRadius = 180.0 * scale
    let inset = 40.0 * scale
    let bgRect = CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Shadow behind the window
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -8 * scale), blur: 30 * scale, color: NSColor.black.withAlphaComponent(0.5).cgColor)
    context.setFillColor(NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0).cgColor)
    context.addPath(bgPath)
    context.fillPath()
    context.restoreGState()

    // Clip to rounded rect for interior drawing
    context.saveGState()
    context.addPath(bgPath)
    context.clip()

    // -- Title bar --
    let titleBarHeight = 72.0 * scale
    let titleBarRect = CGRect(x: bgRect.minX, y: bgRect.maxY - titleBarHeight, width: bgRect.width, height: titleBarHeight)
    context.setFillColor(NSColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1.0).cgColor)
    context.fill(titleBarRect)

    // Separator line below title bar
    context.setStrokeColor(NSColor(red: 0.25, green: 0.25, blue: 0.27, alpha: 1.0).cgColor)
    context.setLineWidth(2.0 * scale)
    context.move(to: CGPoint(x: bgRect.minX, y: titleBarRect.minY))
    context.addLine(to: CGPoint(x: bgRect.maxX, y: titleBarRect.minY))
    context.strokePath()

    // Traffic light dots
    let dotRadius = 12.0 * scale
    let dotY = titleBarRect.midY
    let dotStartX = bgRect.minX + 40.0 * scale
    let dotSpacing = 36.0 * scale

    let trafficColors: [NSColor] = [
        NSColor(red: 1.0, green: 0.38, blue: 0.35, alpha: 1.0), // close - red
        NSColor(red: 1.0, green: 0.78, blue: 0.25, alpha: 1.0), // minimize - yellow
        NSColor(red: 0.30, green: 0.85, blue: 0.40, alpha: 1.0), // maximize - green
    ]
    for (i, color) in trafficColors.enumerated() {
        let cx = dotStartX + CGFloat(i) * dotSpacing
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: CGRect(x: cx - dotRadius, y: dotY - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
    }

    // -- Log lines area --
    let contentTop = titleBarRect.minY - 24.0 * scale
    let contentLeft = bgRect.minX + 36.0 * scale
    let contentRight = bgRect.maxX - 36.0 * scale
    let availableWidth = contentRight - contentLeft
    let lineHeight = 50.0 * scale
    let lineSpacing = 26.0 * scale
    let logDotRadius = 14.0 * scale
    let textBarHeight = 18.0 * scale
    let dotToTextGap = 20.0 * scale

    for (i, line) in logLines.enumerated() {
        let y = contentTop - CGFloat(i) * (lineHeight + lineSpacing) - lineHeight / 2.0

        // Colored dot
        let dotCX = contentLeft + logDotRadius
        let dotCY = y
        context.setFillColor(line.color.cgColor)
        context.fillEllipse(in: CGRect(x: dotCX - logDotRadius, y: dotCY - logDotRadius, width: logDotRadius * 2, height: logDotRadius * 2))

        // "Text" rectangle (gray bar of varying width)
        let textX = dotCX + logDotRadius + dotToTextGap
        let maxTextWidth = availableWidth - (textX - contentLeft)
        let textWidth = maxTextWidth * line.textWidth
        let textRect = CGRect(x: textX, y: dotCY - textBarHeight / 2.0, width: textWidth, height: textBarHeight)
        let textCorner = 4.0 * scale
        let textPath = CGPath(roundedRect: textRect, cornerWidth: textCorner, cornerHeight: textCorner, transform: nil)
        context.setFillColor(NSColor(red: 0.30, green: 0.30, blue: 0.33, alpha: 1.0).cgColor)
        context.addPath(textPath)
        context.fillPath()
    }

    context.restoreGState() // end clip

    // -- Magnifying glass overlay (bottom-right) --
    let glassSize = 260.0 * scale
    let glassCenterX = bgRect.maxX - 80.0 * scale
    let glassCenterY = bgRect.minY + 80.0 * scale

    // Semi-transparent backing circle
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -4 * scale), blur: 12 * scale, color: NSColor.black.withAlphaComponent(0.4).cgColor)

    let lensRadius = glassSize * 0.35
    let lensCenter = CGPoint(x: glassCenterX - glassSize * 0.10, y: glassCenterY + glassSize * 0.10)

    // Glass fill (subtle dark blue tint)
    context.setFillColor(NSColor(red: 0.15, green: 0.20, blue: 0.30, alpha: 0.85).cgColor)
    context.fillEllipse(in: CGRect(x: lensCenter.x - lensRadius, y: lensCenter.y - lensRadius, width: lensRadius * 2, height: lensRadius * 2))

    // Lens ring
    context.setStrokeColor(NSColor(red: 0.70, green: 0.75, blue: 0.85, alpha: 1.0).cgColor)
    context.setLineWidth(14.0 * scale)
    context.strokeEllipse(in: CGRect(x: lensCenter.x - lensRadius, y: lensCenter.y - lensRadius, width: lensRadius * 2, height: lensRadius * 2))

    // Handle
    let handleAngle = -CGFloat.pi / 4.0 // 45 degrees down-right
    let handleStart = CGPoint(
        x: lensCenter.x + cos(handleAngle) * lensRadius,
        y: lensCenter.y + sin(handleAngle) * lensRadius
    )
    let handleLength = 80.0 * scale
    let handleEnd = CGPoint(
        x: handleStart.x + cos(handleAngle) * handleLength,
        y: handleStart.y + sin(handleAngle) * handleLength
    )

    context.setStrokeColor(NSColor(red: 0.70, green: 0.75, blue: 0.85, alpha: 1.0).cgColor)
    context.setLineWidth(18.0 * scale)
    context.setLineCap(.round)
    context.move(to: handleStart)
    context.addLine(to: handleEnd)
    context.strokePath()

    // Glint/highlight on lens
    let glintRadius = lensRadius * 0.60
    let glintCenter = CGPoint(x: lensCenter.x - lensRadius * 0.25, y: lensCenter.y + lensRadius * 0.25)
    context.setStrokeColor(NSColor.white.withAlphaComponent(0.15).cgColor)
    context.setLineWidth(6.0 * scale)
    let glintStart = CGFloat.pi * 0.55
    let glintEnd = CGFloat.pi * 0.95
    context.addArc(center: glintCenter, radius: glintRadius, startAngle: glintStart, endAngle: glintEnd, clockwise: false)
    context.strokePath()

    context.restoreGState()
}

func generateIcon(size: Int) -> NSBitmapImageRep {
    let s = CGFloat(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: s, height: s)

    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    let cgContext = context.cgContext
    // Clear to transparent
    cgContext.clear(CGRect(x: 0, y: 0, width: s, height: s))
    // Enable anti-aliasing
    cgContext.setAllowsAntialiasing(true)
    cgContext.setShouldAntialias(true)

    drawIcon(in: cgContext, size: s)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func savePNG(_ rep: NSBitmapImageRep, to url: URL) {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to create PNG data")
    }
    try! data.write(to: url)
}

// MARK: - Main

let fileManager = FileManager.default
let resourcesDir = "/Users/avoges/cursor/Logger Utility/Resources"
let iconsetDir = NSTemporaryDirectory() + "AppIcon.iconset"

// Clean up any previous iconset
if fileManager.fileExists(atPath: iconsetDir) {
    try! fileManager.removeItem(atPath: iconsetDir)
}
try! fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

// macOS iconset requires specific filenames with @2x variants
// Each "size" has a 1x and 2x version
let iconSizes: [(name: String, pixels: Int)] = [
    ("icon_16x16",       16),
    ("icon_16x16@2x",    32),
    ("icon_32x32",       32),
    ("icon_32x32@2x",    64),
    ("icon_128x128",     128),
    ("icon_128x128@2x",  256),
    ("icon_256x256",     256),
    ("icon_256x256@2x",  512),
    ("icon_512x512",     512),
    ("icon_512x512@2x",  1024),
]

print("Generating icon images...")
for entry in iconSizes {
    print("  \(entry.name).png (\(entry.pixels)x\(entry.pixels))")
    let rep = generateIcon(size: entry.pixels)
    let url = URL(fileURLWithPath: iconsetDir).appendingPathComponent("\(entry.name).png")
    savePNG(rep, to: url)
}

// Convert iconset to icns using iconutil
print("Converting to .icns...")
let outputPath = "\(resourcesDir)/AppIcon.icns"

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir, "-o", outputPath]

let pipe = Pipe()
process.standardError = pipe

try! process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
    let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
    fatalError("iconutil failed: \(errorString)")
}

// Clean up temp iconset
try? fileManager.removeItem(atPath: iconsetDir)

print("App icon saved to: \(outputPath)")
