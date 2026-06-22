//
//  CpuinfoImage.swift
//  cpuinfo
//
//  NSImage subclass that renders the CPU usage bar/text shown in the menu bar.
//

import Cocoa

final class CpuinfoImage: NSImage {

  private static let height: CGFloat = 24.0
  private static let textWidth: CGFloat = 36.0
  private static let textHeight: CGFloat = 20.0

  private var cpuinfo: Cpuinfo?

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
    var colorCode: UInt32 = 0
    if let string = string {
      Scanner(string: string).scanHexInt32(&colorCode)
    }
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
    let iteration = multiCoreEnabled ? Int(cpuinfo?.getCoreCount() ?? 0) : 1
    let barWidth = CGFloat(double(forKey: "BAR_WIDTH"))
    let barCoreWidth = CGFloat(double(forKey: "BAR_COREWIDTH"))
    let barCoreMargin = CGFloat(double(forKey: "BAR_COREMARGIN"))

    for _ in 0..<iteration {
      if multiCoreEnabled {
        // Force image view on MultiCore mode
        width += barCoreWidth
        width += barCoreMargin
      } else {
        if imageEnabled { width += barWidth }
        if textEnabled { width += CpuinfoImage.textWidth }
      }
    }

    size = NSSize(width: width, height: CpuinfoImage.height)
    update()
  }

  // MARK: - Drawing

  @discardableResult
  private func drawImage(at usage: Double, offset: CGFloat) -> CGFloat {
    let barTotalWidth = CGFloat(double(forKey: "BAR_WIDTH"))
    let barCoreWidth = CGFloat(double(forKey: "BAR_COREWIDTH"))
    let barWidth = multiCoreEnabled ? barCoreWidth : barTotalWidth
    let barHeight = CGFloat(double(forKey: "BAR_HEIGHT"))
    let barRadius = CGFloat(double(forKey: "BAR_RADIUS"))
    let bgColor = color(forKey: "BAR_BACKGROUNDCOLOR")
    let borderColor = color(forKey: "BORDER_COLOR")
    let borderRadius = CGFloat(double(forKey: "BORDER_RADIUS"))
    let borderWidth = CGFloat(double(forKey: "BORDER_WIDTH"))

    NSGraphicsContext.saveGraphicsState()

    // clip rounded
    let bgRect = NSRect(x: offset,
                        y: (CpuinfoImage.height - barHeight) / 2,
                        width: barWidth,
                        height: barHeight)
    NSBezierPath(roundedRect: bgRect, xRadius: borderRadius, yRadius: borderRadius).addClip()

    // background
    bgColor.set()
    let bg = NSBezierPath()
    bg.appendRoundedRect(bgRect, xRadius: borderRadius, yRadius: borderRadius)
    bg.fill()

    // border
    if borderWidth > 0 {
      borderColor.set()
      let border = NSBezierPath()
      border.appendRoundedRect(bgRect, xRadius: borderRadius, yRadius: borderRadius)
      border.lineWidth = borderWidth
      border.stroke()
    }

    // usage
    imageColor(forUsage: usage).set()
    let bar = NSBezierPath()
    let barRect = NSRect(x: offset + borderWidth * 2,
                         y: (CpuinfoImage.height - barHeight) / 2 + borderWidth * 2,
                         width: (barWidth - borderWidth * 4) * CGFloat(usage),
                         height: barHeight - borderWidth * 4)
    bar.appendRoundedRect(barRect, xRadius: barRadius, yRadius: barRadius)
    bar.fill()

    NSGraphicsContext.restoreGraphicsState()

    return offset + barWidth
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
      let barCoreMargin = CGFloat(int(forKey: "BAR_COREMARGIN"))
      let count = Int(cpuinfo?.getCoreCount() ?? 0)
      for i in 0..<count {
        let coreUsage = cpuinfo?.getCoreUsageAt(UInt(i)) ?? 0
        // Force image view on MultiCore mode
        offset = drawImage(at: coreUsage, offset: offset)
        offset += barCoreMargin
      }
    } else {
      let hostUsage = cpuinfo?.getHostUsage() ?? 0
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
