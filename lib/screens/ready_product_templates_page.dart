import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ignore: use_key_in_widget_constructors
class ReadyProductTemplatesPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> _fetchProductTemplates() {
    return _firestore.collection('product_templates').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Готовые шаблоны изделий'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: _fetchProductTemplates(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Нет доступных шаблонов.'));
          }

          final templates = snapshot.data!.docs;

          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final templateName = template['template_name'];
              final department = template['department'];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductTemplateDetailsPage(
                        templateId: template.id,
                      ),
                    ),
                  );
                },
                child: ListTile(
                  title: Text(templateName),
                  subtitle: Text('Отдел: $department'),
                  trailing: const Icon(Icons.arrow_forward),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


class ProductTemplateDetailsPage extends StatefulWidget {
  final String templateId;

  const ProductTemplateDetailsPage({super.key, required this.templateId});

  @override
  State<ProductTemplateDetailsPage> createState() =>
      _ProductTemplateDetailsPageState();
}

class _ProductTemplateDetailsPageState
    extends State<ProductTemplateDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<double> _coefficientOptions = [1.0, 1.1, 1.2];

  Future<void> _updateCoefficient(int index, double newCoefficient) async {
    try {
      final docRef =
          _firestore.collection('product_templates').doc(widget.templateId);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        List<dynamic> stages = snapshot['stages'] ?? [];
        if (index >= 0 && index < stages.length) {
          stages[index]['coefficient'] = newCoefficient;

          await docRef.update({'stages': stages});

          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Ошибка обновления коэффициента: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали шаблона'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            _firestore.collection('product_templates').doc(widget.templateId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Шаблон не найден.'));
          }

          final template = snapshot.data!;
          final templateName = template['template_name'];
          final department = template['department'];

          List<Map<String, dynamic>> stages = [];
          if (template['stages'] is List) {
            stages = (template['stages'] as List)
                .whereType<Map<String, dynamic>>() 
                .toList();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Название шаблона: $templateName',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Отдел: $department',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Этапы:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...stages.asMap().entries.map((entry) {
                  int stageIndex = entry.key;
                  Map<String, dynamic> stage = entry.value;

                  String stageName = stage['stage_name'] ?? 'Без названия';
                  bool requiresOtk = stage['requires_otk_check'] ?? false;
                  double coefficient =
                      (stage['coefficient'] is num) ? stage['coefficient'].toDouble() : 1.0;

                  return ListTile(
                    title: Text('${stageIndex + 1}. $stageName'),
                    subtitle: Text(
                        'Коэффициент: $coefficient  |  Проверка ОТК: ${requiresOtk ? "Да" : "Нет"}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        double? newCoefficient =
                            await _showDropdownDialog(context, coefficient);
                        if (newCoefficient != null) {
                          await _updateCoefficient(stageIndex, newCoefficient);
                        }
                      },
                    ),
                  );
                // ignore: unnecessary_to_list_in_spreads
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<double?> _showDropdownDialog(BuildContext context, double currentCoefficient) async {
    double selectedCoefficient = currentCoefficient;

    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выберите коэффициент'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<double>(
                value: selectedCoefficient,
                items: _coefficientOptions.map((double value) {
                  return DropdownMenuItem<double>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (double? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedCoefficient = newValue;
                    });
                  }
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedCoefficient),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }
}

