import Cocoa

public final class SystemAccessibilityElement: AccessibilityElement {
  
  public private(set) var reference: AXUIElement

  public init(_ reference: AXUIElement = AXUIElementCreateSystemWide()) {
    self.reference = reference
  }

  public init() {
    self.reference = AXUIElementCreateSystemWide()
  }

  public func focusedUIElement() throws -> AnyFocusedAccessibilityElement {
    let element = try value(.focusedUIElement, as: AXUIElement.self)
    return AnyFocusedAccessibilityElement(element)
  }
}
