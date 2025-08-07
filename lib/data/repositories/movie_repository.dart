import '../models/movie_model.dart';

abstract class MovieRepository {
  Future<List<MovieModel>> getTrendingMovies();
  Future<List<MovieModel>> getMyListMovies();
  Future<List<MovieModel>> getContinueWatchingMovies();
  Future<List<MovieModel>> getPopularMovies();
  Future<List<MovieModel>> getMoviesByGenre(String genre);
  Future<MovieModel?> getFeaturedMovie();
  Future<bool> addToMyList(String movieId);
  Future<bool> removeFromMyList(String movieId);
  Future<bool> updateWatchProgress(String movieId, int progress);
}

class MockMovieRepository implements MovieRepository {
  // Simulamos una base de datos en memoria
  static List<MovieModel> _allMovies = [
    MovieModel(
      id: '1',
      title: 'Stranger Things',
      description: 'Un grupo de niños se enfrenta a fuerzas sobrenaturales en los años 80. Cuando Will Byers desaparece misteriosamente, sus amigos y familia descubren secretos gubernamentales y criaturas de otra dimensión.',
      genre: 'Ciencia ficción',
      imageUrl: '',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      duration: 51,
      rating: 8.7,
      year: 2023,
      isTrending: true,
    ),
    MovieModel(
      id: '2',
      title: 'The Witcher',
      description: 'Las aventuras de Geralt de Rivia, un cazador de monstruos en un mundo lleno de magia, política y destinos entrelazados.',
      genre: 'Fantasía',
      imageUrl: '',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      duration: 60,
      rating: 8.2,
      year: 2023,
      isTrending: true,
    ),
    MovieModel(
      id: '3',
      title: 'Breaking Bad',
      description: 'Un profesor de química se convierte en fabricante de metanfetaminas para asegurar el futuro financiero de su familia.',
      genre: 'Drama',
      imageUrl: '',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      duration: 47,
      rating: 9.5,
      year: 2022,
      isInMyList: true,
    ),
    MovieModel(
      id: '4',
      title: 'Money Heist',
      description: 'Un grupo de ladrones planea el atraco perfecto a la Fábrica Nacional de Moneda y Timbre de España.',
      genre: 'Acción',
      imageUrl: '',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      duration: 70,
      rating: 8.3,
      year: 2023,
      isContinueWatching: true,
      watchProgress: 1200, // 20 minutos
    ),
    MovieModel(
      id: '5',
      title: 'Dark',
      description: 'Misterios temporales se desentrañan en un pequeño pueblo alemán cuando los niños comienzan a desaparecer.',
      genre: 'Ciencia ficción',
      imageUrl: '',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      duration: 60,
      rating: 8.8,
      year: 2023,
      isContinueWatching: true,
      watchProgress: 800,
    ),
    MovieModel(
      id: '6',
      title: 'Squid Game',
      description: 'Personas desesperadas por dinero compiten en versiones mortales de juegos infantiles tradicionales.',
      genre: 'Suspenso',
      imageUrl: '',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
      duration: 60,
      rating: 8.0,
      year: 2023,
      isTrending: true,
    ),
    MovieModel(
      id: '7',
      title: 'Extraction',
      description: 'Un mercenario debe rescatar al hijo secuestrado de un narcotraficante en una peligrosa misión en Bangladesh.',
      genre: 'Acción',
      imageUrl: '',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
      duration: 116,
      rating: 6.8,
      year: 2023,
    ),
    MovieModel(
      id: '8',
      title: 'The Crown',
      description: 'La historia íntima y política de la reina Isabel II y la familia real británica durante el siglo XX.',
      genre: 'Drama histórico',
      imageUrl: '',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      duration: 58,
      rating: 8.6,
      year: 2023,
      isInMyList: true,
    ),
    MovieModel(
      id: '9',
      title: 'Bridgerton',
      description: 'Romance y drama en la alta sociedad londinense del siglo XIX, siguiendo las aventuras amorosas de la familia Bridgerton.',
      genre: 'Romance',
      imageUrl: '',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
      duration: 62,
      rating: 7.3,
      year: 2023,
    ),
    MovieModel(
      id: '10',
      title: 'The Umbrella Academy',
      description: 'Hermanos adoptivos con superpoderes se reúnen para resolver el misterio de la muerte de su padre y salvar el mundo.',
      genre: 'Superhéroes',
      imageUrl: '',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
      duration: 50,
      rating: 7.9,
      year: 2023,
    ),
  ];

  @override
  Future<List<MovieModel>> getTrendingMovies() async {
    // Simular delay de red
    await Future.delayed(Duration(milliseconds: 500));
    return _allMovies.where((movie) => movie.isTrending).toList();
  }

  @override
  Future<List<MovieModel>> getMyListMovies() async {
    await Future.delayed(Duration(milliseconds: 300));
    return _allMovies.where((movie) => movie.isInMyList).toList();
  }

  @override
  Future<List<MovieModel>> getContinueWatchingMovies() async {
    await Future.delayed(Duration(milliseconds: 300));
    return _allMovies.where((movie) => movie.isContinueWatching).toList();
  }

  @override
  Future<List<MovieModel>> getPopularMovies() async {
    await Future.delayed(Duration(milliseconds: 400));
    return _allMovies.where((movie) => movie.rating >= 8.0).toList();
  }

  @override
  Future<List<MovieModel>> getMoviesByGenre(String genre) async {
    await Future.delayed(Duration(milliseconds: 400));
    return _allMovies.where((movie) => movie.genre.toLowerCase().contains(genre.toLowerCase())).toList();
  }

  @override
  Future<MovieModel?> getFeaturedMovie() async {
    await Future.delayed(Duration(milliseconds: 200));
    return _allMovies.isNotEmpty ? _allMovies.first : null;
  }

  @override
  Future<bool> addToMyList(String movieId) async {
    await Future.delayed(Duration(milliseconds: 300));
    final index = _allMovies.indexWhere((movie) => movie.id == movieId);
    if (index != -1) {
      _allMovies[index] = _allMovies[index].copyWith(isInMyList: true);
      return true;
    }
    return false;
  }

  @override
  Future<bool> removeFromMyList(String movieId) async {
    await Future.delayed(Duration(milliseconds: 300));
    final index = _allMovies.indexWhere((movie) => movie.id == movieId);
    if (index != -1) {
      _allMovies[index] = _allMovies[index].copyWith(isInMyList: false);
      return true;
    }
    return false;
  }

  @override
  Future<bool> updateWatchProgress(String movieId, int progress) async {
    await Future.delayed(Duration(milliseconds: 200));
    final index = _allMovies.indexWhere((movie) => movie.id == movieId);
    if (index != -1) {
      _allMovies[index] = _allMovies[index].copyWith(
        watchProgress: progress,
        isContinueWatching: progress > 0,
      );
      return true;
    }
    return false;
  }
}