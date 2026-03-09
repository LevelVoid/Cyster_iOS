//
// CyclePatternCollectionViewCell.swift
//  PCOS_App
//
//  Created by SDC-USER on 10/01/26.
//

import UIKit

class CyclePatternCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cyclePatternView: UIView!
    @IBOutlet weak var CycleLengthView: UIView!
    @IBOutlet weak var PeriodLengthView: UIView!
    @IBOutlet weak var viewTooTiredToRemove: UIView!
    @IBOutlet weak var periodCycleChartView: PeriodCycleChartView!
    
    // Labels to display the calculated averages
    @IBOutlet weak var avgCycleLengthLabel: UILabel!
    @IBOutlet weak var avgPeriodLengthLabel: UILabel!

    // Programmatic AI elements
    private var observationLabel: UILabel!
    private var loadingIndicator: UIActivityIndicatorView!
    
    private var currentInsightFetchTask: Task<Void, Never>?
    private var cachedInsight: String?
    private var lastCycleCount: Int = -1
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure multiline label wraps correctly in a self-sizing environment
        if observationLabel != nil {
            observationLabel.preferredMaxLayoutWidth = observationLabel.frame.width
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        cyclePatternView.layer.cornerRadius = 20
        viewTooTiredToRemove.layer.cornerRadius = 20
        CycleLengthView.layer.cornerRadius = 10
        PeriodLengthView.layer.cornerRadius = 10
        
        // Disable translatesAutoresizingMaskIntoConstraints for dynamic sizing
        cyclePatternView.translatesAutoresizingMaskIntoConstraints = false
        viewTooTiredToRemove.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup AI Observation Label below the chart
        observationLabel = UILabel()
        observationLabel.translatesAutoresizingMaskIntoConstraints = false
        observationLabel.font = .systemFont(ofSize: 14) // Slightly larger than caption2 for better readability
        observationLabel.textColor = .black
        observationLabel.numberOfLines = 0
        observationLabel.textAlignment = .left
        
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        
        viewTooTiredToRemove.addSubview(observationLabel)
        viewTooTiredToRemove.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            cyclePatternView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cyclePatternView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cyclePatternView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cyclePatternView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            viewTooTiredToRemove.topAnchor.constraint(equalTo: cyclePatternView.topAnchor),
            viewTooTiredToRemove.leadingAnchor.constraint(equalTo: cyclePatternView.leadingAnchor),
            viewTooTiredToRemove.trailingAnchor.constraint(equalTo: cyclePatternView.trailingAnchor),
            viewTooTiredToRemove.bottomAnchor.constraint(equalTo: cyclePatternView.bottomAnchor),
            
            observationLabel.topAnchor.constraint(equalTo: periodCycleChartView.bottomAnchor, constant: 16),
            observationLabel.leadingAnchor.constraint(equalTo: viewTooTiredToRemove.leadingAnchor, constant: 16),
            observationLabel.trailingAnchor.constraint(equalTo: viewTooTiredToRemove.trailingAnchor, constant: -16),
            observationLabel.bottomAnchor.constraint(equalTo: viewTooTiredToRemove.bottomAnchor, constant: -20),
            
            loadingIndicator.centerYAnchor.constraint(equalTo: observationLabel.centerYAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: viewTooTiredToRemove.centerXAnchor)
        ])
    }

    /// Call from cellForItemAt to refresh chart data on every display
    func refreshChart() {
        let cycles = CycleDataStore.shared.previousCycles(count: 6)
        let prediction = CycleDataStore.shared.nextPeriodPrediction
        
        // Update chart
        periodCycleChartView.configure(with: cycles)
        
        // Use pre-calculated averages from prediction engine
        if let avgCycle = prediction.averageCycleLength {
            avgCycleLengthLabel?.text = "\(avgCycle)"
        } else {
            avgCycleLengthLabel?.text = "—"
        }
        
        if let avgPeriod = prediction.averagePeriodLength {
            avgPeriodLengthLabel?.text = "\(avgPeriod)"
        } else {
            avgPeriodLengthLabel?.text = "—"
        }
        
        // Fetch AI Insight
        let cycleCount = cycles.count
        if let cached = cachedInsight, lastCycleCount == cycleCount {
            observationLabel.text = cached
            observationLabel.textColor = .black
            observationLabel.textAlignment = .left
            observationLabel.font = .systemFont(ofSize: 14)
            loadingIndicator.stopAnimating()
            return
        }
        
        observationLabel.text = "Generating your insights..."
        observationLabel.textColor = .secondaryLabel
        observationLabel.textAlignment = .center
        observationLabel.font = .systemFont(ofSize: 14)
        loadingIndicator.startAnimating()
        
        currentInsightFetchTask?.cancel()
        currentInsightFetchTask = Task {
            do {
                let insight = try await CycleObservationsModel.shared.fetchCycleInsight(cycles: cycles)
                guard !Task.isCancelled else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.loadingIndicator.stopAnimating()
                    self?.observationLabel.text = insight
                    self?.observationLabel.textColor = .black
                    self?.observationLabel.textAlignment = .left
                    self?.observationLabel.font = .systemFont(ofSize: 14)
                    self?.cachedInsight = insight
                    self?.lastCycleCount = cycleCount
                    
                    // Trigger cell self-sizing update with new content
                    if let cv = self?.superview as? UICollectionView {
                        cv.performBatchUpdates(nil, completion: nil)
                    } else if let cv = self?.superview?.superview as? UICollectionView {
                        cv.performBatchUpdates(nil, completion: nil)
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.loadingIndicator.stopAnimating()
                    self?.observationLabel.text = "Unable to generate cycle insights at this time."
                    self?.observationLabel.textColor = .secondaryLabel
                    self?.observationLabel.textAlignment = .center
                    self?.observationLabel.font = .systemFont(ofSize: 14)
                    
                    if let cv = self?.superview as? UICollectionView {
                        cv.performBatchUpdates(nil, completion: nil)
                    } else if let cv = self?.superview?.superview as? UICollectionView {
                        cv.performBatchUpdates(nil, completion: nil)
                    }
                }
            }
        }
    }
}
