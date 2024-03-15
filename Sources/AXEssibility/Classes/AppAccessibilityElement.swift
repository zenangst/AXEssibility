import Foundation
import Cocoa

public final class AppAccessibilityElement: AccessibilityElement, @unchecked Sendable {
  public private(set) var reference: AXUIElement
  public let messagingTimeout: Float?

  public var enhancedUserInterface: Bool? {
    get { try? value(NSAccessibility.Attribute(rawValue: "AXEnhancedUserInterface")) }
    set {
      guard let newValue else { return }
      let cfBoolean = newValue as CFBoolean
      AXUIElementSetAttributeValue(reference, "AXEnhancedUserInterface" as CFString, cfBoolean)
    }
  }

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

  public func mainWindow() throws -> WindowAccessibilityElement {
    try getWindow(for: .mainWindow)
  }

  public func focusedWindow() throws -> WindowAccessibilityElement {
    try getWindow(for: .focusedWindow)
  }

  public func focusedUIElement() throws -> AnyAccessibilityElement {
    let element = try value(.focusedUIElement, as: AXUIElement.self)
    return AnyAccessibilityElement(element)
  }

  public func menuBar() throws -> MenuBarAccessibilityElement {
    try getMenubar(for: .menuBar)
  }

  public func windows() throws -> [WindowAccessibilityElement] {
    try value(.windows, as: [AXUIElement].self)
      .compactMap { WindowAccessibilityElement.init($0, messagingTimeout: messagingTimeout) }
  }

  public init(_ reference: AXUIElement, messagingTimeout: Float? = nil) {
    self.reference = reference
    self.messagingTimeout = messagingTimeout
  }

  public init(_ pid: pid_t, messagingTimeout: Float? = nil) {
    self.reference = AXUIElementCreateApplication(pid)
    self.messagingTimeout = messagingTimeout
    setMessagingTimeoutIfNeeded(for: reference)
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

  private func getWindow(for attribute: NSAccessibility.Attribute) throws -> WindowAccessibilityElement {
    let element = try value(attribute, as: AXUIElement.self)
    return WindowAccessibilityElement(element, messagingTimeout: messagingTimeout)
  }

  private func getMenubar(for attribute: NSAccessibility.Attribute) throws -> MenuBarAccessibilityElement {
    let element = try value(attribute, as: AXUIElement.self)
    return MenuBarAccessibilityElement(element, messagingTimeout: messagingTimeout)
  }
}
