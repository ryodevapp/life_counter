import AppKit

// 使い方: compose <入力png> <出力png> <見出し> <小見出し> <ja|en>
let a = CommandLine.arguments
let input = a[1], output = a[2], title = a[3], sub = a[4], lang = a[5]
let W: CGFloat = 1320, H: CGFloat = 2868

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: W, height: H)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// 背景(アプリの背景より少し濃い、温かいクリーム)
color(0xF3EBDF).setFill()
NSRect(x: 0, y: 0, width: W, height: H).fill()

// 文字
let titleFont = lang == "ja" ? NSFont(name: "HiraginoSans-W6", size: 78)! : NSFont.systemFont(ofSize: 82, weight: .semibold)
let subFont = lang == "ja" ? NSFont(name: "HiraginoSans-W3", size: 42)! : NSFont.systemFont(ofSize: 44, weight: .regular)
let para = NSMutableParagraphStyle(); para.alignment = .center; para.lineSpacing = 10
let titleAttr: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: color(0x2C2520), .paragraphStyle: para]
let subAttr: [NSAttributedString.Key: Any] = [.font: subFont, .foregroundColor: color(0x6E665D), .paragraphStyle: para]
let margin: CGFloat = 90
let tRect = NSRect(x: margin, y: H - 150 - 220, width: W - margin * 2, height: 220)
(title as NSString).draw(with: tRect, options: [.usesLineFragmentOrigin], attributes: titleAttr)
let tBound = (title as NSString).boundingRect(with: NSSize(width: W - margin * 2, height: 400), options: [.usesLineFragmentOrigin], attributes: titleAttr)
let sY = H - 150 - tBound.height - 40 - 140
(sub as NSString).draw(with: NSRect(x: margin, y: sY, width: W - margin * 2, height: 140), options: [.usesLineFragmentOrigin], attributes: subAttr)

// 画面(角を丸め、うすい影)
let shot = NSImage(contentsOfFile: input)!
let sw: CGFloat = 1060, sh = sw * shot.size.height / shot.size.width
let sx = (W - sw) / 2, sy: CGFloat = H - 470 - sh
let frame = NSRect(x: sx, y: sy, width: sw, height: sh)
let shadow = NSShadow(); shadow.shadowColor = color(0x2C2520, 0.18); shadow.shadowBlurRadius = 60; shadow.shadowOffset = NSSize(width: 0, height: -20)
NSGraphicsContext.saveGraphicsState()
shadow.set()
let path = NSBezierPath(roundedRect: frame, xRadius: 80, yRadius: 80)
color(0xFDFBF7).setFill(); path.fill()
NSGraphicsContext.restoreGraphicsState()
NSGraphicsContext.saveGraphicsState()
path.addClip()
shot.draw(in: frame)
NSGraphicsContext.restoreGraphicsState()
color(0x2C2520, 0.08).setStroke(); path.lineWidth = 3; path.stroke()

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))