import Cocoa

public final class MenuBarAccessibilityElement: AccessibilityElement {
  public private(set) var reference: AXUIElement

  public init(_ reference: AXUIElement) {
    self.reference = reference
  }

  public func menuItems() throws -> [MenuBarItemAccessibilityElement] {
    try value(.children, as: [AXUIElement].self)
      .compactMap(MenuBarItemAccessibilityElement.init)
  }
}
