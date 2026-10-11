// Draws the Super Simple Todo app icon at 1024×1024.
// Usage: swift tools/MakeIcon.swift <output.png>
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Icon-1024.png"

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
ctx.translateBy(x: 0, y: size)   // draw top-down
ctx.scaleBy(x: 1, y: -1)

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}

// macOS icon grid: an 824-pt rounded square centred on the 1024 canvas.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 12), blur: 28, color: rgb(0x000000, 0.28))
ctx.addPath(tilePath)
ctx.setFillColor(rgb(0xffffff))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(tilePath)
ctx.clip()
let bg = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                    colors: [rgb(0xffffff), rgb(0xe9ecf2)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 512, y: 100), end: CGPoint(x: 512, y: 924), options: [])
ctx.restoreGState()

// Three task rows: High (done), Medium, Low.
let rows: [(color: UInt32, done: Bool, length: CGFloat)] = [
    (0xff3b30, true, 380), (0xff9500, false, 440), (0x007aff, false, 320),
]
let ringRadius: CGFloat = 62
let left: CGFloat = 250
for (i, row) in rows.enumerated() {
    let cy = 300 + CGFloat(i) * 212
    let center = CGPoint(x: left, y: cy)
    let circle = CGRect(x: center.x - ringRadius, y: center.y - ringRadius,
                        width: ringRadius * 2, height: ringRadius * 2)
    if row.done {
        ctx.setFillColor(rgb(row.color))
        ctx.fillEllipse(in: circle)
        ctx.setStrokeColor(rgb(0xffffff))
        ctx.setLineWidth(22)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.move(to: CGPoint(x: center.x - 30, y: center.y + 2))
        ctx.addLine(to: CGPoint(x: center.x - 8, y: center.y + 26))
        ctx.addLine(to: CGPoint(x: center.x + 32, y: center.y - 24))
        ctx.strokePath()
    } else {
        ctx.setStrokeColor(rgb(row.color))
        ctx.setLineWidth(22)
        ctx.strokeEllipse(in: circle.insetBy(dx: 11, dy: 11))
    }
    // The task's "text": a rounded bar, greyed and struck through when done.
    let bar = CGRect(x: left + 112, y: cy - 22, width: row.length, height: 44)
    ctx.addPath(CGPath(roundedRect: bar, cornerWidth: 22, cornerHeight: 22, transform: nil))
    ctx.setFillColor(row.done ? rgb(0xc7cbd3) : rgb(0x3a3f4b))
    ctx.fillPath()
}

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
