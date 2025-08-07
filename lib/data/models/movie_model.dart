class MovieModel {
  final String id;
  final String title;
  final String description;
  final String genre;
  final String imageUrl;
  final String videoUrl;
  final int duration; // en minutos
  final double rating;
  final int year;
  final bool isInMyList;
  final bool isTrending;
  final bool isContinueWatching;
  final int? watchProgress; // progreso en segundos

  MovieModel({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.imageUrl,
    required this.videoUrl,
    required this.duration,
    required this.rating,
    required this.year,
    this.isInMyList = false,
    this.isTrending = false,
    this.isContinueWatching = false,
    this.watchProgress,
  });

  MovieModel copyWith({
    String? id,
    String? title,
    String? description,
    String? genre,
    String? imageUrl,
    String? videoUrl,
    int? duration,
    double? rating,
    int? year,
    bool? isInMyList,
    bool? isTrending,
    bool? isContinueWatching,
    int? watchProgress,
  }) {
    return MovieModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      genre: genre ?? this.genre,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      isInMyList: isInMyList ?? this.isInMyList,
      isTrending: isTrending ?? this.isTrending,
      isContinueWatching: isContinueWatching ?? this.isContinueWatching,
      watchProgress: watchProgress ?? this.watchProgress,
    );
  }

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      genre: json['genre'],
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      duration: json['duration'],
      rating: json['rating'].toDouble(),
      year: json['year'],
      isInMyList: json['isInMyList'] ?? false,
      isTrending: json['isTrending'] ?? false,
      isContinueWatching: json['isContinueWatching'] ?? false,
      watchProgress: json['watchProgress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'genre': genre,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'duration': duration,
      'rating': rating,
      'year': year,
      'isInMyList': isInMyList,
      'isTrending': isTrending,
      'isContinueWatching': isContinueWatching,
      'watchProgress': watchProgress,
    };
  }

  String get formattedDuration {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get movieInfo {
    return '$year • $formattedDuration • $genre';
  }
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String profileImageUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
    };
  }
}