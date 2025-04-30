# 📷 Real-time Object Detection using Flutter & ML Kit

This Flutter project implements real-time object detection using the **Camera plugin** and **Google ML Kit's Image Labeling API**. It detects objects in live camera frames and displays the detected labels with confidence percentages.

## ✨ Features
- Real-time object detection using **ML Kit Image Labeling**.
- Camera integration with **live streaming** for continuous detection.
- Displays detected objects with confidence levels.
- **Modern UI** with Material Design.

## 📸 Screenshot
<img src = "https://github.com/rahulkumardev24/object-detection-with-flutter/blob/master/Screenshot_20250314_003130.png" height = 500/>  | <img src = "https://github.com/rahulkumardev24/object-detection-with-flutter/blob/master/Screenshot_20250314_003418.png" height = 500 />

## 🚀 Installation
### **Step 1: Clone the Repository**
```bash
git clone https://github.com/your-username/object-detection-app.git
cd object-detection-app
```

### **Step 2: Install Dependencies**
Run the following command to install required dependencies:
```bash
flutter pub get
```

### **Step 3: Configure Android & iOS**
For Android, update `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 33
    defaultConfig {
        minSdkVersion 21
    }
}
```
For iOS, enable ML Kit by adding the following to `ios/Podfile`:
```ruby
platform :ios, '11.0'
```
Then run:
```bash
cd ios
pod install
cd ..
```

### **Step 4: Run the App**
```bash
flutter run
```



## 📦 Dependencies Used
```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.11.1
  google_mlkit_image_labeling: ^0.13.0
  path_provider: ^2.1.5
  path: ^1.9.1
```

## 🛠️ How it Works
1. **Initialize Camera**: The app opens the device camera and streams images.
2. **Image Processing**: Captures each frame and sends it to **ML Kit** for object detection.
3. **Object Recognition**: Labels objects and displays them on-screen with confidence percentages.

## 📜 License
This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author
**Rahul Kumar Sahu**

### 💡 Feel free to contribute! 🚀

# object-detection-with-flutter
# object-detection-with-flutter
