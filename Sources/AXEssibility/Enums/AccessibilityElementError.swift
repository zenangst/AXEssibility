enum AccessibilityElementError: Error {
  case unableToCreateRawValue
  case failedToGetAttribute(String)
  case typeIdMismatch
  case failedToFindRawValue
  case failedToCastAnyValue
  case failedToUnpack(AnyObject)
}
