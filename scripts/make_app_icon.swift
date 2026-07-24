import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: a)
}

// テラコッタ地に黒い塗りの錨
let terracotta = rgb(0xC0, 0x5B, 0x49)
let anchorBlack = rgb(0x16, 0x14, 0x12)

let colorSpace = CGColorSpaceCreateDeviceRGB()

func makeContext(_ size: Int) -> CGContext {
    let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    ctx.translateBy(x: 0, y: CGFloat(size))
    ctx.scaleBy(x: 1, y: -1) // y下向き
    return ctx
}

func drawBackground(_ ctx: CGContext, _ size: CGFloat) {
    ctx.setFillColor(terracotta)
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
}

// 塗りつぶしの錨。scale は アイコンに対する縦の占有率。
// holeColor が nil の場合、輪の穴を透過(アダプティブ前景用)にする。
func drawAnchor(_ ctx: CGContext, _ size: CGFloat, scale: CGFloat, holeColor: CGColor?) {
    // 設計座標(1024基準)。錨の外接: x[150,874] y[152,840]
    let designH: CGFloat = 840 - 152
    let k = size * scale / designH
    let cx = size / 2, cy = size / 2
    func T(_ dx: CGFloat, _ dy: CGFloat) -> CGPoint {
        CGPoint(x: cx + (dx - 512) * k, y: cy + (dy - 496) * k)
    }
    func rect(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat) -> CGRect {
        let a = T(x0, y0), b = T(x1, y1)
        return CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(b.x - a.x), height: abs(b.y - a.y))
    }

    ctx.setFillColor(anchorBlack)

    // 各パーツを個別に塗って確実に合成する(1パスにまとめると重なりで打ち消される)
    let rc = T(512, 250); let ro = 98 * k

    // 輪(外円)
    ctx.fillEllipse(in: CGRect(x: rc.x - ro, y: rc.y - ro, width: 2 * ro, height: 2 * ro))

    // シャフト(縦棒。下は三日月の底まで伸ばして繋げる)
    ctx.addPath(CGPath(roundedRect: rect(483, 300, 541, 815), cornerWidth: 10 * k, cornerHeight: 10 * k, transform: nil))
    ctx.fillPath()

    // クロスバー(横棒・両端丸)
    let cb = rect(272, 401, 752, 459)
    ctx.addPath(CGPath(roundedRect: cb, cornerWidth: cb.height / 2, cornerHeight: cb.height / 2, transform: nil))
    ctx.fillPath()

    // フルーク(三日月状の腕)
    let fluke = CGMutablePath()
    fluke.move(to: T(150, 505))
    fluke.addCurve(to: T(512, 840), control1: T(180, 790), control2: T(330, 840))
    fluke.addCurve(to: T(874, 505), control1: T(694, 840), control2: T(844, 790))
    fluke.addCurve(to: T(512, 735), control1: T(778, 655), control2: T(620, 735))
    fluke.addCurve(to: T(150, 505), control1: T(404, 735), control2: T(246, 655))
    fluke.closeSubpath()
    ctx.addPath(fluke)
    ctx.fillPath()

    // 輪の穴
    let ri = 45 * k
    let holeRect = CGRect(x: rc.x - ri, y: rc.y - ri, width: 2 * ri, height: 2 * ri)
    if let holeColor {
        ctx.setFillColor(holeColor)
        ctx.fillEllipse(in: holeRect)
    } else {
        ctx.setBlendMode(.clear)
        ctx.fillEllipse(in: holeRect)
        ctx.setBlendMode(.normal)
    }
}

func write(_ ctx: CGContext, to path: String) {
    let url = URL(fileURLWithPath: path)
    let img = ctx.makeImage()!
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}

func renderFull(_ px: Int, to path: String) {
    let ctx = makeContext(px)
    let size = CGFloat(px)
    drawBackground(ctx, size)
    drawAnchor(ctx, size, scale: 0.66, holeColor: terracotta)
    write(ctx, to: path)
    print("wrote \(path)")
}

func renderForeground(_ px: Int, to path: String) {
    let ctx = makeContext(px)
    drawAnchor(ctx, CGFloat(px), scale: 0.5, holeColor: nil) // セーフゾーン内
    write(ctx, to: path)
    print("wrote \(path)")
}

func renderBackground(_ px: Int, to path: String) {
    let ctx = makeContext(px)
    drawBackground(ctx, CGFloat(px))
    write(ctx, to: path)
    print("wrote \(path)")
}

let out = CommandLine.arguments[1]
let fm = FileManager.default
func mkdir(_ p: String) { try? fm.createDirectory(atPath: p, withIntermediateDirectories: true) }

mkdir("\(out)/ios")
renderFull(1024, to: "\(out)/ios/AppIcon.png")

let legacy: [(String, Int)] = [("mdpi",48),("hdpi",72),("xhdpi",96),("xxhdpi",144),("xxxhdpi",192)]
let adaptive: [(String, Int)] = [("mdpi",108),("hdpi",162),("xhdpi",216),("xxhdpi",324),("xxxhdpi",432)]
for (name, sz) in legacy {
    let dir = "\(out)/android/res/mipmap-\(name)"; mkdir(dir)
    renderFull(sz, to: "\(dir)/ic_launcher.png")
    renderFull(sz, to: "\(dir)/ic_launcher_round.png")
}
for (name, sz) in adaptive {
    let dir = "\(out)/android/res/mipmap-\(name)"; mkdir(dir)
    renderForeground(sz, to: "\(dir)/ic_launcher_foreground.png")
    renderBackground(sz, to: "\(dir)/ic_launcher_background.png")
}
mkdir("\(out)/android/play")
renderFull(512, to: "\(out)/android/play/ic_launcher-web-512.png")
print("done")
