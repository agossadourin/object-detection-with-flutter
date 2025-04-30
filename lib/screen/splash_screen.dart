import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:object_detection_app/screen/object_detection_screen.dart';
import 'package:object_detection_app/utils/my_Text_stylr.dart';

class SplashScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SplashScreen({super.key, required this.cameras});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Splash screen will last for 3 seconds, then navigate to Home
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ObjectDetectionScreen(cameras: widget.cameras),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF3A3A3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
            Image.asset(
              'assets/icons/object.png',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              color: Colors.blue,
            ),

            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              builder: (context, double opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: Text(
                    "AI Vision",
                    style: myTextStyle24(fontWeight: FontWeight.bold , fontColors: Colors.white54),
                  ),
                );
              },
            ),
            Spacer(),
            Text("Detect Anything" , style: myTextStyle18(fontColors: Colors.blue),) ,
            SizedBox(height: MediaQuery.of(context).size.height * 0.1,)
          ],
        ),
      ),
    );
  }
}
