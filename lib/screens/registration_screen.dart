import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:work_line/screens/user_management_page.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  RegistrationScreenState createState() => RegistrationScreenState();
}

class RegistrationScreenState extends State<RegistrationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _patronymicController = TextEditingController();
  final TextEditingController _employeeNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _role = 'employee';
  String _department = '';

  Future<void> _registerUser() async {
    try {
      final lastName = _lastNameController.text.trim();
      final employeeNumber = _employeeNumberController.text.trim();

      final lastNameQuery = await _firestore.collection('users').where('last_name', isEqualTo: lastName).get();
      final employeeNumberQuery = await _firestore.collection('users').where('employee_number', isEqualTo: employeeNumber).get();

      if (lastNameQuery.docs.isNotEmpty) {
        _showSnackBar("Фамилия уже занята");
        return;
      }

      if (employeeNumberQuery.docs.isNotEmpty) {
        _showSnackBar("Личный номер уже занят");
        return;
      }

      final password = _passwordController.text.trim();
      if (password.length < 6) {
        _showSnackBar("Пароль должен содержать не менее 6 символов");
        return;
      }

      final email = '$employeeNumber@example.com';

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'first_name': _firstNameController.text.trim(),
          'last_name': lastName,
          'patronymic': _patronymicController.text.trim(),
          'employee_number': employeeNumber,
          'role': _role,
          'department': _department,
          'created_at': FieldValue.serverTimestamp(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserManagementPage()),
        );
      }
    } catch (e) {
      _showSnackBar("Ошибка: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red[700],
    ));
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Регистрация'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _firstNameController,
              cursorColor: Colors.red,
              decoration: _inputDecoration('Имя'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              cursorColor: Colors.red,
              decoration: _inputDecoration('Фамилия'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _patronymicController,
              cursorColor: Colors.red,
              decoration: _inputDecoration('Отчество'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _employeeNumberController,
              cursorColor: Colors.red,
              decoration: _inputDecoration('Личный номер'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              cursorColor: Colors.red,
              decoration: _inputDecoration('Пароль'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: _inputDecoration('Выберите роль'),
              items: const [
                DropdownMenuItem(value: 'employee', child: Text('Сотрудник')),
                DropdownMenuItem(value: 'manager', child: Text('Руководитель')),
                DropdownMenuItem(value: 'admin', child: Text('Администратор')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _role = value);
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: _firestore.collection('departments').get(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Нет доступных отделов');
                }

                return DropdownButtonFormField<String>(
                  value: _department.isEmpty ? null : _department,
                  decoration: _inputDecoration('Выберите отдел'),
                  items: snapshot.data!.docs
                      .map((doc) => DropdownMenuItem<String>(
                            value: doc['name'],
                            child: Text(doc['name']),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _department = value);
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Зарегистрироваться', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
