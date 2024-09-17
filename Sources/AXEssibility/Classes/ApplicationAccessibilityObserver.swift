import AppKit
import ApplicationServices

public final class ApplicationAccessibilityObserver: Identifiable {
  public let id: UUID
  public let element: AXUIElement
  public let notification: AppAccessibilityElement.Notification
  public let runningApplication: NSRunningApplication
  let reference: AXObserver

  fileprivate init?(_ runningApplication: NSRunningApplication,
                    id: UUID,
                    element: AXUIElement,
                    notification: AppAccessibilityElement.Notification,
                    callback: AXObserverCallback) {
    var observer: AXObserver?
    guard AXObserverCreate(runningApplication.processIdentifier, callback, &observer) == .success, let observer else { return nil }
    self.id = id
    self.runningApplication = runningApplication
    self.reference = observer
    self.element = element
    self.notification = notification
  }

  fileprivate init(_ runningApplication: NSRunningApplication,
                   id: UUID,
                   observer: AXObserver, element: AXUIElement,
                   notification: AppAccessibilityElement.Notification) {
    self.id = id
    self.runningApplication = runningApplication
    self.reference = observer
    self.element = element
    self.notification = notification
  }

  static func observe(_ pid: pid_t, id: UUID, element: AXUIElement, notification: AppAccessibilityElement.Notification,
                      pointer: UnsafeMutableRawPointer? = nil, callback: AXObserverCallback) -> ApplicationAccessibilityObserver? {
    guard let runningApplication = NSRunningApplication(processIdentifier: pid),
      let applicationAccessibilityObserver = ApplicationAccessibilityObserver(
      runningApplication,
      id: id,
      element: element,
      notification: notification,
      callback: callback) else { return nil }
    let observer = applicationAccessibilityObserver.reference
    for _ in 0 ... 1 {
      if AXObserverAddNotification(observer, element, notification.rawValue as CFString, pointer) == .success {
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
        return ApplicationAccessibilityObserver(
          runningApplication,
          id: applicationAccessibilityObserver.id,
          observer: observer,
          element: element, notification: notification)
      }
    }

    return nil
  }

  public  func removeObserver() {
    AXObserverRemoveNotification(reference, element, notification.rawValue as CFString)
  }
}
