import UIKit

extension UIImageView {
    private struct AssociatedKeys {
        static var isFullRoundedKey: UInt8 = 0
    }

    private var isFullRounded: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.isFullRoundedKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isFullRoundedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func addFullRoundedCorner() {
        guard !isFullRounded else { return }
        isFullRounded = true
        clipsToBounds = true
        contentMode = .scaleAspectFill
        applyRoundedIfNeeded()
    }

    func applyRoundedIfNeeded() {
        guard isFullRounded else { return }
        let radius = min(bounds.width, bounds.height) / 2
        if layer.cornerRadius != radius {
            layer.cornerRadius = radius
        }
    }
}
