import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/content_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/livevaulthub_app_bar.dart';
import '../widgets/featured_content.dart';
import '../widgets/movie_section.dart';
import '../widgets/livevaulthub_bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      extendBodyBehindAppBar: true,
      appBar: LiveVaultHubAppBar(
        onProfileTap: _showProfileMenu,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _currentIndex == 0 ? _buildHubContent() : _buildOtherPages(),
        ),
      ),
      bottomNavigationBar: LiveVaultHubBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _fadeController.reset();
          _fadeController.forward();
        },
      ),
    );
  }

  Widget _buildHubContent() {
    return Consumer<ContentProvider>(
      builder: (context, contentProvider, child) {
        if (contentProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando tu Vault...',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (contentProvider.error != null) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient.scale(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ops! Algo salió mal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contentProvider.error!,
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => contentProvider.refreshContent(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      label: const Text(
                        'Reintentar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => contentProvider.refreshContent(),
          color: AppTheme.primaryViolet,
          backgroundColor: AppTheme.darkGrey,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80), // AppBar spacing

                // Welcome header
                _buildWelcomeHeader(),

                const SizedBox(height: 24),

                // Featured content
                if (contentProvider.featuredMovie != null)
                  FeaturedContent(movie: contentProvider.featuredMovie!),

                const SizedBox(height: 32),

                // Content sections with updated names
                if (contentProvider.trendingMovies.isNotEmpty)
                  MovieSection(
                    title: '🔥 Trending en LiveVault',
                    movies: contentProvider.trendingMovies,
                  ),

                if (contentProvider.continueWatchingMovies.isNotEmpty)
                  MovieSection(
                    title: '▶️ Continuar Viendo',
                    movies: contentProvider.continueWatchingMovies,
                    showProgress: true,
                  ),

                if (contentProvider.myListMovies.isNotEmpty)
                  MovieSection(
                    title: '💜 Mi Vault Personal',
                    movies: contentProvider.myListMovies,
                  ),

                if (contentProvider.popularMovies.isNotEmpty)
                  MovieSection(
                    title: '⭐ Más Populares',
                    movies: contentProvider.popularMovies,
                  ),

                if (contentProvider.actionMovies.isNotEmpty)
                  MovieSection(
                    title: '⚡ Acción & Aventura',
                    movies: contentProvider.actionMovies,
                  ),

                const SizedBox(height: 100), // Bottom nav spacing
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${authProvider.currentUser?.name.split(' ').first ?? 'Creator'}! 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bienvenido a tu hub de contenido personal',
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOtherPages() {
    final pageData = _getPageData(_currentIndex);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient.scale(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryViolet.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient.scale(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                pageData['icon'],
                size: 40,
                color: AppTheme.primaryViolet,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              pageData['title'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pageData['subtitle'],
              style: TextStyle(
                color: AppTheme.textGrey,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient.scale(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🚀 Próximamente en LiveVaultHub',
                style: TextStyle(
                  color: AppTheme.accentCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getPageData(int index) {
    switch (index) {
      case 1:
        return {
          'icon': Icons.explore_rounded,
          'title': 'Explorar',
          'subtitle': 'Descubre nuevo contenido\ny creadores increíbles',
        };
      case 2:
        return {
          'icon': Icons.live_tv_rounded,
          'title': 'En Vivo',
          'subtitle': 'Streams en tiempo real\ny eventos exclusivos',
        };
      case 3:
        return {
          'icon': Icons.video_library_rounded,
          'title': 'Mi Vault',
          'subtitle': 'Tu biblioteca personal\nde contenido guardado',
        };
      default:
        return {
          'icon': Icons.home_rounded,
          'title': 'Hub',
          'subtitle': 'Tu centro de contenido',
        };
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.darkGrey,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppTheme.primaryViolet.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Column(
                    children: [
                      // User profile section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient.scale(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryViolet.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  authProvider.currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authProvider.currentUser?.name ?? 'Usuario',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    authProvider.currentUser?.email ?? '',
                                    style: TextStyle(
                                      color: AppTheme.textGrey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Menu options
                      _buildMenuTile(
                        Icons.person_rounded,
                        'Mi Perfil',
                            () => Navigator.pop(context),
                      ),
                      _buildMenuTile(
                        Icons.settings_rounded,
                        'Configuración',
                            () => Navigator.pop(context),
                      ),
                      _buildMenuTile(
                        Icons.help_outline_rounded,
                        'Ayuda & Soporte',
                            () => Navigator.pop(context),
                      ),

                      const SizedBox(height: 24),

                      // Logout button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                          title: const Text(
                            'Cerrar Sesión',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _handleLogout();
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.mediumGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: AppTheme.textGrey,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppTheme.primaryViolet.withOpacity(0.3),
            width: 1,
          ),
        ),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Estás seguro de que quieres salir de tu LiveVault?',
          style: TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.redAccent, Colors.red],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                authProvider.logout();
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension para gradients (si no existe ya)
extension GradientExtension on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((color) => color.withOpacity(opacity)).toList(),
    );
  }
}