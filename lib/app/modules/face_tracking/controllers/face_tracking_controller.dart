import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../data/sqlite/database.dart';

class FaceTrackingController extends GetxController {
  CameraController? cameraController;
  Interpreter? interpreter;
  FaceDetector? faceDetector;

  final isBusy = false.obs;
  final isDisposed = false.obs;

  CameraImage? currentFrame;
  final predictions = <String>[].obs;
  DateTime? _lastFrameTime;
  DateTime lastAlertTime = DateTime.now().subtract(const Duration(seconds: 5));

  final faceBoundingBox = Rxn<Rect>();
  Size? cameraPreviewSize;
  Size? screenSize;
  final detectionMessage = RxnString();

  Future<void> initEverything(BuildContext context) async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.front);

    cameraController = CameraController(frontCamera, ResolutionPreset.medium);
    await cameraController!.initialize();

    cameraPreviewSize = cameraController!.value.previewSize;
    screenSize = MediaQuery.of(context).size;

    faceDetector = FaceDetector(options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast));
    interpreter = await Interpreter.fromAsset('assets/model/MobileNetV3Small.tflite');

    await cameraController!.startImageStream((CameraImage image) {
      if (!isBusy.value && !isDisposed.value && interpreter != null) {
        isBusy.value = true;
        currentFrame = image;
        detectFaceAndPredict();
      }
    });
  }

  Future<void> detectFaceAndPredict() async {
    try {
      if (isDisposed.value || interpreter == null || currentFrame == null) {
        isBusy.value = false;
        return;
      }

      final now = DateTime.now();
      if (_lastFrameTime != null && now.difference(_lastFrameTime!) < const Duration(milliseconds: 100)) {
        isBusy.value = false;
        return;
      }
      _lastFrameTime = now;

      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in currentFrame!.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(currentFrame!.width.toDouble(), currentFrame!.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: currentFrame!.planes[0].bytesPerRow,
        ),
      );

      final faces = await faceDetector!.processImage(inputImage);

      if (faces.length > 1) {
        predictions.clear();
        faceBoundingBox.value = null;
        detectionMessage.value = 'There can be no more than 1 face detected';
        isBusy.value = false;
        return;
      } else if (faces.isEmpty) {
        predictions.clear();
        faceBoundingBox.value = null;
        detectionMessage.value = 'No faces detected';
        isBusy.value = false;
        return;
      }

      detectionMessage.value = null;
      final face = faces.first;
      final rect = face.boundingBox;
      faceBoundingBox.value = rect;

      final img.Image? rgbImage = await compute(convertCameraImage, currentFrame!);
      if (rgbImage == null) {
        isBusy.value = false;
        return;
      }

      final cropped = img.copyCrop(
        rgbImage,
        x: rect.left.toInt().clamp(0, rgbImage.width - 1),
        y: rect.top.toInt().clamp(0, rgbImage.height - 1),
        width: rect.width.toInt().clamp(1, rgbImage.width),
        height: rect.height.toInt().clamp(1, rgbImage.height),
      );

      final resized = img.copyResize(cropped, width: 224, height: 224);
      final input = preprocess(resized);
      final output = List<List<double>>.generate(1, (_) => List.filled(3, 0.0));

      interpreter!.run(input, output);

      final scores = output[0];
      final maxScore = scores.reduce(max);
      final maxIndex = scores.indexOf(maxScore);
      final labels = ['Drowsy', 'Neutral', 'Distracted'];

      String resultLabel = labels[maxIndex];
      int resultIndex = maxIndex;

      if ((maxIndex == 0 || maxIndex == 2) && maxScore > 0.8) {
        resultLabel = 'Neutral';
        resultIndex = 1;
      }

      predictions.assignAll([resultLabel]);

      await DatabaseHelper.instance.insertDetection({
        'feature': resultIndex,
        'detect': resultLabel,
        'percentage': (maxScore * 100).toStringAsFixed(1),
        'date': DateFormat('yyyy-MM-dd').format(now),
        'time': DateFormat('HH:mm:ss').format(now),
        'timestamp': now.toIso8601String(),
      });

      if (now.difference(lastAlertTime) >= const Duration(seconds: 10)) {
        lastAlertTime = now;
        final player = AudioPlayer();
        final index = Random().nextInt(2) + 1;

        if (resultLabel == 'Drowsy') {
          await player.play(AssetSource('alert/drowsy_$index.mp3'));
        } else if (resultLabel == 'Distracted') {
          await player.play(AssetSource('alert/distracted_$index.mp3'));
        }
      }

      isBusy.value = false;
    } catch (e) {
      debugPrint('[ERROR] detectFaceAndPredict: $e');
      isBusy.value = false;
    }
  }

  List<List<List<List<double>>>> preprocess(img.Image image) {
    return [
      List.generate(224, (y) =>
        List.generate(224, (x) {
          final pixel = image.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        })
      )
    ];
  }

  img.Image convertCameraImage(CameraImage image) {
    if (image.format.group != ImageFormatGroup.yuv420) {
      throw Exception("Unsupported image format: \${image.format.group}");
    }

    final width = image.width;
    final height = image.height;
    final imgImage = img.Image(width: width, height: height);

    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final int yIndex = y * image.planes[0].bytesPerRow + x;

        final int yVal = image.planes[0].bytes[yIndex];
        final int uVal = image.planes[1].bytes[uvIndex];
        final int vVal = image.planes[2].bytes[uvIndex];

        final int r = (yVal + 1.370705 * (vVal - 128)).clamp(0, 255).toInt();
        final int g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128)).clamp(0, 255).toInt();
        final int b = (yVal + 1.732446 * (uVal - 128)).clamp(0, 255).toInt();

        imgImage.setPixelRgb(x, y, r, g, b);
      }
    }

    var rotated = img.copyRotate(imgImage, angle: 270);
    return img.flipHorizontal(rotated);
  }

  Rect scaleRectToScreen(Rect rect) {
    if (cameraPreviewSize == null || screenSize == null) return rect;
    final double previewWidth = cameraPreviewSize!.height;
    final double previewHeight = cameraPreviewSize!.width;
    final double screenWidth = screenSize!.width;
    final double screenHeight = screenSize!.height;
    final double scaleX = screenWidth / previewWidth;
    final double scaleY = screenHeight / previewHeight;

    double left = screenWidth - (rect.left + rect.width) * scaleX;
    double top = rect.top * scaleY;
    double width = rect.width * scaleX;
    double height = rect.height * scaleY;

    const double marginFactor = 0.3;
    final double deltaWidth = width * marginFactor;
    final double deltaHeight = height * marginFactor;

    left = (left - deltaWidth / 2).clamp(0, screenWidth);
    top = (top - deltaHeight / 2 - 70).clamp(0, screenHeight);
    width = (width + deltaWidth).clamp(0, screenWidth - left);
    height = (height + deltaHeight).clamp(0, screenHeight - top);

    return Rect.fromLTWH(left, top, width, height);
  }

  Future<void> disposeResources() async {
    isDisposed.value = true;
    await cameraController?.stopImageStream();
    await cameraController?.dispose();
    await faceDetector?.close();
    interpreter?.close();
  }
}