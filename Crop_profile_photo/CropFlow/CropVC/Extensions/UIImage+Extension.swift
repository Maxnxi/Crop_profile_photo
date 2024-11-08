//
//  UIImage+Extension.swift
//  Crop_profile_photo
//
//  Created by Maxnxi on 11/09/24
//

import UIKit


extension UIImage {
	
	/// fix image orientation
	func fixImageOrientation() -> UIImage? {
		guard imageOrientation != UIImage.Orientation.up else {
			// This is default orientation, don't need to do anything
			return copy() as? UIImage
		}
		
		guard let cgImage = cgImage else {
			// CGImage is not available
			return nil
		}
		
		guard
			let colorSpace = cgImage.colorSpace,
			let ctx = CGContext(
				data: nil,
				width: Int(size.width),
				height: Int(size.height),
				bitsPerComponent: cgImage.bitsPerComponent,
				bytesPerRow: 0,
				space: colorSpace,
				bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
			)
		else {
			return nil
		} // Not able to create CGContext
		
		var transform: CGAffineTransform = CGAffineTransform.identity
		
		switch imageOrientation {
		case .down,
				.downMirrored:
			transform = transform.translatedBy(x: size.width, y: size.height)
			transform = transform.rotated(by: CGFloat.pi)
		case .left,
				.leftMirrored:
			transform = transform.translatedBy(x: size.width, y: 0)
			transform = transform.rotated(by: CGFloat.pi / 2.0)
		case .right,
				.rightMirrored:
			transform = transform.translatedBy(x: 0, y: size.height)
			transform = transform.rotated(by: CGFloat.pi / -2.0)
		case .up,
				.upMirrored:
			break
		}
		
		// Flip image one more time if needed to, this is to prevent flipped image
		switch imageOrientation {
		case .upMirrored,
				.downMirrored:
			transform.translatedBy(x: size.width, y: 0)
			transform.scaledBy(x: -1, y: 1)
		case .leftMirrored,
				.rightMirrored:
			transform.translatedBy(x: size.height, y: 0)
			transform.scaledBy(x: -1, y: 1)
		case .up,
				.down,
				.left,
				.right:
			break
		}
		
		ctx.concatenate(transform)
		
		switch imageOrientation {
		case .left,
				.leftMirrored,
				.right,
				.rightMirrored:
			ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
		default:
			ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
		}
		
		guard let newCGImage = ctx.makeImage() else {
			return nil
		}
		return UIImage(cgImage: newCGImage, scale: 1, orientation: .up)
	}
}