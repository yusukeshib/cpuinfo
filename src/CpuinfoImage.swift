//
//  CpuinfoImage.swift
//  cpuinfo
//
//  NSImage subclass that renders the CPU usage bar/text shown in the menu bar.
//

import Cocoa

// Mutable state is only ever touched from the main thread; the explicit
// @unchecked Sendable opts out of the conformance check inherited from NSImage.
final class CpuinfoImage: NSImage, @unchecked Sendable {

  private static let height: CGFloat = 24.0
  private static let textWidth: CGFloat = 36.0
  private static let textHeight: CGFloat = 20.0

  // Per-core ("individual") mode is drawn as a compact vertical-bar equalizer.
  private static let coreBarWidth: CGFloat = 3.0
  private static let coreBarGap: CGFloat = 2.0
  private static let coreInset: CGFloat = 2.0
  private static let coreTrackHeight: CGFloat = 14.0

  // Single ("one-meter") mode is a slim horizontal pill: track + colored fill.
  private static let singleBarHeight: CGFloat = 8.0

  // Faint neutral track shared by both meter styles.
  private var trackColor: NSColor {
    darkMode ? NSColor(white: 1.0, alpha: 0.18) : NSColor(white: 0.0, alpha: 0.15)
  }

  private var cpuinfo: Cpuinfo!

  var darkMode = false
  var theme: String?

  var imageEnabled = false {
    didSet { updateSize() }
  }
  var textEnabled = false {
    didSet { updateSize() }
  }
  var multiCoreEnabled = false {
    didSet { updateSize() }
  }

  func setCpuinfo(_ cpuinfo: Cpuinfo) {
    self.cpuinfo = cpuinfo
  }

  // MARK: - Theme lookup

  // https://stackoverflow.com/questions/8697205/convert-hex-color-code-to-nscolor
  private func color(hex string: String?) -> NSColor {
    // Hex string is RRGGBBAA (8 digits). Parse as UInt64 to tolerate the full
    // 32-bit range, then keep the low 32 bits.
    let colorCode = UInt32(truncatingIfNeeded: string.flatMap { UInt64($0, radix: 16) } ?? 0)
    let red = CGFloat((colorCode >> 24) & 0xff) / 0xff
    let green = CGFloat((colorCode >> 16) & 0xff) / 0xff
    let blue = CGFloat((colorCode >> 8) & 0xff) / 0xff
    let alpha = CGFloat(colorCode & 0xff) / 0xff
    return NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
  }

  private func currentTheme() -> [String: Any] {
    guard let themes = Bundle.main.object(forInfoDictionaryKey: "theme") as? [[String: Any]],
          !themes.isEmpty else {
      return [:]
    }
    var selected = themes[0]
    for item in themes {
      if let name = item["name"] as? String, name == theme {
        selected = item
        break
      }
    }
    let key = darkMode ? "dark" : "light"
    return (selected[key] as? [String: Any]) ?? [:]
  }

  private func color(forKey key: String) -> NSColor {
    return color(hex: currentTheme()[key] as? String)
  }

  private func int(forKey key: String) -> Int {
    let value = currentTheme()[key]
    if let number = value as? NSNumber { return number.intValue }
    if let string = value as? String { return Int(string) ?? 0 }
    return 0
  }

  private func double(forKey key: String) -> Double {
    let value = currentTheme()[key]
    if let number = value as? NSNumber { return number.doubleValue }
    if let string = value as? String { return Double(string) ?? 0 }
    return 0
  }

  private func textColor(forUsage usage: Double) -> NSColor {
    if usage < 0.75 { return color(forKey: "TEXT_NORMALCOLOR") }
    if usage < 0.9 { return color(forKey: "TEXT_MEDIUMCOLOR") }
    return color(forKey: "TEXT_HIGHCOLOR")
  }

  private func imageColor(forUsage usage: Double) -> NSColor {
    if usage < 0.75 { return color(forKey: "BAR_NORMALCOLOR") }
    if usage < 0.9 { return color(forKey: "BAR_MEDIUMCOLOR") }
    return color(forKey: "BAR_HIGHCOLOR")
  }

  // MARK: - Layout

  private func updateSize() {
    var width: CGFloat = 0

    if multiCoreEnabled {
      // Vertical equalizer: one thin bar per core with a small gap.
      let count = CGFloat(cpuinfo.getCoreCount())
      if count > 0 {
        width = count * CpuinfoImage.coreBarWidth
          + max(0, count - 1) * CpuinfoImage.coreBarGap
          + CpuinfoImage.coreInset * 2
      }
    } else {
      if imageEnabled { width += CGFloat(double(forKey: "BAR_WIDTH")) }
      if textEnabled { width += CpuinfoImage.textWidth }
    }

    size = NSSize(width: width, height: CpuinfoImage.height)
    update()
  }

  // MARK: - Drawing

  // Single overall meter: a slim horizontal pill that fills left -> right,
  // matching the equalizer's track + usage-colored fill aesthetic.
  @discardableResult
  private func drawImage(at usage: Double, offset: CGFloat) -> CGFloat {
    let barWidth = CGFloat(double(forKey: "BAR_WIDTH"))
    let barH = CpuinfoImage.singleBarHeight
    let radius = barH / 2
    let y = (CpuinfoImage.height - barH) / 2
    let u = max(0.0, min(1.0, usage))

    // track
    trackColor.set()
    NSBezierPath(roundedRect: NSRect(x: offset, y: y, width: barWidth, height: barH),
                 xRadius: radius, yRadius: radius).fill()

    // usage fill (min width keeps a visible rounded nub at 0%)
    let fillW = max(barH, CGFloat(u) * barWidth)
    imageColor(forUsage: u).set()
    NSBezierPath(roundedRect: NSRect(x: offset, y: y, width: fillW, height: barH),
                 xRadius: radius, yRadius: radius).fill()

    return offset + barWidth
  }

  // Per-core vertical bars (equalizer style), drawn over a faint track.
  private func drawCoreBars() {
    let count = Int(cpuinfo.getCoreCount())
    guard count > 0 else { return }

    let barW = CpuinfoImage.coreBarWidth
    let gap = CpuinfoImage.coreBarGap
    let radius = barW / 2
    let trackH = CpuinfoImage.coreTrackHeight
    let baseY = (CpuinfoImage.height - trackH) / 2
    let minH = barW // small rounded nub even at 0%

    var x = CpuinfoImage.coreInset
    for i in 0..<count {
      let usage = max(0.0, min(1.0, cpuinfo.getCoreUsageAt(UInt(i))))

      // track
      trackColor.set()
      let trackRect = NSRect(x: x, y: baseY, width: barW, height: trackH)
      NSBezierPath(roundedRect: trackRect, xRadius: radius, yRadius: radius).fill()

      // usage bar (grows upward from the baseline)
      let h = max(minH, CGFloat(usage) * trackH)
      imageColor(forUsage: usage).set()
      let barRect = NSRect(x: x, y: baseY, width: barW, height: h)
      NSBezierPath(roundedRect: barRect, xRadius: radius, yRadius: radius).fill()

      x += barW + gap
    }
  }

  @discardableResult
  private func drawText(at usage: Double, offset: CGFloat) -> CGFloat {
    NSGraphicsContext.saveGraphicsState()

    let font = NSFont.menuBarFont(ofSize: NSFont.systemFontSize)
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .paragraphStyle: style,
      .foregroundColor: textColor(forUsage: usage)
    ]
    let str = String(format: "%d%%", Int(round(usage * 100.0)))
    let text = NSAttributedString(string: str, attributes: attributes)
    let rect = NSRect(x: offset,
                      y: (CpuinfoImage.height - CpuinfoImage.textHeight) / 2,
                      width: CpuinfoImage.textWidth,
                      height: CpuinfoImage.textHeight)
    text.draw(in: rect)

    NSGraphicsContext.restoreGraphicsState()

    return offset + CpuinfoImage.textWidth
  }

  func update() {
    let w = size.width
    let h = size.height
    guard w != 0, h != 0 else { return }

    lockFocus()

    // clear all
    let rect = NSRect(x: 0, y: 0, width: w, height: h)
    draw(in: rect, from: rect, operation: .clear, fraction: 1.0)

    var offset: CGFloat = 0

    if multiCoreEnabled {
      drawCoreBars()
    } else {
      let hostUsage = cpuinfo.getHostUsage()
      if imageEnabled {
        offset = drawImage(at: hostUsage, offset: offset)
      }
      if textEnabled {
        offset = drawText(at: hostUsage, offset: offset)
      }
    }

    unlockFocus()
  }
}
