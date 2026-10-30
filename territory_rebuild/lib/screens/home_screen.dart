// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'ranking_screen.dart';
import 'profile_screen.dart';
import 'battles_screen.dart';
import 'clan_screen.dart';
import 'search_screen.dart';
import '../core/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MapScreen(),
    BattlesScreen(),
    RankingScreen(),
    ClanScreen(),
    ProfileScreen(),
  ];

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 70,
            child: GestureDetector(
              onTap: _openSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, color: Colors.white54, size: 16),
                    SizedBox(width: 4),
                    Text('Buscar', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: const Color(0xFF111111),
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Mapa'),
            BottomNavigationBarItem(icon: Icon(Icons.local_fire_department_outlined), activeIcon: Icon(Icons.local_fire_department), label: 'Batalhas'),
            BottomNavigationBarItem(icon: Icon(Icons.leaderboard_outlined), activeIcon: Icon(Icons.leaderboard), label: 'Ranking'),
            BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Clãs'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
