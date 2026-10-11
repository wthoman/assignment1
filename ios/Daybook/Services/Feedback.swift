import UIKit
import AudioToolbox

/// The two feel settings from Settings: "Sounds — A soft tap when you check off"
/// and "Haptics — Little buzzes for big moments".
enum Feedback {
    @MainActor
    static func checkOff(_ m: AppModel) {
        if m.settings["sound"] == true { AudioServicesPlaySystemSound(1104) }   // soft keyboard tick; honours the silent switch
        if m.settings["haptics"] == true { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    }

    @MainActor
    static func bigMoment(_ m: AppModel) {
        if m.settings["haptics"] == true { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    }
}
