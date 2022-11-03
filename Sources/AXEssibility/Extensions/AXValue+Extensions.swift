import Cocoa

extension AXValue {
  internal func toValue<T>() throws -> T? {
    let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    let success = AXValueGetValue(self, AXValueGetType(self), pointer)
    if success {
      return pointer.pointee
    } else {
      throw AXError.failure
    }
  }

  internal static func from<T>(value: T, type: AXValueType) -> AXValue? {
    let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    pointer.pointee = value
    return AXValueCreate(type, pointer)
  }
}
