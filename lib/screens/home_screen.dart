import 'package:flutter/material.dart';
import 'package:work_line/screens/main_page.dart';
import 'package:work_line/screens/history_page.dart';
import 'package:work_line/screens/profile_page.dart';
import 'package:work_line/screens/settings_page.dart';

class HomeScreen extends StatefulWidget {
  final String role; 
  final String number;
  final String department;
  final String name;

  const HomeScreen({super.key, required this.role, required this.number, required this.department, required this.name});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens; 

  @override
  void initState() {
    super.initState();
    _screens = [
      MainPage(role: widget.role, number: widget.number, department: widget.department, name: widget.name,), 
      const HistoryPage(),
      ProfilePage(role: widget.role, number: widget.number, department: widget.department, name: widget.name,),
      const SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'История'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}

