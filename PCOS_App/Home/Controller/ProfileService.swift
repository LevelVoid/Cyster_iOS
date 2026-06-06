import Foundation
import CoreData
import UIKit

class ProfileService {
    static let shared = ProfileService()

    private let legacyProfileKey = "savedUserProfile"

    private var context: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.viewContext
    }

    private init() {
        migrateLegacyDataIfNeeded()
    }

    func getProfile() -> CDUser? {
        let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print(" Failed to fetch CDUser: \(error)")
            return nil
        }
    }

    func buildUserProfile() -> UserProfile? {
        guard let user = getProfile(),
              let dob = user.dateOfBirth else { return nil }

        let diet     = DietPattern(rawString: user.dietPattern ?? "")
        let activity = ActivityLevel(rawString: user.activityLevel ?? "")
        let phenotype = PCOSPhenotype(rawValue: user.pcosPhenotype ?? "") ?? .unknown

        return UserProfile(
            name:         user.name ?? "",
            dateOfBirth:  dob,
            heightInCm:   user.heightCm,
            weightInKg:   user.weightKg,
            dietPattern:  diet,
            activityLevel: activity,
            phenotype:    phenotype
        )
    }

    func setProfile(name: String, dob: Date, heightCm: Double, weightKg: Double,
                    dietPattern: String, activityLevel: String, pcosPhenotype: String?) {

        let user = getProfile() ?? CDUser(context: context)

        if user.id == nil {
            user.id = UUID()
            user.createdAt = Date()
        }

        user.name = name
        user.dateOfBirth = dob
        user.heightCm = heightCm
        user.weightKg = weightKg
        user.dietPattern = dietPattern
        user.activityLevel = activityLevel
        user.pcosPhenotype = pcosPhenotype

        UserDefaults.standard.set(dob, forKey: "userDOB")
        UserDefaults.standard.set(name, forKey: "userName")

        saveContext()
    }

    func setProfile(to profile: ProfileModel) {
        setProfile(
            name: profile.name,
            dob: profile.dob,
            heightCm: Double(profile.height),
            weightKg: Double(profile.weight),
            dietPattern: profile.dietType,
            activityLevel: profile.workoutType,
            pcosPhenotype: profile.pcosPhenotype
        )
    }

    func updateActivityLevel(_ activityLevel: String) {
        guard let user = getProfile() else {

            return
        }
        user.activityLevel = activityLevel
        saveContext()
    }

    func updateDietPattern(_ dietPattern: String) {
        guard let user = getProfile() else { return }
        user.dietPattern = dietPattern
        saveContext()
    }

    func deleteProfile() {
        if let user = getProfile() {
            context.delete(user)
            saveContext()
            print("🗑️ CDUser deleted")
        }
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
            print("✅ CDUser saved successfully")
        } catch {
            print("❌ CoreData save error: \(error)")
        }
    }

    private func migrateLegacyDataIfNeeded() {
        guard let legacyData = UserDefaults.standard.data(forKey: legacyProfileKey),
              getProfile() == nil else {
            return
        }

        print("🔄 Migrating profile from UserDefaults → Core Data...")

        guard let oldProfile = try? JSONDecoder().decode(ProfileModel.self, from: legacyData) else {
            print("⚠️ Failed to decode legacy ProfileModel")
            return
        }

        setProfile(to: oldProfile)

        UserDefaults.standard.removeObject(forKey: legacyProfileKey)
        print("✅ Profile migration complete")
    }
}
