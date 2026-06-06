import UIKit

class CycleReportViewController: UIViewController {

    @IBOutlet weak var NextCycleCard: UIView!

    @IBOutlet weak var CycleOverview: UIView!
    @IBOutlet weak var cycleLengthCard: UIView!
    @IBOutlet weak var periodLengthCard: UIView!

    @IBOutlet weak var periodCycleChartView: PeriodCycleChartView!

    @IBOutlet weak var OvulationCard: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Cycle Patterns"
        navigationController?.navigationBar.prefersLargeTitles = true

        NextCycleCard.layer.cornerRadius = 20

        CycleOverview.layer.cornerRadius = 20
        CycleOverview.clipsToBounds = true
        cycleLengthCard.layer.cornerRadius = 20
        periodLengthCard.layer.cornerRadius = 20

        OvulationCard.layer.cornerRadius = 20

        setupPeriodCycleChart()
    }

    private func setupPeriodCycleChart() {
        let cycles = CycleDataStore.shared.loadRecentCycles(count: 6)
        periodCycleChartView.configure(with: cycles)
    }
}
