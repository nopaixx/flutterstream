import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../data/models/movie_model.dart';
import '../../core/providers/content_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
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

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  // 🚀 WEBVIEW_FLUTTER P2P PLAYER
  late final WebViewController _webViewController;
  bool _isPlayerReady = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _showControls = true;
  bool _showP2PStats = false;

  // Player state
  double _currentTime = 0.0;
  double _duration = 0.0;
  Map<String, dynamic>? _p2pStats;

  // UI Controllers
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;
  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupSystemUI();
    _initializeWebView();
    _startControlsTimer();
  }

  void _setupAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controlsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    ));

    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
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

  void _initializeWebView() {
    try {
      // 🚀 INICIALIZACIÓN ROBUSTA DE WEBVIEW
      _webViewController = WebViewController();

      // Configurar WebView paso a paso
      _configureWebView();

    } catch (e) {
      print('Error initializing WebView: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error inicializando WebView: $e';
        _isLoading = false;
      });
    }
  }

  void _configureWebView() async {
    try {
      // Paso 1: Configurar JavaScript
      await _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);

      // Paso 2: Configurar navegación
      await _webViewController.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('🌐 WebView started loading: $url');
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            print('✅ WebView finished loading: $url');
            _initializePlayer();
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description}');
            setState(() {
              _hasError = true;
              _errorMessage = 'Error cargando player: ${error.description}';
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('📍 Navigation request: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      );

      // Paso 3: Configurar canal JavaScript
      await _webViewController.addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          print('📨 Message from WebView: ${message.message}');
          _handlePlayerMessage(message.message);
        },
      );

      // Paso 4: Cargar HTML
      final htmlContent = await _loadPlayerHTML();
      await _webViewController.loadHtmlString(htmlContent);

    } catch (e) {
      print('Error configuring WebView: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error configurando WebView: $e';
        _isLoading = false;
      });
    }
  }

  Future<String> _loadPlayerHTML() async {
    // HTML Player embebido directamente (sin assets para evitar problemas)
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LiveVaultHub P2P Player</title>
    
    <!-- Styles -->
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            background: #000; 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            overflow: hidden;
            height: 100vh;
            width: 100vw;
        }
        #player-container {
            width: 100vw;
            height: 100vh;
            position: relative;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        video {
            width: 100%;
            height: 100%;
            object-fit: contain;
        }
        .loading {
            color: white;
            text-align: center;
            font-size: 18px;
        }
        .error {
            color: #ff6b6b;
            text-align: center;
            font-size: 16px;
        }
    </style>
</head>
<body>
    <div id="player-container">
        <div class="loading" id="loading">
            <h2>🚀 Iniciando LiveVaultHub Player...</h2>
            <p>Conectando red P2P...</p>
        </div>
        
        <video 
            id="video-player" 
            controls 
            playsinline 
            webkit-playsinline
            style="display: none;"
        >
            Tu navegador no soporta video HTML5.
        </video>
        
        <div class="error" id="error" style="display: none;">
            <h2>❌ Error de Reproducción</h2>
            <p id="error-message">No se pudo cargar el video</p>
        </div>
    </div>

    <script>
        class LiveVaultHubPlayer {
            constructor() {
                this.player = document.getElementById('video-player');
                this.loading = document.getElementById('loading');
                this.error = document.getElementById('error');
                this.currentUrl = null;
                
                console.log('🎬 LiveVaultHub Player initialized');
                this.setupEventListeners();
                this.notifyFlutter('player_ready');
            }
            
            setupEventListeners() {
                this.player.addEventListener('loadstart', () => {
                    this.notifyFlutter('loadstart');
                });
                
                this.player.addEventListener('loadedmetadata', () => {
                    this.hideLoading();
                    this.notifyFlutter('loadedmetadata', {
                        duration: this.player.duration,
                        videoWidth: this.player.videoWidth,
                        videoHeight: this.player.videoHeight
                    });
                });
                
                this.player.addEventListener('canplay', () => {
                    this.notifyFlutter('canplay');
                });
                
                this.player.addEventListener('play', () => {
                    this.notifyFlutter('play');
                });
                
                this.player.addEventListener('pause', () => {
                    this.notifyFlutter('pause');
                });
                
                this.player.addEventListener('timeupdate', () => {
                    this.notifyFlutter('timeupdate', {
                        currentTime: this.player.currentTime,
                        duration: this.player.duration
                    });
                });
                
                this.player.addEventListener('ended', () => {
                    this.notifyFlutter('ended');
                });
                
                this.player.addEventListener('error', (e) => {
                    console.error('Player error:', e);
                    this.showError('Error de reproducción del video');
                });
            }
            
            loadVideo(url, options = {}) {
                console.log('🎥 Loading video:', url);
                this.currentUrl = url;
                
                this.showLoading();
                this.hideError();
                
                this.player.src = url;
                this.player.style.display = 'block';
                
                // Simular estadísticas P2P
                this.simulateP2PStats();
                
                this.notifyFlutter('video_loading', { url: url });
            }
            
            play() {
                this.player.play().catch(e => {
                    console.error('Play failed:', e);
                    this.showError('No se pudo reproducir el video');
                });
            }
            
            pause() {
                this.player.pause();
            }
            
            seekTo(time) {
                this.player.currentTime = time;
            }
            
            simulateP2PStats() {
                // Simular estadísticas P2P cada 3 segundos
                setInterval(() => {
                    const stats = {
                        peers: Math.floor(Math.random() * 20) + 10,
                        downloaded: Math.floor(Math.random() * 1000000),
                        uploaded: Math.floor(Math.random() * 500000),
                        p2pRatio: Math.floor(Math.random() * 30) + 60
                    };
                    
                    this.notifyFlutter('p2p_stats', { stats: stats });
                }, 3000);
            }
            
            showLoading() {
                this.loading.style.display = 'block';
                this.player.style.display = 'none';
                this.error.style.display = 'none';
            }
            
            hideLoading() {
                this.loading.style.display = 'none';
                this.player.style.display = 'block';
            }
            
            showError(message) {
                document.getElementById('error-message').textContent = message;
                this.error.style.display = 'block';
                this.loading.style.display = 'none';
                this.player.style.display = 'none';
                
                this.notifyFlutter('error', { message: message });
            }
            
            hideError() {
                this.error.style.display = 'none';
            }
            
            notifyFlutter(type, data = {}) {
                const message = {
                    type: type,
                    ...data,
                    timestamp: Date.now()
                };
                
                try {
                    // Enviar a Flutter via JavaScriptChannel
                    if (window.FlutterBridge && window.FlutterBridge.postMessage) {
                        window.FlutterBridge.postMessage(JSON.stringify(message));
                    }
                    
                    console.log('📤 Sent to Flutter:', message);
                } catch (error) {
                    console.error('❌ Error sending to Flutter:', error);
                }
            }
            
            // Manejar mensajes de Flutter
            handleFlutterMessage(messageData) {
                try {
                    const data = typeof messageData === 'string' ? JSON.parse(messageData) : messageData;
                    console.log('📥 Received from Flutter:', data);
                    
                    switch(data.action) {
                        case 'loadVideo':
                            this.loadVideo(data.url, data.options || {});
                            break;
                        case 'play':
                            this.play();
                            break;
                        case 'pause':
                            this.pause();
                            break;
                        case 'seekTo':
                            this.seekTo(data.time);
                            break;
                        default:
                            console.log('Unknown action:', data.action);
                    }
                } catch (error) {
                    console.error('Error handling Flutter message:', error);
                }
            }
        }
        
        // Función global para Flutter
        function sendMessageToPlayer(message) {
            if (window.lvhPlayer) {
                window.lvhPlayer.handleFlutterMessage(message);
            }
        }
        
        // Inicializar cuando DOM esté listo
        document.addEventListener('DOMContentLoaded', () => {
            window.lvhPlayer = new LiveVaultHubPlayer();
        });
        
        // Fallback si ya está cargado
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => {
                if (!window.lvhPlayer) {
                    window.lvhPlayer = new LiveVaultHubPlayer();
                }
            });
        } else if (!window.lvhPlayer) {
            window.lvhPlayer = new LiveVaultHubPlayer();
        }
    </script>
</body>
</html>
    ''';
  }

  void _initializePlayer() {
    final script = '''
      if (window.lvhPlayer) {
        window.lvhPlayer.loadVideo('${widget.movie.videoUrl}', {
          isLive: ${widget.movie.duration == 0},
          startTime: ${widget.movie.watchProgress ?? 0}
        });
      } else {
        console.log('❌ Player not ready yet');
      }
    ''';

    _webViewController.runJavaScript(script);
  }

  void _handlePlayerMessage(String message) {
    try {
      print('📨 Received message: $message');

      // Parsing simple para evitar errores complejos
      String type = 'unknown';
      Map<String, dynamic> data = {};

      if (message.contains('player_ready')) type = 'player_ready';
      else if (message.contains('play')) type = 'play';
      else if (message.contains('pause')) type = 'pause';
      else if (message.contains('loadedmetadata')) type = 'loadedmetadata';
      else if (message.contains('error')) type = 'error';

      print('📨 Handling message type: $type');

      switch (type) {
        case 'player_ready':
          setState(() {
            _isPlayerReady = true;
          });
          break;

        case 'loadedmetadata':
          setState(() {
            _isLoading = false;
            _duration = 3600.0; // Duración simulada
          });
          break;

        case 'play':
          setState(() {
            _isPlaying = true;
          });
          break;

        case 'pause':
          setState(() {
            _isPlaying = false;
          });
          break;

        case 'error':
          setState(() {
            _hasError = true;
            _errorMessage = 'Error de reproducción';
            _isLoading = false;
          });
          break;
      }
    } catch (e) {
      print('❌ Error processing player message: $e');
    }
  }

  void _sendMessageToPlayer(String action, [Map<String, dynamic>? data]) {
    final message = {
      'action': action,
      if (data != null) ...data,
    };

    final script = '''
      sendMessageToPlayer(${message.toString().replaceAll("'", '"')});
    ''';

    _webViewController.runJavaScript(script).catchError((e) {
      print('❌ Error sending message to player: $e');
    });
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    _loadingAnimationController.dispose();
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

          // 🎮 Native Flutter Controls Overlay
          if (_showControls) _buildControlsOverlay(),

          // 📊 P2P Stats Overlay
          if (_showP2PStats) _buildP2PStatsOverlay(),

          // ⏳ Loading Overlay
          if (_isLoading) _buildLoadingOverlay(),

          // ❌ Error Overlay
          if (_hasError) _buildErrorOverlay(),

          // 🔙 Back Button
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildWebViewPlayer() {
    return GestureDetector(
      onTap: _onScreenTap,
      child: WebViewWidget(
        controller: _webViewController,
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
            // Top Controls
            _buildTopControls(),

            // Center Play Button
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
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
                    child: IconButton(
                      iconSize: 64,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Controls
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
            // Movie Title
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

            // P2P Stats Toggle
            IconButton(
              icon: Icon(
                _showP2PStats ? Icons.analytics : Icons.analytics_outlined,
                color: _showP2PStats ? AppTheme.primaryViolet : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showP2PStats = !_showP2PStats;
                });
                _sendMessageToPlayer('toggleP2PStats', {'show': _showP2PStats});
              },
            ),

            // More Options
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: _showMoreOptions,
            ),
          ],
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
                    _formatDuration(_currentTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
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
                    _formatDuration(_duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // My List
                _buildControlButton(
                  icon: widget.movie.isInMyList
                      ? Icons.check
                      : Icons.add,
                  label: 'Mi Lista',
                  onPressed: _toggleMyList,
                ),

                // Download (placeholder)
                _buildControlButton(
                  icon: Icons.download,
                  label: 'Descargar',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Descarga disponible próximamente'),
                        backgroundColor: AppTheme.primaryPurple,
                      ),
                    );
                  },
                ),

                // Share
                _buildControlButton(
                  icon: Icons.share,
                  label: 'Compartir',
                  onPressed: _shareStream,
                ),

                // Quality (placeholder)
                _buildControlButton(
                  icon: Icons.hd,
                  label: 'Calidad',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Calidad automática P2P optimizada'),
                        backgroundColor: AppTheme.primaryPurple,
                      ),
                    );
                  },
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildP2PStatsOverlay() {
    return Positioned(
      top: 100,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient.scale(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'P2P Stats',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStatRow('Status', 'Connecting...'),
            _buildStatRow('Peers', '0'),
            _buildStatRow('P2P Ratio', '0%'),
            _buildStatRow('Downloaded', '0 MB'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
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
              'Iniciando P2P Player...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Conectando a la red descentralizada',
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
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
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
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 14,
                ),
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
                      child: Text(
                        'Volver',
                        style: TextStyle(color: AppTheme.textGrey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Reintentar',
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _errorMessage = null;
                          _isLoading = true;
                        });
                        _initializePlayer();
                      },
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

  // Control Methods
  void _togglePlayPause() {
    if (_isPlaying) {
      _sendMessageToPlayer('pause');
    } else {
      _sendMessageToPlayer('play');
    }
    _resetControlsTimer();
  }

  void _seekTo(double time) {
    _sendMessageToPlayer('seekTo', {'time': time});
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
            widget.movie.isInMyList
                ? 'Eliminado de Mi Lista'
                : 'Agregado a Mi Lista',
          ),
          backgroundColor: AppTheme.primaryPurple,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareStream() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Compartir stream - Próximamente'),
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
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text('Información del Stream', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showStreamInfo();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.white),
                title: const Text('Reportar Problema', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Reporte enviado'),
                      backgroundColor: AppTheme.primaryPurple,
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

  void _showStreamInfo() {
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
        title: Text(
          widget.movie.title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Tipo', widget.movie.duration == 0 ? 'Live Stream' : 'Video On Demand'),
            _buildInfoRow('Género', widget.movie.genre),
            _buildInfoRow('Rating', '${widget.movie.rating}/10'),
            if (widget.movie.duration > 0)
              _buildInfoRow('Duración', widget.movie.formattedDuration),
            _buildInfoRow('Tecnología', 'P2P + CDN Híbrido'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: TextStyle(color: AppTheme.primaryViolet),
            ),
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
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppTheme.textGrey,
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

  // Utility Methods
  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    if (duration.inHours > 0) {
      return "${duration.inHours}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
    } else {
      return "${duration.inMinutes}:${twoDigits(duration.inSeconds.remainder(60))}";
    }
  }

  void _updateWatchProgress() {
    if (_currentTime > 0 && _currentTime.toInt() % 30 == 0) {
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      contentProvider.updateWatchProgress(
        widget.movie.id,
        _currentTime.toInt(),
        authProvider,
      );
    }
  }

  void _startControlsTimer() {
    _resetControlsTimer();
  }

  void _resetControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
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