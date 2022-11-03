import Cocoa

public enum AXPermissions {
  private static func check() -> Bool {
    let options: [String: Bool] = [
      kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
    ]

    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }
}
