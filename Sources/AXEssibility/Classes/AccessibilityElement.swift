import Cocoa

public protocol AccessibilityElement: AnyObject {
  var reference: AXUIElement { get }
  var messagingTimeout: Float? { get }

  init(_ reference: AXUIElement, messagingTimeout: Float?)
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
      return WindowAccessibilityElement(reference, messagingTimeout: messagingTimeout)
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

  public func values(_ attributes: [NSAccessibility.Attribute]) throws -> [NSAccessibility.Attribute: Any] {
    let cfAttributes = (attributes.map { $0.rawValue as CFString }) as CFArray
    var values: CFArray?
    let code = AXUIElementCopyMultipleAttributeValues(
      reference,
      cfAttributes,
      AXCopyMultipleAttributeOptions(),
      &values
    )

    guard code == .success else { throw AXError.failure }

    guard let values = values as? [AnyObject] else { throw AXError.cannotComplete }

    guard values.count == attributes.count else { throw AXError.cannotComplete }

    var result = [NSAccessibility.Attribute: Any]()
    for (index, value) in values.enumerated() {
      result[attributes[index]] = try? reference.unpack(value)
    }

    return result
  }

  public func element<Element: AccessibilityElement>(for attribute: NSAccessibility.Attribute, messagingTimeout: Float? = nil) throws -> Element {
    guard let rawValue = try reference.rawValue(for: attribute) else {
      throw AccessibilityElementError.unableToCreateRawValue
    }

    let elementReference = rawValue as! AXUIElement

    if let messagingTimeout {
      AXUIElementSetMessagingTimeout(elementReference, messagingTimeout)
    }

    return Element(elementReference, messagingTimeout: messagingTimeout)
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
      guard let array = try? values([.position, .size]),
            let origin = array[.position] as? CGPoint,
            let size = array[.size] as? CGSize else { return nil }

      return CGRect(origin: origin, size: size)
    }
    set {
      guard let newValue else { return }
      let newFrame = CGRect(origin: newValue.origin, size: newValue.size)
      position = newFrame.origin
      size = newFrame.size
    }
  }

  public func findChild(matching: (_ element: AccessibilityElement?, _ abort: inout Bool) -> Bool, abort: inout Bool) -> AccessibilityElement? {
    if matching(self, &abort) {
      return self
    }

    if abort { return nil }

    for child in self.children {
      if abort { break }

      if let found = child.findChild(matching: matching, abort: &abort) {
        if abort { return nil }
        return found
      }
    }

    return nil
  }

  public func findChild(
    on screen: NSScreen,
    keys: Set<NSAccessibility.Attribute>,
    abort: @escaping () -> Bool,
    matching: (_ values: [NSAccessibility.Attribute: Any]) -> Bool
  ) -> AnyAccessibilitySubject? {
    if abort() == true { return nil }

    var keys = keys
    keys.insert(.position)
    keys.insert(.size)

    guard let values = try? self.values(Array(keys)),
          let origin = values[.position] as? CGPoint,
          let size = values[.size] as? CGSize else {
      return nil
    }

    let elementFrame = CGRect(origin: origin, size: size)
    let convertedFrame = screen.convertRectFromBacking(elementFrame)
    guard convertedFrame.intersects(screen.frame) else { return nil }

    if matching(values) {
      return AnyAccessibilitySubject(element: self, position: elementFrame.origin)
    }
    for child in self.children {
      if abort() == true { break }
      if let match = child.findChild(on: screen, keys: keys,
                                     abort: abort,
                                     matching: matching) {
        return match
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
      return T(element.reference, messagingTimeout: messagingTimeout)
    }
    return nil
  }


  private func anyValue(_ attribute: NSAccessibility.Attribute) throws -> Any? {
    try anyValue(attribute.rawValue)
  }

  private func anyValue(_ attribute: String) throws -> Any {
    try reference.rawValue(for: attribute)
  }

  func setMessagingTimeoutIfNeeded(for reference: AXUIElement) {
    if let messagingTimeout {
      AXUIElementSetMessagingTimeout(reference, messagingTimeout)
    }
  }

  // MARK: Actions

  @discardableResult
  public func performAction(_ action: AnyAccessibilityElement.Action) -> Self {
    AXUIElementPerformAction(reference, action.rawValue as CFString)
    return self
  }
}

public struct AnyAccessibilitySubject {
  public let element: AccessibilityElement
  public let position: CGPoint
}
