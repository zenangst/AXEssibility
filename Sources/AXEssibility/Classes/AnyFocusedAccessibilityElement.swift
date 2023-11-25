import Cocoa

public final class AnyFocusedAccessibilityElement: AccessibilityElement {
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

  public init(_ reference: AXUIElement) {
    self.reference = reference
  }

  public func selectedText() -> String? {
    try? value(.selectedText)
  }

  // MARK: Actions

  @discardableResult
  public func performAction(_ action: Action) -> Self {
    AXUIElementPerformAction(reference, action.rawValue as CFString)
    return self
  }

  public var position: CGPoint? {
    get { return try? value(.position) }
    set { guard let value = AXValue.from(value: newValue, type: .cgPoint) else { return }
      AXUIElementSetAttributeValue(reference, kAXPositionAttribute as CFString, value)
    }
  }

  public var size: CGSize? {
    get { return try? value(.size) }
    set { guard let value = AXValue.from(value: newValue, type: .cgSize) else { return }
      AXUIElementSetAttributeValue(reference, kAXSizeAttribute as CFString, value)
    }
  }

  public var frame: CGRect? {
    get {
      guard let origin = position, let size = size else { return nil }
      return CGRect(origin: origin, size: size)
    }
    set {
      guard let newValue else { return }
      let newFrame = CGRect(origin: newValue.origin, size: newValue.size)
      position = newFrame.origin
      size = newFrame.size
    }
  }
}
