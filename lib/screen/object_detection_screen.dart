import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:object_detection_app/utils/my_Text_stylr.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class ObjectDetectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ObjectDetectionScreen({super.key, required this.cameras});

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  late CameraController _cameraController;
  bool isCameraReady = false;
  String result = "Detecting...";
  late ImageLabeler _imageLabeler;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeMLKit();
  }

  /// Initialize Camera
  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.ultraHigh,
      enableAudio: false,
    );

    await _cameraController.initialize();
    if (!mounted) return;

    setState(() {
      isCameraReady = true;
    });

    // Start Streaming for Real-time Detection
    _startImageStream();
  }

  /// Initialize ML Kit
  void _initializeMLKit() {
    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );
  }

  /// Start Image Stream for Real-time Detection
  void _startImageStream() {
    _cameraController.startImageStream((CameraImage image) async {
      if (isDetecting) return;
      isDetecting = true;
      await _processImage(image);
      isDetecting = false;
    });
  }

  /// Process Camera Frame
  Future<void> _processImage(CameraImage cameraImage) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File imageFile = File(filePath);

      // Convert CameraImage to File
      final XFile picture = await _cameraController.takePicture();
      await picture.saveTo(imageFile.path);

      final inputImage = InputImage.fromFile(imageFile);
      final List<ImageLabel> labels = await _imageLabeler.processImage(
        inputImage,
      );

      String detectedObjects = labels.isNotEmpty
          ? labels
              .map(
                (label) =>
                    "${label.label} - ${(label.confidence * 100).toStringAsFixed(2)}%",
              )
              .join("\n")
          : "No object detected";

      setState(() {
        result = detectedObjects;
      });
    } catch (e) {
      print("Error processing image: $e");
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _imageLabeler.close();
    super.dispose();
  }

  MediaQueryData? mqData;
  @override
  Widget build(BuildContext context) {
    mqData = MediaQuery.of(context);
    return Scaffold(
      /// -------------- Appbar --------------------- ///
      appBar: AppBar(
        backgroundColor: Color(0xff213555),
        title: Text(
          "Real-time Object Detection",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        leading: Image.asset(
          "assets/icons/object.png",
          color: Colors.blue,
        ),
      ),
      backgroundColor: Color(0xff3E5879),

      ///----------------- BODY --------------------///
      body: SingleChildScrollView(
        child: Stack(
          children: [
            /// Camera Preview
            Center(
              child: SizedBox(
                width: mqData!.size.width,
                child: isCameraReady
                    ? CameraPreview(_cameraController)
                    : Center(child: CircularProgressIndicator()),
              ),
            ),

            /// Detection Result
            Positioned(
              bottom: 0,
              child: Container(
                width: mqData!.size.width,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0x5af0bb78),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Detected Objects",
                      style: myTextStyle18(
                        fontWeight: FontWeight.bold,
                        fontColors: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        result,
                        textAlign: TextAlign.start,
                        style: myTextStyle18(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
