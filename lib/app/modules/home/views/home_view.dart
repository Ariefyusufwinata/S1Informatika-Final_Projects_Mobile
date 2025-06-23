import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../../themes/themes.dart';
import '../../../utils/utils.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  CameraController? controller;
  Interpreter? interpreter;
  FaceDetector? faceDetector;
  bool isBusy = false;
  CameraImage? currentFrame;
  List<String> predictions = [];
  double? _fps;
  DateTime? _lastFrameTime;
  DateTime lastAlertTime = DateTime.now().subtract(const Duration(seconds: 5));

  @override
  void initState() {
    super.initState();
    initEverything();
  }

  Future<void> initEverything() async {
    if (await Permission.camera.request().isGranted) {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
      );
      controller = CameraController(frontCamera, ResolutionPreset.high);
      await controller!.initialize();

      faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
        ),
      );
      interpreter = await Interpreter.fromAsset(
        'assets/model/MobileNetV3Large.tflite',
      );

      await controller!.startImageStream((CameraImage image) {
        if (!isBusy) {
          isBusy = true;
          currentFrame = image;
          detectFaceAndPredict();
        }
      });

      setState(() {});
    } else {
      Get.defaultDialog(
        title: "Permission Denied",
        middleText: "Camera permission is required to use this app.",
        textConfirm: "OK",
        onConfirm: () => Get.back(),
      );
    }
  }

  Future<void> detectFaceAndPredict() async {
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final diff = now.difference(_lastFrameTime!).inMilliseconds;
      if (diff > 0) _fps = 1000 / diff;
    }
    _lastFrameTime = now;

    if (currentFrame == null || faceDetector == null || interpreter == null) {
      isBusy = false;
      return;
    }

    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in currentFrame!.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(
          currentFrame!.width.toDouble(),
          currentFrame!.height.toDouble(),
        ),
        rotation: InputImageRotation.rotation270deg,
        format: InputImageFormat.nv21,
        bytesPerRow: currentFrame!.planes[0].bytesPerRow,
      ),
    );

    final faces = await faceDetector!.processImage(inputImage);
    if (faces.isEmpty) {
      predictions = [];
      setState(() => isBusy = false);
      return;
    }

    final face = faces.first;
    final image = _convertCameraImage(currentFrame!);
    final rect = face.boundingBox;
    final cropped = img.copyCrop(
      image,
      x: rect.left.toInt().clamp(0, image.width - 1),
      y: rect.top.toInt().clamp(0, image.height - 1),
      width: rect.width.toInt().clamp(1, image.width),
      height: rect.height.toInt().clamp(1, image.height),
    );

    final input = _preprocess(cropped);
    final output = List<List<double>>.generate(1, (_) => List.filled(3, 0.0));
    interpreter!.run(input, output);

    final scores = output[0];
    final maxIndex = scores.indexWhere((e) => e == scores.reduce(max));
    final labels = ['mengantuk', 'normal', 'distraksi'];
    final label = labels[maxIndex];

    predictions = [
      '${label} (${(scores[maxIndex] * 100).toStringAsFixed(1)}%)',
    ];

    if (now.difference(lastAlertTime) >= const Duration(seconds: 10)) {
      lastAlertTime = now;
      final player = AudioPlayer();
      final index = Random().nextInt(2) + 1;
      if (label == 'mengantuk') {
        await player.play(AssetSource('alert/drowsy_$index.mp3'));
      } else if (label == 'distraksi') {
        await player.play(AssetSource('alert/distracted_$index.mp3'));
      }
    }

    setState(() => isBusy = false);
  }

  img.Image _convertCameraImage(CameraImage image) {
    final plane = image.planes[0];
    final grayscale = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixelIndex = y * plane.bytesPerRow + x;
        final value = plane.bytes[pixelIndex];
        grayscale.setPixelRgb(x, y, value, value, value);
      }
    }
    return img.copyRotate(grayscale, angle: 90);
  }

  List<List<List<List<double>>>> _preprocess(img.Image face) {
    final resized = img.copyResize(face, width: 224, height: 224);
    return [
      List.generate(224, (y) {
        return List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        });
      }),
    ];
  }

  @override
  void dispose() {
    controller?.dispose();
    faceDetector?.close();
    interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Facial Expression Recognition")),
      bottomNavigationBar: ConvexAppBar(
        top: 0,
        height: 60,
        color: AppColor.black,
        activeColor: AppColor.blue,
        backgroundColor: AppColor.white,
        style: TabStyle.react,
        items: const [
          TabItem(icon: Icons.home, title: ''),
          TabItem(icon: Icons.analytics, title: ''),
        ],
        initialActiveIndex: 0,
        onTap: (int i) => Utils.changePage(index: i),
      ),
      body:
          controller == null || !controller!.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  SizedBox.expand(child: CameraPreview(controller!)),
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...predictions.map(
                          (pred) => Text(
                            pred,
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              backgroundColor: Colors.black54,
                            ),
                          ),
                        ),
                        if (_fps != null)
                          Text(
                            'FPS: ${_fps!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              backgroundColor: Colors.black54,
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
