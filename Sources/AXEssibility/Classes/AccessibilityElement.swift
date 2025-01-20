import Cocoa

public protocol AccessibilityElement: AnyObject, Sendable {
  var reference: AXUIElement { get }
  var messagingTimeout: Float? { get }

  init(_ reference: AXUIElement, messagingTimeout: Float?)
}

extension AccessibilityElement {
  public var app: AppAccessibilityElement? {
    if role == kAXApplicationRole {
      return AppAccessibilityElement(reference, messagingTimeout: messagingTimeout)
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
      .map { AnyAccessibilityElement($0) }
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

  internal func packAXValue(_ value: Any) -> AnyObject {
    switch value {
    case let newValue as Bool: newValue as CFBoolean
    case var newValue as CFRange: AXValueCreate(AXValueType(rawValue: kAXValueCFRangeType)!, &newValue)!
    case var newValue as CGPoint: AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!, &newValue)!
    case var newValue as CGRect:  AXValueCreate(AXValueType(rawValue: kAXValueCGRectType)!, &newValue)!
    case var newValue as CGSize: AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!, &newValue)!
    default: value as AnyObject
    }
  }

  public func values(_ attributes: [NSAccessibility.Attribute]) throws -> [NSAccessibility.Attribute: Any] {
    let uniqueAttributes = Array(Set(attributes))
    let cfAttributes = (uniqueAttributes.map { $0.rawValue as CFString }) as CFArray
    var values: CFArray?
    let code = AXUIElementCopyMultipleAttributeValues(
      reference,
      cfAttributes,
      AXCopyMultipleAttributeOptions(),
      &values
    )

    guard code == .success else { throw AXError.failure }

    guard let values = values as? [AnyObject] else { throw AXError.cannotComplete }

    guard values.count == uniqueAttributes.count else { throw AXError.cannotComplete }

    var result = [NSAccessibility.Attribute: Any](minimumCapacity: uniqueAttributes.count)

    for (index, value) in values.enumerated() {
      result[uniqueAttributes[index]] = try? reference.unpack(value)
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
    set { guard let newPoint = newValue,
                let value = AXValue.from(value: newPoint, type: .cgPoint) else { return }
      AXUIElementSetAttributeValue(reference, kAXPositionAttribute as CFString, value)
    }
  }

  public var size: CGSize? {
    get { return try? value(.size) }
    set { guard let newSize = newValue,
                let value = AXValue.from(value: newSize, type: .cgSize) else { return }
      AXUIElementSetAttributeValue(reference, kAXSizeAttribute as CFString, value)
    }
  }

  public var subrole: String? {
    get { return try? value(.subrole) }
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
      AXUIElementSetAttributeValue(reference, kAXPositionAttribute as CFString, packAXValue(newValue.origin))
      AXUIElementSetAttributeValue(reference, kAXSizeAttribute as CFString, packAXValue(newValue.size))
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
    parentFrame: CGRect? = nil,
    keys: Set<NSAccessibility.Attribute>,
    abort: @escaping () -> Bool,
    matching: (_ values: [NSAccessibility.Attribute: Any]) -> Bool
  ) -> AnyAccessibilitySubject? {
    if abort() == true { return nil }
    var parentFrame = parentFrame

    var keys = keys
    keys.insert(.position)
    keys.insert(.size)
    keys.insert(.role)
    keys.insert(.description)

    guard let values = try? self.values(Array(keys)) else { return nil }

    guard let role = values[.role] as? String,
          let origin = values[.position] as? CGPoint,
          let size = values[.size] as? CGSize else {
      return nil
    }

    let frame = CGRect(origin: origin, size: size)
    if role == "AXScrollArea" { parentFrame = frame }

    let elementFrame = CGRect(origin: origin, size: size)

    if let parentFrame = parentFrame,
       parentFrame.intersects(elementFrame) {
      if matching(values) {
        return AnyAccessibilitySubject(element: self, position: elementFrame.origin)
      }
    } else if matching(values) {
      return AnyAccessibilitySubject(element: self, position: elementFrame.origin)
    }

    for element in children {
      if abort() == true { break }

      if let match = element.findChild(on: screen, parentFrame: parentFrame,
                                       keys: keys, abort: abort, matching: matching) {
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

fileprivate extension NSScreen {
  // Different from `NSScreen.main`, the `mainDisplay` sets the conditions for the
  // coordinate system. All other screens have a coordinate space that is relative
  // to the main screen.
  var isMainDisplay: Bool { frame.origin == .zero }
  static var mainDisplay: NSScreen? { screens.first(where: { $0.isMainDisplay }) }

  static func screenContaining(_ rect: CGRect) -> NSScreen? {
    NSScreen.screens.first(where: { $0.frame.contains(rect) })
  }

  static var maxY: CGFloat {
    var maxY = 0.0 as CGFloat
    for screen in screens {
      maxY = CGFloat.maximum(screen.frame.maxY, maxY)
    }
    return maxY
  }
}

extension AccessibilityElement {
  public func isElementFrameVisible(on screen: NSScreen) -> Bool {
    var currentElement: AccessibilityElement? = self
    var globalFrame = self.frame ?? .zero

    while let parent = currentElement?.parent {
      if let parentFrame = parent.frame {
        // Convert the frame from the local coordinate system to the parent's coordinate system
        globalFrame = globalFrame.offsetBy(dx: parentFrame.origin.x, dy: parentFrame.origin.y)
      }
      currentElement = parent.app != nil ? nil : parent // Stop if we reach the app element
    }

    // Now globalFrame is in screen coordinates (assuming the top-level window is aligned with the screen origin)
    // Check if the frame is within the screen's visible frame
    return screen.visibleFrame.intersects(globalFrame)
  }
}
