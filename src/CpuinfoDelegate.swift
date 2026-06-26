//
//  CpuinfoDelegate.swift
//  cpuinfo
//
//  Application delegate: owns the status item, the sampling loop and the menu.
//

import Cocoa

@objc(CpuinfoDelegate)
final class CpuinfoDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow?
  @IBOutlet var statusMenu: NSMenu?
  @IBOutlet var mi_updateInterval: NSMenuItem?
  @IBOutlet var mi_theme: NSMenuItem?
  @IBOutlet var mi_viewMode: NSMenuItem?

  // KVO-compliant properties bound from MainMenu.xib menu items.
  @objc dynamic var startAtLogin = false
  @objc dynamic var showCoresIndividually = false
  @objc dynamic var showImage = false
  @objc dynamic var showText = false

  private var statusItem: NSStatusItem!
  private var loginController: StartAtLoginController!
  private var running = false
  private var updateInterval: Int = 500
  private let cpuinfo = Cpuinfo()
  private var group: DispatchGroup?
  private let image = CpuinfoImage()

  // MARK: - Lifecycle

  override func awakeFromNib() {
    super.awakeFromNib()

    image.setCpuinfo(cpuinfo)

    // initialize StatusItem
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.menu = statusMenu
    statusItem.button?.title = ""

    // Retrieve params from UserDefaults
    let defaults = UserDefaults.standard
    defaults.register(defaults: [
      "updateInterval": 500,
      "showImage": true,
      "showText": false,
      "showCoresIndividually": true
    ])
    updateInterval = defaults.integer(forKey: "updateInterval")
    image.theme = defaults.string(forKey: "theme")
    showImage = defaults.bool(forKey: "showImage")
    showText = defaults.bool(forKey: "showText")
    showCoresIndividually = defaults.bool(forKey: "showCoresIndividually")

    image.imageEnabled = showImage
    image.textEnabled = showText
    image.multiCoreEnabled = showCoresIndividually

    cpuinfo.setMultiCoreEnabled(showCoresIndividually)

    // updateInterval
    mi_updateInterval?.submenu?.items.forEach { item in
      item.state = (item.tag == updateInterval) ? .on : .off
    }

    // theme
    mi_theme?.submenu?.items.forEach { item in
      item.state = (item.title == image.theme) ? .on : .off
    }

    // viewMode is meaningless while per-core mode is on
    mi_viewMode?.isEnabled = !showCoresIndividually

    // loginController
    let identifier = (Bundle.main.bundleIdentifier ?? "") + ".helper"
    loginController = StartAtLoginController(identifier: identifier)
    startAtLogin = loginController.startAtLogin

    // Show the Activity Monitor app icon next to its menu item.
    setActivityMonitorIcon()

    updateView()
  }

  private func setActivityMonitorIcon() {
    guard let item = statusMenu?.items.first(where: {
      $0.action == #selector(launchActivityMonitor(_:))
    }) else { return }

    let bundleID = "com.apple.ActivityMonitor"
    let path: String?
    if #available(macOS 10.15, *) {
      path = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)?.path
    } else {
      path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: bundleID)
    }
    guard let appPath = path else { return }

    let icon = NSWorkspace.shared.icon(forFile: appPath)
    icon.size = NSSize(width: 16, height: 16)
    item.image = icon
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    begin()
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    terminate()
    return .terminateNow
  }

  // MARK: - Actions

  @IBAction func updateUpdateInterval(_ sender: NSMenuItem) {
    sender.state = .on
    sender.menu?.items.forEach { item in
      if item != sender { item.state = .off }
    }
    updateInterval = sender.tag
    UserDefaults.standard.set(updateInterval, forKey: "updateInterval")
  }

  @IBAction func updateTheme(_ sender: NSMenuItem) {
    sender.state = .on
    sender.menu?.items.forEach { item in
      if item != sender { item.state = .off }
    }
    image.theme = sender.title
    UserDefaults.standard.set(image.theme, forKey: "theme")
  }

  // NOTE: the menu items carry a Cocoa `value` binding to these properties,
  // which toggles the bound property itself when the item is clicked. So the
  // actions must NOT toggle it again (that double-toggle cancels out); they
  // read the upcoming value as `!self.prop` and apply the side effects.

  @IBAction func updateShowImage(_ sender: Any) {
    let showImage = !self.showImage
    image.imageEnabled = showImage
    UserDefaults.standard.set(showImage, forKey: "showImage")
    updateView()
  }

  @IBAction func updateShowText(_ sender: Any) {
    let showText = !self.showText
    image.textEnabled = showText
    UserDefaults.standard.set(showText, forKey: "showText")
    updateView()
  }

  @IBAction func updateCoresIndividually(_ sender: Any) {
    let showCoresIndividually = !self.showCoresIndividually
    image.multiCoreEnabled = showCoresIndividually
    cpuinfo.setMultiCoreEnabled(showCoresIndividually)
    UserDefaults.standard.set(showCoresIndividually, forKey: "showCoresIndividually")

    // enable/disable ViewMode menu
    mi_viewMode?.isEnabled = !showCoresIndividually

    updateView()
  }

  @IBAction func updateStartAtLogin(_ sender: Any) {
    let startAtLogin = !self.startAtLogin
    loginController.startAtLogin = startAtLogin
  }

  @IBAction func launchActivityMonitor(_ sender: Any) {
    NSWorkspace.shared.launchApplication(withBundleIdentifier: "com.apple.ActivityMonitor",
                                         options: [],
                                         additionalEventParamDescriptor: nil,
                                         launchIdentifier: nil)
  }

  // MARK: - Sampling loop

  private func begin() {
    running = true
    let group = DispatchGroup()
    self.group = group
    group.enter()
    DispatchQueue.global(qos: .default).async { [weak self] in
      self?.updateLoop()
      group.leave()
    }
  }

  private func terminate() {
    running = false
    group?.wait()
  }

  private func updateLoop() {
    autoreleasepool {
      while running {
        let interval = max(Double(updateInterval) / 1000.0, 0.1)
        Thread.sleep(forTimeInterval: interval)

        cpuinfo.update()
        DispatchQueue.main.async { [weak self] in
          self?.updateView()
        }
      }
    }
  }

  private func updateView() {
    // Resolve appearance before drawing so this frame uses the right colors.
    if let appearance = statusItem.button?.effectiveAppearance {
      image.darkMode = appearanceIsDark(appearance)
    }
    image.update()
    // The image object is reused in place, so the button neither re-renders nor
    // recomputes its width on its own. Drive the status item length from the
    // image size and force a redraw.
    statusItem.length = image.size.width
    statusItem.button?.image = image
    statusItem.button?.needsDisplay = true
  }

  private func appearanceIsDark(_ appearance: NSAppearance) -> Bool {
    if #available(macOS 10.14, *) {
      let basic = appearance.bestMatch(from: [.aqua, .darkAqua])
      return basic == .darkAqua
    }
    return false
  }
}
