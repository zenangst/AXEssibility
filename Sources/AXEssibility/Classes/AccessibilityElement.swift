import Cocoa

public protocol AccessibilityElement {
  var reference: AXUIElement { get }

  init(_ reference: AXUIElement)
}

extension AccessibilityElement {
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

  // MARK: Internal methods

  internal func debugValue(_ value: Any?) -> String {
    if let value {
      return "\(value)"
    } else {
      return "Missing value"
    }
  }

  // MARK: Private methods

  private func anyValue(_ attribute: NSAccessibility.Attribute) throws -> Any? {
    try anyValue(attribute.rawValue)
  }

  private func anyValue(_ attribute: String) throws -> Any {
    try reference.rawValue(for: attribute)
  }
}
