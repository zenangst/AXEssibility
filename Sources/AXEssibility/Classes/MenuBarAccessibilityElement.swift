import Cocoa

public final class MenuBarAccessibilityElement: AccessibilityElement, @unchecked Sendable {
  public private(set) var reference: AXUIElement
  public let messagingTimeout: Float?

  public init(_ reference: AXUIElement, messagingTimeout: Float? = nil) {
    self.reference = reference
    self.messagingTimeout = messagingTimeout
    setMessagingTimeoutIfNeeded(for: reference)
  }

  public func menuItems() throws -> [MenuBarItemAccessibilityElement] {
    try value(.children, as: [AXUIElement].self)
      .compactMap { MenuBarItemAccessibilityElement($0, messagingTimeout: messagingTimeout) }
  }
}
