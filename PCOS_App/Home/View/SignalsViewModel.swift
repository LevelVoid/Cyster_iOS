import Foundation

final class PCOSSignalViewModel {

    private let signal: PCOSSignal

    init(signal: PCOSSignal) {
        self.signal = signal
    }

    var infoText: String {
        signal.scientificReasons.first ?? ""
    }

    var appearanceText: String {
        signal.appearanceDescriptions.first ?? ""
    }

    func supportAction(for category: SupportCategory) -> SupportAction? {
        return SupportRotationStore.shared
            .nextSupportAction(for: signal, category: category)
    }

}

extension PhaseSignal {

    func cardTitle(for type: PhaseCardType) -> String {
        switch type {
        case .understanding:
            return understanding.heading   
        case .symptoms:
            return symptoms.heading        
        case .support:
            return support.heading         
        }
    }

    func cardImage(for type: PhaseCardType) -> String {
        switch (phase, type) {

        case (.menstrual, .understanding):
            return "menstrual_phase_illustration"

        case (.menstrual, .symptoms):
            return "cycle"

        case (.menstrual, .support):
            return "menstrual_support_illustration"

        case (.ovulation, .understanding):
            return "ovulation_phase_illustration"

        case (.ovulation, .symptoms):
            return "cycle"

        case (.ovulation, .support):
            return "ovulation_support_illustration"

            case (.luteal, .understanding):
                return "luteal_phase_illustration"

            case (.luteal, .symptoms):
                return "cycle"

            case (.luteal, .support):
                return "luteal_support_illustration"

            case (.follicular, .understanding):
                return "follicular_phase_illustration"

            case (.follicular, .symptoms):
                return "cycle"

            case (.follicular, .support):
                return "follicular_support_illustration"

        default:
            return illustration
        }
    }
}

