import AppKit

// 使い方: swift resize.swift <入力フォルダ> <出力フォルダ> <幅> <高さ>
// 1.png〜6.png を指定の大きさに縮めて、透明度なしの PNG で書き出す
let a = CommandLine.arguments
let src = a[1], dst = a[2]
let w = Int(a[3])!, h = Int(a[4])!
try? FileManager.default.createDirectory(atPath: dst, withIntermediateDirectories: true)
for i in 1...6 where FileManager.default.fileExists(atPath: "\(src)/\(i).png") {
    let img = NSImage(contentsOfFile: "\(src)/\(i).png")!
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.interpolationQuality = .high
    var rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
    let cg = img.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(dst)/\(i).png"))
}
print("ok")
