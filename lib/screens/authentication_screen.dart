import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:work_line/screens/main_page.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});
  @override
  AuthenticationScreenState createState() => AuthenticationScreenState();
}

class AuthenticationScreenState extends State<AuthenticationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
  try {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('last_name', isEqualTo: _surnameController.text.trim())
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot userData = querySnapshot.docs.first;

      String email = '${userData['employee_number']}@example.com'; 

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;

      if (user != null) {
        String userRole = userData['role'];
        String userNumber = userData['employee_number'];
        String userDepartment = userData['department'];
        String userFirstName =  userData['first_name'];
        String userLastName = userData['last_name'];

        String userName = '$userLastName $userFirstName'.trim();

        debugPrint("✅ Вход выполнен: ${user.email}, роль: $userRole");
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage(role: userRole, number: userNumber, department: userDepartment, name: userName,)),
        );
      }
    } else {
      throw 'Пользователь с такой фамилией не найден';
    }
  } catch (e) {
    debugPrint("❌ Ошибка входа: $e");
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Вход'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextField(
              controller: _surnameController,
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                fillColor: Colors.black,
                labelText: 'Фамилия',
                labelStyle: TextStyle(color: Colors.black),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                fillColor: Colors.black,
                labelText: 'Пароль',
                labelStyle: TextStyle(color: Colors.black),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.0),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _signIn,
                child: const Text(
                  'Начать работу',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
