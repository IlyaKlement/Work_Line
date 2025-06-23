import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageDepartmentsPage extends StatefulWidget {
  const ManageDepartmentsPage({super.key});

  @override
  ManageDepartmentsPageState createState() => ManageDepartmentsPageState();
}

class ManageDepartmentsPageState extends State<ManageDepartmentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _departmentController = TextEditingController();

  void _addOrEditDepartment({String? docId, String? currentName}) {
    _departmentController.text = currentName ?? "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? "Добавить отдел" : "Редактировать отдел"),
        content: TextField(
          controller: _departmentController,
          decoration: const InputDecoration(
            labelText: "Название отдела",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена", style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              final name = _departmentController.text.trim();
              if (name.isEmpty) return;
              if (docId == null) {
                await _firestore.collection('departments').add({'name': name});
              } else {
                await _firestore.collection('departments').doc(docId).update({'name': name});
              }
              Navigator.pop(context);
            },
            child: const Text("Сохранить", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

void _deleteDepartment(String docId, String name) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Удалить отдел"),
      content: Text("Вы уверены, что хотите удалить отдел «$name»?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена", style: TextStyle(color: Colors.black)),
        ),
        TextButton(
          onPressed: () async {
            await _firestore.collection('departments').doc(docId).delete();
            Navigator.pop(context);
          },
          child: const Text("Удалить", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Управление отделами"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('departments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Нет отделов",
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: snapshot.data!.docs.map((doc) {
              final name = doc['name'];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.black54),
                        onPressed: () => _addOrEditDepartment(docId: doc.id, currentName: name),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteDepartment(doc.id, name),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditDepartment(),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
