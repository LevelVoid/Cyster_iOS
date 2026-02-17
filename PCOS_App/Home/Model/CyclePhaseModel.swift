//
//  CyclePhaseModel.swift
//  PCOS_App
//
//  Created by Abhinaya Rajarajan on 17/02/26.
//

import Foundation
import UIKit
struct CycleData: Codable  {
    let id: UUID
    let month: String
    let startDate: Date
    let days: [CycleDay]
}

struct CycleDay : Codable {
    let dayIndex: Int
    let phase: Phase
    let symptoms: [SymptomItem]
}
enum Phase : Codable {
    case menstrual
    case follicular
    case ovulation
    case luteal
    case unknown
}
extension CycleData {

    var cycleLength: Int {
        days.count
    }

    var periodLength: Int {
        days.filter { $0.phase == .menstrual }.count
    }
}
extension Phase {

    var backgroundColor: UIColor {
        switch self {
        case .menstrual:
            return UIColor.systemPink.withAlphaComponent(0.35)
        case .ovulation:
            return UIColor.systemYellow.withAlphaComponent(0.45)
        case .luteal:
            return UIColor.systemGray5
        case .unknown:
            return UIColor.systemGray4
        default:
            return .clear
        }
    }

    var icon: UIImage? {
        switch self {
        case .ovulation:
            return UIImage(systemName: "sparkles")
        default:
            return nil
        }
    }

    var iconTint: UIColor {
        switch self {
        case .ovulation:
            return UIColor.systemOrange
        default:
            return .clear
        }
    }
}


