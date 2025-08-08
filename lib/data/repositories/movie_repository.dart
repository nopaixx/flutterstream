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
  // 🚀 LIVEVAULTHUB P2P STREAMS - Base de datos en memoria
  static List<MovieModel> _allMovies = [
    MovieModel(
      id: '1',
      title: 'LiveVaultHub Demo Stream',
      description: 'Transmisión principal de LiveVaultHub con tecnología P2P. Experimenta la nueva era del streaming descentralizado con calidad 4K y latencia ultra-baja.',
      genre: 'Streaming Live',
      imageUrl: 'https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=800&h=450&fit=crop',
      videoUrl: 'https://fcc3ddae59ed.us-west-2.playback.live-video.net/api/video/v1/us-west-2.893648527354.channel.DmumNckWFTqz.m3u8',
      duration: 0, // Live stream - duración infinita
      rating: 9.8,
      year: 2024,
      isTrending: true,
    ),
    MovieModel(
      id: '2',
      title: 'Gaming Marathon P2P',
      description: 'Maratón de gaming con tecnología P2P para máxima calidad sin buffering. Únete a miles de viewers compartiendo la carga de bandwidth.',
      genre: 'Gaming',
      imageUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800&h=450&fit=crop',
      videoUrl: 'https://fcc3ddae59ed.us-west-2.playback.live-video.net/api/video/v1/us-west-2.893648527354.channel.DmumNckWFTqz.m3u8',
      duration: 240, // 4 horas estimadas
      rating: 8.9,
      year: 2024,
      isTrending: true,
    ),
    MovieModel(
      id: '3',
      title: 'Tech Talk Exclusivo',
      description: 'Charla exclusiva sobre el futuro del streaming P2P y las tecnologías emergentes. Solo disponible en LiveVaultHub.',
      genre: 'Tecnología',
      imageUrl: 'https://images.unsplash.com/photo-1515378791036-0648a814c963?w=800&h=450&fit=crop',
      videoUrl: 'https://fcc3ddae59ed.us-west-2.playback.live-video.net/api/video/v1/us-west-2.893648527354.channel.DmumNckWFTqz.m3u8',
      duration: 120,
      rating: 9.2,
      year: 2024,
      isInMyList: true,
    ),
    MovieModel(
      id: '4',
      title: 'Evento Especial VIP',
      description: 'Evento especial para suscriptores VIP con acceso anticipado y funciones exclusivas. Tecnología P2P de próxima generación.',
      genre: 'Evento Especial',
      imageUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&h=450&fit=crop',
      videoUrl: 'https://fcc3ddae59ed.us-west-2.playback.live-video.net/api/video/v1/us-west-2.893648527354.channel.DmumNckWFTqz.m3u8',
      duration: 180,
      rating: 9.5,
      year: 2024,
      isContinueWatching: true,
      watchProgress: 1200, // 20 minutos
    ),
    MovieModel(
      id: '5',
      title: 'Behind the Scenes P2P',
      description: 'Documental exclusivo sobre cómo funciona la tecnología P2P en LiveVaultHub. Descubre los secretos detrás de la magia del streaming descentralizado.',
      genre: 'Documental',
      imageUrl: 'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=800&h=450&fit=crop',
      videoUrl: 'https://fcc3ddae59ed.us-west-2.playback.live-video.net/api/video/v1/us-west-2.893648527354.channel.DmumNckWFTqz.m3u8',
      duration: 90,
      rating: 8.7,
      year: 2024,
      isContinueWatching: true,
      watchProgress: 800,
    ),
    MovieModel(
      id: '6',
      title: 'Community Stream Live',
      description: 'Transmisión comunitaria en vivo donde los viewers son parte del show. Interacción en tiempo real con tecnología P2P avanzada.',
      genre: 'Comunidad',
      imageUrl: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800&h=450&fit=crop',
      videoUrl: 'https://fcc3ddae59ed.us-west-2.playback.live-video.net/api/video/v1/us-west-2.893648527354.channel.DmumNckWFTqz.m3u8',
      duration: 0, // Live stream
      rating: 8.4,
      year: 2024,
      isTrending: true,
    ),
    MovieModel(
      id: '7',
      title: 'Masterclass Streaming',
      description: 'Aprende las técnicas avanzadas de streaming con los mejores creators. Solo disponible para suscriptores premium de LiveVaultHub.',
      genre: 'Educación',
      imageUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&h=450&fit=crop',
      videoUrl: 'https://fcc3ddae59ed.us-west-2.playback.live-video.net/api/video/v1/us-west-2.893648527354.channel.DmumNckWFTqz.m3u8',
      duration: 150,
      rating: 9.1,
      year: 2024,
    ),
    MovieModel(
      id: '8',
      title: 'Música en Vivo P2P',
      description: 'Concierto exclusivo transmitido con tecnología P2P para la mejor calidad de audio. Una experiencia musical revolucionaria.',
      genre: 'Música',
      imageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&h=450&fit=crop',
      videoUrl: 'https://fcc3ddae59ed.us-west-2.playback.live-video.net/api/video/v1/us-west-2.893648527354.channel.DmumNckWFTqz.m3u8',
      duration: 120,
      rating: 9.3,
      year: 2024,
      isInMyList: true,
    ),
    MovieModel(
      id: '9',
      title: 'Talk Show Nocturno',
      description: 'El talk show más popular de LiveVaultHub con invitados especiales cada noche. Conversaciones profundas y entretenimiento de calidad.',
      genre: 'Talk Show',
      imageUrl: 'https://images.unsplash.com/photo-1478720568477-152d9b164e26?w=800&h=450&fit=crop',
      videoUrl: 'https://fcc3ddae59ed.us-west-2.playback.live-video.net/api/video/v1/us-west-2.893648527354.channel.DmumNckWFTqz.m3u8',
      duration: 90,
      rating: 8.8,
      year: 2024,
    ),
    MovieModel(
      id: '10',
      title: 'Competencia Esports Pro',
      description: 'Torneo profesional de esports con la mejor calidad de streaming P2P. Vive la emoción de los deportes electrónicos como nunca antes.',
      genre: 'Esports',
      imageUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800&h=450&fit=crop',
      videoUrl: 'https://fcc3ddae59ed.us-west-2.playback.live-video.net/api/video/v1/us-west-2.893648527354.channel.DmumNckWFTqz.m3u8',
      duration: 300,
      rating: 9.0,
      year: 2024,
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