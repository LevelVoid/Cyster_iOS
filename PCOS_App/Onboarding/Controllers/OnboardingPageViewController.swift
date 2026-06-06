import UIKit

class OnboardingPageViewController: UIPageViewController {

    var pages: [UIViewController] = []
    var pageControlDelegate: ((Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self

        let page1 = createPage(
            title: "Understand Your Cycle",
            subtitle: "Track patterns, symptoms, and wellness in one calm space.",
            imageName: "heart.text.square.fill"
        )
        let page2 = createPage(
            title: "Build Healthier Habits",
            subtitle: "Small daily routines that support hormonal balance.",
            imageName: "leaf.fill"
        )
        let page3 = createPage(
            title: "Insights That Grow With You",
            subtitle: "Discover trends and personalized wellness guidance over time.",
            imageName: "chart.line.uptrend.xyaxis"
        )

        pages = [page1, page2, page3]
        if let firstPage = pages.first {
            setViewControllers([firstPage], direction: .forward, animated: true, completion: nil)
        }
    }

    private func createPage(title: String, subtitle: String, imageName: String) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor(red: 0.98, green: 0.94, blue: 0.93, alpha: 1.0) 

        let imageView = UIImageView(image: UIImage(systemName: imageName))
        imageView.tintColor = UIColor(red: 0.9, green: 0.4, blue: 0.5, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "Illustration of \(title)"

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .darkText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        vc.view.addSubview(imageView)
        vc.view.addSubview(titleLabel)
        vc.view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor, constant: -80),
            imageView.widthAnchor.constraint(equalToConstant: 120),
            imageView.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -32),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -32)
        ])

        return vc
    }
}

extension OnboardingPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index > 0 else { return nil }
        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index < (pages.count - 1) else { return nil }
        return pages[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let visibleVC = viewControllers?.first, let index = pages.firstIndex(of: visibleVC) {
            pageControlDelegate?(index)
        }
    }
}
