import 'package:flutter/material.dart';
import '../../data/models/movie_model.dart';
import '../screens/video_player_screen.dart';

class MovieSection extends StatelessWidget {
  final String title;
  final List<MovieModel> movies;
  final bool showProgress;

  const MovieSection({
    Key? key,
    required this.title,
    required this.movies,
    this.showProgress = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: showProgress ? 180 : 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              return MovieCard(
                movie: movies[index],
                showProgress: showProgress,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class MovieCard extends StatelessWidget {
  final MovieModel movie;
  final bool showProgress;

  const MovieCard({
    Key? key,
    required this.movie,
    this.showProgress = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(movie: movie),
          ),
        );
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Poster
            Stack(
              children: [
                Container(
                  height: 180,
                  width: 130,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    image: movie.imageUrl.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(movie.imageUrl),
                      fit: BoxFit.cover,
                      onError: (error, stackTrace) {
                        // Fallback handled by placeholder
                      },
                    )
                        : null,
                  ),
                  child: movie.imageUrl.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.movie_outlined,
                          size: 32,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.genre,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                      : null,
                ),

                // Play overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),

                // Rating badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          movie.rating.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Progress indicator for continue watching
                if (showProgress && movie.watchProgress != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildProgressIndicator(),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Movie Title
            Text(
              movie.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Movie info
            if (!showProgress) ...[
              const SizedBox(height: 2),
              Text(
                '${movie.year} • ${movie.formattedDuration}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Continue watching info
            if (showProgress && movie.watchProgress != null) ...[
              const SizedBox(height: 4),
              Text(
                _getProgressText(),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (movie.watchProgress == null) return const SizedBox.shrink();

    final totalDuration = movie.duration * 60; // Convert to seconds
    final progress = movie.watchProgress! / totalDuration;

    return Container(
      height: 3,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[600],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
        ),
      ),
    );
  }

  String _getProgressText() {
    if (movie.watchProgress == null) return '';

    final progressMinutes = movie.watchProgress! ~/ 60;
    final totalMinutes = movie.duration;
    final remainingMinutes = totalMinutes - progressMinutes;

    if (remainingMinutes <= 5) {
      return 'Casi terminada';
    } else if (progressMinutes < 5) {
      return 'Recién comenzada';
    } else {
      return '${remainingMinutes}min restantes';
    }
  }
}

class MovieGrid extends StatelessWidget {
  final List<MovieModel> movies;
  final int crossAxisCount;

  const MovieGrid({
    Key? key,
    required this.movies,
    this.crossAxisCount = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        return MovieCard(movie: movies[index]);
      },
    );
  }
}