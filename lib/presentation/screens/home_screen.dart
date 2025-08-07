import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/content_provider.dart';
import '../widgets/netflix_app_bar.dart';
import '../widgets/featured_content.dart';
import '../widgets/movie_section.dart';
import '../widgets/bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: NetflixAppBar(
        onProfileTap: _showProfileMenu,
      ),
      body: _currentIndex == 0 ? _buildHomeContent() : _buildOtherPages(),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHomeContent() {
    return Consumer<ContentProvider>(
      builder: (context, contentProvider, child) {
        if (contentProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFE50914),
            ),
          );
        }

        if (contentProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  contentProvider.error!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => contentProvider.refreshContent(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => contentProvider.refreshContent(),
          color: const Color(0xFFE50914),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video destacado
                if (contentProvider.featuredMovie != null)
                  FeaturedContent(movie: contentProvider.featuredMovie!),

                const SizedBox(height: 20),

                // Secciones de películas
                if (contentProvider.trendingMovies.isNotEmpty)
                  MovieSection(
                    title: 'Tendencias ahora',
                    movies: contentProvider.trendingMovies,
                  ),

                if (contentProvider.continueWatchingMovies.isNotEmpty)
                  MovieSection(
                    title: 'Continuar viendo',
                    movies: contentProvider.continueWatchingMovies,
                    showProgress: true,
                  ),

                if (contentProvider.myListMovies.isNotEmpty)
                  MovieSection(
                    title: 'Mi lista',
                    movies: contentProvider.myListMovies,
                  ),

                if (contentProvider.popularMovies.isNotEmpty)
                  MovieSection(
                    title: 'Populares en Netflix',
                    movies: contentProvider.popularMovies,
                  ),

                if (contentProvider.actionMovies.isNotEmpty)
                  MovieSection(
                    title: 'Acción y aventuras',
                    movies: contentProvider.actionMovies,
                  ),

                const SizedBox(height: 100), // Padding para el bottom nav
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtherPages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForIndex(_currentIndex),
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            _getTitleForIndex(_currentIndex),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Próximamente...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 1:
        return Icons.search;
      case 2:
        return Icons.play_circle_outline;
      case 3:
        return Icons.download;
      default:
        return Icons.home;
    }
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 1:
        return 'Buscar';
      case 2:
        return 'Próximamente';
      case 3:
        return 'Descargas';
      default:
        return 'Inicio';
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Column(
                    children: [
                      // User info
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE50914),
                          child: Text(
                            authProvider.currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          authProvider.currentUser?.name ?? 'Usuario',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          authProvider.currentUser?.email ?? '',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),

                      const Divider(color: Colors.grey),

                      // Menu options
                      ListTile(
                        leading: const Icon(Icons.person, color: Colors.white),
                        title: const Text('Mi perfil', style: TextStyle(color: Colors.white)),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings, color: Colors.white),
                        title: const Text('Configuración', style: TextStyle(color: Colors.white)),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.help_outline, color: Colors.white),
                        title: const Text('Ayuda', style: TextStyle(color: Colors.white)),
                        onTap: () => Navigator.pop(context),
                      ),

                      const Divider(color: Colors.grey),

                      // Logout
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          _handleLogout();
                        },
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

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}