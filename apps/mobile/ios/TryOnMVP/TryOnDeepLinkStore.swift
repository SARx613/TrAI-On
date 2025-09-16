import Foundation

struct TryOnDeepLinkPayload {
  let originalURL: URL
  let productURL: URL?
  let brand: String?
}

extension Notification.Name {
  static let tryOnDidReceiveLink = Notification.Name("TryOnDidReceiveLink")
}

final class TryOnDeepLinkStore {
  static let shared = TryOnDeepLinkStore()

  private(set) var lastPayload: TryOnDeepLinkPayload?
  private let queue = DispatchQueue(label: "com.tryon.link", qos: .userInitiated)

  private init() {}

  func handle(url: URL) {
    queue.async { [weak self] in
      guard let self else { return }
      let payload = self.parse(url: url)
      self.lastPayload = payload
      let productString = payload.productURL?.absoluteString ?? ""
      let brand = payload.brand ?? ""
      print("[TryOnDeepLink] brand=\(brand) product=\(productString)")
      DispatchQueue.main.async {
        NotificationCenter.default.post(name: .tryOnDidReceiveLink, object: self, userInfo: [
          "url": url.absoluteString,
          "productURL": productString,
          "brand": brand
        ])
      }
    }
  }

  private func parse(url: URL) -> TryOnDeepLinkPayload {
    var product: URL?
    var brand: String?

    if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
      if let queryItems = components.queryItems {
        if let value = queryItems.first(where: { $0.name == "u" })?.value,
           let decoded = value.removingPercentEncoding,
           let productURL = URL(string: decoded) {
          product = productURL
        }
        if let brandValue = queryItems.first(where: { $0.name == "brand" })?.value {
          brand = brandValue
        }
      }
      if components.scheme == "https" && components.host == "tryon.example" {
        components.queryItems = nil
        components.path = "/"
      }
    }

    return TryOnDeepLinkPayload(originalURL: url, productURL: product, brand: brand)
  }
}
