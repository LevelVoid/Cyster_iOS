import Foundation

class RoutineDataStore {
    static let shared = RoutineDataStore()
    private init() {}

    private func ex(_ name: String) -> Exercise {
        guard let exercise = ExerciseDataStore.shared.allExercises.first(where: { $0.name == name }) else {
            fatalError("Exercise '\(name)' not found in ExerciseDataStore")
        }
        return exercise
    }

    lazy var predefinedRoutines: [Routine] = {
        var all = menstrualRoutines + follicularRoutines + ovulationRoutines + lutealRoutines + unknownRoutines
        let cardios = ["Incline Treadmill Walk", "Elliptical Trainer", "Treadmill Run", "Electric Bicycle"]

        for i in 0..<all.count {
            if all[i].estimatedDurationSeconds < 2400 {

                if let existingIdx = all[i].exercises.firstIndex(where: { cardios.contains($0.exercise.name) }) {
                    let currentDur = all[i].exercises[existingIdx].durationSeconds ?? 0
                    all[i].exercises[existingIdx].durationSeconds = currentDur + 600
                } else {
                    if let randomCardioName = cardios.randomElement() {
                        let extraCardio = RoutineExercise(exercise: self.ex(randomCardioName), durationSeconds: 600)
                        all[i].exercises.append(extraCardio)
                    }
                }
            }
        }
        return all
    }()

    func routines(for phase: Phase) -> [Routine] {
        return predefinedRoutines.filter { $0.phase == phase }
    }

    func dailyRoutines(for phase: Phase) -> [Routine] {
        let phaseRoutines = routines(for: phase)
        let yogaRoutines = phaseRoutines.filter { $0.routineType == .yoga }
        let strengthRoutines = phaseRoutines.filter { $0.routineType == .strength }

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1

        var selectedYoga: [Routine] = []
        if yogaRoutines.count >= 2 {
            let startIdx = (dayOfYear - 1) % yogaRoutines.count
            selectedYoga.append(yogaRoutines[startIdx])
            selectedYoga.append(yogaRoutines[(startIdx + 1) % yogaRoutines.count])
        } else {
            selectedYoga = yogaRoutines
        }

        var selectedStrength: [Routine] = []
        if strengthRoutines.count >= 2 {
            let startIdx = (dayOfYear - 1) % strengthRoutines.count
            selectedStrength.append(strengthRoutines[startIdx])
            selectedStrength.append(strengthRoutines[(startIdx + 1) % strengthRoutines.count])
        } else {
            selectedStrength = strengthRoutines
        }

        return selectedYoga + selectedStrength
    }

    func recommendedRoutine(for phase: Phase) -> Routine {
        let daily = dailyRoutines(for: phase)
        return daily.first ?? predefinedRoutines.first!
    }

    func isRecommendedToday(_ routine: Routine, for phase: Phase) -> Bool {
        return recommendedRoutine(for: phase).id == routine.id
    }

    private lazy var menstrualRoutines: [Routine] = [
        Routine(
            id: UUID(), name: "Gentle Flow",
            exercises: [
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Downward Dog"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Bhujangasana"), durationSeconds: 420)
            ],
            thumbnailImageName: "routine_9", routineTagline: "A grounding yoga sequence to safely ease back and pelvic tension during your period.",
            routineDescription: "A restorative and gentle yoga flow tailored for menstrual phase comfort, promoting relaxation and reducing cortisol.",
            phase: .menstrual, routineType: .yoga
        ),
        Routine(
            id: UUID(), name: "Restorative Stretch",
            exercises: [
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Hip Rotation"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Malasana (Yogic Squat)"), durationSeconds: 420)
            ],
            thumbnailImageName: "routine_10", routineTagline: "Deep, restorative holds perfectly soothing your tough menstrual cramps and stiffness.",
            routineDescription: "This long-hold stretching routine specifically targets the hips, pelvis, and lower back to ease intense menstrual discomfort.",
            phase: .menstrual, routineType: .yoga
        ),
        Routine(
            id: UUID(), name: "Light Core Activation",
            exercises: [
                RoutineExercise(exercise: ex("Jumping Jacks"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Bird Dog"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Glute Bridge"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Plank"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Leg Raises"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Incline Treadmill Walk"), durationSeconds: 600),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 120)
            ],
            thumbnailImageName: "routine_11", routineTagline: "Gentle core engagement importantly supporting full circulation safely during your period.",
            routineDescription: "A light, stabilizing core session that builds necessary strength while completely avoiding high-intensity burnout during your period.",
            phase: .menstrual, routineType: .strength
        ),
        Routine(
            id: UUID(), name: "Lower Body Ease",
            exercises: [
                RoutineExercise(exercise: ex("Jumping Jacks"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Glute Bridge"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Lunges"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Squats"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Seated Calf Raises"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Incline Treadmill Walk"), durationSeconds: 600),
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 120)
            ],
            thumbnailImageName: "routine_12", routineTagline: "Maintain consistent leg strength with safe, low-impact movements during your true period.",
            routineDescription: "Keep your lower body strong without exhausting yourself. This low-impact strength session is designed specifically for menstrual energy dips.",
            phase: .menstrual, routineType: .strength
        ),
        Routine(
            id: UUID(), name: "Low Energy Movement",
            exercises: [
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Glute Bridge"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Bird Dog"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Incline Treadmill Walk"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_13", routineTagline: "A deeply comforting routine gently supporting lymphatic flow when fatigued from your period.",
            routineDescription: "For your lowest energy days, this extremely gentle routine prioritizes light activation to help you feel better rather than drained.",
            phase: .menstrual, routineType: .mixed
        ),
        Routine(
            id: UUID(), name: "Calm & Steady",
            exercises: [
                RoutineExercise(exercise: ex("Hip Rotation"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Face Pulls"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Cable Row"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Elliptical Trainer"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Downward Dog"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_14", routineTagline: "Slow, perfectly deliberate movements to comfortably steady your mind safely during your period.",
            routineDescription: "A combination of stabilizing exercises tailored to help regulate physical and mental stress when you feel overloaded.",
            phase: .menstrual, routineType: .mixed
        ),
        Routine(
            id: UUID(), name: "Gentle Mobility",
            exercises: [
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Bird Dog"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Plank"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Incline Treadmill Walk"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_15", routineTagline: "Release tight hips and slowly improve your functional mobility to reduce menstrual bloating.",
            routineDescription: "Blend gentle joint mobility with light cardiovascular movement to reduce water retention and ease painful cramps gently.",
            phase: .menstrual, routineType: .mixed
        )
    ]

    private lazy var follicularRoutines: [Routine] = [
        Routine(
            id: UUID(), name: "Energizing Yoga Flow",
            exercises: [
                RoutineExercise(exercise: ex("Downward Dog"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Bhujangasana"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Bow Pose"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Malasana (Yogic Squat)"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 420)
            ],
            thumbnailImageName: "routine_9", routineTagline: "A dynamic flowing sequence designed cleanly to build your naturally rising follicular stamina.",
            routineDescription: "As your estrogen climbs, harness your growing energy with this progressive yoga flow designed to increase your cardiovascular stamina safely.",
            phase: .follicular, routineType: .yoga
        ),
        Routine(
            id: UUID(), name: "Sun Salutation Series",
            exercises: [
                RoutineExercise(exercise: ex("Downward Dog"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Bhujangasana"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Plank"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 420)
            ],
            thumbnailImageName: "routine_10", routineTagline: "A highly modified sun salutation perfectly syncing with your rising follicular hormones.",
            routineDescription: "Flow through repeated, heat-building postures that encourage circulation and gently push your cardiovascular boundaries without overstressing.",
            phase: .follicular, routineType: .yoga
        ),
        Routine(
            id: UUID(), name: "Progressive Lower Body",
            exercises: [
                RoutineExercise(exercise: ex("Jump Rope"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Squats"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Lunges"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Leg Press"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Seated Calf Raises"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Treadmill Run"), durationSeconds: 600),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 120)
            ],
            thumbnailImageName: "routine_11", routineTagline: "Steadily condition the sensitive lower body and nicely build follicular resilience safely.",
            routineDescription: "Your body is primed for strength gains during this phase. This progressive lower body workout focuses heavily on form, power, and muscle resilience.",
            phase: .follicular, routineType: .strength
        ),
        Routine(
            id: UUID(), name: "Upper Body Builder",
            exercises: [
                RoutineExercise(exercise: ex("Jumping Jacks"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Lat Pulldown"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Cable Row"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Face Pulls"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Lateral Raises"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Elliptical Trainer"), durationSeconds: 600),
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 120)
            ],
            thumbnailImageName: "routine_12", routineTagline: "Sculpt your upper body naturally utilizing steady follicular energy safely for improved posture.",
            routineDescription: "Leverage this phase's hormonal environment to build strong, stable upper body muscles, particularly focusing on your back and shoulders.",
            phase: .follicular, routineType: .strength
        ),
        Routine(
            id: UUID(), name: "Cardio & Core Combo",
            exercises: [
                RoutineExercise(exercise: ex("Hip Rotation"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Electric Bicycle"), durationSeconds: 120),
                RoutineExercise(exercise: ex("Leg Raises"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Jump Rope"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_13", routineTagline: "Elevate your heart rate and properly engage your core cleanly utilizing fresh follicular energy.",
            routineDescription: "A mix of moderate cardiovascular intervals and targeted core work, perfect for utilizing your improving stamina and boosting metabolic health.",
            phase: .follicular, routineType: .mixed
        ),
        Routine(
            id: UUID(), name: "Dynamic Warm-Up",
            exercises: [
                RoutineExercise(exercise: ex("Jumping Jacks"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Squats"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Lunges"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Treadmill Run"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Downward Dog"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_14", routineTagline: "Properly warm up major muscle groups carefully utilizing your new building follicular energy.",
            routineDescription: "A dynamic transition routine that bridges the gap between gentle mobility and full-blown strength, getting you ready for more challenging days.",
            phase: .follicular, routineType: .mixed
        ),
        Routine(
            id: UUID(), name: "Full Body Activation",
            exercises: [
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Bent Over Row"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Glute Bridge"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Elliptical Trainer"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Plank"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_15", routineTagline: "A brilliantly balanced approach easily building solid foundational strength in your follicular phase.",
            routineDescription: "A balanced, moderately intense full-body session that recruits all your major muscle groups evenly, promoting systemic strength and stability.",
            phase: .follicular, routineType: .mixed
        )
    ]

    private lazy var ovulationRoutines: [Routine] = [
        Routine(
            id: UUID(), name: "Power Yoga",
            exercises: [
                RoutineExercise(exercise: ex("Plank"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Downward Dog"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Bhujangasana"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Bow Pose"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Malasana (Yogic Squat)"), durationSeconds: 420)
            ],
            thumbnailImageName: "routine_9", routineTagline: "A highly challenging power yoga sequence perfectly utilizing your absolute peak ovulation energy.",
            routineDescription: "A demanding power yoga sequence designed to take full advantage of your testosterone and estrogen peaks, pushing your muscular endurance to its limit.",
            phase: .ovulation, routineType: .yoga
        ),
        Routine(
            id: UUID(), name: "Flexibility Flow",
            exercises: [
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Bow Pose"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Downward Dog"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Malasana (Yogic Squat)"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Bhujangasana"), durationSeconds: 420)
            ],
            thumbnailImageName: "routine_10", routineTagline: "Deep flexibility work purely safely pushing your true mobility boundaries while pliable in ovulation.",
            routineDescription: "Take advantage of peak hormone-induced ligament laxity with a flow that deeply stretches and improves your overall functional range of motion.",
            phase: .ovulation, routineType: .yoga
        ),
        Routine(
            id: UUID(), name: "Build & Burn Legs",
            exercises: [
                RoutineExercise(exercise: ex("Jump Rope"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Deadlift"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Leg Press"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Squats"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Seated Calf Raises"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Treadmill Run"), durationSeconds: 600),
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 120)
            ],
            thumbnailImageName: "routine_11", routineTagline: "A amazingly strong, compound session completely confidently building leg strength during ovulation.",
            routineDescription: "This heavy compound lower body routine is meant for your highest energy days. Push real weight and focus on maximizing your strength output safely.",
            phase: .ovulation, routineType: .strength
        ),
        Routine(
            id: UUID(), name: "Maximum Strength Upper",
            exercises: [
                RoutineExercise(exercise: ex("Jumping Jacks"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Bent Over Row"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Lat Pulldown"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Hammer Curl"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Lateral Raises"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Elliptical Trainer"), durationSeconds: 600),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 120)
            ],
            thumbnailImageName: "routine_12", routineTagline: "Push past limits purely safely with heavy upper body movements deeply during peak ovulation.",
            routineDescription: "When your testosterone peaks mid-cycle, use this high-intensity upper body routine to challenge your limits and prioritize significant muscle growth.",
            phase: .ovulation, routineType: .strength
        ),
        Routine(
            id: UUID(), name: "HIIT Fusion",
            exercises: [
                RoutineExercise(exercise: ex("Jump Rope"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Squats"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Electric Bicycle"), durationSeconds: 120),
                RoutineExercise(exercise: ex("Treadmill Run"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_13", routineTagline: "A truly fast-paced, high interval routine to perfectly match your incredible peak ovulation energy.",
            routineDescription: "Blend high-intensity athletic intervals with steady recovery to massively boost cardiovascular fitness during the narrow window your body can handle the stress.",
            phase: .ovulation, routineType: .mixed
        ),
        Routine(
            id: UUID(), name: "Total Body Challenge",
            exercises: [
                RoutineExercise(exercise: ex("Hip Rotation"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Deadlift"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Cable Row"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Elliptical Trainer"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Plank"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_14", routineTagline: "A highly demanding full-body conditioning session perfectly testing your peak stamina in ovulation.",
            routineDescription: "Combine heavy full-body strength movements with sustained cardiovascular efforts to build elite endurance and power while you have the energy to spare.",
            phase: .ovulation, routineType: .mixed
        ),
        Routine(
            id: UUID(), name: "Peak Performance",
            exercises: [
                RoutineExercise(exercise: ex("Jumping Jacks"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Squats"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Lat Pulldown"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Treadmill Run"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Downward Dog"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_15", routineTagline: "Train completely fearlessly at your absolute ovulation peak with explosive power and high endurance.",
            routineDescription: "This is the routine you save for when you feel invincible. Push limits across all muscle groups in this demanding peak performance conditioning session.",
            phase: .ovulation, routineType: .mixed
        )
    ]

    private lazy var lutealRoutines: [Routine] = [
        Routine(
            id: UUID(), name: "Calming Yoga",
            exercises: [
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Downward Dog"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Hip Rotation"), durationSeconds: 420)
            ],
            thumbnailImageName: "routine_9", routineTagline: "An unbelievably anxiety-reducing sequence purposefully designed to effectively soothe luteal PMS.",
            routineDescription: "As progesterone rises and energy wanes, use this incredibly soothing yoga flow to intentionally lower your heart rate and combat pre-menstrual anxiety.",
            phase: .luteal, routineType: .yoga
        ),
        Routine(
            id: UUID(), name: "Yin Stretch",
            exercises: [
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Malasana (Yogic Squat)"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Hip Rotation"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 420)
            ],
            thumbnailImageName: "routine_10", routineTagline: "A very deeply relaxing luteal stretch practice safely releasing tension just before your period.",
            routineDescription: "A yin-style practice emphasizing very long, relaxed holds that open up stubborn connective tissues and melt away built-up physical and mental tension.",
            phase: .luteal, routineType: .yoga
        ),
        Routine(
            id: UUID(), name: "Moderate Lower Body",
            exercises: [
                RoutineExercise(exercise: ex("Hip Rotation"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Squats"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Glute Bridge"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Lunges"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Leg Extension"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Incline Treadmill Walk"), durationSeconds: 600),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 120)
            ],
            thumbnailImageName: "routine_11", routineTagline: "A perfectly steady, highly sustainable lower body workout session specifically for your luteal phase.",
            routineDescription: "Protect your hard-earned strength gains with a highly consistent, moderate-intensity workout that won't spike your cortisol or exhaust you prematurely.",
            phase: .luteal, routineType: .strength
        ),
        Routine(
            id: UUID(), name: "Steady Resistance",
            exercises: [
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Cable Row"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Lat Pulldown"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Face Pulls"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Seated Calf Raises"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Elliptical Trainer"), durationSeconds: 600),
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 120)
            ],
            thumbnailImageName: "routine_12", routineTagline: "Controlled, highly moderate resistance absolutely safely keeping your strength base in the luteal phase.",
            routineDescription: "A highly controlled, mostly machine-based workout designed to provide excellent muscular stimulus without stressing your central nervous system.",
            phase: .luteal, routineType: .strength
        ),
        Routine(
            id: UUID(), name: "Slow Burn",
            exercises: [
                RoutineExercise(exercise: ex("Hip Rotation"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Glute Bridge"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Bird Dog"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Incline Treadmill Walk"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_13", routineTagline: "Super low-impact luteal training gracefully prioritizing glute activation and gentle steady cardio.",
            routineDescription: "A pure, slow-burn cardiovascular session focused entirely on gentle incline walking and simple glute work to keep your engine running smoothly.",
            phase: .luteal, routineType: .mixed
        ),
        Routine(
            id: UUID(), name: "Mindful Movement",
            exercises: [
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Squats"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Plank"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Elliptical Trainer"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Downward Dog"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_14", routineTagline: "Dynamic luteal movements simply requiring deep focus to gently tune exactly into your personal body.",
            routineDescription: "By combining intentional, slow-movement strength patterns with deep stretching, this routine honors your body's need for both work and deliberate rest.",
            phase: .luteal, routineType: .mixed
        ),
        Routine(
            id: UUID(), name: "Balanced Recovery",
            exercises: [
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Lunges"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Electric Bicycle"), durationSeconds: 120),
                RoutineExercise(exercise: ex("Incline Treadmill Walk"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_15", routineTagline: "A highly supportive, deeply calming luteal session smoothly promoting recovery before your period.",
            routineDescription: "The ultimate bridge routine designed specifically for those exhausted pre-menstrual days, ensuring you stay active without making your fatigue any worse.",
            phase: .luteal, routineType: .mixed
        )
    ]

    private lazy var unknownRoutines: [Routine] = [
        Routine(
            id: UUID(), name: "Gentle Yoga Flow",
            exercises: [
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Downward Dog"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Bhujangasana"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 420)
            ],
            thumbnailImageName: "routine_9", routineTagline: "A purely universally satisfying yoga flow that feels totally incredibly good at any random cycle phase.",
            routineDescription: "This fail-safe yoga routine is perfectly balanced for any day. It provides enough movement to feel productive, but enough rest to feel deeply rejuvenated.",
            phase: .unknown, routineType: .yoga
        ),
        Routine(
            id: UUID(), name: "Grounding Stretch",
            exercises: [
                RoutineExercise(exercise: ex("Malasana (Yogic Squat)"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Hip Rotation"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 420),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 420)
            ],
            thumbnailImageName: "routine_10", routineTagline: "Find your incredibly calm, beautiful spiritual center carefully balancing out any random cycle phase.",
            routineDescription: "Use this comprehensive stretching routine to improve pelvic floor circulation and ground yourself physically and mentally whenever you feel completely disconnected.",
            phase: .unknown, routineType: .yoga
        ),
        Routine(
            id: UUID(), name: "General Strength Legs",
            exercises: [
                RoutineExercise(exercise: ex("Jumping Jacks"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Squats"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Glute Bridge"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Leg Press"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Seated Calf Raises"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Treadmill Run"), durationSeconds: 600),
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 120)
            ],
            thumbnailImageName: "routine_11", routineTagline: "Safely establish a highly reliable, strongly functional lower-body baseline naturally in any specific phase.",
            routineDescription: "Perfect for any phase, this highly reliable lower body session skips the complex movements in favor of safe, foundational exercises that always work well.",
            phase: .unknown, routineType: .strength
        ),
        Routine(
            id: UUID(), name: "Body Balance Back",
            exercises: [
                RoutineExercise(exercise: ex("Hip Rotation"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Bent Over Row"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Cable Row"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Lat Pulldown"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Face Pulls"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Elliptical Trainer"), durationSeconds: 600),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 120)
            ],
            thumbnailImageName: "routine_12", routineTagline: "A beautifully supportive upper body routine absolutely safely designed flawlessly for any random cycle phase.",
            routineDescription: "Focuses heavily on pulling movements and back stability. This is your go-to routine to reverse the effects of daily life and build symmetrical upper body strength.",
            phase: .unknown, routineType: .strength
        ),
        Routine(
            id: UUID(), name: "Adaptive Movement",
            exercises: [
                RoutineExercise(exercise: ex("Cat Cow"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Squats"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Bird Dog"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Incline Treadmill Walk"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Glute Bridge"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_13", routineTagline: "A perfectly flexible, highly adaptable routine safely harmonizing exactly with however your random cycle feels.",
            routineDescription: "A highly adaptable combination routine that serves as a moving meditation. You decide the intensity, ensuring you ALWAYS get exactly what you need out of it.",
            phase: .unknown, routineType: .mixed
        ),
        Routine(
            id: UUID(), name: "Core & Stretch",
            exercises: [
                RoutineExercise(exercise: ex("Hip Rotation"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Electric Bicycle"), durationSeconds: 120),
                RoutineExercise(exercise: ex("Leg Raises"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Incline Treadmill Walk"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Butterfly Stretch"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_14", routineTagline: "A wonderfully well-balanced approach safely strengthening your exact core through any random cycle phase.",
            routineDescription: "This elegant routine alternates between active core engagement and passive stretching to build torso stability without tightening up your hips and back.",
            phase: .unknown, routineType: .mixed
        ),
        Routine(
            id: UUID(), name: "Easy Full Body",
            exercises: [
                RoutineExercise(exercise: ex("Jumping Jacks"), durationSeconds: 180),
                RoutineExercise(exercise: ex("Squats"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Face Pulls"), numberOfSets: 3, reps: 15),
                RoutineExercise(exercise: ex("Elliptical Trainer"), durationSeconds: 900),
                RoutineExercise(exercise: ex("Child Pose"), durationSeconds: 180)
            ],
            thumbnailImageName: "routine_15", routineTagline: "A flawlessly engaging circuit powerfully hitting every specific muscle safely at any exact time in your cycle.",
            routineDescription: "When you don't know what to train, do this. A comprehensive, easy-going full body circuit that touches on all essential movement patterns safely and simply.",
            phase: .unknown, routineType: .mixed
        )
    ]
}
