import UIKit

class ProteinViewController: UIViewController {

    @IBOutlet weak var proteinChartContainer: ProteinIntakeChartView!

    @IBOutlet weak var View2_1: UIView!
    @IBOutlet weak var View2: UIView!
    @IBOutlet weak var View1: UIView!

    var recommendation: Recommendation?

    @IBAction func proteinImportanceLinkTapped(_ sender: UIButton) {
        guard let url = URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC10904368/") else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        if let rec = recommendation {print("Workout recommendation: \(rec.title)")}

        View1.layer.cornerRadius = 20
        View1.clipsToBounds = true

        View2.layer.cornerRadius = 20
        View2.clipsToBounds = true

        View2_1.layer.cornerRadius = 20
        View2_1.clipsToBounds = true

        setupProteinChart()
    }
    private func setupProteinChart() {

        proteinChartContainer.subviews.forEach { $0.removeFromSuperview() }

        let chartCard = ProteinIntakeChartCardView()
        chartCard.translatesAutoresizingMaskIntoConstraints = false
        proteinChartContainer.addSubview(chartCard)

        NSLayoutConstraint.activate([
            chartCard.topAnchor.constraint(equalTo: proteinChartContainer.topAnchor),
            chartCard.leadingAnchor.constraint(equalTo: proteinChartContainer.leadingAnchor),
            chartCard.trailingAnchor.constraint(equalTo: proteinChartContainer.trailingAnchor),
            chartCard.bottomAnchor.constraint(equalTo: proteinChartContainer.bottomAnchor)
        ])

        let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var data: [ProteinIntakeChartView.DataPoint] = []

        let lastWeek: [CGFloat] = [65, 72, 78, 70, 68, 75, 80]
        for (i, day) in weekdays.enumerated() {
            data.append(ProteinIntakeChartView.DataPoint(day: day, value: lastWeek[i], type: .lastWeek))
        }

        let thisWeek: [CGFloat] = [45, 50, 42, 55, 48, 52, 58]
        for (i, day) in weekdays.enumerated() {
            data.append(ProteinIntakeChartView.DataPoint(day: day, value: thisWeek[i], type: .thisWeek))
        }

        chartCard.configure(with: data)
    }

}
