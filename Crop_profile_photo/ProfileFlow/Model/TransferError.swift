//
//  TransferError.swift
//  Crop_profile_photo
//
//  Created by Maxnxi on 11/09/24
//

import Foundation

enum TransferError: Error {
	case errorInPhotosPickerItem
	case errorInLoadTransferable
	case errorCreatingUIImage
	
	case errorCropUIImage
}
