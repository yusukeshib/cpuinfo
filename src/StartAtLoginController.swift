//
//  StartAtLoginController.swift
//  cpuinfo
//
//  Manages the "start at login" helper login item.
//
//  Originally Copyright (c) 2011 Alex Zielenski, (c) 2012 Travis Tilley (MIT).
//  Ported to Swift.
//

import Foundation
import ServiceManagement

final class StartAtLoginController {

  let identifier: String
  private(set) var enabled = false

  init(identifier: String) {
    self.identifier = identifier
    _ = startAtLogin
  }

  var startAtLogin: Bool {
    get {
      var isEnabled = false
      if let jobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd)?
        .takeRetainedValue() as? [[String: Any]] {
        for job in jobs {
          if let label = job["Label"] as? String, label == identifier {
            isEnabled = (job["OnDemand"] as? Bool) ?? false
            break
          }
        }
      }
      enabled = isEnabled
      return isEnabled
    }
    set {
      if SMLoginItemSetEnabled(identifier as CFString, newValue) {
        enabled = newValue
      } else {
        NSLog("SMLoginItemSetEnabled failed!")
        enabled = false
      }
    }
  }
}
