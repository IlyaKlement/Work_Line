import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:work_line/screens/ready_product_templates_page.dart';

class CreateProductTemplatePage extends StatefulWidget {
  const CreateProductTemplatePage({super.key});

  @override
  State<CreateProductTemplatePage> createState() =>
      _CreateProductTemplatePageState();
}

class _CreateProductTemplatePageState extends State<CreateProductTemplatePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _templateNameController = TextEditingController();
  final TextEditingController _stageController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedCoefficient;
  bool _requiresOtkCheck = false;

  List<String> _departments = [];
  final List<Map<String, dynamic>> _stages = [];
  final List<String> _coefficients = ['1', '1.1', '1.2'];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  void _fetchDepartments() async {
    final snapshot = await _firestore.collection('departments').get();
    final departments =
        snapshot.docs.map((doc) => doc['name'] as String).toList();

    if (mounted) {
      setState(() {
        _departments = departments;
      });
    }
  }

  void _addStage() {
    if (_stageController.text.isNotEmpty && _selectedCoefficient != null) {
      setState(() {
        _stages.add({
          'stage_name': _stageController.text.trim(),
          'coefficient': _selectedCoefficient,
          'requires_otk_check': _requiresOtkCheck,
        });
        _stageController.clear();
        _selectedCoefficient = null;
        _requiresOtkCheck = false;
      });
    }
  }

  void _saveTemplate() async {
    if (_selectedDepartment != null &&
        _stages.isNotEmpty &&
        _templateNameController.text.isNotEmpty) {
      await _firestore.collection('product_templates').add({
        'template_name': _templateNameController.text.trim(),
        'department': _selectedDepartment,
        'stages': _stages,
      });

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ReadyProductTemplatesPage()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните все поля и добавьте хотя бы один этап.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    _stageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание шаблона'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.redAccent),
            onPressed: _saveTemplate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(_templateNameController, 'Название шаблона'),
            const SizedBox(height: 16),
            _buildDropdown(
              hint: 'Выберите отдел',
              value: _selectedDepartment,
              items: _departments,
              onChanged: (val) => setState(() => _selectedDepartment = val),
            ),
            const SizedBox(height: 16),
            if (_selectedDepartment != null) ...[
              _buildTextField(_stageController, 'Название этапа'),
              const SizedBox(height: 8),
              _buildDropdown(
                hint: 'Коэффициент сложности',
                value: _selectedCoefficient,
                items: _coefficients,
                onChanged: (val) => setState(() => _selectedCoefficient = val),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _requiresOtkCheck,
                    activeColor: Colors.redAccent,
                    onChanged: (val) =>
                        setState(() => _requiresOtkCheck = val ?? false),
                  ),
                  const Text('Требует проверки ОТК'),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addStage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Добавить этап'),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (_stages.isNotEmpty) ...[
              const Divider(),
              const Text('Добавленные этапы:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _stages.length,
                itemBuilder: (context, index) {
                  final stage = _stages[index];
                  return Card(
                    key: ValueKey(stage),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(stage['stage_name']),
                      subtitle: Text(
                          'Коэф: ${stage['coefficient']} | ОТК: ${stage['requires_otk_check'] ? "Да" : "Нет"}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            setState(() => _stages.removeAt(index)),
                      ),
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _stages.removeAt(oldIndex);
                    _stages.insert(newIndex, item);
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint),
        dropdownColor: Colors.white,
        isExpanded: true,
        underline: const SizedBox(),
        iconEnabledColor: Colors.redAccent,
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
