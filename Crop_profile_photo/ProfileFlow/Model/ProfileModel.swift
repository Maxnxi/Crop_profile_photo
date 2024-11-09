import SwiftUI
import PhotosUI
import CoreTransferable
import Combine

@MainActor
class ProfileModel: ObservableObject {
	
	enum Constants {
		static let baseImage: UIImage = UIImage(named: "whoAreYou")!
	}
	
	// MARK: - Profile Details
	
	@Published var firstName:	String = ""
	@Published var lastName:	String = ""
	@Published var aboutMe:		String = ""
	
	@Published private(set) var imageState: ImageState = .empty
	
	@State var profileImage: UIImage?
	
	var imageToCrop: UIImage {
		_imageToCrop ?? Constants.baseImage
	}
	
	var photosPickerItem: PhotosPickerItem? {
		didSet {
			selectedItemSubject.send(photosPickerItem)
		}
	}
	
	var callCropViewSubject			= PassthroughSubject<Void, Never>()
	private var selectedItemSubject	= PassthroughSubject<PhotosPickerItem?, Error>()
	
	private var _imageToCrop: UIImage?
	private var cancellables = Set<AnyCancellable>()

	
	init()	{
		setupBindings()
	}
	
	func setupBindings() {
		selectedItemSubject
			.asyncTryMap { item in
				guard let item else {
					throw TransferError.errorInPhotosPickerItem
				}
				
				guard let imageData = try await item.loadTransferable(type: Data.self) else {
					
					throw TransferError.errorInLoadTransferable
				}
				
				
				guard let image = UIImage(data: imageData) else {
					throw TransferError.errorCreatingUIImage
				}
				return image
			}
			.catch { error -> Just<UIImage> in
				debugPrint(error.localizedDescription)
				return Just(Constants.baseImage)
			}
			.sink { [weak self] image in
				self?._imageToCrop = image
				self?.callCropViewSubject.send()
			}
			.store(in: &cancellables)
	}
	
	
	func updateImageState(uiImage: UIImage?) {
		guard let uiImage else {
			imageState = .failure(TransferError.errorCropUIImage)
			return
		}
		let image = Image(uiImage: uiImage)
		imageState = .success(image)
	}
}


