import AppKit
import Cocoa
import Foundation

public final class AppAccessibilityElement: AccessibilityElement, @unchecked Sendable {
  public enum Notification: String {
    case closed
    case focusedWindowChanged
    case windowCreated

    public var rawValue: String {
      switch self {
      case .windowCreated: kAXWindowCreatedNotification
      case .focusedWindowChanged: kAXFocusedWindowChangedNotification
      case .closed: kAXUIElementDestroyedNotification
      }
    }
  }

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

  public var pid: Int32? { try? getPid() }

  public var title: String? { try? value(.title) }

  public var isFrontmost: Bool? {
    let intValue = try? value(.frontmost, as: Int.self)
    return intValue != 0 ? true : false
  }

  public func mainWindow() throws -> WindowAccessibilityElement? {
    try getWindow(for: .mainWindow)
  }

  public func focusedWindow() throws -> WindowAccessibilityElement? {
    try getWindow(for: .focusedWindow)
  }

  public func focusedUIElement() throws -> AnyAccessibilityElement {
    let element = try value(.focusedUIElement, as: AXUIElement.self)
    return AnyAccessibilityElement(element)
  }

  public func menuBar() throws -> MenuBarAccessibilityElement {
    try getMenubar(for: .menuBar)
  }

  public func windows(_ filter: ((WindowAccessibilityElement) -> Bool)? = nil) throws -> [WindowAccessibilityElement] {
    try value(.windows, as: [AXUIElement].self)
      .compactMap { axElement in
        guard let element = WindowAccessibilityElement(axElement, messagingTimeout: messagingTimeout) else {
          return nil
        }

        if let filter, !filter(element) {
          return nil
        }

        return element
      }
  }

  public init(_ reference: AXUIElement, messagingTimeout: Float? = nil) {
    self.reference = reference
    self.messagingTimeout = messagingTimeout
  }

  public init(_ pid: pid_t, messagingTimeout: Float? = nil) {
    reference = AXUIElementCreateApplication(pid)
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

  public var hidden: Bool? {
    get { try? value(.hidden) }
    set {
      guard let newValue else { return }
      AXUIElementSetAttributeValue(
        reference,
        kAXHiddenAttribute as CFString,
        packAXValue(newValue)
      )
    }
  }

  public func observe(_ notification: Notification, element: AXUIElement, id: UUID, pointer: UnsafeMutableRawPointer? = nil, callback: AXObserverCallback) -> AccessibilityObserver? {
    guard let pid, let observation = AccessibilityObserver.observe(
      pid,
      id: id,
      element: element,
      notification: notification,
      pointer: pointer,
      callback: callback
    ) else {
      return nil
    }

    return observation
  }

  // MARK: Private methods

  private func getWindow(for attribute: NSAccessibility.Attribute) throws -> WindowAccessibilityElement? {
    let element = try value(attribute, as: AXUIElement.self)
    return WindowAccessibilityElement(element, messagingTimeout: messagingTimeout)
  }

  private func getMenubar(for attribute: NSAccessibility.Attribute) throws -> MenuBarAccessibilityElement {
    let element = try value(attribute, as: AXUIElement.self)
    return MenuBarAccessibilityElement(element, messagingTimeout: messagingTimeout)
  }
}
