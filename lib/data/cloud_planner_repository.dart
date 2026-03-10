import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/planner_data.dart';

class CloudPlannerRepository {
  final FirebaseFirestore db;
  CloudPlannerRepository(this.db);

  DocumentReference<Map<String, dynamic>> _doc(String uid) => db
      .collection('users')
      .doc(uid)
      .collection('planner')
      .doc('main');

  Future<PlannerData?> load(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    final payload = data['data'];
    if (payload is Map) {
      return PlannerData.fromJson(Map<String, dynamic>.from(payload));
    }
    return null;
  }

  Stream<PlannerData?> watch(String uid) {
    return _doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      final payload = data['data'];
      if (payload is Map) {
        return PlannerData.fromJson(Map<String, dynamic>.from(payload));
      }
      return null;
    });
  }

  Future<void> save(String uid, PlannerData plannerData) async {
    await _doc(uid).set(
      {
        'schema': 2,
        'updatedAt': FieldValue.serverTimestamp(),
        'data': plannerData.toJson(),
      },
      SetOptions(merge: true),
    );
  }
}