import Cocoa

final class AnyAccessibilityElement: AccessibilityElement {
  private(set) var reference: AXUIElement

  init(_ reference: AXUIElement) {
    self.reference = reference
  }
}
