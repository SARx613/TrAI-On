import UIKit
import React

@main
class AppDelegate: RCTAppDelegate {
  override init() {
    super.init()
    moduleName = "TryOnMVP"
    initialProps = [:]
  }

  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let userActivityDictionary = launchOptions?[.userActivityDictionary] as? [AnyHashable: Any] {
      for (_, activity) in userActivityDictionary {
        if let userActivity = activity as? NSUserActivity,
           userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
          TryOnDeepLinkStore.shared.handle(url: url)
        }
      }
    }

    return result
  }

  override func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    TryOnDeepLinkStore.shared.handle(url: url)
    return super.application(application, open: url, options: options)
  }

  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
      TryOnDeepLinkStore.shared.handle(url: url)
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  override func sourceURL(for bridge: RCTBridge!) -> URL! {
    #if DEBUG
    return RCTBundleURLProvider.sharedSettings()?.jsBundleURL(forBundleRoot: "index")
    #else
    return Bundle.main.url(forResource: "main", withExtension: "jsbundle")
    #endif
  }
}
