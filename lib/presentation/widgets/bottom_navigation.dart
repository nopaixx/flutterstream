import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
            Colors.black,
          ],
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 24),
            activeIcon: Icon(Icons.home, size: 28),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 24),
            activeIcon: Icon(Icons.search, size: 28),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline, size: 24),
            activeIcon: Icon(Icons.play_circle_filled, size: 28),
            label: 'Próximamente',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download_outlined, size: 24),
            activeIcon: Icon(Icons.download, size: 28),
            label: 'Descargas',
          ),
        ],
      ),
    );
  }
}