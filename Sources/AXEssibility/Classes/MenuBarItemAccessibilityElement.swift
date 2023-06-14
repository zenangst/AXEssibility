import Cocoa

public final class MenuBarItemAccessibilityElement: AccessibilityElement {
  public enum Action {
   case pick
    var rawValue: String {
      switch self {
      case .pick:
        return kAXPickAction
      }
    }
  }

  public private(set) var reference: AXUIElement

  public init(_ reference: AXUIElement) {
    self.reference = reference
  }

  public var title: String? {
    get { try? value(.title) }
  }

  public var role: String? {
    get { try? value(.role) }
  }

  public var isEnabled: Bool? {
    get { try? value(.enabled) }
  }

  public var isSubMenu: Bool {
    get {
      (try? menuItems())?.isEmpty == false
    }
  }

  @discardableResult
  public func performAction(_ action: Action) -> Self {
    AXUIElementPerformAction(reference, action.rawValue as CFString)
    return self
  }

  public func menuItems() throws -> [MenuBarItemAccessibilityElement] {
    try value(.children, as: [AXUIElement].self)
      .compactMap(MenuBarItemAccessibilityElement.init)
  }
}
