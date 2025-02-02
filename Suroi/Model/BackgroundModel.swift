import UIKit

class BackgroundModel {

    func backgroundImageName(forGameMode mode: String) -> String {
        switch mode {
        case "winter":
            return "winter_background"
        case "fall":
            return "fall_background"
        case "halloween":
            return "halloween_background"
        default:
            return "normal_background"
        }
    }

    func updateBackground(forGameMode mode: String, in imageView: UIImageView) {
        let imageName = backgroundImageName(forGameMode: mode)
        imageView.image = UIImage(named: imageName)
    }
}
// bleh again
