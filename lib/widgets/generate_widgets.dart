import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:work_line/screens/generate_qr_screen.dart';
import 'package:work_line/screens/template_list_screen.dart';

class GenerateWidgets extends StatefulWidget {
  const GenerateWidgets({super.key});

  @override
  State<GenerateWidgets> createState() => _GenerateWidgetsState();
}

class _GenerateWidgetsState extends State<GenerateWidgets> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          userRole = userDoc['role'];
        });
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Wrap(
      spacing: 16,
      runSpacing: 24,
      children: [
        _buildFeatureCard(
          icon: Icons.auto_awesome_outlined,
          label: 'Генерация\nQR-кодов',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GenerateQrScreen()),
          ),
        ),
        _buildFeatureCard(
          icon: Icons.description_outlined,
          label:  'Создание\nшаблонов',
          onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TemplateListScreen()),
              );
          },
        ),
      ],
    ),
  );
}

Widget _buildFeatureCard({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: (MediaQuery.of(context).size.width - 48) / 2,
      height: MediaQuery.of(context).size.height * 0.165,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.black87),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );
}

}
