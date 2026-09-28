import UIKit
import AVFoundation
import Vision
import CoreML

protocol FoodScannerDelegate: AnyObject {
    func didScanFood(_ foodItem: FoodItem)
}

class FoodScannerViewController: UIViewController {

    weak var delegate: FoodScannerDelegate?
    weak var dietDelegate: AddDescribedMealDelegate?

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    private var capturedImage: UIImage?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private var foodClassifier: VNCoreMLModel?

    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 0.996, green: 0.478, blue: 0.588, alpha: 1.0)
        button.setTitle("Capture", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 35
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Position food within the frame"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let scanningFrameView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor(red: 0.996, green: 0.478, blue: 0.588, alpha: 1.0).cgColor
        view.layer.borderWidth = 3
        view.layer.cornerRadius = 12
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var loadingView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        setupMLModel()
        setupCamera()
        setupUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    private func setupMLModel() {
        do {

            let config = MLModelConfiguration()
            let model = try FoodClassifier_1(configuration: config)
            foodClassifier = try VNCoreMLModel(for: model.model)
        } catch {
            print("ERROR: Failed to load ML model: \(error)")
            showError("Could not load food recognition model")
        }
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high

        // Get camera device
        let camera: AVCaptureDevice?
        if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            camera = backCamera
        } else {
            camera = AVCaptureDevice.default(for: .video)
        }

        guard let camera = camera else {
            showError("Camera not available")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)

            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            // For simulator, use video data output instead of photo output
            // AVCapturePhotoOutput queries device capabilities that RocketSim doesn't support
            if isSimulator {
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

                if captureSession.canAddOutput(videoOutput) {
                    captureSession.addOutput(videoOutput)
                    self.videoDataOutput = videoOutput
                }
            } else {
                photoOutput = AVCapturePhotoOutput()

                if captureSession.canAddOutput(photoOutput) {
                    captureSession.addOutput(photoOutput)
                }
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }

        } catch {
            showError("Could not access camera: \(error.localizedDescription)")
        }
    }

    private func setupUI() {
        view.addSubview(scanningFrameView)
        view.addSubview(instructionLabel)
        view.addSubview(captureButton)
        view.addSubview(cancelButton)

        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            scanningFrameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanningFrameView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            scanningFrameView.widthAnchor.constraint(equalToConstant: 280),
            scanningFrameView.heightAnchor.constraint(equalToConstant: 280),

            instructionLabel.bottomAnchor.constraint(equalTo: scanningFrameView.topAnchor, constant: -20),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.widthAnchor.constraint(equalToConstant: 300),
            instructionLabel.heightAnchor.constraint(equalToConstant: 44),

            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 200),
            captureButton.heightAnchor.constraint(equalToConstant: 70),

            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cancelButton.widthAnchor.constraint(equalToConstant: 40),
            cancelButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private var shouldCaptureNextFrame = false

    @objc private func captureButtonTapped() {
        captureButton.isEnabled = false

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if isSimulator {
            // Signal to capture the next video frame
            shouldCaptureNextFrame = true
        } else {
            // Capture photo on real device
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }

    private func classifyFood(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            hideLoadingIndicator()
            showError("Could not process image")
            return
        }

        Task {
            do {
                let prompt = "Provide complete nutritional breakdown."
                let food = try await AIBrain.shared.analyzeFoodImage(imageData: data, prompt: prompt)
                
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.parseAndNavigate(food: food, foodName: food.name)
                }
            } catch {
                print("ERROR: Vision request failed: \(error)")
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showError("Classification failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func parseAndNavigate(food: Food, foodName: String) {
        let ingredients: [Ingredient] = food.ingredients ?? []

        guard !ingredients.isEmpty else {
            showError("No ingredients found in AI response. Please try again.")
            return
        }

        var savedImageName = "dietPlaceholder"
        if let capturedImage = self.capturedImage {
            let fileName = "food_\(UUID().uuidString).jpg"
            if let data = capturedImage.jpegData(compressionQuality: 0.7) {
                let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let foodImagesDir = documentsDir.appendingPathComponent("FoodImages", isDirectory: true)
                try? FileManager.default.createDirectory(at: foodImagesDir, withIntermediateDirectories: true)
                let fileURL = foodImagesDir.appendingPathComponent(fileName)
                try? data.write(to: fileURL)
                savedImageName = fileName
                print("DEBUG: Saved food image relative name: \(fileName)")
            }
        }

        let foodItem = FoodItem(
            id: Int.random(in: 100000...999999),
            name: food.name,
            calories: Int(food.calories),
            image: savedImageName,
            servingSize: food.servingSize,
            unit: "g",
            protein: food.proteinContent,
            carbs: food.carbsContent,
            fat: food.fatsContent,
            fiber: food.fiberContent,
            isSelected: false,
            desc: food.desc,
            ingredients: ingredients,
            confidence: food.confidence
        )

        print("DEBUG: Parsed FoodItem - \(foodItem.name), \(ingredients.count) ingredients")

        showFoodConfirmationAlert(foodItem: foodItem)
    }

    private func showFoodConfirmationAlert(foodItem: FoodItem) {
        let alert = UIAlertController(
            title: "Food Detected",
            message: "Detected: \(foodItem.name)\n\nDo you want to log this item?",
            preferredStyle: .alert
        )

        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            self?.navigateToAdd(foodItem)
        }

        let noAction = UIAlertAction(title: "Retake", style: .cancel) { [weak self] _ in
            self?.captureButton.isEnabled = true
        }

        alert.addAction(noAction)
        alert.addAction(yesAction)

        present(alert, animated: true)
    }

    private func navigateToAdd(_ foodItem: FoodItem) {
        print("DEBUG: Navigating to AddDescribedMealViewController with \(foodItem.name)")

        guard let presentingVC = self.presentingViewController else {
            print("ERROR: No presenting view controller found")
            showError("Navigation error occurred")
            return
        }

        let storyboard = UIStoryboard(name: "Diet", bundle: nil)

        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "AddDescribedMealViewController"
        ) as? AddDescribedMealViewController else {
            print("ERROR: Could not instantiate AddDescribedMealViewController")
            showError("Could not load meal confirmation screen.")
            return
        }

        vc.foodItem = foodItem
        vc.delegate = dietDelegate

        print("DEBUG: AddDescribedMealViewController configured with delegate: \(dietDelegate != nil ? "set" : "nil")")
        print("DEBUG: Presenting VC type: \(type(of: presentingVC))")

        dismiss(animated: true) {
            print("DEBUG: Scanner dismissed, now presenting AddDescribedMealViewController")

            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .pageSheet

            if let sheet = nav.sheetPresentationController {
                if #available(iOS 16.0, *) {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                    sheet.selectedDetentIdentifier = .large
                }
            }

            presentingVC.present(nav, animated: true) {
                print("DEBUG: AddDescribedMealViewController presented successfully")
            }
        }
    }

    private func showLoadingIndicator(message: String = "Processing...") {
        let loadingView = UIView(frame: view.bounds)
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        loadingView.tag = 999

        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = loadingView.center
        activityIndicator.color = .white
        activityIndicator.startAnimating()

        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.frame = CGRect(
            x: 0,
            y: activityIndicator.frame.maxY + 20,
            width: view.bounds.width,
            height: 30
        )

        loadingView.addSubview(activityIndicator)
        loadingView.addSubview(label)
        view.addSubview(loadingView)

        self.loadingView = loadingView
        view.isUserInteractionEnabled = false
    }

    private func hideLoadingIndicator() {
        loadingView?.removeFromSuperview()
        loadingView = nil
        view.viewWithTag(999)?.removeFromSuperview()
        view.isUserInteractionEnabled = true
        captureButton.isEnabled = true
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.captureButton.isEnabled = true
        })

        present(alert, animated: true)
    }
}

// MARK: - Video Data Output Delegate (for Simulator)
extension FoodScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard shouldCaptureNextFrame else { return }
        shouldCaptureNextFrame = false

        // Convert CMSampleBuffer to UIImage
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            DispatchQueue.main.async { [weak self] in
                self?.showError("Could not process captured frame")
                self?.captureButton.isEnabled = true
            }
            return
        }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            DispatchQueue.main.async { [weak self] in
                self?.showError("Could not process captured frame")
                self?.captureButton.isEnabled = true
            }
            return
        }

        let image = UIImage(cgImage: cgImage)
        self.capturedImage = image

        DispatchQueue.main.async { [weak self] in
            print("DEBUG: Frame captured successfully in simulator mode")
            self?.showLoadingIndicator(message: "Identifying food...")
            self?.classifyFood(image: image)
        }
    }
}

extension FoodScannerViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("ERROR: Photo capture failed: \(error)")
            showError("Failed to capture photo")
            captureButton.isEnabled = true
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            showError("Could not process captured image")
            captureButton.isEnabled = true
            return
        }
        self.capturedImage = image
        print("DEBUG: Photo captured successfully")
        showLoadingIndicator(message: "Identifying food...")

        classifyFood(image: image)
    }
}
