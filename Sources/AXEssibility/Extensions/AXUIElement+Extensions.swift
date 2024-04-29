import Cocoa

extension AXUIElement: @unchecked Sendable {
  internal func rawValue(for attribute: NSAccessibility.Attribute) throws -> Any? {
    try rawValue(for: attribute.rawValue)
  }

  public func findAttribute<T>(_ attribute: NSAccessibility.Attribute, of role: String) -> T? {
    if let resolvedRole = try? (rawValue(for: kAXRoleAttribute) as? String), resolvedRole == role {
      let result = try? rawValue(for: attribute.rawValue) as? T
      return result
    }

    if let children = try? rawValue(for: kAXChildrenAttribute) as? [AXUIElement] {
      for child in children {
        if let result: T = child.findAttribute(attribute, of: role) {
          return result
        }
      }
    }
    return nil
  }

  internal func rawValue(for attribute: String) throws -> Any {
    var rawValue: AnyObject?
    let cfString = attribute as CFString
    let error = AXUIElementCopyAttributeValue(self, cfString, &rawValue)

    try error.checkThrowing()

    if let rawValue {
      return try unpack(rawValue)
    } else {
      throw AccessibilityElementError.failedToFindRawValue
    }
  }

  public func parameterizedValue<T>(key: String, parameters: AnyObject, as _: T.Type) throws -> T {
    var value: AnyObject?
    let error = AXUIElementCopyParameterizedAttributeValue(self, key as CFString, parameters as CFTypeRef, &value)
    if error == .success, let value = value as? T {
      return value
    }
    throw error
  }

  func unpack(_ value: AnyObject) throws -> Any {
    switch CFGetTypeID(value) {
    case AXUIElementGetTypeID():
      return value as! AXUIElement
    case AXValueGetTypeID():
      let type = AXValueGetType(value as! AXValue)
      var result: Any
      switch type {
      case .axError:
        result = AXError.success
      case .cfRange:
        result = CFRange()
      case .cgPoint:
        result = CGPoint.zero
      case .cgRect:
        result = CGRect.zero
      case .cgSize:
        result = CGSize.zero
      case .illegal:
        return value
      @unknown default:
        return value
      }

      if !AXValueGetValue(value as! AXValue, type, &result) {
        throw AccessibilityElementError.failedToUnpack(value)
      }

      return result
    default:
      return value
    }
  }
}
