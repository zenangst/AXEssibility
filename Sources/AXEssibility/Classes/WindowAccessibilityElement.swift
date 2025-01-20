import Cocoa

private let kAXFullscreenAttribute = "AXFullScreen"

public final class WindowAccessibilityElement: AccessibilityElement, @unchecked Sendable {
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
  public let messagingTimeout: Float?

  public var id: CGWindowID {
    var windowID: CGWindowID = 0
    _AXUIElementGetWindow(reference, &windowID)
    return windowID
  }

  // MARK: Read-only

  public var isFocused: Int? {
    get {
      try? value(.focused)
    }
  }

  public var title: String? {
    get { try? value(.title) }
  }

  public var document: String? {
    get { try? value(.document) }
  }

  public var isMinimized: Bool? {
    get { try? value(.minimized) }
    set {
      guard let newValue else { return  }
      AXUIElementSetAttributeValue(
        reference,
        kAXMinimizedAttribute as CFString,
        packAXValue(newValue)
      )
    }
  }

  public var main: Bool? {
    get { try? value(.main) }
    set {
      guard let newValue else { return  }
      AXUIElementSetAttributeValue(
        reference,
        kAXMainAttribute as CFString,
        packAXValue(newValue)
      )
    }
  }

  public var isFullscreen: Bool? {
    get { try? value(kAXFullscreenAttribute)  }
  }

  public init(_ reference: AXUIElement, messagingTimeout: Float? = nil) {
    self.reference = reference
    self.messagingTimeout = messagingTimeout
    setMessagingTimeoutIfNeeded(for: reference)
  }

  // MARK: Actions

  @discardableResult
  public func performAction(_ action: Action) -> Self {
    AXUIElementPerformAction(reference, action.rawValue as CFString)
    return self
  }
}
