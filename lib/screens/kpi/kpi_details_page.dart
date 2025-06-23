import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:work_line/google_sheets_service.dart';
import 'package:work_line/screens/kpi/kpi_calculator.dart';
import 'package:work_line/screens/kpi/kpi_reports_page.dart';

class KpiDetailsPage extends StatefulWidget {
  const KpiDetailsPage({super.key});

  @override
  State<KpiDetailsPage> createState() => _KpiDetailsPageState();
}

class _KpiDetailsPageState extends State<KpiDetailsPage> with SingleTickerProviderStateMixin {
  final sheetsService = GoogleSheetsService();
  List<Map<String, String>> rows = [];
  DateTimeRange? _selectedDateRange; 
  late TabController _tabController; 

  Map<String, int> completeStages = {};
  bool isLoadingStages = true;

  Map<String, int> defectsStages = {};
  bool isLoadingDefects = false;

  Map<String, Map<String, dynamic>> kpiStages = {};
  bool isLoadingKpi = false;

  final List<String> sortOptions = ['По алфавиту: A–Я', 'По алфавиту: Я–A'];

  List<String> allDepartments = [];
  String? selectedDepartment;

 
  List<String> monthsList = [
    'ЯНВАРЬ 25', 'ФЕВРАЛЬ 25', 'МАРТ 25', 'АПРЕЛЬ 25', 'МАЙ 25',
  ];

  String? _selectedMonthString; 

  @override
  void initState() {
    super.initState();
    fetchDepartments();
    _tabController = TabController(length: 2, vsync: this);
    _selectedMonthString = monthsList[3]; 
    _loadData();
    
  }

  Future<void> _loadCompletedStages({required DateTime start, required DateTime end}) async {
  final calculator = KPIStatsCalculator(rows);
  final resultCompleteStages = await calculator.calculateCompletedStagesForEmployee(start: start, end: end);
  final resultDefectsStages = await calculator.calculateDefectsByEmployee(start, end);

  final tmp = await calculator.workHoursByDayMapFromMapList(rows);

  final resultKpiStages = await calculator.calculateKPIForDateRange(start, end, tmp);
  setState(() {
    completeStages = resultCompleteStages;
    isLoadingStages = false;
    defectsStages = resultDefectsStages;
    kpiStages = resultKpiStages;
  });
}


  Future<void> _loadData() async {
    final rawRows = await sheetsService.getRows(_selectedMonthString!);

    if (rawRows.isEmpty) return;

    final headers = rawRows.first.keys.toList();

    
    final today = DateTime.now();
    

    final filteredColumns = headers.where((header) {
      final index = headers.indexOf(header);
      if (index < 3) return true; 

      try {
        final parsedDate = DateFormat('dd.MM.yyyy').parseStrict(header);
        return parsedDate.isBefore(today) || _isSameDate(parsedDate, today);
      } catch (e) {
        return false;
      }
    }).toList();

    final filteredRows = rawRows.map((row) {
      final newRow = <String, String>{};
      for (final key in filteredColumns) {
        newRow[key] = row[key] ?? '';
      }
      return newRow;
    }).toList();

    setState(() {
      rows = filteredRows;
    });
  }

  bool _isSameDate(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  double _parseHours(String? value) {
  if (value == null || value.trim() == '' || value == '0') return 0;

  try {
    final parts = value.split('-');
    if (parts.length != 2) return 0;

    final startRaw = parts[0].trim().replaceAll('.', ':');
    final endRaw = parts[1].trim().replaceAll('.', ':');

    final start = _parseTime(startRaw);
    final end = _parseTime(endRaw);

    final diff = end.difference(start);
    final hours = diff.inMinutes / 60;

    if (hours < 0) {
      debugPrint('⚠️ Отрицательная разница времени: $value → $startRaw - $endRaw → $hours ч');
      return 0;
    }

    return hours;
  } catch (e) {
    debugPrint('⚠️ Ошибка при обработке времени "$value": $e');
    return 0;
  }
}


  DateTime _parseTime(String time) {
  if (time.trim().isEmpty || time == '0') {
    return DateFormat.Hm().parse('00:00');
  }

  String numeric = time.replaceAll(RegExp(r'[^\d]'), '');

  if (numeric.length == 1 || numeric.length == 2) {
    numeric = '$numeric:00';
  } else if (numeric.length == 3) {
    numeric = '0${numeric.substring(0, 1)}:${numeric.substring(1)}';
  } else if (numeric.length == 4) {
    numeric = '${numeric.substring(0, 2)}:${numeric.substring(2)}';
  }

  if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(numeric)) {
    debugPrint('⚠️ Невозможно преобразовать "$time" в формат времени, используем 00:00');
    return DateFormat.Hm().parse('00:00');
  }

  try {
    final parts = numeric.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      debugPrint('⚠️ Недопустимое значение времени "$numeric": час=$hour, минута=$minute');
      return DateFormat.Hm().parse('00:00');
    }

    return DateFormat.Hm().parseStrict(numeric);
  } catch (e) {
    debugPrint('⚠️ Ошибка при парсинге времени "$numeric": $e');
    return DateFormat.Hm().parse('00:00');
  }
}


  DateTime _parseDate(String dateStr) {
    return DateFormat('dd.MM.yyyy').parse(dateStr);
  }

  bool _isDateColumn(String column) {
    final regex = RegExp(r'\d{2}\.\d{2}\.\d{4}');
    return regex.hasMatch(column);
  }

  void _selectDateRange() async {
  final now = DateTime.now();
  final firstDayOfMonth = DateTime(now.year, now.month, 1);
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

  final picked = await showDateRangePicker(
    context: context,
    firstDate: firstDayOfMonth,
    lastDate: lastDayOfMonth,
    initialDateRange: _selectedDateRange ??
        DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth),
  );

  if (picked != null) {
    setState(() {
      _selectedDateRange = picked;
    });
  }
  await _loadRowsForCurrentMonth();
}

  void _onMonthChanged(String? newValue) async {
  if (newValue == null) return;

  setState(() {
    _selectedMonthString = newValue;
    isLoadingDefects = true;
    isLoadingKpi = true;
  });

  final DateTime start = getStartOfMonth(newValue);
    final DateTime end = getEndOfMonth(newValue);
    await _loadData();

    _loadCompletedStages(start: start, end: end);

  

  setState(() {
    isLoadingDefects = false;
    isLoadingKpi = false;
  });
}

DateTime getStartOfMonth(String monthStr) {
  final parts = monthStr.split('.');
  final month = _russianMonthToNumber(parts[0]);
  return DateTime(2025, month, 1);
}

DateTime getEndOfMonth(String monthStr) {
  final start = getStartOfMonth(monthStr);
  final nextMonth = DateTime(start.year, start.month + 1, 1);
  return nextMonth.subtract(const Duration(days: 1));
}

int _russianMonthToNumber(String month) {
  const months = {
    'ЯНВАРЬ 25': 1,
    'ФЕВРАЛЬ 25': 2,
    'МАРТ 25': 3,
    'АПРЕЛЬ 25': 4,
    'МАЙ 25': 5,
    'Июнь': 6,
    'Июль': 7,
    'Август': 8,
    'Сентябрь': 9,
    'Октябрь': 10,
    'Ноябрь': 11,
    'Декабрь': 12,
  };
  return months[month] ?? 1;
}


Future<void> _loadRowsForCurrentMonth() async {
  await _loadCompletedStages(start: _selectedDateRange!.start, end: _selectedDateRange!.end);
  final now = DateTime.now();

  final monthString = _formatMonthYear(now);

  final newRows = await sheetsService.getRows(monthString);

  setState(() {
    rows = newRows;
  });
}

String _formatMonthYear(DateTime date) {
  final months = [
    'ЯНВАРЬ 25', 'ФЕВРАЛЬ 25', 'МАРТ 25', 'АПРЕЛЬ 25',
    'МАЙ 25', 'Июнь', 'Июль', 'Август',
    'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];
  return months[date.month - 1];
}



  Map<String, double> _calculateTotalHoursPerEmployee() {
    final result = <String, double>{};

    if (_selectedDateRange == null) {
      return result;
    }

    final startDate = _selectedDateRange!.start;
    final endDate = _selectedDateRange!.end;

    for (var row in rows) {
      final name = row.values.first;
      double total = 0;

      for (var entry in row.entries) {
        final column = entry.key;

        if (_isDateColumn(column)) {
          try {
            final date = _parseDate(column);
            if (date.isAfter(startDate.subtract(Duration(days: 1))) &&
                date.isBefore(endDate.add(Duration(days: 1)))) {
              total += _parseHours(entry.value);
            }
          } catch (e) {
            continue;
          }
        }
      }

      result[name] = total;
    }

    return result;
  }

  Map<String, double> _calculateMonthlyTotalHours() {
  final result = <String, double>{};

  for (var row in rows) {
    final name = row.values.first;
    double total = 0;

    for (var entry in row.entries) {
      final column = entry.key;

      if (_isDateColumn(column)) {
        try {
          total += _parseHours(entry.value);
        } catch (e) {
          continue;
        }
      }
    }

    result[name] = total;
  }

  return result;
}

Future<void> fetchDepartments() async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('departments').get();
    final List<String> fetchedDepartments = snapshot.docs
        .map((doc) => doc.data()['name'] as String)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    setState(() {
      allDepartments = fetchedDepartments;
    });
  } catch (e) {
    debugPrint('Ошибка при загрузке отделов: $e');
  }
}



 @override
Widget build(BuildContext context) {
  final filteredRows = selectedDepartment == null
        ? rows
        : rows.where((row) => row['Отдел'] == selectedDepartment).toList();
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('KPI Статистика'),
      bottom: TabBar(
        unselectedLabelColor: Colors.white,
        labelColor: Colors.red,
        indicatorColor: const Color.fromARGB(255, 255, 255, 255),
        controller: _tabController,
        tabs: const [
          Tab(text: 'Текущий месяц'),
          Tab(text: 'Прошлые месяцы'),
        ],
      ),
    ),
    body: TabBarView(
      
      controller: _tabController,
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _selectDateRange(),
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
                  if (_selectedDateRange != null)
                    Expanded(
                      child: Text(
                        '${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.start)} – ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.end)}',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: allDepartments.isEmpty
              ? const SizedBox.shrink()
              : DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все отделы')),
                    ...allDepartments.map((dep) => DropdownMenuItem(
                          value: dep,
                          child: Text(dep),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedDepartment = value;
                    });
                  },
                )

            ),

            Expanded(
              child: isLoadingDefects && isLoadingStages && isLoadingKpi
                  ? const Center(child: CircularProgressIndicator())
                  : rows.isEmpty
                      ? const Center(child: Text('Нет данных'))
                      : ListView.builder(
                          itemCount: filteredRows.length,
                          itemBuilder: (context, index) {
                            final employeeName = filteredRows[index][''] ?? 'Без имени';
                            final department = filteredRows[index]['Отдел'] ?? 'Без отдела';
                            final totals = _calculateTotalHoursPerEmployee();

                            final double completed = (completeStages[employeeName] ?? 0).toDouble();
                            final double hours = (totals[employeeName] ?? 0).toDouble();
                            final double defectCounts = (defectsStages[employeeName] ?? 0).toDouble();


                            double employeeKpiSum = 0.0;
                            List<double> kpiPerDay = [];


                            kpiStages.forEach((dateKey, employeeMap) {
                              final employeeKpiData = employeeMap[employeeName];
                              if (employeeKpiData != null) {
                                final double kpi = employeeKpiData['effectiveKpi'];
                                if (kpi is num) {
                                  employeeKpiSum += kpi;
                                  kpiPerDay.add(kpi);
                                }
                              }
                            });

                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ExpansionTile(
                                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                  employeeName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                 Text(
                                  'Отдел: $department\n'
                                  'KPI: ${employeeKpiSum.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 13),
                                  
                                ),
                                  ],
                                ),
                                children: [
                                   Align(
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('Отработано часов: ${hours == 0 ? '-' : hours.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                                        Text('Выполнено этапов: ${completed == 0 ? '-' : completed.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                                        Text('Допущено брака: ${defectCounts == 0 ? '-' : defectCounts.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => KpiReportsPage(
                                                    employeeName: employeeName, 
                                                    department: department, 
                                                    employeeKpiSum: employeeKpiSum, 
                                                    hours: hours, 
                                                    completed: completed, 
                                                    defectCounts: defectCounts,
                                                    kpiPerDay: kpiPerDay,
                                                  )
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(color: Colors.red),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: const Text(
                                              'Подробнее',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )


                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMonthString,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.red),
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    dropdownColor: Colors.white,
                    onChanged: _onMonthChanged,
                    items: monthsList.map((month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(
                          month,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: allDepartments.isEmpty
              ? const SizedBox.shrink()
              : DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все отделы')),
                    ...allDepartments.map((dep) => DropdownMenuItem(
                          value: dep,
                          child: Text(dep),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedDepartment = value;
                    });
                  },
                )

            ),

            Expanded(
              child: isLoadingDefects && isLoadingKpi && isLoadingStages
                  ? const Center(child: CircularProgressIndicator())
                  : filteredRows.isEmpty
                      ? const Center(child: Text('Нет данных'))
                      : ListView.builder(
                          itemCount: _calculateMonthlyTotalHours().length,
                          itemBuilder: (context, index) {
                            final totals = _calculateMonthlyTotalHours();

                            final employeeName = filteredRows[index][''] ?? 'Без имени';
                            final department = filteredRows[index]['Отдел'] ?? 'Без отдела';

                            final double completed = (completeStages[employeeName] ?? 0).toDouble();
                            final double hours = (totals[employeeName] ?? 0).toDouble();
                            final double defectCounts = (defectsStages[employeeName] ?? 0).toDouble();

                            double employeeKpiSum = 0.0;
                            List<double> kpiPerDay = []; 


                            kpiStages.forEach((dateKey, employeeMap) {
                              final employeeKpiData = employeeMap[employeeName];
                              if (employeeKpiData != null) {
                                final double kpi = employeeKpiData['effectiveKpi'];
                                if (kpi is num) {
                                  employeeKpiSum += kpi;
                                  kpiPerDay.add(kpi);
                                }
                              }
                            });

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employeeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Отдел: $department\n'
                          'KPI: ${employeeKpiSum.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Отработано часов: $hours', style: const TextStyle(fontSize: 13)),
                            Text('Выполнено этапов: $completed', style: const TextStyle(fontSize: 13)),
                            Text('Допущено брака: $defectCounts', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => KpiReportsPage(
                                                    employeeName: employeeName, 
                                                    department: department, 
                                                    employeeKpiSum: employeeKpiSum, 
                                                    hours: hours, 
                                                    completed: completed, 
                                                    defectCounts: defectCounts,
                                                    kpiPerDay: kpiPerDay,
                                                  )
                                                ),
                                              );
                                            },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  'Подробнее',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )

                    ],
                  ),
                );
              },
            ),
),

          ],
        ),
      ],
    ),
  );
}


}
