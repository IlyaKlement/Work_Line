import 'package:cloud_firestore/cloud_firestore.dart';

class KPIStatsCalculator {
  final List<Map<String, dynamic>> rows;

  KPIStatsCalculator(this.rows);

  List<String> getEmployees() {
    return rows.map((row) => row[''] as String).toSet().toList();
  }


  Future<Map<String, int>> calculateCompletedStagesForEmployee({
  required DateTime start,
  required DateTime end,
}) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('details')
      .get();

  final Map<String, int> stepsCountPerEmployee = {};

  for (final doc in querySnapshot.docs) {
    final data = doc.data();
    final steps = data['steps'] as List<dynamic>?;

    if (steps != null) {
      for (final step in steps) {
        if (step['status'] == 'Completed' &&
            step['employee_name'] != null &&
            step['completed_at'] != null) {
          final timestamp = (step['completed_at'] as Timestamp).toDate();
          if (timestamp.isAfter(start) && timestamp.isBefore(end)) {
            final name = step['employee_name'];
            stepsCountPerEmployee[name] =
                (stepsCountPerEmployee[name] ?? 0) + 1;
          }
        }
      }
    }
  }

  return stepsCountPerEmployee;
}



  Future<Map<String, int>> calculateDefectsByEmployee(DateTime start, DateTime end) async {

  final querySnapshot = await FirebaseFirestore.instance
    .collection('details')
    .get(); 
  final Map<String, int> defectsCount = {};

  for (final doc in querySnapshot.docs) {
    final steps = doc['steps'] as List<dynamic>? ?? [];

    for (final step in steps) {
      final defectHistory = step['defect_history'] as List<dynamic>? ?? [];

      for (final defect in defectHistory) {
        final defectTimestamp = (defect['defect_timestamp'] as Timestamp?)?.toDate();
        final employeeName = defect['defected_by_name'] ?? 'Без имени';

        if (defectTimestamp != null &&
            defectTimestamp.isAfter(start.subtract(const Duration(seconds: 1))) &&
            defectTimestamp.isBefore(end.add(const Duration(seconds: 1)))) {
          defectsCount.update(employeeName, (count) => count + 1, ifAbsent: () => 1);
        }
      }
    }
  }

  return defectsCount;
}

Future<Map<String, Map<DateTime, double>>> workHoursByDayMapFromMapList(
  List<Map<String, String>> mapList,
) async {
  final result = <String, Map<DateTime, double>>{};

  if (mapList.isEmpty) return result;

  final headerKeys = mapList.first.keys.where((k) {
  final dateRegex = RegExp(r'^\d{2}\.\d{2}\.\d{4}$');
  return dateRegex.hasMatch(k);
  }).toList();


  for (final row in mapList) {
    final name = row['']?.trim();
    if (name == null || name.isEmpty) continue;

    final employeeHours = <DateTime, double>{};

    for (final key in headerKeys) {
      try {
        final dateParts = key.split('.');
        final date = DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
        );
        final rawValue = row[key] ?? '';
        final hours = _calculateTotalHoursFromCell(rawValue);
        employeeHours[date] = hours;
      } catch (_) {
        continue;
      }
    }

    result[name] = employeeHours;
  }

  return result;
}


double _calculateTotalHoursFromCell(String cell) {
  if (cell == '0' || cell.isEmpty) return 0.0;

  final cleanedCell = cell.replaceAll('.', ':');
  final parts = cleanedCell.split(';');
  double totalHours = 0.0;

  for (final part in parts) {
    final times = part.split('-');
    if (times.length != 2) continue;

    final time = parseTimeRange(part);

    totalHours += time;
    
  }

  return totalHours;
}

double parseTimeRange(String input) {
  if (input.trim().isEmpty || input.trim() == '0') return 0;

  try {
    final parts = input.split('-');
    if (parts.length != 2) return 0;

    double parsePart(String part) {
      part = part.trim().replaceAll(',', '.');
      if (part.contains(':')) {
        final timeParts = part.split(':');
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        return hour + minute / 60;
      } else {
        return double.tryParse(part) ?? 0;
      }
    }

    final start = parsePart(parts[0]);
    final end = parsePart(parts[1]);
    if (end < start) return 0;

    return end - start;
  } catch (e) {
    return 0;
  }
}

DateTime _parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}



Future<Map<String, Map<String, dynamic>>> calculateKPIForDateRange(
    DateTime startDate,
    DateTime endDate,
    Map<String, Map<DateTime, double>> workHoursByDayMap,
) async {
  final firestore = FirebaseFirestore.instance;
  final result = <String, Map<String, dynamic>>{};

  final querySnapshot = await firestore
      .collection('details')
      .where('steps', isGreaterThan: [])
      .get();

  for (var doc in querySnapshot.docs) {
    final data = doc.data();
    final steps = List<Map<String, dynamic>>.from(data['steps'] ?? []);

    for (var step in steps) {
      final defectHistory = step['defect_history'] as List<dynamic>? ?? [];
      final completedAt = (step['completed_at'] as Timestamp?)?.toDate();
      final employeeName = step['employee_name'] as String?;

      for (var defect in defectHistory) {
      final defectTime = (defect['defect_timestamp'] as Timestamp?)?.toDate();
      final defectedBy = defect['defected_by_name'] as String?;
      final detectedBy = defect['defected_by_name'] as String?;

      if (defectTime != null &&
          !defectTime.isBefore(startDate) &&
          !defectTime.isAfter(endDate) &&
          defectedBy != null) {
        final dayKey = _formatDate(defectTime);
        final isSameFixer = defectedBy == detectedBy;
        final defectCoeff = isSameFixer ? 1.0 : 1.2;

        result.putIfAbsent(dayKey, () => {});
        final dayData = result[dayKey]!;


        dayData.putIfAbsent(defectedBy, () => {
              'totalCompleted': 0,
              'totalDefects': 0,
              'workedHours': workHoursByDayMap[defectedBy]?[_parseDateKey(dayKey)] ?? 100.0,
              'coefficientSum': 0.0,
            });

        dayData[defectedBy]['totalDefects'] += 1;
        dayData[defectedBy]['coefficientSum'] -= defectCoeff;
      }
    }
      

      if (completedAt != null &&
          employeeName != null &&
          !completedAt.isBefore(startDate) &&
          !completedAt.isAfter(endDate)) {
        final dayKey = _formatDate(completedAt);
        final coefficient = double.tryParse(step['coefficient'].toString()) ?? 1.0;

        result.putIfAbsent(dayKey, () => {});
        final dayData = result[dayKey]!;

        dayData.putIfAbsent(employeeName, () => {
              'totalCompleted': 0,
              'totalDefects': 0,
              'workedHours': workHoursByDayMap[employeeName]?[_parseDateKey(dayKey)] ?? 0.0,
              'coefficientSum': 0.0,
            });

        dayData[employeeName]['totalCompleted'] += 1;
        dayData[employeeName]['coefficientSum'] += coefficient;
      }
    }

    
  }

  result.forEach((day, employees) {
    employees.forEach((employeeName, data) {
      final hours = data['workedHours'] as double;
      final coeff = data['coefficientSum'] as double;
      final kpi = hours > 0 ? (coeff / hours) : 0.0;
      data['effectiveKpi'] = double.parse(kpi.toStringAsFixed(2));
    });
  });

  return result;
}

String _formatDate(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';


}
