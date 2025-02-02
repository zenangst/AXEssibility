import Foundation

extension WindowAccessibilityElement: CustomDebugStringConvertible {
  public var debugDescription: String {
    let output =
"""
WindowAccessibilityElement
    .id: \(debugValue(id))
    .title: \(debugValue(title))
    .role: \(debugValue(role))
    .subrole: \(debugValue(subrole))
    .isFocused: \(debugValue(isFocused))
    .isMinimized: \(debugValue(isMinimized))
    .isFullscreen: \(debugValue(isFullscreen))
    .position: (x: \(debugValue(position?.x)) y: \(debugValue(position?.y))
    .size: (width: \(debugValue(size?.width)) height: \(debugValue(size?.height)))\n
"""
    return output
  }
}
