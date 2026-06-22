//
//  Cpuinfo.swift
//  cpuinfo
//
//  CPU usage sampler backed by the Mach host/processor statistics APIs.
//

import Foundation

final class Cpuinfo {

  private struct Ticks {
    var user: natural_t = 0
    var system: natural_t = 0
    var idle: natural_t = 0
    var nice: natural_t = 0
  }

  private struct Core {
    var ticks = Ticks()
    var usage: Double = 0
  }

  // update() runs on a background thread while the getters are read from the
  // main thread during drawing, so all shared state is guarded by this lock.
  private let lock = NSLock()

  private var multiCoreEnabled = false
  private(set) var coreCount: UInt = 0

  private var host = Core()
  private var cores: [Core] = []

  init() {
    var cpuCount = natural_t(0)
    var info: processor_info_array_t?
    var infoCount = mach_msg_type_number_t(0)

    let result = host_processor_info(mach_host_self(),
                                     PROCESSOR_CPU_LOAD_INFO,
                                     &cpuCount,
                                     &info,
                                     &infoCount)

    if result == KERN_SUCCESS, let info = info {
      coreCount = UInt(cpuCount)
      cores = Array(repeating: Core(), count: Int(cpuCount))
      vm_deallocate(mach_task_self_,
                    vm_address_t(bitPattern: info),
                    vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride))
    }
  }

  func setMultiCoreEnabled(_ enabled: Bool) {
    lock.lock()
    multiCoreEnabled = enabled
    lock.unlock()
  }

  func getHostUsage() -> Double {
    lock.lock()
    defer { lock.unlock() }
    return host.usage
  }

  func getCoreUsageAt(_ index: UInt) -> Double {
    lock.lock()
    defer { lock.unlock() }
    guard index < coreCount else { return 0 }
    return cores[Int(index)].usage
  }

  func getCoreCount() -> UInt {
    return coreCount
  }

  // Computes the fraction of busy time between two tick snapshots.
  private static func usage(from previous: Ticks, to current: Ticks) -> Double {
    return usageRatio(user: Double(current.user &- previous.user),
                      system: Double(current.system &- previous.system),
                      idle: Double(current.idle &- previous.idle),
                      nice: Double(current.nice &- previous.nice))
  }

  // Pure busy-time ratio from per-state deltas. Exposed (internal) for testing.
  static func usageRatio(user: Double, system: Double, idle: Double, nice: Double) -> Double {
    let used = user + system + nice
    let total = system + user + idle + nice
    return total > 0 ? used / total : 0
  }

  func update() {
    lock.lock()
    defer { lock.unlock() }
    if multiCoreEnabled {
      updateCores()
    } else {
      updateHost()
    }
  }

  private func updateCores() {
    var cpuCount = natural_t(0)
    var info: processor_info_array_t?
    var infoCount = mach_msg_type_number_t(0)

    let result = host_processor_info(mach_host_self(),
                                     PROCESSOR_CPU_LOAD_INFO,
                                     &cpuCount,
                                     &info,
                                     &infoCount)
    guard result == KERN_SUCCESS, let info = info else { return }

    let stateMax = Int(CPU_STATE_MAX)
    for i in 0..<Int(coreCount) {
      let base = i * stateMax
      // info holds integer_t (Int32); tick counters are unsigned and can
      // exceed Int32.max, so reinterpret the bits instead of converting.
      let current = Ticks(
        user: natural_t(bitPattern: info[base + Int(CPU_STATE_USER)]),
        system: natural_t(bitPattern: info[base + Int(CPU_STATE_SYSTEM)]),
        idle: natural_t(bitPattern: info[base + Int(CPU_STATE_IDLE)]),
        nice: natural_t(bitPattern: info[base + Int(CPU_STATE_NICE)])
      )
      cores[i].usage = Cpuinfo.usage(from: cores[i].ticks, to: current)
      cores[i].ticks = current
    }

    vm_deallocate(mach_task_self_,
                  vm_address_t(bitPattern: info),
                  vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride))
  }

  private func updateHost() {
    var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
    var cpuLoad = host_cpu_load_info_data_t()

    let result = withUnsafeMutablePointer(to: &cpuLoad) { ptr -> kern_return_t in
      ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
      }
    }
    guard result == KERN_SUCCESS else { return }

    // cpu_ticks tuple order matches CPU_STATE_USER/SYSTEM/IDLE/NICE (0..3).
    let t = cpuLoad.cpu_ticks
    let current = Ticks(user: t.0, system: t.1, idle: t.2, nice: t.3)
    host.usage = Cpuinfo.usage(from: host.ticks, to: current)
    host.ticks = current
  }
}
