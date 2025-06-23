import 'package:flutter/material.dart';

class NormsKpiPage extends StatelessWidget {
  const NormsKpiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Посмотреть нормы')),
      body: Center(
        child: Text('Здесь будут данные по нормам'),
      ),
    );
  }
}
