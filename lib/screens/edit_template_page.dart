import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditTemplatePage extends StatefulWidget {
  final String templateId;

  const EditTemplatePage({super.key, required this.templateId});

  @override
  _EditTemplatePageState createState() => _EditTemplatePageState();
}

class _EditTemplatePageState extends State<EditTemplatePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> stages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplateData();
  }

  Future<void> _loadTemplateData() async {
    try {
      DocumentSnapshot templateDoc = await _firestore
          .collection('product_templates')
          .doc(widget.templateId)
          .get();

      if (templateDoc.exists && templateDoc.data() is Map<String, dynamic>) {
        Map<String, dynamic> templateData =
            templateDoc.data() as Map<String, dynamic>;

        if (templateData['stages'] is List) {
          setState(() {
            stages = (templateData['stages'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки данных: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _saveChanges() async {
    try {
      await _firestore
          .collection('product_templates')
          .doc(widget.templateId)
          .update({'stages': stages});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Изменения сохранены')),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Ошибка сохранения: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Редактирование шаблона'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование шаблона'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stages.length,
        itemBuilder: (context, index) {
          TextEditingController controller = TextEditingController(
            text: stages[index]['norm']?.toString() ?? '',
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Этап ${index + 1}: ${stages[index]['stage_name']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Введите норму',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  stages[index]['norm'] = int.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
