import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class KpiStatisticsPage extends StatefulWidget {
  const KpiStatisticsPage({super.key});

  @override
  _KpiStatisticsPageState createState() => _KpiStatisticsPageState();
}

class _KpiStatisticsPageState extends State<KpiStatisticsPage> {
  String? selectedEmployeeId;
  String? selectedEmployeeName;
  Future<List<StageData>>? _stagesFuture;
  DateTimeRange? selectedDateRange;
  double? workedHours; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Статистика сотрудников"),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmployeeDropdown(),
            const SizedBox(height: 20),
            _buildDateFilter(),
            const SizedBox(height: 20),
            if (selectedEmployeeId != null)
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStatsView(),
                ),
              )

            else
              const Center(child: Text("Выберите сотрудника", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeDropdown() {
  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance.collection('users').get(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const CircularProgressIndicator();

      final employeeItems = snapshot.data!.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final lastName = data['last_name'] ?? "Без имени";
        return DropdownMenuItem<String>(
          value: doc.id,
          child: Text(
            lastName,
            style: const TextStyle(fontSize: 16),
          ),
        );
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              "Сотрудник",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          DropdownButtonFormField<String>(
            value: selectedEmployeeId,
            decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
            isExpanded: true,
            hint: const Text("Выберите сотрудника", style: TextStyle(fontSize: 16)),
            items: employeeItems,
            onChanged: (newValue) async {
              setState(() {
                selectedEmployeeId = newValue;
                selectedEmployeeName = "Без имени";
                try {
                  selectedEmployeeName = (snapshot.data!.docs
                          .firstWhere((doc) => doc.id == newValue)
                          .data() as Map<String, dynamic>)['last_name'] ?? "Без имени";
                } catch (_) {
                  selectedEmployeeName = "Без имени";
                }
              });

              _stagesFuture = fetchStages(selectedEmployeeId!, selectedDateRange);
            },
          ),
        ],
      );
    },
  );
}


  Widget _buildDateFilter() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: Text(
          'Период',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
              DateTimeRange? pickedRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (pickedRange != null) {
                setState(() {
                  selectedDateRange = pickedRange;
                  if (selectedEmployeeId != null) {
                    _stagesFuture = fetchStages(selectedEmployeeId!, selectedDateRange);
                  }
                });
              }
            },
              style: OutlinedButton.styleFrom( 
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.calendar_today, size: 18, color: Colors.red),
              label: const Text(
                'Выбрать даты',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
              ),
            ),
            const SizedBox(width: 12),
            if (selectedDateRange != null)
              Expanded(
                child: Text(
                  '${DateFormat('dd.MM.yyyy').format(selectedDateRange!.start)} – ${DateFormat('dd.MM.yyyy').format(selectedDateRange!.end)}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}





 Widget _buildStatsView() {
  return FutureBuilder<List<StageData>>(
    future: _stagesFuture,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      if (snapshot.data!.isEmpty) {
        return const Center(child: Text("Нет данных для выбранного сотрудника и периода"));
      }

      List<StageData> stages = snapshot.data!;
      Map<String, Map<String, StageSummary>> groupedData = groupStages(stages);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Сотрудник: $selectedEmployeeName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Divider(),
          _buildTotalStats(stages),
          ...groupedData.entries.map((product) => _buildProductItem(product.key, product.value)),
        ],
      );
    },
  );
}



  Widget _buildProductItem(String productName, Map<String, StageSummary> stages) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          productName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: stages.entries.map((entry) {
          String stageName = entry.key;
          StageSummary summary = entry.value;

          return ListTile(
            title: Text(stageName, style: const TextStyle(fontSize: 16)),
            subtitle: Text(
              "Выполнено: ${summary.completedCount} | Брак: ${summary.defectCount}",
              style: TextStyle(color: Colors.black),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalStats(List<StageData> stages) {
    int totalCompleted = stages.length;
    int totalDefects = stages.fold(0, (sum, stage) => sum + stage.defectCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Общее количество выполненных этапов: $totalCompleted", style: const TextStyle(fontSize: 16)),
        Text("Общий брак: $totalDefects", style: const TextStyle(fontSize: 16, color: Colors.red)),
        const Divider(),
      ],
    );
  }

  Future<List<StageData>> fetchStages(String employeeId, DateTimeRange? dateRange) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('details')
        .get();

    List<StageData> allStages = [];

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var steps = (data['steps'] as List<dynamic>?) ?? [];

      for (var step in steps) {
        var stepData = step as Map<String, dynamic>;

        if (stepData['employee_id'] == employeeId && stepData['status'] == "Completed") {
          Timestamp? timestamp = stepData['completed_at'] as Timestamp?;

          if (timestamp == null) continue;
          DateTime stepDate = timestamp.toDate();

          if (dateRange != null) {
            DateTime stepDateOnly = DateTime(stepDate.year, stepDate.month, stepDate.day);
            DateTime startDateOnly = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
            DateTime endDateOnly = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);

            if (stepDateOnly.isBefore(startDateOnly) || stepDateOnly.isAfter(endDateOnly)) {
              continue;
            } 
          }

          allStages.add(StageData.fromMap(stepData, data['detail_name'] ?? "Без названия"));
        }
      }
    }

    debugPrint('Total stages: ${allStages.length}');
    return allStages;
  }

  double parseWorkedHours(String time) {
    if (time == "0") return 0.0;
    
    List<String> parts = time.split('-');
    if (parts.length == 2) {
      double start = parseTime(parts[0]);
      double end = parseTime(parts[1]);
      if (end < start) end += 24; 
      return end - start;
    }
    return 0.0;
  }

  double parseTime(String timeStr) {
    List<String> parts = timeStr.split(':');
    double hours = double.parse(parts[0]);
    double minutes = parts.length > 1 ? double.parse(parts[1]) / 60.0 : 0.0;
    return hours + minutes;
  }

  Map<String, Map<String, StageSummary>> groupStages(List<StageData> stages) {
    Map<String, Map<String, StageSummary>> groupedData = {};

    for (var stage in stages) {
      String productName = stage.templateName;
      String stageName = stage.stageName;

      groupedData.putIfAbsent(productName, () => {});
      groupedData[productName]!.putIfAbsent(stageName, () => StageSummary());

      groupedData[productName]![stageName]!.completedCount++;
      groupedData[productName]![stageName]!.defectCount += stage.defectCount;
    }

    return groupedData;
  }
}


class StageData {
  final String stageName;
  final String status;
  final double coefficient;
  final String templateName;
  final int defectCount;

  StageData({
    required this.stageName,
    required this.status,
    required this.coefficient,
    required this.templateName,
    required this.defectCount,
  });

  factory StageData.fromMap(Map<String, dynamic> map, String templateName) {
  final defectHistory = map['defect_history'];
  int defectCount = 0;

  if (defectHistory is List) {
    defectCount = defectHistory.length;
  }

  return StageData(
    stageName: map['stage_name'] ?? 'Неизвестно',
    status: map['status'] ?? 'Неизвестно',
    coefficient: (map['coefficient'] is num) 
        ? (map['coefficient'] as num).toDouble() 
        : double.tryParse(map['coefficient'].toString()) ?? 1.0,
    templateName: templateName,
    defectCount: defectCount,
  );
}

}
class StageSummary {
  int completedCount = 0;
  int defectCount = 0;
}
