import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateStageStatus(String detailId, String stageName, String status, String employeeId) async {
    try {
      final detailRef = _firestore.collection('details').doc(detailId);

      DocumentSnapshot docSnapshot = await detailRef.get();
      var detailData = docSnapshot.data() as Map<String, dynamic>;

      var steps = detailData['steps'] as List<dynamic>;

      for (var step in steps) {
        if (step['name'] == stageName) {
          step['status'] = status;
          step['employee'] = employeeId; 
        }
      }

      bool allStagesCompleted = steps.every((step) => step['status'] == 'Completed');

      if (allStagesCompleted && detailData['status'] != 'Completed') {
        await detailRef.update({'status': 'Completed'});
      } else if (!allStagesCompleted && detailData['status'] != 'in_progress') {
        await detailRef.update({'status': 'in_progress'});
      }

      await detailRef.update({'steps': steps});

    } catch (e) {
      throw Exception('Ошибка при обновлении статуса этапа: $e');
    }
  }

  Future<Map<String, dynamic>?> getDetailInfo(String detailId) async {
    try {
      final docSnapshot = await _firestore.collection('details').doc(detailId).get();
      return docSnapshot.exists ? docSnapshot.data() : null;
    } catch (e) {
      throw Exception('Ошибка при получении данных: $e');
    }
  }

  Future<Map<String, dynamic>?> getTemplateInfo(String templateId) async {
    try {
      final docSnapshot = await _firestore.collection('product_templates').doc(templateId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Ошибка при получении данных о шаблоне: $e');
    }
  }
}
