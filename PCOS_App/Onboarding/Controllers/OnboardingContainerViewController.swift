import UIKit

class OnboardingContainerViewController: UIViewController {
    
    private let pageControl = UIPageControl()
    private let getStartedButton = UIButton(type: .system)
    private var pageViewController: OnboardingPageViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.98, green: 0.94, blue: 0.93, alpha: 1.0)
        
        setupPageViewController()
        setupBottomControls()
    }
    
    private func setupPageViewController() {
        pageViewController = OnboardingPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        pageViewController.pageControlDelegate = { [weak self] index in
            self?.pageControl.currentPage = index
            self?.animateButtonVisibility(for: index)
        }
    }
    
    private func setupBottomControls() {
        pageControl.numberOfPages = 3
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.currentPageIndicatorTintColor = UIColor(red: 0.9, green: 0.4, blue: 0.5, alpha: 1.0)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)
        
        getStartedButton.setTitle("Get Started", for: .normal)
        getStartedButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        getStartedButton.backgroundColor = UIColor(red: 0.9, green: 0.4, blue: 0.5, alpha: 1.0)
        getStartedButton.setTitleColor(.white, for: .normal)
        getStartedButton.layer.cornerRadius = 28
        getStartedButton.alpha = 0 // Hidden initially
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false
        getStartedButton.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
        view.addSubview(getStartedButton)
        
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            getStartedButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            getStartedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            getStartedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            getStartedButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func animateButtonVisibility(for index: Int) {
        let isLastPage = index == 2
        UIView.animate(withDuration: 0.3) {
            self.getStartedButton.alpha = isLastPage ? 1.0 : 0.0
            self.pageControl.alpha = isLastPage ? 0.0 : 1.0
        }
        if isLastPage {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    @objc private func getStartedTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        OnboardingManager.shared.hasSeenOnboarding = true
        
        // Transition to Original Onboarding Questions
        let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
        if let onboardingVC = onboardingStoryboard.instantiateInitialViewController() {
            if let window = self.view.window {
                window.rootViewController = onboardingVC
                UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil, completion: nil)
            }
        }
    }
}
