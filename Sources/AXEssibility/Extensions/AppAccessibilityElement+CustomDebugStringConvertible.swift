import Foundation

extension AppAccessibilityElement: CustomDebugStringConvertible  {
  public var debugDescription: String {
    var output = """
AppAccessibilityElement
  .pid: \(debugValue(pid))
  .title: \(debugValue(title))
  .isFrontmost: \(debugValue(isFrontmost))
  .windows:\n
"""
    for window in windows {
      let lines = window.debugDescription.components(separatedBy: "\n")
      for line in lines {
        output += """
      \(line)\n
"""
      }
    }

    return output
  }
}
