import Cocoa

public final class AnyAccessibilityElement: AccessibilityElement {
  public private(set) var reference: AXUIElement

  public init(_ reference: AXUIElement) {
    self.reference = reference
  }

  public func selectedText() -> String? {
    try? value(.selectedText)
  }
}
