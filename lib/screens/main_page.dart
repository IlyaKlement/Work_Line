import 'package:flutter/material.dart';
import 'package:work_line/screens/kpi/kpi_menu_screen.dart';
import 'package:work_line/screens/kpi/kpi_page.dart';
import 'package:work_line/screens/profile_page.dart';
import 'package:work_line/screens/settings_page.dart';
import 'package:work_line/widgets/scan_qr_code.dart'; 
import 'package:work_line/widgets/generate_widgets.dart';
import 'package:work_line/widgets/operation_list.dart';

class MainPage extends StatefulWidget {
  final String role; 
  final String number;
  final String department;
  final String name;

  const MainPage({super.key, required this.role, required this.number, required this.department, required this.name});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _selectedIndex = 0; 
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _selectedIndex == 0 
    ? AppBar(
        backgroundColor: Colors.black,
        title: const Text('Work Line', style: TextStyle(color: Colors.white)),
        elevation: 0,
      )
    : null,

    body: _selectedIndex == 0 
    ? Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: const ScanQrCode(),
                    ),
                    Expanded(
                      child: Column(
                        children: const [
                          Expanded(
                            child: GenerateWidgets(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: const KpiPage(),
          ),
          Expanded(
            flex: 2,
            child: const OperationList(),
          ),
        ],
      )
    : _selectedIndex == 1
    ? const KpiMenuPage()
    : _selectedIndex == 2
        ? ProfilePage(role: widget.role, number: widget.number, department: widget.department, name: widget.name,)
        : const SettingsPage(),



    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      backgroundColor: Colors.black,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Главная',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'KPI',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Профиль',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Настройки',
        ),
      ],
    ),
  );
}

}
