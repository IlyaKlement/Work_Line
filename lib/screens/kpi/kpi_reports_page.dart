import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class KpiReportsPage extends StatefulWidget {
  final String employeeName;
  final String department;
  final double employeeKpiSum;
  final double hours;
  final double completed;
  final double defectCounts;
  final List<double> kpiPerDay;

  const KpiReportsPage({
    super.key,
    required this.employeeName,
    required this.department,
    required this.employeeKpiSum,
    required this.hours,
    required this.completed,
    required this.defectCounts,
    required this.kpiPerDay,
  });

  @override
  State<KpiReportsPage> createState() => _KpiReportsPageState();
}

class _KpiReportsPageState extends State<KpiReportsPage> {
  List<FlSpot> spots = [];
  int selectedChart = 0; 
  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    generateSpots();
  }

  @override
  void didUpdateWidget(KpiReportsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kpiPerDay != widget.kpiPerDay) {
      generateSpots();
    }
  }

  void generateSpots() {
    spots = List.generate(
      widget.kpiPerDay.length,
      (index) => FlSpot(index.toDouble(), widget.kpiPerDay[index]),
    );
  }

  @override
Widget build(BuildContext context) {
  double total = widget.completed + widget.defectCounts;
  total = total == 0 ? 1 : total;

  double completedPercentage = (widget.completed / total) * 100;
  double defectPercentage = (widget.defectCounts / total) * 100;

  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.red,
      elevation: 1,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Статистика',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard("KPI", widget.employeeKpiSum.toStringAsFixed(2)),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Прогресс KPI',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildKpiProgressBar(widget.employeeKpiSum),
                  const SizedBox(height: 20),

                  _buildInfoCard("Часы работы", widget.hours.toStringAsFixed(2)),
                  _buildInfoCard("Выполнено этапов", widget.completed.toStringAsFixed(2)),
                  _buildInfoCard("Брак", widget.defectCounts.toStringAsFixed(2)),

                  const SizedBox(height: 24),
                  const Text('Графики', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ToggleButtons(
                    isSelected: [selectedChart == 0, selectedChart == 1],
                    onPressed: (index) {
                      setState(() {
                        selectedChart = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    selectedColor: Colors.white,
                    color: Colors.black87,
                    fillColor: Colors.red,
                    textStyle: const TextStyle(fontSize: 16),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Диаграмма этапов'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Динамика KPI'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (selectedChart == 0)
                    buildPieChart(total, completedPercentage, defectPercentage)
                  else
                    buildLineChart(),

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      generatePdfReportWithChart(
                        employeeName: widget.employeeName,
                        period: 'АПРЕЛЬ 25',
                        workedHours: widget.hours,
                        completedStages: widget.completed,
                        defects: widget.defectCounts,
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white,),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    label: const Text('Создать PDF отчет', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildKpiProgressBar(double currentKpi) {
  const double goalKpi = 3;
  double progress = (currentKpi / goalKpi).clamp(0.0, 1.0);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Stack(
        children: [
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Container(
            height: 20,
            width: progress * MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: progress >= 0.5 ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        '${currentKpi.toStringAsFixed(1)} / $goalKpi',
        style: const TextStyle(fontSize: 14, color: Colors.black54),
      ),
    ],
  );
}


Widget _buildProfileCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.15),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.red,
          child: Text(
            widget.employeeName.isNotEmpty ? widget.employeeName[0] : '?',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.employeeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.department, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoCard(String label, String value) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );
}


  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: $value', style: const TextStyle(fontSize: 16)),
    );
  }

  Widget buildPieChart(double total, double completedPercentage, double defectPercentage) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  startDegreeOffset: -90,
                  sections: [
                    PieChartSectionData(
                      value: widget.completed,
                      color: Colors.green,
                      title: '',
                    ),
                    PieChartSectionData(
                      value: widget.defectCounts,
                      color: Colors.red,
                      title: '',
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Всего этапов',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(widget.completed + widget.defectCounts).toInt()}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LegendItem(color: Colors.green, text: 'Выполнено: ${completedPercentage.toStringAsFixed(1)}%'),
            const SizedBox(width: 16),
            LegendItem(color: Colors.red, text: 'Брак: ${defectPercentage.toStringAsFixed(1)}%'),
          ],
        ),
      ],
    );
  }

  Widget buildLineChart() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Динамика KPI по дням', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      RepaintBoundary(
        key: _chartKey, 
        child: SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blueAccent,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                  barWidth: 3,
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
                  ),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
      ),
    ],
  );
}


  Future<Uint8List?> captureChart() async {
  try {
    final context = _chartKey.currentContext;
    if (context == null) {
      debugPrint("Не удалось найти контекст для скриншота");
      return null;
    }

    RenderRepaintBoundary boundary = context.findRenderObject() as RenderRepaintBoundary;
    var image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();

    if (pngBytes == null) {
      debugPrint("Не удалось получить изображение графика.");
    }

    return pngBytes;
  } catch (e) {
    debugPrint('Ошибка при захвате изображения: $e');
    return null;
  }
}


Future<void> generatePdfReportWithChart({
  required String employeeName,
  required String period,
  required double workedHours,      
  required double completedStages,   
  required double defects,           
}) async {
  final chartImage = await captureChart();  
  if (chartImage == null) {
    debugPrint('Не удалось получить изображение графика.');
    return;
  }

  final pdf = pw.Document();

  final font = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  final ttf = pw.Font.ttf(font);

  final image = pw.MemoryImage(chartImage);

  pdf.addPage(
    pw.Page(
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Отчет по KPI', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, font: ttf)),
            pw.SizedBox(height: 16),
            pw.Text('Сотрудник: $employeeName', style: pw.TextStyle(fontSize: 18, font: ttf)),
            pw.SizedBox(height: 8),
            pw.Text('Период: $period', style: pw.TextStyle(fontSize: 16, font: ttf)),
            pw.SizedBox(height: 16),
            pw.Text('Отработано часов: $workedHours', style: pw.TextStyle(fontSize: 16, font: ttf)),
            pw.Text('Завершено этапов: $completedStages', style: pw.TextStyle(fontSize: 16, font: ttf)),
            pw.Text('Количество брака: $defects', style: pw.TextStyle(fontSize: 16, font: ttf)),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text('График динамики KPI', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: ttf)),
            pw.SizedBox(height: 8),
            pw.Image(image),
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text('Сформировано системой автоматически', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey, font: ttf)),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}

}


class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
