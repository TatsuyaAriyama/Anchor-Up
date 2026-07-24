import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// MARK: - 色

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: a)
}

let seaTop = rgb(0x12, 0x4A, 0x42)     // 明るめの深緑
let seaBottom = rgb(0x08, 0x1C, 0x1A)  // 深い底
let moon = rgb(0xF2, 0xED, 0xE1)       // 暖色オフホワイト
let anchorColor = rgb(0xE7, 0xD9, 0xB4) // くすんだタン/クリーム

let colorSpace = CGColorSpaceCreateDeviceRGB()

// MARK: - 描画部品

func makeContext(_ size: Int) -> CGContext {
    let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    // y下向き(SwiftUI/UIKit座標)に合わせて反転
    ctx.translateBy(x: 0, y: CGFloat(size))
    ctx.scaleBy(x: 1, y: -1)
    return ctx
}

func drawBackground(_ ctx: CGContext, _ size: CGFloat) {
    // 縦グラデーション
    let grad = CGGradient(colorsSpace: colorSpace, colors: [seaTop, seaBottom] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size), options: [])

    // 右上の月あかり(放射状のにじみ)
    let glow = CGGradient(colorsSpace: colorSpace,
                          colors: [moon.copy(alpha: 0.28)!, moon.copy(alpha: 0)!] as CFArray,
                          locations: [0, 1])!
    let c = CGPoint(x: size * 0.76, y: size * 0.24)
    ctx.drawRadialGradient(glow, startCenter: c, startRadius: 0, endCenter: c, endRadius: size * 0.42, options: [])

    // 底のかすかな波の帯
    ctx.saveGState()
    ctx.setFillColor(rgb(0x0D, 0x2B, 0x28, 0.5))
    let wave = CGMutablePath()
    let base = size * 0.82
    wave.move(to: CGPoint(x: 0, y: base))
    let steps = 6
    for i in 1...steps {
        let x = size * CGFloat(i) / CGFloat(steps)
        let y = base + sin(Double(i) * 1.6) * size * 0.02
        wave.addLine(to: CGPoint(x: x, y: y))
    }
    wave.addLine(to: CGPoint(x: size, y: size))
    wave.addLine(to: CGPoint(x: 0, y: size))
    wave.closeSubpath()
    ctx.addPath(wave)
    ctx.fillPath()
    ctx.restoreGState()
}

// アンカー(錨)を描く。scale は アイコンに対する縦の占有率の目安。
func drawAnchor(_ ctx: CGContext, _ size: CGFloat, scale: CGFloat) {
    let s = size * scale / 18.0        // 単位。錨は縦およそ18単位
    let cx = size / 2
    let originY = size * 0.5 - 10.5 * s // 錨の縦中心(10.5s)を中央へ

    func y(_ f: CGFloat) -> CGFloat { originY + f * s }

    ctx.setStrokeColor(anchorColor)
    ctx.setFillColor(anchorColor)
    ctx.setLineWidth(s * 1.5)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    // リング(輪)
    let ringRect = CGRect(x: cx - 2.6 * s, y: y(1.5), width: 5.2 * s, height: 5.2 * s)
    ctx.strokeEllipse(in: ringRect)

    let path = CGMutablePath()
    // シャフト(縦棒)
    path.move(to: CGPoint(x: cx, y: y(6.7)))
    path.addLine(to: CGPoint(x: cx, y: y(19.5)))
    // クロスバー(横棒)
    path.move(to: CGPoint(x: cx - 4.5 * s, y: y(10.5)))
    path.addLine(to: CGPoint(x: cx + 4.5 * s, y: y(10.5)))
    // 左のフルーク(腕)
    path.move(to: CGPoint(x: cx, y: y(19.5)))
    path.addQuadCurve(to: CGPoint(x: cx - 7.2 * s, y: y(13)),
                      control: CGPoint(x: cx - 5.5 * s, y: y(19)))
    // 右のフルーク
    path.move(to: CGPoint(x: cx, y: y(19.5)))
    path.addQuadCurve(to: CGPoint(x: cx + 7.2 * s, y: y(13)),
                      control: CGPoint(x: cx + 5.5 * s, y: y(19)))
    ctx.addPath(path)
    ctx.strokePath()
}

// MARK: - 出力

func write(_ ctx: CGContext, to path: String) {
    let url = URL(fileURLWithPath: path)
    let img = ctx.makeImage()!
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(path)")
}

// フルアイコン(背景+錨)
func renderFull(_ px: Int, to path: String) {
    let ctx = makeContext(px)
    let size = CGFloat(px)
    drawBackground(ctx, size)
    drawAnchor(ctx, size, scale: 0.54) // 縦占有 ~54%
    write(ctx, to: path)
}

// アダプティブ前景(錨のみ・透過。セーフゾーン内に収める)
func renderForeground(_ px: Int, to path: String) {
    let ctx = makeContext(px)
    let size = CGFloat(px)
    drawAnchor(ctx, size, scale: 0.44) // 少し小さめ(セーフゾーン内)
    write(ctx, to: path)
}

// アダプティブ背景(グラデーションのみ)
func renderBackground(_ px: Int, to path: String) {
    let ctx = makeContext(px)
    drawBackground(ctx, CGFloat(px))
    write(ctx, to: path)
}

let out = CommandLine.arguments[1]
let fm = FileManager.default
func mkdir(_ p: String) { try? fm.createDirectory(atPath: p, withIntermediateDirectories: true) }

// iOS
mkdir("\(out)/ios")
renderFull(1024, to: "\(out)/ios/AppIcon.png")

// Android: 密度
let legacy: [(String, Int)] = [("mdpi",48),("hdpi",72),("xhdpi",96),("xxhdpi",144),("xxxhdpi",192)]
let adaptive: [(String, Int)] = [("mdpi",108),("hdpi",162),("xhdpi",216),("xxhdpi",324),("xxxhdpi",432)]

for (name, sz) in legacy {
    let dir = "\(out)/android/res/mipmap-\(name)"
    mkdir(dir)
    renderFull(sz, to: "\(dir)/ic_launcher.png")
    renderFull(sz, to: "\(dir)/ic_launcher_round.png")
}
for (name, sz) in adaptive {
    let dir = "\(out)/android/res/mipmap-\(name)"
    mkdir(dir)
    renderForeground(sz, to: "\(dir)/ic_launcher_foreground.png")
    renderBackground(sz, to: "\(dir)/ic_launcher_background.png")
}

// Play Store 用の512
mkdir("\(out)/android/play")
renderFull(512, to: "\(out)/android/play/ic_launcher-web-512.png")

print("done")
