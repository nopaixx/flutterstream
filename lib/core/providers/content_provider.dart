import 'package:flutter/material.dart';
import '../../data/models/movie_model.dart';
import '../../data/repositories/movie_repository.dart';
import './auth_provider.dart';

class ContentProvider extends ChangeNotifier {
  final MovieRepository _movieRepository = MockMovieRepository();

  List<MovieModel> _trendingMovies = [];
  List<MovieModel> _myListMovies = [];
  List<MovieModel> _continueWatchingMovies = [];
  List<MovieModel> _popularMovies = [];
  List<MovieModel> _actionMovies = [];
  MovieModel? _featuredMovie;

  bool _isLoading = false;
  String? _error;

  // Getters
  List<MovieModel> get trendingMovies => _trendingMovies;
  List<MovieModel> get myListMovies => _myListMovies;
  List<MovieModel> get continueWatchingMovies => _continueWatchingMovies;
  List<MovieModel> get popularMovies => _popularMovies;
  List<MovieModel> get actionMovies => _actionMovies;
  MovieModel? get featuredMovie => _featuredMovie;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ContentProvider() {
    loadAllContent();
  }

  Future<void> loadAllContent() async {
    _setLoading(true);
    _error = null;

    try {
      // Cargar todo el contenido en paralelo
      final results = await Future.wait([
        _movieRepository.getFeaturedMovie(),
        _movieRepository.getTrendingMovies(),
        _movieRepository.getMyListMovies(),
        _movieRepository.getContinueWatchingMovies(),
        _movieRepository.getPopularMovies(),
        _movieRepository.getMoviesByGenre('Acción'),
      ]);

      _featuredMovie = results[0] as MovieModel?;
      _trendingMovies = results[1] as List<MovieModel>;
      _myListMovies = results[2] as List<MovieModel>;
      _continueWatchingMovies = results[3] as List<MovieModel>;
      _popularMovies = results[4] as List<MovieModel>;
      _actionMovies = results[5] as List<MovieModel>;

      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar el contenido';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshContent() async {
    await loadAllContent();
  }

  // Método modificado para manejar acciones que requieren autenticación
  Future<bool> toggleMyList(String movieId, BuildContext context, AuthProvider authProvider) async {
    // Verificar si requiere autenticación
    if (authProvider.requiresAuth('add_to_list')) {
      if (!authProvider.isLoggedIn) {
        // Mostrar diálogo de login requerido
        authProvider.showLoginRequired(context, feature: 'add_to_list');
        return false;
      }
    }

    try {
      final movie = _findMovieById(movieId);
      if (movie == null) return false;

      bool success;
      if (movie.isInMyList) {
        success = await _movieRepository.removeFromMyList(movieId);
      } else {
        success = await _movieRepository.addToMyList(movieId);
      }

      if (success) {
        // Actualizar el estado local
        _updateMovieInLists(movieId, (movie) => movie.copyWith(isInMyList: !movie.isInMyList));

        // Recargar la lista "Mi lista" solo si el usuario está logueado
        if (authProvider.isLoggedIn) {
          _myListMovies = await _movieRepository.getMyListMovies();
        }
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Error al actualizar Mi Lista';
      notifyListeners();
      return false;
    }
  }

  // Método modificado para manejar progreso de visualización
  Future<bool> updateWatchProgress(String movieId, int progress, AuthProvider? authProvider) async {
    try {
      // El progreso se puede guardar localmente sin autenticación
      // Pero se sincroniza con el servidor solo si está logueado
      final success = await _movieRepository.updateWatchProgress(movieId, progress);

      if (success) {
        _updateMovieInLists(movieId, (movie) => movie.copyWith(
          watchProgress: progress,
          isContinueWatching: progress > 0,
        ));

        // Recargar continuar viendo
        _continueWatchingMovies = await _movieRepository.getContinueWatchingMovies();
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Error al actualizar progreso';
      notifyListeners();
      return false;
    }
  }

  // Método para verificar si el contenido es premium
  bool isContentPremium(String movieId) {
    final movie = _findMovieById(movieId);
    // Por ahora todo el contenido es gratuito, pero aquí se podría agregar lógica
    return false;
  }

  // Método para verificar acceso a contenido
  bool canAccessContent(String movieId, AuthProvider authProvider) {
    if (isContentPremium(movieId)) {
      return authProvider.isPremiumUser;
    }
    return true; // Contenido gratuito accesible para todos
  }

  MovieModel? _findMovieById(String movieId) {
    // Buscar en todas las listas
    for (final list in [_trendingMovies, _myListMovies, _continueWatchingMovies, _popularMovies, _actionMovies]) {
      final movie = list.where((m) => m.id == movieId).firstOrNull;
      if (movie != null) return movie;
    }
    return _featuredMovie?.id == movieId ? _featuredMovie : null;
  }

  void _updateMovieInLists(String movieId, MovieModel Function(MovieModel) updater) {
    // Actualizar en todas las listas
    _trendingMovies = _updateMovieInList(_trendingMovies, movieId, updater);
    _myListMovies = _updateMovieInList(_myListMovies, movieId, updater);
    _continueWatchingMovies = _updateMovieInList(_continueWatchingMovies, movieId, updater);
    _popularMovies = _updateMovieInList(_popularMovies, movieId, updater);
    _actionMovies = _updateMovieInList(_actionMovies, movieId, updater);

    if (_featuredMovie?.id == movieId) {
      _featuredMovie = updater(_featuredMovie!);
    }
  }

  List<MovieModel> _updateMovieInList(List<MovieModel> list, String movieId, MovieModel Function(MovieModel) updater) {
    return list.map((movie) => movie.id == movieId ? updater(movie) : movie).toList();
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

extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}