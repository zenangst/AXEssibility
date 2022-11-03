import Cocoa

extension AXError: Error {}

internal extension AXError {
  func checkThrowing() throws {
    if self != .success {
      throw self
    }
  }
}
