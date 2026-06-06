import Foundation

final class PhaseSignalDataStore {

    static let shared = PhaseSignalDataStore()
    private init() {}

    func signals(for phase: Phase) -> [DisplaySignal] {
        guard let phaseSignal = signal(for: phase) else { return [] }

        return phaseSignal.cards.map { cardType in
            .phase(phaseSignal, cardType)
        }

    }

    private func signal(for phase: Phase) -> PhaseSignal? {
        switch phase {
        case .menstrual:
            return menstrualSignal

        case .ovulation:
            return ovulationSignal
        case .luteal:
            return lutealSignal
        case .follicular:
            return follicularSignal

        default:
            return nil
        }
    }
}

private let menstrualSignal = PhaseSignal(
    phase: .menstrual,
    illustration: "menstrual_phase_illustration",
    cards: [.understanding, .symptoms, .support],
    understanding: PhaseUnderstanding(
        heading: "Periods in PCOS",
        descriptions: [
            "Because PCOS can cause skipped ovulation, the lining of your uterus might build up over time without shedding.",
            "When your period finally arrives, a lack of certain hormones can make the bleeding irregular, heavier, or last longer than usual.",
            "During your period, the shift in hormones and related body inflammation can leave you feeling extra tired or experiencing a bit of brain fog."
        ]
    ),

    symptoms: PhaseSymptoms(
        heading: "How you may feel",
        introText: "Everyone experiences this phase differently. You may notice some of the following.",
        symptomItems: [
            SymptomItem(
                name: "Cramps",
                icon: "AbdominalCrampsIcon",
                category: "menstrual"
            ),
            SymptomItem(
                name: "Bloating",
                icon: "BloatingIcon",
                category: "menstrual"
            ),
            SymptomItem(
                name: "Acne",
                icon: "AcneIcon",
                category: "menstrual"
            ),
            SymptomItem(
                name: "Mood Swings",
                icon: "DepressedIcon",
                category: "menstrual"
            )
        ]
    ),

    support: PhaseSupport(
        heading: "Support your body today",
        actions: menstrualSupportActions
    )
)
private let menstrualSupportActions: [SupportAction] = [

    SupportAction(
        category: .physicalCare,
        text: "Try gentle stretches like Cat-Cow or Child’s pose to ease cramps."
    ),
    SupportAction(
        category: .physicalCare,
        text: "Use a warm heating pad on your lower abdomen to reduce pain."
    ),
    SupportAction(
        category: .physicalCare,
        text: "Avoid intense workouts today and opt for light movement."
    ),

    SupportAction(
        category: .dietNutrition,
        text: "Eat anti-inflammatory foods like leafy greens, berries, nuts, olive oil, and turmeric."
    ),
    SupportAction(
        category: .dietNutrition,
        text: "Include iron-rich foods if bleeding feels heavier than usual."
    ),
    SupportAction(
        category: .dietNutrition,
        text: "Drink enough water to help reduce bloating and fatigue."
    ),

    SupportAction(
        category: .miscellaneous,
        text: "Prioritize good sleep and give your body permission to rest."
    ),
    SupportAction(
        category: .miscellaneous,
        text: "Practice stress-reducing habits like breathing or journaling."
    ),
    SupportAction(
        category: .miscellaneous,
        text: "Avoid touching or picking acne-prone skin."
    )
]

private let ovulationSignal = PhaseSignal(
    phase: .ovulation,
    illustration: "ovulation_phase_illustration",
    cards: [.understanding, .symptoms, .support],

    understanding: PhaseUnderstanding(
        heading: "Ovulation in PCOS",
        descriptions: [
            "Ovulation is when your body releases an egg. With PCOS, higher levels of certain hormones can pause this process, causing irregular periods or skipped ovulation.",
            "If and when ovulation does happen, a natural rise in estrogen can give you a nice boost in energy, sharper focus, and an uplifted mood.",
            "While tracking ovulation signs like body temperature can be helpful, keep in mind that PCOS can sometimes cause false hormone peaks on over-the-counter test kits."
        ]
    ),

    symptoms: PhaseSymptoms(
        heading: "How you may feel",
        introText: "Hormones can peak around ovulation. If ovulation occurs, you may notice some of these changes.",
        symptomItems: [

            SymptomItem(
                name: "Acne",
                icon: "AcneIcon",
                category: "Skin and Hair"
            ),

            SymptomItem(
                name: "Fatigue",
                icon: "FatigueIcon",
                category: "Lifestyle"
            ),

            SymptomItem(
                name: "Bloating",
                icon: "BloatingIcon",
                category: "Gut Health"
            ),

            SymptomItem(
                name: "Headache",
                icon: "HeadacheIcon",
                category: "Pain"
            )
        ]
    ),

    support: PhaseSupport(
        heading: "Support your body today",
        actions: ovulationSupportActions
    )
)
private let ovulationSupportActions: [SupportAction] = [

    SupportAction(
        category: .physicalCare,
        text: "Energy levels may be higher during ovulation. Moderate exercise or strength training can feel easier during this phase."
    ),

    SupportAction(
        category: .physicalCare,
        text: "Stay hydrated and maintain balanced meals to support hormone balance and steady energy."
    ),

    SupportAction(
        category: .dietNutrition,
        text: "Eating protein, healthy fats, and fiber can help stabilize blood sugar, which is especially important for people with PCOS."
    ),

    SupportAction(
        category: .dietNutrition,
        text: "Foods rich in magnesium and zinc may support hormonal health."
    ),

    SupportAction(
        category: .miscellaneous,
        text: "Fertility is highest around ovulation. Tracking your cycle can help you better understand your body's patterns."
    ),

    SupportAction(
        category: .miscellaneous,
        text: "Some people notice increased confidence, sociability, or sex drive during ovulation due to higher estrogen levels."
    )
]

private let follicularSignal = PhaseSignal(
    phase: .follicular,
    illustration: "follicular_phase_illustration",
    cards: [.understanding, .symptoms, .support],

    understanding: PhaseUnderstanding(
        heading: "Follicular Phase in PCOS",
        descriptions: [
            "This phase begins on the first day of your period and lasts until you ovulate. It's when your body prepares an egg to be released.",
            "Usually, your hormones encourage one egg to grow and mature. In PCOS, though, extra hormones can sometimes stall this growth.",
            "Because of this stall, your follicular phase might be longer than usual, or pause altogether, which contributes to the small, fluid-filled sacs often seen on ovaries."
        ]
    ),

    symptoms: PhaseSymptoms(
        heading: "How you may feel",
        introText: "As estrogen rises, many people notice improved mood, focus, and motivation.",
        symptomItems: [

            SymptomItem(
                name: "Fatigue",
                icon: "FatigueIcon",
                category: "Lifestyle"
            ),

            SymptomItem(
                name: "Acne",
                icon: "AcneIcon",
                category: "Skin and Hair"
            ),

            SymptomItem(
                name: "Bloating",
                icon: "BloatingIcon",
                category: "Gut Health"
            ),

            SymptomItem(
                name: "Headache",
                icon: "HeadacheIcon",
                category: "Pain"
            )
        ]
    ),

    support: PhaseSupport(
        heading: "Support your body today",
        actions: follicularSupportActions
    )
)
private let follicularSupportActions: [SupportAction] = [

    SupportAction(
        category: .physicalCare,
        text: "Energy may begin to improve during this phase, making it a good time to gradually increase physical activity."
    ),

    SupportAction(
        category: .physicalCare,
        text: "Strength training or moderate workouts may feel easier as estrogen rises."
    ),

    SupportAction(
        category: .dietNutrition,
        text: "Focus on balanced meals with protein, healthy fats, and fiber to support blood sugar stability in PCOS."
    ),

    SupportAction(
        category: .dietNutrition,
        text: "Include leafy greens, whole grains, and anti-inflammatory foods."
    ),

    SupportAction(
        category: .miscellaneous,
        text: "Mental clarity and motivation often increase in this phase, making it a good time for planning or creative work."
    ),

    SupportAction(
        category: .miscellaneous,
        text: "Tracking your cycle can help you recognize when ovulation may occur."
    )
]

private let lutealSignal = PhaseSignal(
    phase: .luteal,
    illustration: "luteal_phase_illustration",
    cards: [.understanding, .symptoms, .support],

    understanding: PhaseUnderstanding(
        heading: "Luteal Phase in PCOS",
        descriptions: [
            "This phase happens right after ovulation, where your body creates a balancing hormone called progesterone to support a healthy cycle.",
            "If you skipped ovulation, your body doesn't produce this extra progesterone, leaving you exposed to higher levels of estrogen.",
            "Without enough progesterone, and with PCOS hormones in the mix, you might notice stronger PMS symptoms like fatigue, mood swings, and unexpected breakouts."
        ]
    ),

    symptoms: PhaseSymptoms(
        heading: "How you may feel",
        introText: "Hormone changes during the luteal phase can cause both physical and emotional symptoms.",
        symptomItems: [

            SymptomItem(
                name: "Bloating",
                icon: "BloatingIcon",
                category: "Gut Health"
            ),

            SymptomItem(
                name: "Fatigue",
                icon: "FatigueIcon",
                category: "Lifestyle"
            ),

            SymptomItem(
                name: "Acne",
                icon: "AcneIcon",
                category: "Skin and Hair"
            ),

            SymptomItem(
                name: "Depressed",
                icon: "DepressedIcon",
                category: "Lifestyle"
            )
        ]
    ),

    support: PhaseSupport(
        heading: "Support your body today",
        actions: lutealSupportActions
    )
)
private let lutealSupportActions: [SupportAction] = [

    SupportAction(
        category: .physicalCare,
        text: "Gentle exercise such as walking, yoga, or stretching may help reduce bloating and discomfort."
    ),

    SupportAction(
        category: .physicalCare,
        text: "Prioritize sleep and rest as energy levels may decrease in this phase."
    ),

    SupportAction(
        category: .dietNutrition,
        text: "Balanced meals with protein and complex carbohydrates may help stabilize blood sugar."
    ),

    SupportAction(
        category: .dietNutrition,
        text: "Magnesium-rich foods such as nuts, seeds, and leafy greens may support mood and muscle relaxation."
    ),

    SupportAction(
        category: .miscellaneous,
        text: "Mood changes are common during this phase. Gentle self-care and stress management can help."
    ),

    SupportAction(
        category: .miscellaneous,
        text: "Tracking symptoms can help you recognize patterns in your cycle."
    )
]
