import 'package:flutter/material.dart';
import 'package:work_line/screens/create_product_template_screen.dart';
import 'package:work_line/screens/manage_departments_page.dart';
import 'package:work_line/screens/ready_product_templates_page.dart';

class TemplateListScreen extends StatelessWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Управление шаблонами"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTemplateItem(context, "Отделы", Icons.apartment, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageDepartmentsPage()));
          }),
          _buildTemplateItem(context, "Создание шаблона", Icons.fiber_new_rounded , () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CreateProductTemplatePage()));
          }),
          _buildTemplateItem(context, "Готовые шаблоны изделий", Icons.assignment, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) =>  ReadyProductTemplatesPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildTemplateItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
