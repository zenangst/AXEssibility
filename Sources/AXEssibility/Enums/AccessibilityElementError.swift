enum AccessibilityElementError: Error {
  case unableToCreateRawValue
  case failedToGetAttribute(String)
  case typeIdMismatch
  case failedToUnpack(AnyObject)
}
