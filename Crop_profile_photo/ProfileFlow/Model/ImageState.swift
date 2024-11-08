//
//  ImageState.swift
//  Crop_profile_photo
//
//  Created by Maxnxi on 11/09/24
//

import Foundation
import SwiftUI

enum ImageState {
	case empty
	case loading(Progress)
	case success(Image)
	case failure(Error)
}
