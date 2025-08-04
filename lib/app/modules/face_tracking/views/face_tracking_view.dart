import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';

import '../../../themes/themes.dart';
import '../controllers/face_tracking_controller.dart';

class FaceTrackingView extends StatefulWidget {
  const FaceTrackingView({super.key});

  @override
  State<FaceTrackingView> createState() => _FaceTrackingViewState();
}

class _FaceTrackingViewState extends State<FaceTrackingView> {
  final controller = Get.put(FaceTrackingController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initEverything(context);
    });
  }

  @override
  void dispose() {
    controller.disposeResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.cameraController == null || !controller.cameraController!.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller.cameraController!),
              Obx(() {
                final box = controller.faceBoundingBox.value;
                if (box == null) return const SizedBox.shrink();
                final screenRect = controller.scaleRectToScreen(box);
                return Positioned(
                  left: screenRect.left,
                  top: screenRect.top,
                  width: screenRect.width,
                  height: screenRect.height,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 3),
                    ),
                  ),
                );
              }),
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: Obx(() {
                  final msg = controller.detectionMessage.value;
                  if (msg != null) {
                    return Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColor.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: controller.predictions.map((pred) {
                      return Text(
                        pred,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      );
                    }).toList(),
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }
}


// import 'dart:async';
// import 'dart:math';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:camera/camera.dart';
// import 'package:convex_bottom_bar/convex_bottom_bar.dart';
// import 'package:fer_mobile/app/data/sqlite/database.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:image/image.dart' as img;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';

// import 'package:intl/intl.dart';

// import '../../../themes/themes.dart';
// import '../../../utils/utils.dart';

// class FaceTrackingView extends StatefulWidget {
//   const FaceTrackingView({super.key});

//   @override
//   State<FaceTrackingView> createState() => _FaceTrackingViewState();
// }

// class _FaceTrackingViewState extends State<FaceTrackingView> {
//   CameraController? controller;
//   Interpreter? interpreter;
//   FaceDetector? faceDetector;
//   bool isBusy = false;
//   bool isDisposed = false;

//   CameraImage? currentFrame;
//   List<String> predictions = [];
//   DateTime? _lastFrameTime;
//   DateTime lastAlertTime = DateTime.now().subtract(const Duration(seconds: 5));

//   Rect? faceBoundingBox;
//   Size? cameraPreviewSize;
//   Size? screenSize;
//   String? detectionMessage;

//   @override
//   void initState() {
//     super.initState();
//     initEverything();
//   }

//   Future<void> initEverything() async {
//     if (await Permission.camera.request().isGranted) {
//       final cameras = await availableCameras();
//       final frontCamera = cameras.firstWhere(
//         (cam) => cam.lensDirection == CameraLensDirection.front,
//       );

//       controller = CameraController(frontCamera, ResolutionPreset.medium);
//       await controller!.initialize();

//       if (mounted) {
//         cameraPreviewSize = controller!.value.previewSize;
//         screenSize = MediaQuery.of(context).size;
//       }

//       faceDetector = FaceDetector(
//         options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
//       );

//       try {
//         interpreter = await Interpreter.fromAsset(
//           'assets/model/MobileNetV3Small.tflite',
//         );
//       } catch (e) {
//         debugPrint('[ERROR] Failed to load model: $e');
//         return;
//       }

//       await controller!.startImageStream((CameraImage image) {
//         if (!isBusy && !isDisposed && interpreter != null) {
//           isBusy = true;
//           currentFrame = image;
//           detectFaceAndPredict();
//         }
//       });

//       setState(() {});
//     } else {
//       Get.defaultDialog(
//         title: "Permission Denied",
//         middleText: "Camera permission is required to use this app.",
//         textConfirm: "OK",
//         onConfirm: () => Get.back(),
//       );
//     }
//   }

//   Future<void> detectFaceAndPredict() async {
//     try {
//       if (!mounted ||
//           isDisposed ||
//           interpreter == null ||
//           currentFrame == null) {
//         isBusy = false;
//         return;
//       }

//       final now = DateTime.now();
//       if (_lastFrameTime != null &&
//           now.difference(_lastFrameTime!) < const Duration(milliseconds: 100)) {
//         isBusy = false;
//         return;
//       }
//       _lastFrameTime = now;

//       final WriteBuffer allBytes = WriteBuffer();
//       for (Plane plane in currentFrame!.planes) {
//         allBytes.putUint8List(plane.bytes);
//       }
//       final bytes = allBytes.done().buffer.asUint8List();

//       final inputImage = InputImage.fromBytes(
//         bytes: bytes,
//         metadata: InputImageMetadata(
//           size: Size(
//             currentFrame!.width.toDouble(),
//             currentFrame!.height.toDouble(),
//           ),
//           rotation: InputImageRotation.rotation270deg,
//           format: InputImageFormat.nv21,
//           bytesPerRow: currentFrame!.planes[0].bytesPerRow,
//         ),
//       );

//       final faces = await faceDetector!.processImage(inputImage);

//       if (faces.length > 1) {
//         predictions = [];
//         faceBoundingBox = null;
//         detectionMessage = 'There can be no more than 1 face detected';
//         if (mounted && !isDisposed) {
//           setState(() => isBusy = false);
//         }
//         return;
//       } else if (faces.isEmpty) {
//         predictions = [];
//         faceBoundingBox = null;
//         detectionMessage = 'No faces detected';
//         if (mounted && !isDisposed) {
//           setState(() => isBusy = false);
//         }
//         return;
//       }

//       detectionMessage = null;
//       final face = faces.first;
//       final rect = face.boundingBox;
//       faceBoundingBox = rect;

//       final img.Image? rgbImage = await compute(
//         convertCameraImage,
//         currentFrame!,
//       );

//       if (rgbImage == null) {
//         debugPrint('[ERROR] RGB conversion failed');
//         isBusy = false;
//         return;
//       }

//       final cropped = img.copyCrop(
//         rgbImage,
//         x: rect.left.toInt().clamp(0, rgbImage.width - 1),
//         y: rect.top.toInt().clamp(0, rgbImage.height - 1),
//         width: rect.width.toInt().clamp(1, rgbImage.width),
//         height: rect.height.toInt().clamp(1, rgbImage.height),
//       );

//       final resized = img.copyResize(cropped, width: 224, height: 224);
//       final input = _preprocess(resized);
//       final output = List<List<double>>.generate(1, (_) => List.filled(3, 0.0));

//       try {
//         interpreter?.run(input, output);
//       } catch (e) {
//         debugPrint('[ERROR] Interpreter run failed: $e');
//         isBusy = false;
//         return;
//       }

//       final scores = output[0];
//       final maxScore = scores.reduce(max);
//       final maxIndex = scores.indexOf(maxScore);
//       final labels = ['Drowsy', 'Neutral', 'Distracted'];

//       String resultLabel = labels[maxIndex];
//       int resultIndex = maxIndex;

//       if (maxIndex == 2 && maxScore > 0.8) {
//         resultLabel = 'Neutral';
//         resultIndex = 1;
//       }

//       if (maxIndex == 0 && maxScore > 0.8) {
//         resultLabel = 'Neutral';
//         resultIndex = 1;
//       }

//       predictions = [resultLabel];

//       await DatabaseHelper.instance.insertDetection({
//         'feature': resultIndex,
//         'detect': resultLabel,
//         'percentage': (maxScore * 100).toStringAsFixed(1),
//         'date': DateFormat('yyyy-MM-dd').format(now),
//         'time': DateFormat('HH:mm:ss').format(now),
//         'timestamp': now.toIso8601String(),
//       });

//       if (now.difference(lastAlertTime) >= const Duration(seconds: 10)) {
//         lastAlertTime = now;
//         final player = AudioPlayer();
//         final index = Random().nextInt(2) + 1;

//         if (resultLabel == 'Drowsy') {
//           await player.play(AssetSource('alert/drowsy_$index.mp3'));
//         }

//         if (resultLabel == 'Distracted') {
//           await player.play(AssetSource('alert/distracted_$index.mp3'));
//         }
//       }

//       if (mounted && !isDisposed) {
//         setState(() => isBusy = false);
//       }
//     } catch (e, stack) {
//       debugPrint('[ERROR] detectFaceAndPredict: $e\n$stack');
//       isBusy = false;
//     }
//   }

//   Rect scaleRectToScreen(Rect rect) {
//     if (cameraPreviewSize == null || screenSize == null) return rect;

//     final double previewWidth = cameraPreviewSize!.height;
//     final double previewHeight = cameraPreviewSize!.width;

//     final double screenWidth = screenSize!.width;
//     final double screenHeight = screenSize!.height;

//     final double scaleX = screenWidth / previewWidth;
//     final double scaleY = screenHeight / previewHeight;

//     double left = screenWidth - (rect.left + rect.width) * scaleX;
//     double top = rect.top * scaleY;
//     double width = rect.width * scaleX;
//     double height = rect.height * scaleY;

//     const double marginFactor = 0.3;
//     final double deltaWidth = width * marginFactor;
//     final double deltaHeight = height * marginFactor;

//     left = (left - deltaWidth / 2).clamp(0, screenWidth);
//     top = (top - deltaHeight / 2 - 70).clamp(0, screenHeight);
//     width = (width + deltaWidth).clamp(0, screenWidth - left);
//     height = (height + deltaHeight).clamp(0, screenHeight - top);

//     return Rect.fromLTWH(left, top, width, height);
//   }

//   List<List<List<List<double>>>> _preprocess(img.Image image) {
//     return [
//       List.generate(224, (y) {
//         return List.generate(224, (x) {
//           final pixel = image.getPixel(x, y);
//           return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
//         });
//       }),
//     ];
//   }

//   @override
//   void dispose() {
//     _disposeResources();
//     super.dispose();
//   }

//   Future<void> _disposeResources() async {
//     debugPrint('[DEBUG] Disposing resources...');

//     isDisposed = true;
//     await controller?.stopImageStream();
//     await controller?.dispose();
//     await faceDetector?.close();
//     interpreter?.close();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text(''), backgroundColor: AppColor.white),
//       bottomNavigationBar: ConvexAppBar(
//         top: 0,
//         height: 50,
//         color: AppColor.black,
//         activeColor: AppColor.blue,
//         backgroundColor: AppColor.white,
//         style: TabStyle.react,
//         items: const [
//           TabItem(icon: Icons.home, title: ''),
//           TabItem(icon: Icons.face, title: ''),
//         ],
//         initialActiveIndex: 1,
//         onTap: (i) => Utils.changePage(index: i),
//       ),
//       body:
//           controller == null || !controller!.value.isInitialized
//               ? const Center(child: CircularProgressIndicator())
//               : Stack(
//                 children: [
//                   SizedBox.expand(
//                     child: AspectRatio(
//                       aspectRatio: controller!.value.aspectRatio,
//                       child: CameraPreview(controller!),
//                     ),
//                   ),
//                   if (faceBoundingBox != null && detectionMessage == null)
//                     Positioned(
//                       left: scaleRectToScreen(faceBoundingBox!).left,
//                       top: scaleRectToScreen(faceBoundingBox!).top,
//                       child: Container(
//                         width: scaleRectToScreen(faceBoundingBox!).width,
//                         height: scaleRectToScreen(faceBoundingBox!).height,
//                         decoration: BoxDecoration(
//                           border: Border.all(color: AppColor.blue, width: 2),
//                         ),
//                       ),
//                     ),
//                   Positioned(
//                     bottom: 20,
//                     left: 0,
//                     right: 0,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         if (detectionMessage != null)
//                           Text(
//                             detectionMessage!,
//                             style: const TextStyle(
//                               fontSize: 24,
//                               color: AppColor.red,
//                               backgroundColor: AppColor.black,
//                             ),
//                           )
//                         else
//                           ...predictions.map(
//                             (pred) => Text(
//                               pred,
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 color: AppColor.white,
//                                 backgroundColor: AppColor.black,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//     );
//   }
// }

// img.Image convertCameraImage(CameraImage image) {
//   if (image.format.group != ImageFormatGroup.yuv420) {
//     throw Exception("Unsupported image format: ${image.format.group}");
//   }

//   final width = image.width;
//   final height = image.height;
//   final imgImage = img.Image(width: width, height: height);

//   final int uvRowStride = image.planes[1].bytesPerRow;
//   final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

//   for (int y = 0; y < height; y++) {
//     for (int x = 0; x < width; x++) {
//       final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
//       final int yIndex = y * image.planes[0].bytesPerRow + x;

//       final int yVal = image.planes[0].bytes[yIndex];
//       final int uVal = image.planes[1].bytes[uvIndex];
//       final int vVal = image.planes[2].bytes[uvIndex];

//       final int r = (yVal + 1.370705 * (vVal - 128)).clamp(0, 255).toInt();
//       final int g =
//           (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128))
//               .clamp(0, 255)
//               .toInt();
//       final int b = (yVal + 1.732446 * (uVal - 128)).clamp(0, 255).toInt();

//       imgImage.setPixelRgb(x, y, r, g, b);
//     }
//   }

//   var rotated = img.copyRotate(imgImage, angle: 270);
//   return img.flipHorizontal(rotated);
// }
