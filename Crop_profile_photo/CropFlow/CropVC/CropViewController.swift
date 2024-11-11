//
//  CropViewController.swift
//  Crop_profile_photo
//
//  Created by Maxnxi on 11/09/24
//

import Combine
import UIKit
import EasyPeasy


public final class CropViewController: UIViewController {
	
	// MARK: - Constants
	
	private enum Constants {
		static let maximumZoomScale:		CGFloat = 10
		static let circleBorderWidth:		CGFloat = 1
		static let overlayViewColorAlpha:	Float	= 0.8
		static let horizontalInset:			Double	= 32
		
		static let backGroundColor:		UIColor = .black
		static let overlayViewColor:	UIColor = .black
		static let navigationBarColor:	UIColor = .black
		
		// Circle
		// shows the area wich would be seen
		static let circleBorderColor:	UIColor = .white
		
		// The circle center is transparent
		static let circleFillColor:		UIColor = .clear
		
		static let cancelButtonImage:	UIImage = UIImage(systemName: "xmark.circle.fill")!
		static let doneButtonImage:		UIImage = UIImage(systemName: "v.circle.fill")!
		
		static let isUseCompletions:	Bool = true
	}
	
	
	
	// MARK: - Properties
	
	private let sourceImage:			UIImage
	private let cropViewFrameSize:		CGSize
	private let cropOutputImageSize:	CGSize
	
	// If you want you can use complitions
	public var onCancelButtonCompletion:	(() -> Void)?
	public var onDoneButtonCompletion:		((UIImage?) -> Void)?
	
	public var onCancelButtonSubject	= PassthroughSubject<Void, Never>()
	public var onDoneButtonSubject		= PassthroughSubject<UIImage?, Never>()
	
	// MARK: - UI elements
	
	private lazy var cropFrame: CGRect			= makeCropFrame()
	private lazy var scrollView: UIScrollView	= makeScrollView()
	private lazy var imageView: UIImageView		= makeImageView()
	private lazy var circleOverlayView			= TouchThruView()
	private lazy var cancelButton: UIButton		= makeButton(type: .cancel)
	private lazy var doneButton: UIButton		= makeButton(type: .done)
	private lazy var bottomBar: UIView			= UIView()
	
	private var hasInitialLayout = false
	
	private var cancellables = Set<AnyCancellable>()
	
	
	// MARK: - Initialization
	
	public init(
		image: UIImage,
		cropViewFrameSize: CGSize? = nil,
		cropOutputImageSize: CGSize = CGSize(
			width: 1080,
			height: 1080
		)
	) {
		self.sourceImage = image
		if let cropViewFrameSize {
			self.cropViewFrameSize = cropViewFrameSize
		} else {
			let width = UIScreen.main.bounds.width - Constants.horizontalInset
			let size = CGSize(
				width: width,
				height: width
			)
			self.cropViewFrameSize = size
		}
		
		self.cropOutputImageSize = cropOutputImageSize
		super.init(
			nibName: nil,
			bundle: nil
		)
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override public var preferredStatusBarStyle: UIStatusBarStyle {
		.lightContent
	}
	
	// MARK: - Lifecycle
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		setupView()
		setupBindings()
		setupNavigationBar()
	}
	
	public override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		setupOverlayMask()
		
		// Only set up initial zoom once
		if !hasInitialLayout {
			setupInitialZoom()
			setContentInset()
			hasInitialLayout = true
		}
	}
	
	
	// MARK: - Crop Image
	
	private func cropImage(sizeToCrop: CGSize) -> UIImage? {
		
		guard let correctImage = sourceImage.fixImageOrientation() else {
			debugPrint("ERROR: Failed to fix orientation of source image")
			return nil
		}
		
		guard let sourceImageCG = correctImage.cgImage else {
			debugPrint("ERROR: Could not get CGImage from source image")
			return nil
		}
		
		// Debug prints for initial state
		debugPrint("=== Cropping Debug Info ===")
		debugPrint("Source image size:", sourceImage.size)
		debugPrint("correctImage image size:", correctImage.size)
		
		debugPrint("Image view bounds:", imageView.bounds)
		debugPrint("Scroll view content offset:", scrollView.contentOffset)
		debugPrint("Scroll view content inset:", scrollView.contentInset)
		debugPrint("Scroll view zoom scale:", scrollView.zoomScale)
		debugPrint("Crop frame:", cropFrame)
		
		// 1. Calculate the scale between the original image and how it's displayed in the imageView
		let imageScale = correctImage.size.width / imageView.bounds.width
		
		// 2. Calculate visible portion in scroll view coordinates
		// Account for content inset when calculating the offset
		let adjustedX = (scrollView.contentOffset.x + scrollView.contentInset.left) / scrollView.zoomScale
		let adjustedY = (scrollView.contentOffset.y + scrollView.contentInset.top) / scrollView.zoomScale
		
		let visibleRect = CGRect(
			x: adjustedX,
			y: adjustedY,
			width: cropFrame.width / scrollView.zoomScale,
			height: cropFrame.height / scrollView.zoomScale
		)
		
		debugPrint("=== Coordinate Transformations ===")
		debugPrint("Adjusted offset (x, y):", adjustedX, adjustedY)
		debugPrint("Visible rect in scroll view space:", visibleRect)
		debugPrint("Image scale:", imageScale)
		
		// 3. Convert to source image coordinates
		let sourceRect = CGRect(
			x: visibleRect.origin.x * imageScale,
			y: visibleRect.origin.y * imageScale,
			width: visibleRect.width * imageScale,
			height: visibleRect.height * imageScale
		).integral
		
		debugPrint("=== Source Image Calculations ===")
		debugPrint("Source rect before bounds check:", sourceRect)
		
		// 4. Ensure the rect is within the source image bounds
		let boundedRect = CGRect(
			x: max(0, min(sourceRect.origin.x, CGFloat(sourceImageCG.width) - sourceRect.width)),
			y: max(0, min(sourceRect.origin.y, CGFloat(sourceImageCG.height) - sourceRect.height)),
			width: min(sourceRect.width, CGFloat(sourceImageCG.width)),
			height: min(sourceRect.height, CGFloat(sourceImageCG.height))
		).integral
		
		debugPrint("Final bounded rect:", boundedRect)
		
		// 5. Create the cropped image
		guard let croppedCGImage = sourceImageCG.cropping(to: boundedRect) else {
			debugPrint("ERROR: Failed to crop image with rect:", boundedRect)
			return nil
		}
		
		// 6. Create the final circular mask
		let format = UIGraphicsImageRendererFormat()
		format.scale = 1.0
		
		var finalImage = UIGraphicsImageRenderer(
			size: sizeToCrop,
			format: format
		).image { context in
			
			let rect = CGRect(
				origin: .zero,
				size: sizeToCrop
			)
			UIImage(cgImage: croppedCGImage).draw(in: rect)
		}
		
		debugPrint("=== Final Result ===")
		debugPrint("Final image size:", finalImage.size)
		
		return finalImage
	}
	
}

// MARK: - Create UI

private extension CropViewController {
	func makeCropFrame() -> CGRect {
		let center = CGPoint(
			x: scrollView.bounds.midX,
			y: scrollView.bounds.midY
		)
		
		return CGRect(
			x: center.x - cropViewFrameSize.width / 2,
			y: center.y - cropViewFrameSize.height / 2,
			width: cropViewFrameSize.width,
			height: cropViewFrameSize.height
		)
	}
	
	func makeScrollView() -> UIScrollView {
		let scrollView = UIScrollView()
		scrollView.backgroundColor = .clear
		scrollView.delegate = self
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.showsVerticalScrollIndicator = false
		scrollView.clipsToBounds = true
		scrollView.contentInsetAdjustmentBehavior = .never
		scrollView.bounces = false
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		return scrollView
	}
	
	func makeImageView() -> UIImageView {
		let imageView = UIImageView(image: sourceImage)
		imageView.contentMode = .scaleAspectFill
		imageView.translatesAutoresizingMaskIntoConstraints = false
		return imageView
	}
	
	func makeButton(type: ButtonType) -> UIButton {
		let image: UIImage
		switch type {
		case .cancel:
			image = Constants.cancelButtonImage
		case .done:
			image = Constants.doneButtonImage
		}
		
		let button = UIButton(type: .custom)
		button.setImage(
			image,
			for: .normal
		)
		button.tintColor = .lightGray
		
		return button
	}
}

// MARK: - Setup

private extension CropViewController {
	
	func setupView() {
		view.backgroundColor = Constants.backGroundColor
		
		view.addSubview(scrollView)
		scrollView.addSubview(imageView)
		view.addSubview(circleOverlayView)
		
		view.addSubview(bottomBar)
		bottomBar.addSubview(cancelButton)
		bottomBar.addSubview(doneButton)
		
		scrollView.easy.layout(
			Top(150),
			Leading(),
			Trailing(),
			Bottom(150)
		)
		
		circleOverlayView.easy.layout(
			Edges().to(scrollView)
		)
		
		bottomBar.easy.layout(
			Height(64),
			Leading(),
			Trailing(),
			Bottom(34)
		)
		
		cancelButton.easy.layout(
			Size(36),
			CenterY(),
			Leading(16)
		)
		
		doneButton.easy.layout(
			Size(36),
			CenterY(),
			Trailing(16)
		)
	}
	
	func setupBindings() {
		cancelButton
			.makePublisher(for: .touchUpInside)
			.sink { [weak self] _ in
				guard let self else {
					return
				}
				
				if Constants.isUseCompletions {
					onCancelButtonCompletion?()
				} else {
					onCancelButtonSubject.send()
				}
			}
			.store(in: &cancellables)
		
		doneButton
			.makePublisher(for: .touchUpInside)
			.sink { [weak self] _ in
				guard let self else {
					return
				}
				let croppedImage = cropImage(sizeToCrop: cropOutputImageSize)
				
				// you can use completion or combine
				if Constants.isUseCompletions {
					onDoneButtonCompletion?(croppedImage)
				} else {
					onDoneButtonSubject.send(croppedImage)
				}
			}
			.store(in: &cancellables)
	}
	
	func setupNavigationBar() {
		// Create appearance object
		let appearance = UINavigationBarAppearance()
		appearance.configureWithOpaqueBackground()
		appearance.backgroundColor = Constants.navigationBarColor
		appearance.backgroundEffect = nil
		
		// Remove bottom border/shadow
		appearance.shadowColor = .clear
		appearance.shadowImage = nil
		
		// Apply to all navigation bar states
		let navBar = navigationController?.navigationBar
		navBar?.standardAppearance			= appearance
		navBar?.scrollEdgeAppearance		= appearance
		navBar?.compactAppearance			= appearance
		navBar?.compactScrollEdgeAppearance	= appearance
		
		// Ensure the navigation bar is not translucent
		navBar?.isTranslucent = false
		
		// Optional: If you want to change the tint color of the navigation items
		navBar?.tintColor = Constants.navigationBarColor
	}
	
	func setupOverlayMask() {
		circleOverlayView.layer.sublayers?.removeAll()
		
		let overlayPath = UIBezierPath(rect: circleOverlayView.bounds)
		let circlePath = UIBezierPath(ovalIn: cropFrame)
		overlayPath.append(circlePath)
		overlayPath.usesEvenOddFillRule = true
		
		// Create mask layer for the overlay
		let maskLayer = CAShapeLayer()
		maskLayer.path = overlayPath.cgPath
		maskLayer.fillRule = .evenOdd
		maskLayer.fillColor = Constants.overlayViewColor.cgColor
		maskLayer.opacity = Constants.overlayViewColorAlpha
		
		// Create circle border layer
		let borderLayer	= CAShapeLayer()
		borderLayer.path = circlePath.cgPath
		borderLayer.strokeColor	= Constants.circleBorderColor.cgColor
		borderLayer.fillColor = Constants.circleFillColor.cgColor
		borderLayer.lineWidth = Constants.circleBorderWidth
		
		circleOverlayView.layer.addSublayer(maskLayer)
		circleOverlayView.layer.addSublayer(borderLayer)
	}
	
	func setContentInset() {
		// Center the content within the circle
		let topInset = cropFrame.minY
		let bottomInset = scrollView.bounds.maxY - cropFrame.maxY
		let leftInset = cropFrame.minX
		let rightInset = scrollView.bounds.maxX - cropFrame.maxX
		
		scrollView.contentInset = UIEdgeInsets(
			top: topInset,
			left: leftInset,
			bottom: bottomInset,
			right: rightInset
		)
	}
	
	func setupInitialZoom() {
		guard let image = imageView.image else { return }
		
		let imageSize = image.size
		
		// First set content size based on image aspect ratio
		let widthRatio = imageView.bounds.width / imageSize.width
		let heightRatio = imageView.bounds.height / imageSize.height
		
		// Use the smaller ratio to ensure the image fits in the view
		let aspectRatio = min(widthRatio, heightRatio)
		
		// Calculate scaled dimensions
		let scaledWidth = imageSize.width * aspectRatio
		let scaledHeight = imageSize.height * aspectRatio
		
		// Set imageView frame with scaled dimensions
		imageView.frame = CGRect(
			x: 0,
			y: 0,
			width: scaledWidth,
			height: scaledHeight
		)
		
		// Update scroll view content size
		scrollView.contentSize = CGSize(width: scaledWidth, height: scaledHeight)
		
		// Calculate minimum zoom to fit circle frame
		let minZoom = max(
			cropViewFrameSize.width / scaledWidth,
			cropViewFrameSize.height / scaledHeight
		)
		
		debugPrint("Setup zoom - scaled size:", CGSize(width: scaledWidth, height: scaledHeight))
		debugPrint("Setup zoom - minZoom:", minZoom)
		debugPrint("Setup zoom - cropViewFrameSize:", cropViewFrameSize)
		
		// Set zoom scales
		scrollView.minimumZoomScale = minZoom
		scrollView.maximumZoomScale = Constants.maximumZoomScale
		
		// Set initial zoom
		scrollView.zoomScale = minZoom
		
		debugPrint("After setup - imageView frame:", imageView.frame)
		debugPrint("After setup - scrollView contentSize:", scrollView.contentSize)
		debugPrint("After setup - scrollView zoomScale:", scrollView.zoomScale)
		
		centerContent()
	}
	
	func centerContent() {
		let boundsSize = scrollView.bounds.size
		var frameToCenter = imageView.frame
		
		if frameToCenter.size.width < boundsSize.width {
			frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
		} else {
			frameToCenter.origin.x = 0
		}
		
		if frameToCenter.size.height < boundsSize.height {
			frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
		} else {
			frameToCenter.origin.y = 0
		}
		
		imageView.frame = frameToCenter
	}
}

// MARK: - UIScrollViewDelegate

extension CropViewController: UIScrollViewDelegate {
	public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return imageView
	}
	
	public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
		// Double check the zoom scale after zooming ends
		if scale < scrollView.minimumZoomScale {
			scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
		}
	}
	
	public func scrollViewDidZoom(_ scrollView: UIScrollView) {
		debugPrint("Current zoom scale: \(scrollView.zoomScale)")
		debugPrint("Minimum zoom scale: \(scrollView.minimumZoomScale)")
		
		if scrollView.zoomScale < scrollView.minimumZoomScale {
			debugPrint("Correcting zoom scale to minimum: \(scrollView.minimumZoomScale)")
			scrollView.zoomScale = scrollView.minimumZoomScale
		}
		centerContent()
	}
}






