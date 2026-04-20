// ─────────────────────────────────────────────────────────────────────────────
// gemini_service.dart — Google Gemini Vision API integration
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants.dart';

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Sends [imageFile] to Gemini Vision and returns a structured description.
  /// Throws [GeminiException] on API or network errors.
  Future<GeminiResult> describe(File imageFile) async {
    // 1. Validate API key
    if (kGeminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw GeminiException(
        'Gemini API key not configured. '
        'Please set kGeminiApiKey in lib/core/constants.dart. '
        'Get a free key at https://aistudio.google.com/app/apikey',
      );
    }

    // 2. Encode image to base64
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    final mimeType = _mimeTypeFromExtension(imageFile.path);

    // 3. Build request body
    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              },
            },
            {
              'text': kGeminiPrompt,
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 256,
      },
    });

    // 4. Call Gemini API
    final uri = Uri.parse('$kGeminiBaseUrl?key=$kGeminiApiKey');

    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw GeminiException('No internet connection. Please check your network.');
    } on http.ClientException catch (e) {
      throw GeminiException('Network error: ${e.message}');
    } catch (e) {
      throw GeminiException('Request failed: $e');
    }

    // 5. Parse response
    if (response.statusCode == 200) {
      return _parseResponse(response.body);
    } else if (response.statusCode == 429) {
      throw GeminiException('API rate limit reached. Please wait a moment and try again.');
    } else if (response.statusCode == 403) {
      throw GeminiException('Invalid Gemini API key. Please check your key in constants.dart.');
    } else {
      final error = _extractError(response.body);
      throw GeminiException('Gemini API error (${response.statusCode}): $error');
    }
  }

  // ── Private Helpers ───────────────────────────────────────────────────────────

  GeminiResult _parseResponse(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw GeminiException('No description received from Gemini. Try again.');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final rawText = (parts?[0]['text'] as String? ?? '').trim();

      if (rawText.isEmpty) {
        throw GeminiException('Empty description received. The image may be unclear.');
      }

      return GeminiResult.fromRawText(rawText);
    } on GeminiException {
      rethrow;
    } catch (e) {
      throw GeminiException('Failed to parse Gemini response: $e');
    }
  }

  String _extractError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['error']?['message'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }

  String _mimeTypeFromExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

// ── Result Model ─────────────────────────────────────────────────────────────

class GeminiResult {
  final String objectName;
  final String appearance;
  final String use;
  final String safety;
  final String fullDescription;

  const GeminiResult({
    required this.objectName,
    required this.appearance,
    required this.use,
    required this.safety,
    required this.fullDescription,
  });

  /// Parses the structured response format returned by the prompt.
  factory GeminiResult.fromRawText(String raw) {
    String objectName = 'Unknown Object';
    String appearance = '';
    String use = '';
    String safety = 'No safety concerns.';

    // Extract each labelled section
    final objectMatch = RegExp(r'OBJECT:\s*(.+)', caseSensitive: false).firstMatch(raw);
    final appearMatch = RegExp(r'APPEARANCE:\s*(.+)', caseSensitive: false).firstMatch(raw);
    final useMatch    = RegExp(r'USE:\s*(.+)', caseSensitive: false).firstMatch(raw);
    final safetyMatch = RegExp(r'SAFETY:\s*(.+)', caseSensitive: false).firstMatch(raw);

    if (objectMatch != null) objectName = objectMatch.group(1)?.trim() ?? objectName;
    if (appearMatch != null) appearance = appearMatch.group(1)?.trim() ?? appearance;
    if (useMatch    != null) use        = useMatch.group(1)?.trim() ?? use;
    if (safetyMatch != null) safety     = safetyMatch.group(1)?.trim() ?? safety;

    // If parsing fails, use the whole raw text
    final hasStructure = objectMatch != null || appearMatch != null;
    final fullDescription = hasStructure
        ? '$objectName. $appearance $use $safety'.trim()
        : raw;

    return GeminiResult(
      objectName:      objectName,
      appearance:      appearance,
      use:             use,
      safety:          safety,
      fullDescription: fullDescription.isEmpty ? raw : fullDescription,
    );
  }

  /// TTS-optimised spoken version of the description
  String get spokenDescription =>
      'I can see $objectName. '
      '${appearance.isNotEmpty ? "It $appearance" : ""} '
      '${use.isNotEmpty ? "It is used for $use" : ""} '
      '${safety != "No safety concerns." ? "Safety note: $safety" : ""}';
}

// ── Exception ─────────────────────────────────────────────────────────────────

class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);

  @override
  String toString() => 'GeminiException: $message';
}
