import 'package:flutter/material.dart';
import 'package:work_line/screens/operations_details.dart';

class OperationList extends StatelessWidget {
  const OperationList({super.key});

  @override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      final detailId = 'exampleDetailId';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OperationDetailsPage(detailId: detailId),
        ),
      );
    },
    child: Container(
      height: MediaQuery.of(context).size.height * 0.2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE0E0E0),
            Color(0xFFC7C7C7), 
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            offset: const Offset(-4, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.list_alt_rounded,
              size: 44,
              color: Color(0xFF37474F),
            ),
            SizedBox(height: 12),
            Text(
              "Список продукции",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                letterSpacing: 0.3,
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}
