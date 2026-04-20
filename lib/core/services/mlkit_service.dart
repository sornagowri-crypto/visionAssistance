// ─────────────────────────────────────────────────────────────────────────────
// mlkit_service.dart — Offline object detection using Google MLKit
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import '../constants.dart';
import 'gemini_service.dart';

class MlKitService {
  MlKitService._();
  static final MlKitService instance = MlKitService._();

  ObjectDetector? _detector;

  // ── Initialisation ────────────────────────────────────────────────────────────

  Future<void> _ensureInitialised() async {
    if (_detector != null) return;
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    );
    _detector = ObjectDetector(options: options);
  }

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Detects objects in [imageFile] using on-device MLKit.
  /// Returns a [GeminiResult] shaped result (same model, isOffline=true).
  Future<MlKitResult> detect(File imageFile) async {
    await _ensureInitialised();

    final inputImage = InputImage.fromFile(imageFile);

    late List<DetectedObject> objects;
    try {
      objects = await _detector!.processImage(inputImage);
    } catch (e) {
      throw MlKitException('MLKit detection failed: $e');
    }

    if (objects.isEmpty) {
      return MlKitResult(
        objectName: 'Unrecognised Object',
        description:
            'I could not identify what I see. '
            'Please ensure the object is well lit and in frame, '
            'then try scanning again.',
        labels: [],
      );
    }

    // Collect all labels across all detected objects
    final allLabels = <String>[];
    for (final obj in objects) {
      for (final label in obj.labels) {
        if (label.confidence > 0.5) {
          allLabels.add(label.text);
        }
      }
    }

    final primaryLabel = allLabels.isNotEmpty ? allLabels.first : 'Object';
    final secondary = allLabels.length > 1
        ? allLabels.skip(1).take(3).join(', ')
        : '';

    final description = _buildOfflineDescription(primaryLabel, secondary);

    return MlKitResult(
      objectName: primaryLabel,
      description: description,
      labels: allLabels,
    );
  }

  String _buildOfflineDescription(String primary, String secondary) {
    final sb = StringBuffer();
    sb.write('I can see what appears to be $primary. ');
    if (secondary.isNotEmpty) {
      sb.write('It may also be related to $secondary. ');
    }
    sb.write(
      'This is an offline identification and may not be fully accurate. '
      'Connect to the internet for a detailed AI description.',
    );
    return sb.toString();
  }

  Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
  }
}

// ── Result ────────────────────────────────────────────────────────────────────

class MlKitResult {
  final String objectName;
  final String description;
  final List<String> labels;

  const MlKitResult({
    required this.objectName,
    required this.description,
    required this.labels,
  });
}

// ── Exception ─────────────────────────────────────────────────────────────────

class MlKitException implements Exception {
  final String message;
  const MlKitException(this.message);

  @override
  String toString() => 'MlKitException: $message';
}
