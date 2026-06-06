import UIKit
import UserNotifications

struct ReminderPreferences {
    static let mealEnabledKey = "mealReminderEnabled"
    static let mealFrequencyKey = "mealReminderFrequency"
    static let mealTimesKey = "mealReminderTimes"

    static let workoutEnabledKey = "workoutReminderEnabled"
    static let workoutTimeKey = "workoutReminderTime"

    static let sleepEnabledKey = "sleepReminderEnabled"
    static let sleepTimeKey = "sleepReminderTime"
}

class RemindersViewController: UITableViewController {

    private var mealEnabled: Bool = false
    private var mealFrequency: Int = 3
    private var mealTimes: [Date] = []

    private var workoutEnabled: Bool = false
    private var workoutTime: Date = Date()

    private var sleepEnabled: Bool = false
    private var sleepTime: Date = Date()

    private let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Reminders"
        view.backgroundColor = UIColor(hex: "FCEEED")

        loadPreferences()
        requestNotificationPermission()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        savePreferences()
        scheduleNotifications()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()

        center.removeAllPendingNotificationRequests()

        if mealEnabled {
            for (index, time) in mealTimes.enumerated() {
                scheduleDailyNotification(time: time, title: "Time to Log Your Meal!", body: "Staying consistent with your tracking helps manage PCOS effectively.", identifier: "meal_reminder_\(index)")
            }
        }

        if workoutEnabled {
            scheduleDailyNotification(time: workoutTime, title: "Workout Time!", body: "Get moving! Remember, consistency is key to balancing hormones.", identifier: "workout_reminder")
        }

        if sleepEnabled {
            scheduleDailyNotification(time: sleepTime, title: "Wind Down for Sleep", body: "A good night's rest is critical for your recovery and hormone health.", identifier: "sleep_reminder")
        }
    }

    private func scheduleDailyNotification(time: Date, title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func loadPreferences() {
        mealEnabled = defaults.bool(forKey: ReminderPreferences.mealEnabledKey)
        mealFrequency = defaults.integer(forKey: ReminderPreferences.mealFrequencyKey)
        if mealFrequency == 0 { mealFrequency = 3 }

        if let storedDates = defaults.array(forKey: ReminderPreferences.mealTimesKey) as? [Date] {
            mealTimes = storedDates
        } else {

            mealTimes = [
                makeDate(hour: 8, min: 0),
                makeDate(hour: 13, min: 0),
                makeDate(hour: 19, min: 0)
            ]
        }

        adjustMealTimesArray()

        workoutEnabled = defaults.bool(forKey: ReminderPreferences.workoutEnabledKey)
        workoutTime = defaults.object(forKey: ReminderPreferences.workoutTimeKey) as? Date ?? makeDate(hour: 17, min: 30) 

        sleepEnabled = defaults.bool(forKey: ReminderPreferences.sleepEnabledKey)
        sleepTime = defaults.object(forKey: ReminderPreferences.sleepTimeKey) as? Date ?? makeDate(hour: 22, min: 0) 
    }

    private func savePreferences() {
        defaults.set(mealEnabled, forKey: ReminderPreferences.mealEnabledKey)
        defaults.set(mealFrequency, forKey: ReminderPreferences.mealFrequencyKey)
        defaults.set(mealTimes, forKey: ReminderPreferences.mealTimesKey)

        defaults.set(workoutEnabled, forKey: ReminderPreferences.workoutEnabledKey)
        defaults.set(workoutTime, forKey: ReminderPreferences.workoutTimeKey)

        defaults.set(sleepEnabled, forKey: ReminderPreferences.sleepEnabledKey)
        defaults.set(sleepTime, forKey: ReminderPreferences.sleepTimeKey)
    }

    private func makeDate(hour: Int, min: Int) -> Date {
        var comp = DateComponents()
        comp.hour = hour
        comp.minute = min
        return Calendar.current.date(from: comp) ?? Date()
    }

    private func adjustMealTimesArray() {

        while mealTimes.count < mealFrequency {
            mealTimes.append(makeDate(hour: 12, min: 0))
        }

        while mealTimes.count > mealFrequency {
            mealTimes.removeLast()
        }
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }

        header.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        header.textLabel?.textColor = .secondaryLabel
        if let text = header.textLabel?.text {
            header.textLabel?.text = text.uppercased()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return "Meal Logging" }
        if section == 1 { return "Workout" }
        if section == 2 { return "Sleep Logging" }
        return nil
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 { return "Select how many meals you want to be reminded to log each day." }
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if !mealEnabled { return 1 }
            return 2 + mealFrequency 
        }
        if section == 1 {
            return workoutEnabled ? 2 : 1 
        }
        if section == 2 {
            return sleepEnabled ? 2 : 1 
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none

        if indexPath.section == 0 {
            if indexPath.row == 0 {

                cell.textLabel?.text = "Enable Reminders"
                let sw = UISwitch()
                sw.isOn = mealEnabled
                sw.addTarget(self, action: #selector(mealToggleChanged(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else if indexPath.row == 1 {

                cell.textLabel?.text = "Meals per day"
                cell.detailTextLabel?.text = "\(mealFrequency)"

                let stepper = UIStepper()
                stepper.minimumValue = 1
                stepper.maximumValue = 6
                stepper.value = Double(mealFrequency)
                stepper.addTarget(self, action: #selector(mealFrequencyChanged(_:)), for: .valueChanged)
                cell.accessoryView = stepper
            } else {

                let timeIndex = indexPath.row - 2
                cell.textLabel?.text = "Meal \(timeIndex + 1)"

                let dp = UIDatePicker()
                dp.datePickerMode = .time
                dp.preferredDatePickerStyle = .compact
                dp.date = mealTimes[timeIndex]
                dp.tag = timeIndex
                dp.addTarget(self, action: #selector(mealTimeChanged(_:)), for: .valueChanged)
                cell.accessoryView = dp
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Enable Reminder"
                let sw = UISwitch()
                sw.isOn = workoutEnabled
                sw.addTarget(self, action: #selector(workoutToggleChanged(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else {
                cell.textLabel?.text = "Time"
                let dp = UIDatePicker()
                dp.datePickerMode = .time
                dp.preferredDatePickerStyle = .compact
                dp.date = workoutTime
                dp.addTarget(self, action: #selector(workoutTimeChanged(_:)), for: .valueChanged)
                cell.accessoryView = dp
            }
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Enable Reminder"
                let sw = UISwitch()
                sw.isOn = sleepEnabled
                sw.addTarget(self, action: #selector(sleepToggleChanged(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else {
                cell.textLabel?.text = "Time"
                let dp = UIDatePicker()
                dp.datePickerMode = .time
                dp.preferredDatePickerStyle = .compact
                dp.date = sleepTime
                dp.addTarget(self, action: #selector(sleepTimeChanged(_:)), for: .valueChanged)
                cell.accessoryView = dp
            }
        }

        return cell
    }

    @objc private func mealToggleChanged(_ sender: UISwitch) {
        mealEnabled = sender.isOn
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }

    @objc private func mealFrequencyChanged(_ sender: UIStepper) {
        mealFrequency = Int(sender.value)
        adjustMealTimesArray()
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }

    @objc private func mealTimeChanged(_ sender: UIDatePicker) {
        let index = sender.tag
        if index < mealTimes.count {
            mealTimes[index] = sender.date
        }
    }

    @objc private func workoutToggleChanged(_ sender: UISwitch) {
        workoutEnabled = sender.isOn
        tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
    }

    @objc private func workoutTimeChanged(_ sender: UIDatePicker) {
        workoutTime = sender.date
    }

    @objc private func sleepToggleChanged(_ sender: UISwitch) {
        sleepEnabled = sender.isOn
        tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
    }

    @objc private func sleepTimeChanged(_ sender: UIDatePicker) {
        sleepTime = sender.date
    }
}
