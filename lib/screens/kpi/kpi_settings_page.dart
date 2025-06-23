import 'package:flutter/material.dart';

class KpiSettingsPage extends StatelessWidget {
  const KpiSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки KPI')),
      body: Center(
        child: Text('Здесь будут настройки для KPI'),
      ),
    );
  }
}
