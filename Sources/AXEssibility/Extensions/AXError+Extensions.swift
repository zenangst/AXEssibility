import Cocoa

extension AXError: @retroactive Error {}

internal extension AXError {
  func checkThrowing() throws {
    if self != .success {
      throw self
    }
  }
}
