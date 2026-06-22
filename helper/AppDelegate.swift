//
//  AppDelegate.swift
//  helper
//
//  Login item bootstrapper: relaunches the main app, then quits.
//

import Cocoa

@objc(AppDelegate)
final class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow?

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Get to the waaay top. Goes through LoginItems, Library, Contents, Applications.
    // bundlePath == .../cpuinfo.app/Contents/Library/LoginItems/helper.app
    // Walk up four levels (LoginItems, Library, Contents, helper.app) to reach cpuinfo.app.
    var appPath = Bundle.main.bundlePath
    for _ in 0..<4 {
      appPath = (appPath as NSString).deletingLastPathComponent
    }

    NSWorkspace.shared.launchApplication(appPath)
    NSApp.terminate(nil)
  }
}
