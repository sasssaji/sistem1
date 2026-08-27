import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/scan_result.dart';

class ScanResultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveScanResult(ScanResult result) async {
    try {
      await _firestore
          .collection('scan_results')
          .doc(result.id)
          .set(result.toMap());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return;
      }
      rethrow;
    }
  }

  Future<List<ScanResult>> fetchResults() async {
    try {
      final snapshot = await _firestore
          .collection('scan_results')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ScanResult.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return [];
      }
      rethrow;
    }
  }
}
