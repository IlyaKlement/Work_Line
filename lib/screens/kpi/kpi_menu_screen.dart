import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:work_line/screens/kpi/kpi_norms_page.dart';
import 'kpi_details_page.dart';
import 'kpi_statistics_page.dart';

class KpiMenuPage extends StatefulWidget {
  const KpiMenuPage({super.key});

  @override
  State<KpiMenuPage> createState() => _KpiMenuPageState();
}

class _KpiMenuPageState extends State<KpiMenuPage> {
  final TextEditingController _templateNameController = TextEditingController();

  Future<String> getTemplateIdFromFirestore() async {
    final templateName = _templateNameController.text.trim();
    if (templateName.isEmpty) {
      debugPrint('Имя шаблона пустое');
      return 'default-template-id';
    }

    debugPrint('Ищем шаблон с именем: $templateName');
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('product_templates')
          .where('template_name', isEqualTo: templateName)
          .get();

      debugPrint('Найдено документов: ${snapshot.docs.length}');

      if (snapshot.docs.isNotEmpty) {
        var template = snapshot.docs.first;
        debugPrint('Шаблон найден, ID: ${template.id}');
        return template.id;
      } else {
        debugPrint('Шаблон не найден');
        return 'default-template-id';
      }
    } catch (e) {
      debugPrint('Ошибка получения templateId: $e');
      return 'default-template-id';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('KPI Меню'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            _MenuItem(
              title: 'Посмотреть KPI',
              icon: Icons.bar_chart,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => KpiDetailsPage()),
                );
              },
            ),
            _MenuItem(
              title: 'Индивидуальная статистика',
              icon: Icons.person_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => KpiStatisticsPage()),
                );
              },
            ),
            _MenuItem(
              title: 'Нормы KPI',
              icon: Icons.rule,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NormsKpiPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
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
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          leading: Icon(icon, color: Colors.redAccent, size: 28),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        ),
      ),
    );
  }
}
