import AppKit
import Foundation
import WebKit

struct Args {
    let sourcePath: String
    let outputPath: String
    let targetWidth: Int
}

func parseArgs() -> Args? {
    let values = Array(CommandLine.arguments.dropFirst())
    guard values.count == 3, let targetWidth = Int(values[2]), targetWidth > 0 else {
        return nil
    }
    return Args(sourcePath: values[0], outputPath: values[1], targetWidth: targetWidth)
}

func extractViewBoxSize(from svg: String) -> CGSize? {
    let pattern = #"viewBox\s*=\s*"[^"]*?([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)""#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(svg.startIndex..<svg.endIndex, in: svg)
    guard let match = regex.firstMatch(in: svg, range: range),
          let widthRange = Range(match.range(at: 3), in: svg),
          let heightRange = Range(match.range(at: 4), in: svg),
          let width = Double(svg[widthRange]),
          let height = Double(svg[heightRange]),
          width > 0, height > 0 else {
        return nil
    }
    return CGSize(width: width, height: height)
}

func extractExplicitSize(from svg: String) -> CGSize? {
    let pattern = #"(width|height)\s*=\s*"([0-9.]+)(px)?""#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(svg.startIndex..<svg.endIndex, in: svg)
    let matches = regex.matches(in: svg, range: range)
    var width: Double?
    var height: Double?
    for match in matches {
        guard let keyRange = Range(match.range(at: 1), in: svg),
              let valueRange = Range(match.range(at: 2), in: svg),
              let value = Double(svg[valueRange]) else {
            continue
        }
        let key = String(svg[keyRange])
        if key == "width" { width = value }
        if key == "height" { height = value }
    }
    if let width, let height, width > 0, height > 0 {
        return CGSize(width: width, height: height)
    }
    return nil
}

func intrinsicSVGSize(from svg: String) -> CGSize? {
    extractViewBoxSize(from: svg) ?? extractExplicitSize(from: svg)
}

guard let args = parseArgs() else {
    fputs("usage: render_svg_logo.swift <source_svg> <output_png> <target_width>\n", stderr)
    exit(1)
}

let sourceURL = URL(fileURLWithPath: args.sourcePath)
guard let svgString = try? String(contentsOf: sourceURL, encoding: .utf8) else {
    fputs("failed to read svg source\n", stderr)
    exit(1)
}

guard let intrinsicSize = intrinsicSVGSize(from: svgString) else {
    fputs("failed to determine svg size\n", stderr)
    exit(1)
}

let targetWidth = CGFloat(args.targetWidth)
let targetHeight = max(1, round(targetWidth * intrinsicSize.height / intrinsicSize.width))
let frame = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)

_ = NSApplication.shared
NSApp.setActivationPolicy(.prohibited)

let configuration = WKWebViewConfiguration()
let webView = WKWebView(frame: frame, configuration: configuration)
webView.setValue(false, forKey: "drawsBackground")

let html = """
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<style>
html, body {
  margin: 0;
  padding: 0;
  width: \(Int(targetWidth))px;
  height: \(Int(targetHeight))px;
  background: transparent;
  overflow: hidden;
}
svg {
  display: block;
  width: \(Int(targetWidth))px;
  height: \(Int(targetHeight))px;
}
</style>
</head>
<body>
\(svgString)
</body>
</html>
"""

final class SnapshotDelegate: NSObject, WKNavigationDelegate {
    let webView: WKWebView
    let outputPath: String
    var finished = false
    var errorMessage: String?

    init(webView: WKWebView, outputPath: String) {
        self.webView = webView
        self.outputPath = outputPath
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let config = WKSnapshotConfiguration()
        config.rect = webView.bounds
        webView.takeSnapshot(with: config) { image, error in
            if let error {
                self.errorMessage = "snapshot failed: \(error)"
                self.finished = true
                return
            }

            guard let image,
                  let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                self.errorMessage = "failed to encode png"
                self.finished = true
                return
            }

            do {
                try FileManager.default.createDirectory(
                    at: URL(fileURLWithPath: self.outputPath).deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try pngData.write(to: URL(fileURLWithPath: self.outputPath))
            } catch {
                self.errorMessage = "failed to write png: \(error)"
            }
            self.finished = true
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        errorMessage = "navigation failed: \(error)"
        finished = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        errorMessage = "navigation failed: \(error)"
        finished = true
    }
}

let delegate = SnapshotDelegate(webView: webView, outputPath: args.outputPath)
webView.navigationDelegate = delegate
webView.loadHTMLString(html, baseURL: sourceURL.deletingLastPathComponent())

while !delegate.finished {
    RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
}

if let errorMessage = delegate.errorMessage {
    fputs("\(errorMessage)\n", stderr)
    exit(1)
}

print(args.outputPath)
