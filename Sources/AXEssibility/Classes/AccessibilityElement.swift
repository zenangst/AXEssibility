import Cocoa

public protocol AccessibilityElement {
  var reference: AXUIElement { get }

  init(_ reference: AXUIElement)
}

extension AccessibilityElement {
  public var app: AppAccessibilityElement? {
    if role == kAXApplicationRole {
      return AppAccessibilityElement(reference)
    } else {
      return findParent(with: kAXApplicationRole, as: AppAccessibilityElement.self)
    }
  }

  public var window: WindowAccessibilityElement? {
    if role == kAXWindowRole {
      return WindowAccessibilityElement(reference)
    } else {
      return findParent(with: .window, as: WindowAccessibilityElement.self)
    }
  }

  public var identifier: String? { return try? value(.identifier) }
  public var parent: AnyAccessibilityElement? { return try? element(for: .parent) }
  public var children: [any AccessibilityElement] {
    let results = (try? value(.children, as: [AXUIElement].self)) ?? []
    return results
      .map { element in
        AnyAccessibilityElement(element)
      }
}
  public var role: String? { return try? value(.role, as: String.self) }
  public var description: String? { return try? value(.description, as: String.self) }
  public var roleDescription: String? { return try? value(.roleDescription, as: String.self) }
  public var value: String? { return try? value(.value, as: String.self) }
  public var title: String? { return try? value(.title, as: String.self) }

  public func value<T>(_ attribute: NSAccessibility.Attribute) throws -> T? {
    try value(attribute.rawValue, as: T.self)
  }

  public func value<T>(_ string: String) throws -> T? {
    try value(string, as: T.self)
  }

  public func value<T>(_ attribute: NSAccessibility.Attribute, as type: T.Type) throws -> T {
    try value(attribute.rawValue, as: T.self)
  }

  public func value<T>(_ attribute: String, as type: T.Type) throws -> T {
    if let anyValue =  try anyValue(attribute) as? T {
      return anyValue
    }
    throw AccessibilityElementError.failedToCastAnyValue
  }

  public func element<Element: AccessibilityElement>(for attribute: NSAccessibility.Attribute) throws -> Element {
    guard let rawValue = try reference.rawValue(for: attribute) else {
      throw AccessibilityElementError.unableToCreateRawValue
    }

    let elementReference = rawValue as! AXUIElement
    return Element(elementReference)
  }

  public func findAttribute<T>(_ attribute: NSAccessibility.Attribute, of role: String) -> T? {
    reference.findAttribute(attribute, of: role)
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

  public func findChild(matching: (AccessibilityElement?) -> Bool) -> AnyAccessibilityElement? {
    if matching(self) {
      return AnyAccessibilityElement(self.reference)
    }

    for child in self.children {
      if let found = child.findChild(matching: matching) {
        return found
      }
    }

    return nil
  }

  // MARK: Internal methods

  internal func debugValue(_ value: Any?) -> String {
    if let value {
      return "\(value)"
    } else {
      return "Missing value"
    }
  }

  // MARK: Private methods

  private func findParent<T: AccessibilityElement>(with role: NSAccessibility.Attribute, as type: T.Type) -> T? {
    findParent(with: role.rawValue, as: type)
  }

  private func findParent<T: AccessibilityElement>(with role: String, as type: T.Type) -> T? {
    var element: AccessibilityElement? = self
    while element != nil, element?.role != role {
      if let nextElement: AccessibilityElement = element?.parent {
        element = nextElement
      } else {
        element = nil
      }
    }
    if let element {
      return T(element.reference)
    }
    return nil
  }


  private func anyValue(_ attribute: NSAccessibility.Attribute) throws -> Any? {
    try anyValue(attribute.rawValue)
  }

  private func anyValue(_ attribute: String) throws -> Any {
    try reference.rawValue(for: attribute)
  }

  // MARK: Actions

  @discardableResult
  public func performAction(_ action: AnyAccessibilityElement.Action) -> Self {
    AXUIElementPerformAction(reference, action.rawValue as CFString)
    return self
  }
}
