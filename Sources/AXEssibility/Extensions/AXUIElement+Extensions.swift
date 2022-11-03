import Cocoa

extension AXUIElement {
  internal func rawValue(for attribute: NSAccessibility.Attribute) throws -> Any? {
    try rawValue(for: attribute.rawValue)
  }

  internal func rawValue(for attribute: String) throws -> Any? {
    var rawValue: AnyObject?
    let cfString = attribute as CFString
    let error = AXUIElementCopyAttributeValue(self, cfString, &rawValue)

    try error.checkThrowing()

    if let rawValue {
      return try unpack(rawValue)
    } else {
      return nil
    }
  }

  private func unpack(_ value: AnyObject) throws -> Any {
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
