import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/movie_model.dart';
import '../../core/providers/content_provider.dart';
import '../widgets/custom_button.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MovieModel movie;

  const VideoPlayerScreen({
    Key? key,
    required this.movie,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.movie.videoUrl),
      );

      _initializeVideoPlayerFuture = _controller.initialize().then((_) {
        // Saltar al progreso guardado si existe
        if (widget.movie.watchProgress != null && widget.movie.watchProgress! > 0) {
          _controller.seekTo(Duration(seconds: widget.movie.watchProgress!));
        }

        // Agregar listener para el progreso
        _controller.addListener(_onVideoProgressChanged);

        setState(() {});
      }).catchError((error) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error al cargar el video: ${error.toString()}';
        });
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error al inicializar el video: ${e.toString()}';
      });
    }
  }

  void _onVideoProgressChanged() {
    if (_controller.value.isInitialized) {
      final progress = _controller.value.position.inSeconds;
      if (progress > 0 && progress % 30 == 0) {
        // Actualizar progreso cada 30 segundos
        Provider.of<ContentProvider>(context, listen: false)
            .updateWatchProgress(widget.movie.id, progress);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoProgressChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cast, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de cast próximamente'),
                  backgroundColor: Color(0xFFE50914),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildVideoPlayer(),
          Expanded(
            child: _buildMovieInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.black,
      child: _hasError
          ? _buildErrorWidget()
          : FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                children: [
                  VideoPlayer(_controller),
                  _buildVideoControls(),
                ],
              ),
            );
          } else {
            return _buildLoadingWidget();
          }
        },
      ),
    );
  }

  Widget _buildVideoControls() {
    return Positioned(
      bottom: 10,
      left: 10,
      right: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
            },
          ),
          Expanded(
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFFE50914),
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Error al cargar el video',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
              });
              _initializeVideoPlayer();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFE50914),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando video...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 64,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildMovieInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y año
          Text(
            widget.movie.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Información básica
          Text(
            widget.movie.movieInfo,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          // Rating
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                widget.movie.rating.toString(),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Descripción
          Text(
            widget.movie.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Botones de acción
          _buildActionButtons(),
          const SizedBox(height: 20),

          // Información adicional
          _buildAdditionalInfo(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<ContentProvider>(
      builder: (context, contentProvider, child) {
        final isInMyList = widget.movie.isInMyList;

        return Column(
          children: [
            // Botón principal de reproducir
            SizedBox(
              width: double.infinity,
              height: 50,
              child: CustomButton(
                text: widget.movie.watchProgress != null && widget.movie.watchProgress! > 0
                    ? 'Continuar reproduciendo'
                    : 'Reproducir',
                icon: Icons.play_arrow,
                onPressed: () {
                  if (_controller.value.isInitialized) {
                    _controller.play();
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // Botones secundarios
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final success = await contentProvider.toggleMyList(widget.movie.id);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isInMyList
                                  ? 'Eliminado de Mi Lista'
                                  : 'Agregado a Mi Lista',
                            ),
                            backgroundColor: const Color(0xFFE50914),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      isInMyList ? Icons.check : Icons.add,
                      color: Colors.white,
                    ),
                    label: Text(
                      isInMyList ? 'En Mi Lista' : 'Mi Lista',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Función de descarga próximamente'),
                          backgroundColor: Color(0xFFE50914),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text(
                      'Descargar',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Género', widget.movie.genre),
        _buildInfoRow('Duración', widget.movie.formattedDuration),
        _buildInfoRow('Año', widget.movie.year.toString()),
        _buildInfoRow('Calificación', '${widget.movie.rating}/10'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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

  void _showMoreOptions() {
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

              ListTile(
                leading: const Icon(Icons.share, color: Colors.white),
                title: const Text('Compartir', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de compartir próximamente'),
                      backgroundColor: Color(0xFFE50914),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.white),
                title: const Text('Reportar problema', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gracias por tu reporte'),
                      backgroundColor: Color(0xFFE50914),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}