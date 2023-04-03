import Foundation
import Cocoa

public final class AppAccessibilityElement: AccessibilityElement {
  public private(set) var reference: AXUIElement

  public var pid: Int32? {
    get { try? self.getPid() }
  }

  public var title: String? {
    get { try? value(.title) }
  }

  public var isFrontmost: Bool? {
    get {
      let intValue = try? value(.frontmost, as: Int.self)
      return intValue != 0 ? true : false
    }
  }

  public var mainWindow: WindowAccessibilityElement? {
    get { getWindow(for: .mainWindow) }
  }

  public var focusedWindow: WindowAccessibilityElement? {
    get { getWindow(for: .focusedWindow) }
  }

  public func windows() throws -> [WindowAccessibilityElement] {
    if let elements = try value(.windows, as: [AXUIElement].self) {
      return elements.compactMap(WindowAccessibilityElement.init)
    } else {
      return []
    }
  }

  public init(_ reference: AXUIElement) {
    self.reference = reference
  }

  public init(_ pid: pid_t) {
    self.reference = AXUIElementCreateApplication(pid)
  }

  public static func focusedApplication() -> AppAccessibilityElement? {
    if let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier {
      return AppAccessibilityElement(pid)
    }
    return nil
  }

  public func getPid() throws -> pid_t {
    var pid: pid_t = 0
    var error: AXError
    error = AXUIElementGetPid(reference, &pid)
    try error.checkThrowing()
    return pid
  }

  // MARK: Private methods

  private func getWindow(for attribute: NSAccessibility.Attribute) -> WindowAccessibilityElement? {
    if let element = try? value(attribute, as: AXUIElement.self) {
      return WindowAccessibilityElement(element)
    }
    return nil
  }
}
