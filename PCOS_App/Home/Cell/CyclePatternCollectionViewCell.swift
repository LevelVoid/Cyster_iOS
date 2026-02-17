//
//  CyclePatternCollectionViewCell.swift
//  PCOS_App
//
//  Created by SDC-USER on 10/01/26.
//

import UIKit

class CyclePatternCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cyclePatternView: UIView!
    
    @IBOutlet weak var avgCycleLength: UIView!
    
    @IBOutlet weak var avgPeriodLength: UIView!
    @IBOutlet weak var viewTooTiredToRemove: UIView!
    @IBOutlet weak var periodCycleChartView: PeriodCycleChartView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        cyclePatternView.layer.cornerRadius = 20
        viewTooTiredToRemove.layer.cornerRadius = 20
        avgCycleLength.layer.cornerRadius = 10
        avgPeriodLength.layer.cornerRadius = 10
        
        setupPeriodCycleChart()
    }
    
    private func setupPeriodCycleChart() {
        let cycles = CycleDataStore.shared.loadRecentCycles(count: 6)
        periodCycleChartView.configure(with: cycles)
    }
    
}
