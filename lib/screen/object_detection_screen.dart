import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:object_detection_app/utils/my_Text_stylr.dart';
import 'package:path/path.dart';
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
  late ObjectDetector _objectDetector;
  bool isDetecting = false;

  // Store detected objects and their bounding boxes
  List<DetectedObject> _detectedObjects = [];
  Size? _imageSize;

  // Camera image rotation
  int _imageRotation = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeObjectDetector();
  }

  /// Initialize Camera
  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController.initialize();
    if (!mounted) return;

    // Set the image rotation based on camera sensor orientation
    _imageRotation = _cameraController.description.sensorOrientation;

    setState(() {
      isCameraReady = true;
    });

    // Start Streaming for Real-time Detection
    _startImageStream();
  }

  Future<String> getModelPath(String asset) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$asset';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(asset);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  /// Initialize Object Detector
  void _initializeObjectDetector() async {
    final modelPath = await getModelPath('assets/ml/object_labeler.tflite');
    final options = LocalObjectDetectorOptions(
      mode: DetectionMode.stream,
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  /// Start Image Stream for Real-time Detection
  void _startImageStream() {
    _cameraController.startImageStream((CameraImage image) {
      if (isDetecting) return;
      isDetecting = true;

      _processImageStream(image);

      isDetecting = false;
    });
  }

  /// Process Camera Frame from Stream
  Future<void> _processImageStream(CameraImage cameraImage) async {
    try {
      // Save image dimensions for drawing the bounding boxes later
      _imageSize = Size(
        cameraImage.width.toDouble(),
        cameraImage.height.toDouble(),
      );

      // Convert CameraImage to InputImage format required by ML Kit
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in cameraImage.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final InputImageMetadata metadata = InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: InputImageRotation.values[_imageRotation ~/ 90],
        format: InputImageFormat.nv21, // For Android YUV format
        bytesPerRow: cameraImage.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );

      // Process the image and detect objects
      final List<DetectedObject> objects =
          await _objectDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _detectedObjects = objects;
        });
      }
    } catch (e) {
      print("Error processing image stream: $e");
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _objectDetector.close();
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
      body: Column(
        children: [
          // Camera Preview with Overlay
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera Preview
                isCameraReady
                    ? CameraPreview(_cameraController)
                    : Center(child: CircularProgressIndicator()),

                // Bounding Box Overlay
                if (isCameraReady)
                  CustomPaint(
                    painter: ObjectDetectorPainter(
                      _detectedObjects,
                      _imageSize ?? Size(0, 0),
                      MediaQuery.of(context).size,
                      _imageRotation,
                    ),
                  ),
              ],
            ),
          ),

          // Object Detection Info Panel
          Container(
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
                  "Detected Objects: ${_detectedObjects.length}",
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _detectedObjects.map((object) {
                      String label = "Unknown";
                      double confidence = 0.0;

                      if (object.labels.isNotEmpty) {
                        label = object.labels.first.text;
                        confidence = object.labels.first.confidence;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          "$label - ${(confidence * 100).toStringAsFixed(1)}%",
                          style: myTextStyle18(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for drawing bounding boxes
class ObjectDetectorPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size imageSize;
  final Size screenSize;
  final int rotation;

  ObjectDetectorPainter(
      this.objects, this.imageSize, this.screenSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width == 0 || imageSize.height == 0) return;

    final double scaleX = screenSize.width / imageSize.width;
    final double scaleY = screenSize.height / imageSize.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Paint background = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(0x99000000);

    final Paint textPainter = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    for (final DetectedObject object in objects) {
      // Determine the bounding box color based on confidence
      double confidence = 0.0;
      String label = "Unknown";

      if (object.labels.isNotEmpty) {
        confidence = object.labels.first.confidence;
        label = object.labels.first.text;

        if (confidence > 0.7) {
          paint.color = Colors.green;
        } else if (confidence > 0.5) {
          paint.color = Colors.yellow;
        } else {
          paint.color = Colors.red;
        }
      } else {
        paint.color = Colors.grey;
      }

      // The coordinate system needs to be adjusted based on rotation
      final Rect boundingBox =
          _transformBoundingBox(object.boundingBox, scaleX, scaleY);

      // Draw the bounding box
      canvas.drawRect(boundingBox, paint);

      // Draw label with background
      final textSpan = TextSpan(
        text: "$label (${(confidence * 100).toStringAsFixed(0)}%)",
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final Rect textBgRect = Rect.fromLTWH(
        boundingBox.left,
        boundingBox.top - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );

      canvas.drawRect(textBgRect, background);
      textPainter.paint(
        canvas,
        Offset(boundingBox.left + 4, boundingBox.top - textPainter.height - 2),
      );
    }
  }

  Rect _transformBoundingBox(Rect box, double scaleX, double scaleY) {
    // Based on the rotation, adjust the box coordinates
    switch (rotation) {
      case (0): // No rotation
        return Rect.fromLTRB(
          box.left * scaleX,
          box.top * scaleY,
          box.right * scaleX,
          box.bottom * scaleY,
        );
      case (90): // 90 degrees clockwise rotation
        return Rect.fromLTRB(
          box.top * scaleX,
          imageSize.width * scaleY - box.right * scaleY,
          box.bottom * scaleX,
          imageSize.width * scaleY - box.left * scaleY,
        );
      case (180): // 180 degrees rotation
        return Rect.fromLTRB(
          imageSize.width * scaleX - box.right * scaleX,
          imageSize.height * scaleY - box.bottom * scaleY,
          imageSize.width * scaleX - box.left * scaleX,
          imageSize.height * scaleY - box.top * scaleY,
        );
      case (270): // 270 degrees clockwise rotation
        return Rect.fromLTRB(
          imageSize.height * scaleX - box.bottom * scaleX,
          box.left * scaleY,
          imageSize.height * scaleX - box.top * scaleX,
          box.right * scaleY,
        );
      default:
        return Rect.fromLTRB(
          box.left * scaleX,
          box.top * scaleY,
          box.right * scaleX,
          box.bottom * scaleY,
        );
    }
  }

  @override
  bool shouldRepaint(ObjectDetectorPainter oldDelegate) {
    return oldDelegate.objects != objects;
  }
}
