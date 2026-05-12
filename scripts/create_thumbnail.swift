import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let rgbaBitmapInfo = CGBitmapInfo.byteOrder32Big.union(
    CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
)

struct Args {
    let sourcePath: String
    let logoPath: String
    let outputPath: String
    let outputWidth: Int
    let outputHeight: Int
    let logoLeft: Int
    let logoTop: Int
    let logoWidth: Int
    let labelLeft: Int?
    let labelBottom: Int?
    let labelGap: Int?
    let labelTexts: [String]
}

struct LabelSpec {
    let text: String
    let borderColor: CGColor
    let textColor: CGColor
}

func renderSVGLogoIfNeeded(sourcePath: String, targetWidth: Int) -> String? {
    guard sourcePath.lowercased().hasSuffix(".svg") else { return sourcePath }

    let fileManager = FileManager.default
    let cwd = fileManager.currentDirectoryPath
    let rendererScriptPath = URL(fileURLWithPath: cwd)
        .appendingPathComponent("scripts/render_svg_logo.swift").path
    let outputPath = URL(fileURLWithPath: cwd)
        .appendingPathComponent("outputs/tmp_logo")
        .appendingPathComponent("rendered-logo-\(targetWidth).png").path

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
    process.arguments = [rendererScriptPath, sourcePath, outputPath, String(targetWidth)]
    process.standardOutput = Pipe()
    process.standardError = Pipe()

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        return nil
    }

    guard process.terminationStatus == 0 else { return nil }
    return outputPath
}

func parseArgs() -> Args? {
    let values = Array(CommandLine.arguments.dropFirst())
    guard values.count == 8 || values.count >= 12 else { return nil }

    guard
        let outputWidth = Int(values[3]),
        let outputHeight = Int(values[4]),
        let logoLeft = Int(values[5]),
        let logoTop = Int(values[6]),
        let logoWidth = Int(values[7])
    else {
        return nil
    }

    var labelLeft: Int?
    var labelBottom: Int?
    var labelGap: Int?
    var labelTexts: [String] = []

    if values.count >= 12 {
        guard
            let parsedLabelLeft = Int(values[8]),
            let parsedLabelBottom = Int(values[9]),
            let parsedLabelGap = Int(values[10])
        else {
            return nil
        }

        labelLeft = parsedLabelLeft
        labelBottom = parsedLabelBottom
        labelGap = parsedLabelGap
        labelTexts = Array(values.dropFirst(11)).filter { !$0.isEmpty }
    }

    return Args(
        sourcePath: values[0],
        logoPath: values[1],
        outputPath: values[2],
        outputWidth: outputWidth,
        outputHeight: outputHeight,
        logoLeft: logoLeft,
        logoTop: logoTop,
        logoWidth: logoWidth,
        labelLeft: labelLeft,
        labelBottom: labelBottom,
        labelGap: labelGap,
        labelTexts: Array(labelTexts.prefix(2))
    )
}

func loadCGImage(at path: String) -> CGImage? {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let source = CGImageSourceCreateWithURL(url, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

func centerCropRect(for image: CGImage) -> CGRect {
    let width = CGFloat(image.width)
    let height = CGFloat(image.height)
    let edge = min(width, height)
    let x = (width - edge) / 2.0
    let y = (height - edge) / 2.0
    return CGRect(x: x, y: y, width: edge, height: edge)
}

func hasVisibleContent(_ pixels: UnsafePointer<UInt8>, alphaIndex: Int) -> Bool {
    let alpha = pixels[alphaIndex]
    if alpha == 0 { return false }

    let red = pixels[alphaIndex - 3]
    let green = pixels[alphaIndex - 2]
    let blue = pixels[alphaIndex - 1]

    let isNearWhite = red >= 245 && green >= 245 && blue >= 245
    return !isNearWhite
}

func trimmedImage(_ image: CGImage) -> CGImage? {
    let width = image.width
    let height = image.height
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let bitsPerComponent = 8

    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return image }
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: bitsPerComponent,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: rgbaBitmapInfo.rawValue
    ) else {
        return image
    }

    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

    guard let data = context.data else { return image }
    let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

    var minX = width
    var minY = height
    var maxX = -1
    var maxY = -1

    for y in 0..<height {
        for x in 0..<width {
            let alphaIndex = y * bytesPerRow + x * bytesPerPixel + 3
            if hasVisibleContent(pixels, alphaIndex: alphaIndex) {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
    }

    guard maxX >= minX, maxY >= minY else { return image }

    let trimRect = CGRect(
        x: minX,
        y: minY,
        width: maxX - minX + 1,
        height: maxY - minY + 1
    )

    return image.cropping(to: trimRect)
}

func imageByRemovingNearWhiteBackground(
    _ image: CGImage,
    threshold: UInt8 = 245
) -> CGImage? {
    let width = image.width
    let height = image.height
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel

    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return image }
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: rgbaBitmapInfo.rawValue
    ) else {
        return image
    }

    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

    guard let data = context.data else { return image }
    let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

    for y in 0..<height {
        for x in 0..<width {
            let offset = y * bytesPerRow + x * bytesPerPixel
            let red = pixels[offset]
            let green = pixels[offset + 1]
            let blue = pixels[offset + 2]
            let alpha = pixels[offset + 3]

            if alpha == 0 {
                continue
            }

            if red >= threshold, green >= threshold, blue >= threshold {
                pixels[offset] = 0
                pixels[offset + 1] = 0
                pixels[offset + 2] = 0
                pixels[offset + 3] = 0
            }
        }
    }

    return context.makeImage()
}

func resolveLabelText(_ raw: String) -> String {
    switch raw.lowercased() {
    case "free_shipping":
        return "무료배송"
    case "mix_and_match_discount":
        return "골라담아할인"
    default:
        return raw
    }
}

func colorFromHex(_ raw: String) -> CGColor? {
    let hex = raw.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
    guard hex.count == 6, let value = Int(hex, radix: 16) else { return nil }
    let red = CGFloat((value >> 16) & 0xFF) / 255.0
    let green = CGFloat((value >> 8) & 0xFF) / 255.0
    let blue = CGFloat(value & 0xFF) / 255.0
    return CGColor(red: red, green: green, blue: blue, alpha: 1.0)
}

func parseLabelSpec(_ raw: String) -> LabelSpec? {
    let parts = raw.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
    guard let first = parts.first, !first.isEmpty else { return nil }

    let defaultBlack = CGColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    var borderColor = defaultBlack
    var textColor = defaultBlack

    if parts.count >= 2, !parts[1].isEmpty {
        guard let parsed = colorFromHex(parts[1]) else { return nil }
        borderColor = parsed
    }

    if parts.count >= 3, !parts[2].isEmpty {
        guard let parsed = colorFromHex(parts[2]) else { return nil }
        textColor = parsed
    }

    return LabelSpec(
        text: resolveLabelText(first),
        borderColor: borderColor,
        textColor: textColor
    )
}

func labelFontSize(for height: CGFloat) -> CGFloat {
    max(12, round(height * 0.44))
}

func labelHorizontalPadding(for height: CGFloat) -> CGFloat {
    max(12, round(height * 0.31))
}

func makeLabelLine(_ text: String, fontSize: CGFloat, textColor: CGColor) -> CTLine {
    let font = CTFontCreateUIFontForLanguage(.system, fontSize, nil)
        ?? CTFontCreateWithName("AppleSDGothicNeo-Bold" as CFString, fontSize, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(rawValue: kCTFontAttributeName as String): font,
        NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): textColor,
    ]
    let attributed = NSAttributedString(string: text, attributes: attributes)
    return CTLineCreateWithAttributedString(attributed)
}

func drawLabel(
    in context: CGContext,
    spec: LabelSpec,
    origin: CGPoint,
    height: CGFloat
) -> CGFloat {
    let fontSize = labelFontSize(for: height)
    let horizontalPadding = labelHorizontalPadding(for: height)
    let line = makeLabelLine(spec.text, fontSize: fontSize, textColor: spec.textColor)

    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    let textWidth = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
    let labelWidth = ceil(textWidth + horizontalPadding * 2)
    let rect = CGRect(x: origin.x, y: origin.y, width: labelWidth, height: height)

    context.saveGState()
    context.setStrokeColor(spec.borderColor)
    context.setLineWidth(2)
    context.stroke(rect.insetBy(dx: 1, dy: 1))

    context.textMatrix = .identity
    let textX = rect.minX + (rect.width - textWidth) / 2.0
    let textY = rect.minY + (rect.height - (ascent + descent)) / 2.0 + descent
    context.textPosition = CGPoint(x: textX, y: textY)
    CTLineDraw(line, context)
    context.restoreGState()

    return labelWidth
}

guard let args = parseArgs() else {
    fputs("usage: create_thumbnail.swift <source> <logo> <output> <width> <height> <logo_left> <logo_top> <logo_width> [<label_left> <label_bottom> <label_gap> <label_text1> [<label_text2>]]\n", stderr)
    exit(1)
}

guard let sourceImage = loadCGImage(at: args.sourcePath) else {
    fputs("failed to load source image\n", stderr)
    exit(1)
}

let resolvedLogoPath = renderSVGLogoIfNeeded(sourcePath: args.logoPath, targetWidth: args.logoWidth) ?? args.logoPath

guard let loadedLogoImage = loadCGImage(at: resolvedLogoPath) else {
    fputs("failed to load logo image\n", stderr)
    exit(1)
}
let logoWithoutWhiteBackground = imageByRemovingNearWhiteBackground(loadedLogoImage) ?? loadedLogoImage
let logoImage = trimmedImage(logoWithoutWhiteBackground) ?? logoWithoutWhiteBackground

let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = rgbaBitmapInfo.rawValue

guard let context = CGContext(
    data: nil,
    width: args.outputWidth,
    height: args.outputHeight,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: bitmapInfo
) else {
    fputs("failed to create bitmap context\n", stderr)
    exit(1)
}

context.interpolationQuality = .high
context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0))
context.fill(CGRect(x: 0, y: 0, width: args.outputWidth, height: args.outputHeight))

let cropRect = centerCropRect(for: sourceImage)
guard let croppedSource = sourceImage.cropping(to: cropRect.integral) else {
    fputs("failed to crop source image\n", stderr)
    exit(1)
}

context.draw(croppedSource, in: CGRect(x: 0, y: 0, width: args.outputWidth, height: args.outputHeight))

let logoAspect = CGFloat(logoImage.height) / CGFloat(logoImage.width)
let logoHeight = Int(round(CGFloat(args.logoWidth) * logoAspect))
let logoY = args.outputHeight - args.logoTop - logoHeight
let logoRect = CGRect(x: args.logoLeft, y: logoY, width: args.logoWidth, height: logoHeight)
context.draw(logoImage, in: logoRect)

if !args.labelTexts.isEmpty {
    guard
        let labelLeft = args.labelLeft,
        let labelBottom = args.labelBottom,
        let labelGap = args.labelGap
    else {
        fputs("missing label layout values\n", stderr)
        exit(1)
    }

    var currentX = labelLeft

    for labelText in args.labelTexts {
        guard let labelSpec = parseLabelSpec(labelText) else {
            fputs("failed to parse label spec: \(labelText)\n", stderr)
            exit(1)
        }

        let scaledLabelHeight = CGFloat(logoHeight)
        let labelY = CGFloat(labelBottom)
        let usedWidth = drawLabel(
            in: context,
            spec: labelSpec,
            origin: CGPoint(x: CGFloat(currentX), y: labelY),
            height: scaledLabelHeight
        )
        currentX += Int(ceil(usedWidth)) + labelGap
    }
}

guard let outputImage = context.makeImage() else {
    fputs("failed to create output image\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: args.outputPath)
let outputDir = outputURL.deletingLastPathComponent()

do {
    try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
} catch {
    fputs("failed to create output directory: \(error)\n", stderr)
    exit(1)
}

guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fputs("failed to create image destination\n", stderr)
    exit(1)
}

CGImageDestinationAddImage(destination, outputImage, nil)

if CGImageDestinationFinalize(destination) {
    print(outputURL.path)
} else {
    fputs("failed to write png output\n", stderr)
    exit(1)
}
