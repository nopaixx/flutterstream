import 'package:flutter/material.dart';
import '../../data/models/movie_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/screens/login_screen.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = MockAuthRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // Getter para determinar si el usuario es premium/VIP
  bool get isPremiumUser => _currentUser != null;
  bool get isVIPUser => _currentUser?.email == 'vip@livevaulthub.com';

  AuthProvider() {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    // Cargar usuario silenciosamente sin afectar la UI inicial
    _currentUser = await _authRepository.getCurrentUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await _authRepository.login(email, password);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      } else {
        _error = 'Credenciales inválidas. Intenta con test@netflix.com / 123456';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión. Verifica tu internet.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authRepository.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cerrar sesión';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Método para verificar si una acción requiere login
  bool requiresAuth(String action) {
    switch (action) {
      case 'add_to_list':
      case 'remove_from_list':
      case 'save_progress':
      case 'premium_content':
      case 'live_chat':
      case 'donate':
        return true;
      case 'watch_free_content':
      case 'browse_catalog':
      case 'view_streams':
        return false;
      default:
        return false;
    }
  }

  // Método para mostrar diálogo de login cuando sea necesario
  void showLoginRequired(BuildContext context, {String? feature}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LoginRequiredBottomSheet(feature: feature),
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

// Bottom sheet que aparece cuando se requiere login
class LoginRequiredBottomSheet extends StatelessWidget {
  final String? feature;

  const LoginRequiredBottomSheet({Key? key, this.feature}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_add_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),

          const SizedBox(height: 24),

          // Title
          const Text(
            '¡Únete a LiveVaultHub!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            feature != null
                ? 'Inicia sesión para ${_getFeatureDescription(feature!)}'
                : 'Accede a contenido exclusivo y funciones premium',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Benefits
          _buildBenefit(Icons.favorite_rounded, 'Guarda contenido en tu lista personal'),
          _buildBenefit(Icons.hd_rounded, 'Acceso a contenido en alta calidad'),
          _buildBenefit(Icons.notifications_rounded, 'Notificaciones de nuevos episodios'),
          _buildBenefit(Icons.download_rounded, 'Descarga contenido para offline'),

          const SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryViolet),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Más tarde',
                    style: TextStyle(
                      color: AppTheme.primaryViolet,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navegar a pantalla de login
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Demo credentials hint
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.mediumGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💡 Usa: test@netflix.com / 123456',
              style: TextStyle(
                color: AppTheme.textGrey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient.scale(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryViolet, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFeatureDescription(String feature) {
    switch (feature) {
      case 'add_to_list':
        return 'añadir contenido a tu lista';
      case 'save_progress':
        return 'guardar tu progreso de visualización';
      case 'premium_content':
        return 'acceder a contenido premium';
      case 'live_chat':
        return 'participar en el chat en vivo';
      case 'donate':
        return 'enviar donaciones';
      default:
        return 'acceder a esta función';
    }
  }
}

// Extension para gradients
extension GradientExtension on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((color) => color.withOpacity(opacity)).toList(),
    );
  }
}