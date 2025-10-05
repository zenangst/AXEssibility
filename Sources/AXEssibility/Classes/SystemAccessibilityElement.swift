import Cocoa

public final class SystemAccessibilityElement: AccessibilityElement, @unchecked Sendable {
  public private(set) var reference: AXUIElement
  public let messagingTimeout: Float?

  public init(_ reference: AXUIElement = AXUIElementCreateSystemWide(), messagingTimeout: Float? = nil) {
    self.reference = reference
    self.messagingTimeout = messagingTimeout
    setMessagingTimeoutIfNeeded(for: reference)
  }

  public func focusedUIElement(_: Float? = nil) throws -> AnyFocusedAccessibilityElement {
    let element = try value(.focusedUIElement, as: AXUIElement.self)
    return AnyFocusedAccessibilityElement(element)
  }

  public func element<T: AccessibilityElement>(at location: CGPoint,
                                               as _: T.Type) -> T?
  {
    var matchingReference: AXUIElement?
    AXUIElementCopyElementAtPosition(reference, Float(location.x), Float(location.y), &matchingReference)
    if let matchingReference {
      return T(matchingReference, messagingTimeout: messagingTimeout)
    }
    return nil
  }
}
