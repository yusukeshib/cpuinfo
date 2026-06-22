//
//  StartAtLoginController.swift
//  cpuinfo
//
//  Manages the "start at login" helper login item.
//
//  Uses SMAppService on macOS 13+, falling back to the legacy
//  ServiceManagement login-item API on older systems.
//
//  Legacy paths originally Copyright (c) 2011 Alex Zielenski,
//  (c) 2012 Travis Tilley (MIT). Ported to Swift.
//

import Foundation
import ServiceManagement

final class StartAtLoginController {

  let identifier: String

  init(identifier: String) {
    self.identifier = identifier
  }

  var startAtLogin: Bool {
    get {
      if #available(macOS 13.0, *) {
        return SMAppService.loginItem(identifier: identifier).status == .enabled
      }
      return legacyStartAtLogin
    }
    set {
      if #available(macOS 13.0, *) {
        let service = SMAppService.loginItem(identifier: identifier)
        do {
          if newValue {
            try service.register()
          } else {
            try service.unregister()
          }
        } catch {
          NSLog("SMAppService \(newValue ? "register" : "unregister") failed: \(error)")
        }
      } else {
        legacySetStartAtLogin(newValue)
      }
    }
  }

  // MARK: - Legacy (macOS < 13)

  @available(macOS, deprecated: 13.0)
  private var legacyStartAtLogin: Bool {
    guard let jobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd)?
      .takeRetainedValue() as? [[String: Any]] else {
      return false
    }
    for job in jobs where (job["Label"] as? String) == identifier {
      return (job["OnDemand"] as? Bool) ?? false
    }
    return false
  }

  @available(macOS, deprecated: 13.0)
  private func legacySetStartAtLogin(_ flag: Bool) {
    if !SMLoginItemSetEnabled(identifier as CFString, flag) {
      NSLog("SMLoginItemSetEnabled failed!")
    }
  }
}
