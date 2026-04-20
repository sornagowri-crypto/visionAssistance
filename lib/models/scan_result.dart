// ─────────────────────────────────────────────────────────────────────────────
// scan_result.dart — Data model for a single object scan
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

class ScanResult {
  final String id;
  final String imageUrl;     // Firebase Storage URL (empty if offline)
  final String localPath;    // Local file path for offline display
  final String description;  // Full AI description text
  final String objectName;   // Extracted object name
  final DateTime timestamp;
  final bool isOffline;      // true = MLKit result, false = Gemini result
  final String userId;       // Firebase Auth UID

  const ScanResult({
    required this.id,
    required this.imageUrl,
    required this.localPath,
    required this.description,
    required this.objectName,
    required this.timestamp,
    required this.isOffline,
    required this.userId,
  });

  // ── Factory from Firestore document ─────────────────────────────────────────
  factory ScanResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScanResult(
      id:          doc.id,
      imageUrl:    data['imageUrl']   as String? ?? '',
      localPath:   data['localPath']  as String? ?? '',
      description: data['description'] as String? ?? '',
      objectName:  data['objectName'] as String? ?? 'Unknown Object',
      timestamp:   (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOffline:   data['isOffline']  as bool? ?? false,
      userId:      data['userId']     as String? ?? '',
    );
  }

  // ── To Firestore map ─────────────────────────────────────────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl':    imageUrl,
      'localPath':   localPath,
      'description': description,
      'objectName':  objectName,
      'timestamp':   Timestamp.fromDate(timestamp),
      'isOffline':   isOffline,
      'userId':      userId,
    };
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Returns a short excerpt of the description for list tiles
  String get shortDescription {
    if (description.length <= 80) return description;
    return '${description.substring(0, 80)}…';
  }

  /// Returns the display label shown in the history list
  String get displayLabel => isOffline ? '$objectName (offline)' : objectName;

  ScanResult copyWith({
    String? id,
    String? imageUrl,
    String? localPath,
    String? description,
    String? objectName,
    DateTime? timestamp,
    bool? isOffline,
    String? userId,
  }) {
    return ScanResult(
      id:          id          ?? this.id,
      imageUrl:    imageUrl    ?? this.imageUrl,
      localPath:   localPath   ?? this.localPath,
      description: description ?? this.description,
      objectName:  objectName  ?? this.objectName,
      timestamp:   timestamp   ?? this.timestamp,
      isOffline:   isOffline   ?? this.isOffline,
      userId:      userId      ?? this.userId,
    );
  }

  @override
  String toString() =>
      'ScanResult(id: $id, object: $objectName, offline: $isOffline)';
}
