import Cocoa

public final class AnyFocusedAccessibilityElement: AccessibilityElement, @unchecked Sendable {
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

  public func setSelectedText(_ newValue: String) {
    AXUIElementSetAttributeValue(
      reference,
      kAXSelectedTextAttribute as CFString,
      packAXValue(newValue)
    )
  }
}
