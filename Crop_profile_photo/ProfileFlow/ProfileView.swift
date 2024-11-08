//
//  ProfileView.swift
//  Crop_profile_photo
//
//  Created by Maxnxi on 11/09/24
//

import SwiftUI

struct ProfileView: View {
	var body: some View {
		#if os(macOS)
		ProfileForm()
			.labelsHidden()
			.frame(width: 400)
			.padding()
		#else
		NavigationView {
			ProfileForm()
		}
		#endif
	}
}


#Preview {
	ProfileView()
}
