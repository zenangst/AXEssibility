import Cocoa

public final class AnyFocusedAccessibilityElement: AccessibilityElement {
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
