import Foundation
import TipKit

@available(iOS 17.0, *)
struct LogPeriodTip: Tip {
    var title: Text { Text("Log your cycle") }
    var message: Text? { Text("Track your period to get personalized insights.") }
    var image: Image? { Image(systemName: "calendar.badge.plus") }
}

@available(iOS 17.0, *)
struct SymptomTrackerTip: Tip {
    var title: Text { Text("Log symptoms daily") }
    var message: Text? { Text("Patterns become clearer over time.") }
    var image: Image? { Image(systemName: "list.clipboard") }
}

@available(iOS 17.0, *)
struct ChatbotTip: Tip {
    var title: Text { Text("Wellness Assistant") }
    var message: Text? { Text("Ask questions and get instant PCOS guidance.") }
    var image: Image? { Image(systemName: "message.badge.filled.fill") }
}

@available(iOS 17.0, *)
struct AddMealTip: Tip {
    var title: Text { Text("Track Nutrition") }
    var message: Text? { Text("Log your meals to hit your daily goals.") }
    var image: Image? { Image(systemName: "fork.knife") }
}

@available(iOS 17.0, *)
struct StartWorkoutTip: Tip {
    var title: Text { Text("Stay Active") }
    var message: Text? { Text("Start a workout tailored to your cycle phase.") }
    var image: Image? { Image(systemName: "figure.run") }
}

@available(iOS 17.0, *)
struct CycleTrendsTip: Tip {
    var title: Text { Text("Cycle Trends") }
    var message: Text? { Text("Monitor how your cycle lengths vary over time.") }
    var image: Image? { Image(systemName: "chart.bar.xaxis") }
}

@available(iOS 17.0, *)
struct SymptomPatternTip: Tip {
    var title: Text { Text("Symptom Patterns") }
    var message: Text? { Text("Discover when specific symptoms typically occur.") }
    var image: Image? { Image(systemName: "waveform.path.ecg") }
}

@available(iOS 17.0, *)
struct CalendarTip: Tip {
    var title: Text { Text("Your Cycle History") }
    var message: Text? { Text("View previous cycles, symptoms, and logged days at a glance.") }
    var image: Image? { Image(systemName: "calendar") }
}

@available(iOS 17.0, *)
struct DailySymptomLogTip: Tip {
    var title: Text { Text("Log Today's Symptoms") }
    var message: Text? { Text("Tap here to record how you feel — even a quick note helps build your health picture.") }
    var image: Image? { Image(systemName: "plus.circle.fill") }
}
