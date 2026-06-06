import Foundation

struct UserProfile {

    let name: String
    let dateOfBirth: Date
    let heightInCm: Double
    let weightInKg: Double

    let dietPattern: DietPattern
    let activityLevel: ActivityLevel

    let phenotype: PCOSPhenotype

}

enum DietPattern {
    case balanced
    case highSugar
    case irregular
    case unsure

    init(rawString: String) {
        switch rawString {
        case "Balanced Diet":    self = .balanced
        case "Frequent Sugar":   self = .highSugar
        case "Irregular Meals":  self = .irregular
        default:                 self = .unsure
        }
    }
}

enum ActivityLevel {
    case sedentary 
    case lightlyActive 
    case active 
    case veryActive 

    init(rawString: String) {
        switch rawString {
        case "Sedentary Type":           self = .sedentary
        case "Light Movements":          self = .lightlyActive
        case "Regular Movements":        self = .active
        case "Very active on most days": self = .veryActive
        default:                         self = .lightlyActive
        }
    }
}

enum BMICategory {
    case underweight 
    case normal 
    case overweight 
    case obese 
}

enum PCOSPhenotype: String {
    case typeA = "Type A" 
    case typeB   = "Type B"    
    case typeC   = "Type C"    
    case typeD   = "Type D"    
    case unknown = "I Don't Know"

}

extension UserProfile {

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    var bmi: Double {
        let h = heightInCm / 100
        return weightInKg / (h * h)
    }

    var bmiCategory: BMICategory {

        switch bmi {

        case ..<18.5:
            return .underweight

        case 18.5..<25:
            return .normal

        case 25..<30:
            return .overweight

        default:
            return .obese
        }
    }

    fileprivate var bmr: Double {
        (10.0 * weightInKg) + (6.25 * heightInCm) - (5.0 * Double(age)) - 161.0
    }

    fileprivate var tdee: Double {
        let pal: Double
        switch activityLevel {
        case .sedentary:     pal = 1.200
        case .lightlyActive: pal = 1.375
        case .active:        pal = 1.550
        case .veryActive:    pal = 1.725
        }
        return bmr * pal
    }

    fileprivate var isHighIRRisk: Bool {
        (phenotype == .typeA || phenotype == .typeB) &&
        (bmiCategory == .overweight || bmiCategory == .obese)
    }

    fileprivate var workoutReadiness: Double {
        switch activityLevel {
        case .veryActive:    return 1.00
        case .active:        return 0.90
        case .lightlyActive: return 0.70
        case .sedentary:     return 0.55
        }
    }

    fileprivate var dietReadiness: Double {
        switch dietPattern {
        case .balanced, .unsure: return 1.00
        case .highSugar:         return 0.85
        case .irregular:         return 0.80
        }
    }
}

struct DietGoals {

    let dailyCalories: Int

    let proteinGrams: Int
    let carbsGrams: Int
    let fatsGrams: Int

    let startingProteinGrams: Int
    let startingCarbsGrams: Int
    let startingFatsGrams: Int
}

struct WorkoutGoals {

    let workoutMinutesPerDay: Int
    let caloriesBurnedPerDay: Int
    let stepsPerDay: Int

    let startingMinutesPerDay: Int
    let startingStepsPerDay: Int
}

struct SleepGoals {
    let sleepHours: Double
    let bedtimeRecommendation: String
}

struct UserGoals {
    let diet: DietGoals
    let workout: WorkoutGoals
    let sleep: SleepGoals

    let rampUpNote: String
}

struct GoalEngine {
    static func generateGoals(for user: UserProfile) -> UserGoals {
        UserGoals(
            diet:      dietGoals(for: user),
            workout:   workoutGoals(for: user),
            sleep:     sleepGoals(for: user),
            rampUpNote: rampUpNote(for: user)
        )
    }

    private static func rampUpNote(for user: UserProfile) -> String {
        let activityRamped = user.activityLevel == .sedentary || user.activityLevel == .lightlyActive
        let dietRamped     = user.dietPattern == .irregular || user.dietPattern == .highSugar

        if activityRamped && dietRamped {
            return "Your goals are set to a gentler starting level because both your current activity and eating patterns suggest a gradual approach will be more sustainable. Expect your daily targets to increase every 2–3 weeks as your habits build."
        } else if activityRamped {
            return "Your workout targets start a little lower than the ideal to help you build a lasting habit. They'll progress upward as your fitness grows."
        } else if dietRamped {
            return "Your nutrition targets are slightly eased for the first few weeks to give your body time to adjust. They'll move toward the full PCOS-optimised goal as your eating patterns stabilise."
        } else {
            return ""
        }
    }
}

private func dietGoals(for user: UserProfile) -> DietGoals {

    let rawCalories: Double
    switch user.bmiCategory {
    case .underweight: rawCalories = user.tdee + 150
    case .normal:      rawCalories = user.tdee
    case .overweight:  rawCalories = user.tdee - 300
    case .obese:       rawCalories = user.tdee - 500
    }
    let dailyCalories = max(1_200, rawCalories)

    let carbPct: Double
    let proteinPct: Double

    switch (user.phenotype, user.bmiCategory) {

    case (.typeA, .obese), (.typeA, .overweight),
         (.typeB, .obese), (.typeB, .overweight):
        carbPct = 0.25; proteinPct = 0.30

    case (.typeA, .normal), (.typeA, .underweight),
         (.typeB, .normal), (.typeB, .underweight):
        carbPct = 0.35; proteinPct = 0.28

    case (.typeC, .obese), (.typeC, .overweight):
        carbPct = 0.32; proteinPct = 0.27

    case (.typeC, .normal), (.typeC, .underweight):
        carbPct = 0.42; proteinPct = 0.23

    case (.typeD, .obese), (.typeD, .overweight):
        carbPct = 0.35; proteinPct = 0.25

    default:
        carbPct = 0.42; proteinPct = 0.23
    }

    var finalCarbPct    = carbPct
    var finalProteinPct = proteinPct

    switch user.dietPattern {
    case .highSugar:
        finalCarbPct    -= 0.05
        finalProteinPct += 0.03
    case .irregular:
        finalCarbPct    -= 0.02
        finalProteinPct += 0.02
    case .balanced, .unsure:
        break
    }

    finalCarbPct    = min(0.55, max(0.20, finalCarbPct))
    finalProteinPct = min(0.40, max(0.20, finalProteinPct))
    let finalFatPct = max(0.25, 1.0 - finalCarbPct - finalProteinPct)

    let protein = Int(dailyCalories * finalProteinPct / 4.0)
    let carbs   = Int(dailyCalories * finalCarbPct    / 4.0)
    let fats    = Int(dailyCalories * finalFatPct     / 9.0)

    let r = user.dietReadiness
    let startProtein = Int(Double(protein) * r)
    let startCarbs   = Int(Double(carbs)   * r)
    let startFats    = Int(Double(fats)    * r)

    return DietGoals(
        dailyCalories:        Int(dailyCalories),
        proteinGrams:         protein,
        carbsGrams:           carbs,
        fatsGrams:            fats,
        startingProteinGrams: startProtein,
        startingCarbsGrams:   startCarbs,
        startingFatsGrams:    startFats
    )
}

private func workoutGoals(for user: UserProfile) -> WorkoutGoals {

    var minutes: Int
    var steps: Int

    switch user.activityLevel {
    case .sedentary:

        minutes = 20; steps = 4_000

    case .lightlyActive:

        minutes = 30; steps = 6_000

    case .active:

        minutes = 40; steps = 8_000

    case .veryActive:

        minutes = 50; steps = 10_000
    }

    switch user.bmiCategory {
    case .overweight:
        minutes += 10
        steps   += 2_000
    case .obese:
        steps   = max(steps, 6_000)
        minutes = min(minutes + 10, 45)
    case .underweight:
        minutes = min(minutes, 30)
        steps   = min(steps, 6_000)
    case .normal:
        break
    }

    switch user.phenotype {
    case .typeA:
        minutes  = min(minutes + 5, 60)     
        steps   += 1_000
    case .typeB:
        minutes  = min(minutes, 40)          
        steps    = min(steps, 8_000)
    case .typeC, .typeD, .unknown:
        break
    }

    let met: Double
    switch user.activityLevel {
    case .sedentary, .lightlyActive: met = 3.5
    case .active:                    met = 5.0
    case .veryActive:                met = 7.0
    }
    let caloriesBurned = Int(met * user.weightInKg * (Double(minutes) / 60.0))

    let w = user.workoutReadiness
    let startMinutes = max(10, Int(Double(minutes) * w))  
    let startSteps   = max(2_000, Int(Double(steps) * w)) 

    return WorkoutGoals(
        workoutMinutesPerDay: minutes,
        caloriesBurnedPerDay: caloriesBurned,
        stepsPerDay:          steps,
        startingMinutesPerDay: startMinutes,
        startingStepsPerDay:   startSteps
    )
}

private func sleepGoals(for user: UserProfile) -> SleepGoals {

    var sleepHours: Double
    var recommendation: String

    switch user.phenotype {
    case .typeA:
        sleepHours    = 8.5
        recommendation = "Prioritise 8–9 hours. Deep sleep is when cortisol clears and insulin sensitivity resets — both critical for Type A. Keep a strict wake time even on weekends."

    case .typeB:
        sleepHours    = 8.0
        recommendation = "Consistent bed and wake times stabilise your adrenal rhythm. Irregular sleep directly raises adrenal androgens in Type B — treat sleep timing as part of your treatment."

    case .typeC:
        sleepHours    = 7.5
        recommendation = "Aim for 7–8 hours with a consistent schedule. Avoid late-night eating, as it disrupts the insulin-cortisol rhythm overnight."

    case .typeD:
        sleepHours    = 7.5
        recommendation = "Focus on stress reduction and a steady bedtime. Chronic stress worsens anovulation even without elevated androgens — quality sleep is a key regulator."

    case .unknown:
        sleepHours    = 8.0
        recommendation = "Aim for 7.5–8.5 hours with consistent timing. Irregular sleep disrupts reproductive hormones regardless of PCOS type."
    }

    if user.age < 20 {
        sleepHours    = max(sleepHours, 9.0)
        recommendation += " As a teenager, aim for 9–10 hours — your hormonal system is still maturing and needs the extra recovery."
    }

    if user.bmiCategory == .obese {
        recommendation += " If you snore or wake unrefreshed, discuss sleep apnoea screening with your doctor — it's common in PCOS and worsens insulin resistance."
    }

    return SleepGoals(
        sleepHours:            sleepHours,
        bedtimeRecommendation: recommendation
    )
}
