//
//  TouchThruView.swift
//  Crop_profile_photo
//
//  Created by Maxnxi on 11/09/24
//

import UIKit


final class TouchThruView: UIView {
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		let hitView = super.hitTest(point, with: event)
		return hitView == self ? nil : hitView
	}
}
