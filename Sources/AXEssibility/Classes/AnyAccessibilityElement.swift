import Cocoa

public final class AnyAccessibilityElement: AccessibilityElement {
  public enum Action {
    case raise
    case showMenu
    case pick
    case press

    var rawValue: String {
      switch self {
      case .raise:
        return kAXRaiseAction
      case .showMenu:
        return kAXShowMenuAction
      case .pick:
        return kAXPickAction
      case .press:
        return kAXPressAction
      }
    }
  }

  public private(set) var reference: AXUIElement
  public let messagingTimeout: Float?

  public init(_ reference: AXUIElement, messagingTimeout: Float? = nil) {
    self.reference = reference
    self.messagingTimeout = messagingTimeout
    setMessagingTimeoutIfNeeded(for: reference)
  }

  public func selectedText() -> String? {
    try? value(.selectedText)
  }
}
