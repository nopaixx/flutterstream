import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../data/models/movie_model.dart';
import '../../core/providers/content_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/p2p_service.dart';
import '../../core/models/p2p_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/p2p_utils.dart';
import '../widgets/custom_button.dart';
import '../widgets/p2p_stats_widget.dart';
import '../widgets/p2p_connection_indicator.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MovieModel movie;

  const VideoPlayerScreen({
    Key? key,
    required this.movie,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  // 🚀 LIVEVAULTHUB P2P PLAYER - flutter_inappwebview
  InAppWebViewController? _webViewController;
  late P2PService _p2pService;

  // Player state
  bool _isPlayerReady = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _showControls = true;
  bool _showP2PStats = false;
  double _currentTime = 0.0;
  double _duration = 0.0;

  // P2P state
  P2PStats _p2pStats = P2PStats.empty;
  P2PState _p2pState = P2PState.initializing;

  // UI Controllers
  late AnimationController _controlsAnimationController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _controlsAnimation;
  late Animation<double> _loadingAnimation;
  Timer? _controlsTimer;

  // Streams
  StreamSubscription<P2PStats>? _statsSubscription;
  StreamSubscription<P2PState>? _stateSubscription;
  StreamSubscription<P2PEvent>? _eventSubscription;
  StreamSubscription<P2PError>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _p2pService = P2PService.instance;
    _setupAnimations();
    _setupSystemUI();
    _setupP2PListeners();
    _startControlsTimer();
  }

  void _setupAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _controlsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    ));

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_loadingAnimationController);

    _controlsAnimationController.forward();
  }

  void _setupSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  void _setupP2PListeners() {
    // Estadísticas P2P
    _statsSubscription = _p2pService.stats.listen((stats) {
      if (mounted) {
        setState(() {
          _p2pStats = stats;
        });
      }
    });

    // Estado P2P
    _stateSubscription = _p2pService.state.listen((state) {
      if (mounted) {
        setState(() {
          _p2pState = state;
        });
      }
    });

    // Eventos P2P
    _eventSubscription = _p2pService.events.listen((event) {
      _handleP2PEvent(event);
    });

    // Errores P2P
    _errorSubscription = _p2pService.errors.listen((error) {
      _handleP2PError(error);
    });

    // En web, timeout para forzar carga si no llega player_ready
    if (kIsWeb) {
      Timer(const Duration(seconds: 8), () {
        if (mounted && !_isPlayerReady && _isLoading) {
          P2PUtils.logP2PEvent('Web timeout - forcing video load');
          setState(() {
            _isPlayerReady = true;
          });
          _loadVideo();
        }
      });
    }
  }

  void _handleP2PEvent(P2PEvent event) {
    if (!mounted) return;

    P2PUtils.logP2PDebug('Handling P2P event', {'type': event.type.name, 'data': event.data});

    switch (event.type) {
      case P2PEventType.playerReady:
        setState(() {
          _isPlayerReady = true;
        });
        _loadVideo();
        break;

      case P2PEventType.metadataLoaded:
        setState(() {
          _isLoading = false;
          _duration = event.data['duration']?.toDouble() ?? 0.0;
        });
        break;

      case P2PEventType.play:
        setState(() {
          _isPlaying = true;
        });
        break;

      case P2PEventType.pause:
        setState(() {
          _isPlaying = false;
        });
        break;

      case P2PEventType.timeUpdate:
        final currentTime = event.data['currentTime']?.toDouble() ?? 0.0;
        setState(() {
          _currentTime = currentTime;
        });
        _updateWatchProgress(currentTime);
        break;

      case P2PEventType.ended:
        setState(() {
          _isPlaying = false;
        });
        _handleVideoEnded();
        break;

      case P2PEventType.error:
        _handlePlayerError(event.data['message'] ?? 'Error desconocido');
        break;

      case P2PEventType.peerConnect:
        _showP2PNotification('Peer conectado: ${event.data['peerId']}');
        break;

      default:
        break;
    }
  }

  void _handleP2PError(P2PError error) {
    P2PUtils.logP2PError('P2P Error in player', error);

    if (error.code == 'CONNECTION_FAILED') {
      _showP2PNotification('P2P: Usando CDN como respaldo', isError: true);
    }
  }

  void _showP2PNotification(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.orange : AppTheme.primaryPurple,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _loadVideo() async {
    if (_webViewController == null) {
      P2PUtils.logP2PError('WebView controller not available');
      return;
    }

    try {
      P2PUtils.logP2PEvent('Loading video', {
        'movieId': widget.movie.id,
        'url': widget.movie.videoUrl,
        'isLive': widget.movie.duration == 0,
        'platform': kIsWeb ? 'web' : 'native',
        'playerReady': _isPlayerReady,
      });

      final config = P2PUtils.createOptimalConfig(
        widget.movie.id,
        isLive: widget.movie.duration == 0,
        enableDebug: true,
      );

      await _p2pService.loadVideo(widget.movie.videoUrl, config: config);

    } catch (e) {
      P2PUtils.logP2PError('Failed to load video', e);
      _handlePlayerError('Error al cargar el video: $e');
    }
  }

  void _handlePlayerError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _isLoading = false;
    });
  }

  void _handleVideoEnded() {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Marcar como completado
    contentProvider.updateWatchProgress(
      widget.movie.id,
      widget.movie.duration * 60, // Convertir a segundos
      authProvider,
    );
  }

  void _updateWatchProgress(double currentTime) {
    if (currentTime.toInt() % 30 == 0) { // Cada 30 segundos
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      contentProvider.updateWatchProgress(
        widget.movie.id,
        currentTime.toInt(),
        authProvider,
      );
    }
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    _loadingAnimationController.dispose();
    _controlsTimer?.cancel();

    // Cancelar suscripciones P2P
    _statsSubscription?.cancel();
    _stateSubscription?.cancel();
    _eventSubscription?.cancel();
    _errorSubscription?.cancel();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🎬 WebView Player
          _buildWebViewPlayer(),

          // 🎮 Controls Overlay
          if (_showControls) _buildControlsOverlay(),

          // 📊 P2P Stats
          if (_showP2PStats) _buildP2PStatsOverlay(),

          // ⏳ Loading Overlay
          if (_isLoading) _buildLoadingOverlay(),

          // ❌ Error Overlay
          if (_hasError) _buildErrorOverlay(),

          // 🔙 Back Button
          _buildBackButton(),

          // 📡 P2P Status Indicator
          _buildP2PStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildWebViewPlayer() {
    return GestureDetector(
      onTap: _onScreenTap,
      child: InAppWebView(
        onWebViewCreated: (controller) async {
          _webViewController = controller;
          try {
            await _p2pService.initialize(controller);
          } catch (e) {
            P2PUtils.logP2PError('Failed to initialize P2P service', e);
            // En web, continuar sin P2P si falla la inicialización
            if (kIsWeb) {
              setState(() {
                _isPlayerReady = true;
              });
              _loadVideo();
            } else {
              _handlePlayerError('Error inicializando P2P: $e');
            }
          }
        },
        onLoadStart: (controller, url) {
          P2PUtils.logP2PDebug('WebView loading started', {'url': url.toString()});
        },
        onLoadStop: (controller, url) async {
          P2PUtils.logP2PDebug('WebView loading finished', {'url': url.toString()});
        },
        onConsoleMessage: (controller, consoleMessage) {
          P2PUtils.logP2PDebug('WebView Console: ${consoleMessage.message}');
        },
        onLoadError: (controller, url, code, message) {
          P2PUtils.logP2PError('WebView error', {'code': code, 'message': message});

          // En web, algunos errores son esperados, ser más permisivo
          if (kIsWeb && (code == -1 || message.contains('net::ERR_FILE_NOT_FOUND'))) {
            P2PUtils.logP2PDebug('Web WebView error ignored: $message');
            return;
          }

          _handlePlayerError('Error cargando player: $message');
        },
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          allowsInlineMediaPlayback: true,
          mediaPlaybackRequiresUserGesture: false,
          allowUniversalAccessFromFileURLs: true,
          allowFileAccessFromFileURLs: true,
          isInspectable: true, // Para debugging
          clearCache: false,
          cacheEnabled: true,
        ),
        initialFile: "assets/webview/player.html",
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return FadeTransition(
      opacity: _controlsAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildTopControls(),
            Expanded(
              child: Center(
                child: _buildCenterPlayButton(),
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.movie.duration == 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'EN VIVO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            P2PToolbarIndicator(
              state: _p2pState,
              peers: _p2pStats.peers,
              onTap: () {
                setState(() {
                  _showP2PStats = !_showP2PStats;
                });
              },
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: _showMoreOptions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPlayButton() {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient.scale(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress Bar (only for VOD)
            if (widget.movie.duration > 0) ...[
              Row(
                children: [
                  Text(
                    P2PUtils.formatDuration(_currentTime),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Expanded(
                    child: Slider(
                      value: _duration > 0 ? _currentTime / _duration : 0.0,
                      onChanged: (value) {
                        final newTime = value * _duration;
                        _seekTo(newTime);
                      },
                      activeColor: AppTheme.primaryViolet,
                      inactiveColor: Colors.white24,
                    ),
                  ),
                  Text(
                    P2PUtils.formatDuration(_duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: widget.movie.isInMyList ? Icons.check : Icons.add,
                  label: 'Mi Lista',
                  onPressed: _toggleMyList,
                ),
                _buildControlButton(
                  icon: Icons.share,
                  label: 'Compartir',
                  onPressed: _shareStream,
                ),
                _buildControlButton(
                  icon: Icons.analytics,
                  label: 'Estadísticas',
                  onPressed: () {
                    setState(() {
                      _showP2PStats = !_showP2PStats;
                    });
                  },
                ),
                _buildControlButton(
                  icon: Icons.settings,
                  label: 'Calidad',
                  onPressed: _showQualitySettings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildP2PStatsOverlay() {
    return Positioned(
      top: 100,
      right: 16,
      child: P2PStatsWidget(
        stats: _p2pStats,
        state: _p2pState,
        isExpanded: true,
        onClose: () {
          setState(() {
            _showP2PStats = false;
          });
        },
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _loadingAnimation.value * 2 * 3.14159,
                  child: Container(
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
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Iniciando LiveVaultHub Player...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _p2pState.description,
              style: TextStyle(
                color: AppTheme.textGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Error de Reproducción',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Error desconocido',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.textGrey),
                      ),
                      child: Text('Volver', style: TextStyle(color: AppTheme.textGrey)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Reintentar',
                      onPressed: _retryLoad,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return SafeArea(
      child: Positioned(
        top: 16,
        left: 16,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _buildP2PStatusIndicator() {
    return Positioned(
      top: 80,
      left: 16,
      child: SafeArea(
        child: P2PConnectionIndicator(
          state: _p2pState,
          peers: _p2pStats.peers,
          compact: true,
          onTap: () {
            setState(() {
              _showP2PStats = !_showP2PStats;
            });
          },
        ),
      ),
    );
  }

  // Control Methods
  void _togglePlayPause() {
    if (_isPlaying) {
      _p2pService.pause();
    } else {
      _p2pService.play();
    }
    _resetControlsTimer();
  }

  void _seekTo(double time) {
    _p2pService.seekTo(time);
    setState(() {
      _currentTime = time;
    });
  }

  void _toggleMyList() async {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await contentProvider.toggleMyList(
      widget.movie.id,
      context,
      authProvider,
    );

    if (success && authProvider.isLoggedIn && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.movie.isInMyList ? 'Eliminado de Mi Lista' : 'Agregado a Mi Lista',
          ),
          backgroundColor: AppTheme.primaryPurple,
        ),
      );
    }
  }

  void _shareStream() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Función de compartir próximamente'),
        backgroundColor: AppTheme.primaryPurple,
      ),
    );
  }

  void _showQualitySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Calidad automática P2P optimizada'),
        backgroundColor: AppTheme.primaryPurple,
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildMoreOptionsSheet(),
    );
  }

  Widget _buildMoreOptionsSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white),
            title: const Text('Información del Stream', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showStreamInfo();
            },
          ),
          ListTile(
            leading: Icon(
              _p2pState == P2PState.disabled ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
            ),
            title: Text(
              _p2pState == P2PState.disabled ? 'Habilitar P2P' : 'Deshabilitar P2P',
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              if (_p2pState == P2PState.disabled) {
                _p2pService.enableP2P();
              } else {
                _p2pService.disableP2P();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.white),
            title: const Text('Diagnóstico P2P', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showP2PDiagnostic();
            },
          ),
        ],
      ),
    );
  }

  void _showStreamInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(widget.movie.title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Tipo', widget.movie.duration == 0 ? 'Live Stream' : 'VOD'),
            _buildInfoRow('Estado P2P', _p2pState.description),
            _buildInfoRow('Peers', _p2pStats.peers.toString()),
            _buildInfoRow('Ratio P2P', _p2pStats.p2pRatioFormatted),
            _buildInfoRow('Descargado', _p2pStats.downloadedMB),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: AppTheme.primaryViolet)),
          ),
        ],
      ),
    );
  }

  void _showP2PDiagnostic() {
    final diagnostic = _p2pService.getDiagnosticInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkGrey,
        title: const Text('Diagnóstico P2P', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(
            diagnostic.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: AppTheme.primaryViolet)),
          ),
        ],
      ),
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
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _retryLoad() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _isLoading = true;
    });
    _loadVideo();
  }

  void _startControlsTimer() {
    _resetControlsTimer();
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls && _isPlaying) {
        setState(() {
          _showControls = false;
        });
        _controlsAnimationController.reverse();
      }
    });
  }

  void _onScreenTap() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _controlsAnimationController.forward();
      _resetControlsTimer();
    } else {
      _controlsAnimationController.reverse();
    }
  }
}

// Extension para gradientes
extension GradientExtension on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((color) => color.withOpacity(opacity)).toList(),
    );
  }
}