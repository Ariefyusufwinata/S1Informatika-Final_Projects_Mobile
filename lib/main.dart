import 'dart:math';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:fer_mobile/app/themes/themes.dart';
import 'package:fer_mobile/app/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DateTime lastAlertTime = DateTime.now().subtract(const Duration(seconds: 5));
  CameraController? controller;
  Interpreter? interpreter;
  FaceDetector? faceDetector;
  bool isBusy = false;
  CameraImage? currentFrame;
  List<String> predictions = [];
  DateTime? _lastFrameTime;
  double? _fps;

  @override
  void initState() {
    super.initState();
    initEverything();
  }

  Future<void> initEverything() async {
    if (await Permission.camera.request().isGranted) {
      interpreter = await Interpreter.fromAsset(
        'assets/model/MobileNetV3Large.tflite',
      );
      faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
        ),
      );
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
      );
      controller = CameraController(camera, ResolutionPreset.high);
      await controller!.initialize();
      await controller!.startImageStream((CameraImage image) {
        if (!isBusy) {
          isBusy = true;
          currentFrame = image;
          detectFaceAndPredict();
        }
      });
      setState(() {});
    } else {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("Permission Denied"),
              content: const Text(
                "Camera permission is required to use this app.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    }
  }

  Future<void> detectFaceAndPredict() async {
    final now = DateTime.now();

    if (_lastFrameTime != null) {
      final diff = now.difference(_lastFrameTime!).inMilliseconds;
      if (diff > 0) {
        _fps = 1000 / diff;
        debugPrint('FPS: ${_fps!.toStringAsFixed(2)}');
      }
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
    final maxIndex = scores.indexWhere(
      (e) => e == scores.reduce((a, b) => a > b ? a : b),
    );

    final labels = ['mengantuk', 'normal', 'distraksi'];
    final labelIndex = maxIndex;
    final label = labels[labelIndex];
    predictions = [
      '$label (${(scores[labelIndex] * 100).toStringAsFixed(1)}%)',
    ];

    // final now = DateTime.now();

    // Kalau sudah lewat 5 detik sejak alert terakhir
    if (now.difference(lastAlertTime) >= const Duration(seconds: 10)) {
      lastAlertTime = now;

      final player = AudioPlayer();
      final random = Random();

      if (label == 'mengantuk') {
        final index = random.nextInt(2) + 1;
        await player.play(AssetSource('alert/drowsy_$index.mp3'));
      } else if (label == 'distraksi') {
        final index = random.nextInt(2) + 1;
        await player.play(AssetSource('alert/distracted_$index.mp3'));
      }
    }
    debugPrint('Predicted label: $predictions');

    setState(() => isBusy = false);
  }

  List<List<List<List<double>>>> _preprocess(img.Image face) {
    final resized = img.copyResize(face, width: 224, height: 224);
    return [
      List.generate(224, (y) {
        return List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          final r = pixel.r / 255.0;
          final g = pixel.g / 255.0;
          final b = pixel.b / 255.0;
          return [r, g, b];
        });
      }),
    ];
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
                  CameraPreview(controller!),
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
