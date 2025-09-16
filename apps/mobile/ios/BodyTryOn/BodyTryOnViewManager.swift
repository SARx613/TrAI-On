import Foundation
import React

@objc(BodyTryOnViewManager)
class BodyTryOnViewManager: RCTViewManager {
  override static func requiresMainQueueSetup() -> Bool { true }

  override func view() -> UIView! {
    return BodyTryOnView(frame: .zero)
  }
}
