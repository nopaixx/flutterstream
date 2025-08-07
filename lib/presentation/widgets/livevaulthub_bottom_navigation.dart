import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LiveVaultHubBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const LiveVaultHubBottomNavigation({
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
            AppTheme.deepBlack.withOpacity(0.8),
            AppTheme.deepBlack,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryPurple.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppTheme.primaryViolet,
          unselectedItemColor: AppTheme.textGrey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
          ),
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home_rounded, 0),
              activeIcon: _buildActiveNavIcon(Icons.home_rounded, 0),
              label: 'Hub',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.explore_rounded, 1),
              activeIcon: _buildActiveNavIcon(Icons.explore_rounded, 1),
              label: 'Explorar',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.live_tv_rounded, 2),
              activeIcon: _buildActiveNavIcon(Icons.live_tv_rounded, 2),
              label: 'En Vivo',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.video_library_rounded, 3),
              activeIcon: _buildActiveNavIcon(Icons.video_library_rounded, 3),
              label: 'Vault',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Icon(
        icon,
        size: 24,
        color: currentIndex == index ? AppTheme.primaryViolet : AppTheme.textGrey,
      ),
    );
  }

  Widget _buildActiveNavIcon(IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient.scale(0.3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 26,
        color: Colors.white,
      ),
    );
  }
}

// Extension helper para gradientes
extension GradientExtension on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((color) => color.withOpacity(opacity)).toList(),
    );
  }
}