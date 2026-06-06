import UIKit
import ImageIO

final class GIFManager {

    static let shared = GIFManager()
    private init() {}

    private let cache = NSCache<NSString, UIImage>()

    func gif(named name: String) -> UIImage? {

        if let cached = cache.object(forKey: name as NSString) {
            return cached
        }

        guard let asset = NSDataAsset(name: name.replacingOccurrences(of: ".gif", with: "")) else {
            return nil
        }

        guard let gifImage = UIImage.gifImageWithData(asset.data) else {
            return nil
        }

        cache.setObject(gifImage, forKey: name as NSString)

        return gifImage
    }
}

