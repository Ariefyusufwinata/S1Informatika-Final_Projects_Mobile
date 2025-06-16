import 'dart:typed_data';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ExpressionClassifier {
  late Interpreter _interpreter;
  final int inputSize = 224;
  final List<String> labels = ['drowsy', 'neutral', 'distracted'];

  ExpressionClassifier(String modelPath) {
    _loadModel(modelPath);
  }

  void _loadModel(String modelPath) async {
    _interpreter = await Interpreter.fromAsset(modelPath);
  }

  Float32List _preprocess(img.Image image) {
    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    final Float32List buffer = Float32List(inputSize * inputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return buffer;
  }

  Future<String> predict(img.Image faceImage) async {
    final input = _preprocess(faceImage).reshape([1, inputSize, inputSize, 3]);
    final output = List.filled(3, 0.0).reshape([1, 3]);

    _interpreter.run(input, output);

    final scores = output[0];
    final maxIdx = scores.indexOf(scores.reduce(max));
    return labels[maxIdx];
  }
}
class Recognition {
  final String label;
  final double score;

  Recognition({required this.label, required this.score});
}
