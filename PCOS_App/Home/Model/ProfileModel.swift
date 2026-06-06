import Foundation

struct ProfileModel: Codable{
    var name: String
    var dob: Date
    var height: Int
    var weight: Int
    var dietType: String
    var workoutType: String
    var pcosPhenotype: String
}
