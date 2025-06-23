import 'package:flutter/material.dart';
import 'package:work_line/qr_scanner/qr_scanner_page.dart';

class ScanQrCode extends StatelessWidget {
  const ScanQrCode({super.key});

  @override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QrScannerPage()),
      );
    },
    child: Container(
      height: MediaQuery.of(context).size.height * 0.8,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 171, 72, 72),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: 40, color: Colors.black),
            SizedBox(height: 8),
            Text(
              "Сканировать \n QR-код",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
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
