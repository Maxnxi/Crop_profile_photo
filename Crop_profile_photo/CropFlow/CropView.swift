//
//  CropView.swift
//  Crop_profile_photo
//
//  Created by Maxnxi on 11/09/24
//

import SwiftUI
import UIKit
import Combine

struct CropView: UIViewControllerRepresentable {
	
	let inputImage: UIImage
	
	@Binding var outputImage: UIImage?
	@Binding var isOpened: Bool
	
	func makeUIViewController(context: Context) -> CropViewController {
		// Create an instance of your UIViewController
		let vc = CropViewController(image: inputImage)
		
		vc.onCancelButtonCompletion = {
			isOpened = false
		}
		
		vc.onDoneButtonCompletion = { outputImage in
			self.outputImage = outputImage
			isOpened = false
		}
		
		return vc
	}
	
	func updateUIViewController(_ uiViewController: CropViewController, context: Context) {
		// Update the view controller as needed
	}
}
