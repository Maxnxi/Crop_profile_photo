//
//  ProfileForm.swift
//  Crop_profile_photo
//
//  Created by Maxnxi on 11/09/24
//

import SwiftUI
import PhotosUI
import Combine
import UIKit

struct ProfileForm: View {
	
	@StateObject var viewModel = ProfileModel()
	
	@State private var isCropViewShow = false
	@State var profileImage: UIImage?
		
	@State var cancelables = Set<AnyCancellable>()
	
	var body: some View {
		NavigationStack {
			VStack {
				Form {
					Section {
						HStack {
							Spacer()
							
							avatarView
							
							Spacer()
						}
					}
					.listRowBackground(Color.clear)
#if !os(macOS)
					.padding([.top], 10)
#endif
					bioInfo
					
				}
			}
			.navigationTitle("Account Profile")
			
			.sheet(isPresented: $isCropViewShow) {
				CropView(
					inputImage: viewModel.imageToCrop,
					outputImage: $profileImage,
					isOpened: $isCropViewShow
				)
			}
		}
		.task {
			setupBindings()
		}
		.onChange(of: profileImage) { oldValue, newValue in
			viewModel.updateImageState(uiImage: profileImage)
		}
	}
	
	@ViewBuilder
	var avatarView: some View {
		CircularProfileImage(imageState: viewModel.imageState)
			.overlay(alignment: .bottomTrailing) {
				PhotosPicker(selection: $viewModel.photosPickerItem) {
					Image(systemName: "pencil.circle.fill")
						.symbolRenderingMode(.multicolor)
						.font(.system(size: 30))
						.foregroundColor(.accentColor)
				}
				.buttonStyle(.borderless)
			}
	}
	
	@ViewBuilder
	var bioInfo: some View {
		VStack {
			Section {
				TextField(
					"First Name",
					text: $viewModel.firstName,
					prompt: Text("First Name")
				)
				TextField(
					"Last Name",
					text: $viewModel.lastName,
					prompt: Text("Last Name")
				)
			}
			Section {
				TextField(
					"About Me",
					text: $viewModel.aboutMe,
					prompt: Text("About Me")
				)
			}
		}
	}
	
	func setupBindings() {
		viewModel.callCropViewSubject
			.sink { _ in
				isCropViewShow = true
			}
			.store(in: &cancelables)
	}
}
