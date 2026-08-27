import 'package:cloud_firestore/cloud_firestore.dart';

class ScanResult {
  ScanResult({
    required this.id,
    required this.shellName,
    required this.prediction,
    required this.confidence,
    required this.label,
    required this.filename,
    required this.imageUrl,
    required this.createdAt,
    required this.rawResponse,
  });

  final String id;
  final String shellName;
  final String prediction;
  final double confidence;
  final String label;
  final String filename;
  final String imageUrl;
  final DateTime createdAt;
  final Map<String, dynamic> rawResponse;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shell_name': shellName,
      'prediction': prediction,
      'confidence': confidence,
      'label': label,
      'filename': filename,
      'image_url': imageUrl,
      'created_at': Timestamp.fromDate(createdAt),
      'raw_response': rawResponse,
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'] ?? '',
      shellName: map['shell_name'] ?? '',
      prediction: map['prediction'] ?? '',
      confidence: (map['confidence'] is num)
          ? (map['confidence'] as num).toDouble()
          : 0.0,
      label: map['label'] ?? '',
      filename: map['filename'] ?? '',
      imageUrl: map['image_url'] ?? '',
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      rawResponse: Map<String, dynamic>.from(map['raw_response'] ?? {}),
    );
  }
}
