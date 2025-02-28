# Crop profile photo

This is the example of croping and scaling image in Profile page in app

CropViewController implemented in UIKit and connected to SwiftUI View





## Examples

![photo_2024-11-11 11 39 59](https://github.com/user-attachments/assets/b97250c9-831d-4ffc-ba3e-052c076ab618)



## Usage

```swift
let cropVC = CropViewController(
    image: sourceImage,
    cropOutputImageSize: CGSize(width: 1080, height: 1080)
)
```


And get the result with completion handler 

```swift
// Using completion handlers
cropVC.onDoneButtonCompletion = { croppedImage in
    // Handle the cropped image
}
cropVC.onCancelButtonCompletion = {
    // Handle cancellation
}
```

or


```swift
// Or using Combine
cropVC.onDoneButtonSubject
    .sink { croppedImage in
        // Handle the cropped image
    }
    .store(in: &cancellables)
```



