import UIKit

class CompletionCircleView: UIView {

    private var progressLayer = CAShapeLayer()
    private var trackLayer = CAShapeLayer()

    var lineWidth: CGFloat = 10 {
        didSet {
            trackLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth
            setNeedsLayout()
        }
    }

    var progressColor = UIColor(hex: "fe7a96") {
        didSet {
            progressLayer.strokeColor = progressColor.withAlphaComponent(0.8).cgColor
        }
    }

    var trackColor = UIColor(hex: "e5e5e5"){
        didSet{
            trackLayer.strokeColor = trackColor.cgColor
        }
    }

    override init(frame: CGRect) {
            super.init(frame: frame)
            setupLayers()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupLayers()
        }

    private func setupLayers() {
            trackLayer.fillColor = UIColor.clear.cgColor
            trackLayer.lineCap = .round
            trackLayer.strokeEnd = 1.0
            layer.addSublayer(trackLayer)

            progressLayer.fillColor = UIColor.clear.cgColor
            progressLayer.lineCap = .round
            progressLayer.strokeEnd = 0
            layer.addSublayer(progressLayer)

            trackLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth

        }

    override func layoutSubviews() {
            super.layoutSubviews()

            let center = CGPoint(x: bounds.midX, y: bounds.midY)

            let radius = (min(bounds.width, bounds.height) - lineWidth - 16) / 2

            let circularPath = UIBezierPath(arcCenter: center,
                                            radius: radius,
                                            startAngle: -CGFloat.pi / 2,
                                            endAngle: 2 * CGFloat.pi - CGFloat.pi / 2,
                                            clockwise: true)

            trackLayer.path = circularPath.cgPath
            trackLayer.strokeColor = trackColor.cgColor
            trackLayer.lineWidth = lineWidth 

            progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = progressColor.withAlphaComponent(0.8).cgColor
            progressLayer.lineWidth = lineWidth 
        }

    func setProgress(to value: Float, animated: Bool = true) {
                let clampedValue = max(0, min(1, value))

                if animated {
                let animation = CABasicAnimation(keyPath: "strokeEnd")
                animation.fromValue = progressLayer.strokeEnd
                animation.toValue = clampedValue
                animation.duration = 0.5
                animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                progressLayer.strokeEnd = CGFloat(clampedValue)
                progressLayer.add(animation, forKey: "animateProgress")
            } else {
                progressLayer.strokeEnd = CGFloat(clampedValue)
            }
        }

        func configure(progress: Float, thickness: CGFloat, color: UIColor? = nil) {
            self.lineWidth = thickness
            if let color = color {
                self.progressColor = color
            }
            self.setProgress(to: progress)
        }

}
