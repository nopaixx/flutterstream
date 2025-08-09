import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:rxdart/rxdart.dart';
import '../models/p2p_models.dart';
import '../utils/p2p_utils.dart';

/// Servicio central para manejo del sistema P2P
class P2PService extends ChangeNotifier {
  /// Controller del WebView
  InAppWebViewController? _webViewController;

  /// Streams para eventos
  final _eventController = StreamController<P2PEvent>.broadcast();
  final _statsController = BehaviorSubject<P2PStats>();
  final _stateController = BehaviorSubject<P2PState>();
  final _errorController = StreamController<P2PError>.broadcast();

  /// Estado actual
  P2PStats _currentStats = P2PStats.empty;
  P2PState _currentState = P2PState.initializing;
  P2PConfig? _currentConfig;
  bool _isInitialized = false;

  /// Timer para polling en web
  Timer? _webPollingTimer;

  /// Constructor
  P2PService() {
    // Inicializar streams con valores por defecto
    _statsController.add(_currentStats);
    _stateController.add(_currentState);
  }

  /// Getters para streams
  Stream<P2PEvent> get events => _eventController.stream;
  Stream<P2PStats> get stats => _statsController.stream;
  Stream<P2PState> get state => _stateController.stream;
  Stream<P2PError> get errors => _errorController.stream;

  /// Getters para valores actuales
  P2PStats get currentStats => _currentStats;
  P2PState get currentState => _currentState;
  bool get isInitialized => _isInitialized;
  bool get isConnected => _currentState.isActive;

  /// Inicializar el servicio con WebView
  Future<void> initialize(InAppWebViewController controller) async {
    _webViewController = controller;

    // Configurar canal de comunicación según plataforma
    if (kIsWeb) {
      // En web, usamos window.postMessage para comunicación
      await _setupWebCommunication();
    } else {
      // En móvil/desktop, usamos JavaScript handler nativo
      _webViewController!.addJavaScriptHandler(
        handlerName: 'FlutterBridge',
        callback: (args) {
          if (args.isNotEmpty) {
            _handleWebViewMessage(args.first.toString());
          }
        },
      );
    }

    _updateState(P2PState.connecting);
    P2PUtils.logP2PEvent('Service initialized', {'platform': kIsWeb ? 'web' : 'native'});
  }

  /// Configurar comunicación para web
  Future<void> _setupWebCommunication() async {
    try {
      // En web, inyectamos JavaScript para escuchar mensajes
      await _webViewController!.evaluateJavascript(source: '''
        // Limpiar listeners previos
        window.flutterMessageQueue = [];
        
        // Configurar listener para recibir mensajes del player
        window.addEventListener('message', function(event) {
          if (event.data && event.data.type) {
            console.log('Flutter received:', event.data);
            window.flutterMessageQueue = window.flutterMessageQueue || [];
            window.flutterMessageQueue.push(JSON.stringify(event.data));
          }
        });
        
        // Función global para que el player envíe mensajes
        window.sendToFlutter = function(data) {
          console.log('Sending to Flutter:', data);
          window.flutterMessageQueue = window.flutterMessageQueue || [];
          window.flutterMessageQueue.push(JSON.stringify(data));
        };
        
        // Forzar notificación de player ready
        setTimeout(() => {
          if (window.lvhPlayer) {
            window.sendToFlutter({type: 'player_ready', timestamp: Date.now()});
          } else {
            console.log('Player not found, will retry...');
          }
        }, 2000);
        
        console.log('Web communication setup complete');
        true;
      ''');

      // Iniciar polling inmediatamente
      _startWebMessagePolling();

      // Timeout para forzar player ready si no llega
      Timer(const Duration(seconds: 5), () {
        if (!_isInitialized) {
          P2PUtils.logP2PEvent('Forcing player ready in web');
          _handleWebViewMessage('{"type":"player_ready","timestamp":${DateTime.now().millisecondsSinceEpoch}}');
        }
      });

      P2PUtils.logP2PEvent('Web communication setup successful');
    } catch (e) {
      P2PUtils.logP2PError('Web communication setup failed', e);
      _updateState(P2PState.disabled);
    }
  }

  /// Polling de mensajes para web
  void _startWebMessagePolling() {
    _webPollingTimer?.cancel();
    _webPollingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_webViewController == null) {
        timer.cancel();
        return;
      }

      try {
        final result = await _webViewController!.evaluateJavascript(source: '''
          if (window.flutterMessageQueue && window.flutterMessageQueue.length > 0) {
            const messages = window.flutterMessageQueue.splice(0);
            JSON.stringify(messages);
          } else {
            null;
          }
        ''');

        if (result != null && result.toString() != 'null') {
          try {
            final messageList = json.decode(result.toString()) as List;
            final messages = messageList.map((item) => item.toString()).toList();

            for (final message in messages) {
              _handleWebViewMessage(message);
            }
          } catch (e) {
            P2PUtils.logP2PDebug('Error parsing web messages: $e');
          }
        }
      } catch (e) {
        // Ignorar errores de polling silenciosamente
      }
    });
  }

  /// Cargar video con configuración P2P
  Future<void> loadVideo(String url, {P2PConfig? config}) async {
    if (_webViewController == null) {
      throw Exception('P2P Service not initialized');
    }

    _currentConfig = config ?? P2PConfig.forMovie(
        P2PUtils.extractStreamId(url) ?? 'default'
    );

    P2PUtils.logP2PEvent('Starting video load', {
      'url': url,
      'platform': kIsWeb ? 'web' : 'native',
      'isInitialized': _isInitialized,
    });

    if (kIsWeb) {
      // En web, cargar video directamente sin P2P complejo
      await _loadVideoWeb(url);
    } else {
      // En móvil, usar configuración P2P completa
      final message = P2PUtils.createWebViewMessage('loadVideo', {
        'url': url,
        'p2pConfig': _currentConfig!.toJson(),
      });
      await _sendToWebView(message);
    }
  }

  /// Cargar video específico para web
  Future<void> _loadVideoWeb(String url) async {
    try {
      await _webViewController!.evaluateJavascript(source: '''
        console.log('Loading video in web:', '$url');
        
        if (window.lvhPlayer) {
          window.lvhPlayer.loadVideo('$url', {
            isLive: ${url.contains('.m3u8')},
            enableP2P: false  // Simplificar para web
          });
        } else {
          console.error('Player not ready for video load');
          // Reintentar en 1 segundo
          setTimeout(() => {
            if (window.lvhPlayer) {
              window.lvhPlayer.loadVideo('$url', {isLive: ${url.contains('.m3u8')}});
            }
          }, 1000);
        }
      ''');

      P2PUtils.logP2PEvent('Web video load initiated', {'url': url});
    } catch (e) {
      P2PUtils.logP2PError('Web video load failed', e);
      throw e;
    }
  }

  /// Controles de reproducción
  Future<void> play() async {
    await _sendToWebView(P2PUtils.createWebViewMessage('play'));
  }

  Future<void> pause() async {
    await _sendToWebView(P2PUtils.createWebViewMessage('pause'));
  }

  Future<void> seekTo(double time) async {
    await _sendToWebView(P2PUtils.createWebViewMessage('seekTo', {
      'time': time,
    }));
  }

  Future<void> setVolume(double volume) async {
    await _sendToWebView(P2PUtils.createWebViewMessage('setVolume', {
      'volume': volume,
    }));
  }

  /// Configuración P2P dinámica
  Future<void> enableP2P() async {
    await _sendToWebView(P2PUtils.createWebViewMessage('enableP2P'));
  }

  Future<void> disableP2P() async {
    await _sendToWebView(P2PUtils.createWebViewMessage('disableP2P'));
    _updateState(P2PState.disabled);
  }

  Future<void> updateP2PConfig(P2PConfig config) async {
    _currentConfig = config;
    await _sendToWebView(P2PUtils.createWebViewMessage('updateConfig', {
      'config': config.toJson(),
    }));
  }

  /// Obtener estadísticas de rendimiento
  Map<String, dynamic> getPerformanceStats() {
    return P2PUtils.calculatePerformanceStats(_currentStats);
  }

  /// Toggle estadísticas P2P en UI
  Future<void> toggleP2PStats(bool show) async {
    await _sendToWebView(P2PUtils.createWebViewMessage('toggleStats', {
      'show': show,
    }));
  }

  /// Manejo de mensajes del WebView
  void _handleWebViewMessage(String message) {
    if (P2PUtils.shouldThrottleEvent('webview_message', throttleMs: 100)) {
      return;
    }

    final data = P2PUtils.parseWebViewMessage(message);
    if (data == null) return;

    try {
      final event = P2PEvent.fromJson(data);
      _processP2PEvent(event);
    } catch (e) {
      P2PUtils.logP2PError('Error processing WebView message', e);
    }
  }

  /// Procesar eventos P2P
  void _processP2PEvent(P2PEvent event) {
    _eventController.add(event);

    switch (event.type) {
      case P2PEventType.playerReady:
        _isInitialized = true;
        P2PUtils.logP2PEvent('Player ready');
        break;

      case P2PEventType.stateChanged:
        final newState = P2PState.values.firstWhere(
              (state) => state.name == event.data['state'],
          orElse: () => P2PState.error,
        );
        _updateState(newState);
        break;

      case P2PEventType.statsUpdate:
        _updateStats(P2PStats.fromJson(event.data['stats'] ?? {}));
        break;

      case P2PEventType.peerConnect:
        P2PUtils.logP2PEvent('Peer connected', {
          'peerId': event.data['peerId'],
        });
        break;

      case P2PEventType.peerDisconnect:
        P2PUtils.logP2PEvent('Peer disconnected', {
          'peerId': event.data['peerId'],
        });
        break;

      case P2PEventType.segmentLoaded:
        if (!P2PUtils.shouldThrottleEvent('segment_loaded', throttleMs: 2000)) {
          P2PUtils.logP2PDebug('Segment loaded', {
            'source': event.data['source'],
            'bytes': event.data['bytes'],
          });
        }
        break;

      case P2PEventType.error:
        final error = P2PError.fromJson(event.data);
        _errorController.add(error);
        _updateState(P2PState.error);
        P2PUtils.logP2PError('P2P Error', error);
        break;

      default:
      // Otros eventos (play, pause, timeupdate, etc.)
        break;
    }

    notifyListeners();
  }

  /// Actualizar estado P2P
  void _updateState(P2PState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);

      P2PUtils.logP2PEvent('State changed', {
        'state': newState.name,
        'description': newState.description,
      });
    }
  }

  /// Actualizar estadísticas P2P
  void _updateStats(P2PStats newStats) {
    _currentStats = newStats;
    _statsController.add(newStats);

    // Log periódico de estadísticas (cada 10 segundos)
    if (!P2PUtils.shouldThrottleEvent('stats_log', throttleMs: 10000)) {
      P2PUtils.logP2PDebug('Stats update', {
        'peers': newStats.peers,
        'ratio': newStats.p2pRatioFormatted,
        'downloaded': newStats.downloadedMB,
      });
    }
  }

  /// Enviar mensaje al WebView
  Future<void> _sendToWebView(String message) async {
    if (_webViewController == null) return;

    try {
      if (kIsWeb) {
        // En web, enviamos mensaje directamente al player
        await _webViewController!.evaluateJavascript(source: '''
          if (window.lvhPlayer && window.lvhPlayer.handleFlutterMessage) {
            window.lvhPlayer.handleFlutterMessage($message);
          } else if (window.sendMessageToPlayer) {
            window.sendMessageToPlayer($message);
          } else {
            console.log('Player not ready for message:', $message);
          }
        ''');
      } else {
        // En plataformas nativas, usamos el método original
        await _webViewController!.evaluateJavascript(source: '''
          if (window.lvhPlayer && window.lvhPlayer.handleFlutterMessage) {
            window.lvhPlayer.handleFlutterMessage($message);
          } else {
            console.log('Player not ready for message: $message');
          }
        ''');
      }
    } catch (e) {
      P2PUtils.logP2PError('Error sending to WebView', e);
    }
  }

  /// Métodos de conveniencia para UI
  String get statusText => _currentState.description;

  String get connectionInfo {
    if (_currentStats.peers == 0) return 'Sin conexión P2P';
    return '${_currentStats.peers} peer${_currentStats.peers != 1 ? 's' : ''} conectado${_currentStats.peers != 1 ? 's' : ''}';
  }

  String get performanceSummary {
    if (_currentStats.totalDownloaded == 0) return 'Iniciando...';
    return 'P2P: ${_currentStats.p2pRatioFormatted} • Descargado: ${_currentStats.downloadedMB}';
  }

  Color get statusColor {
    switch (_currentState) {
      case P2PState.sharing:
        return const Color(0xFF4CAF50); // Verde
      case P2PState.connected:
        return const Color(0xFF2196F3); // Azul
      case P2PState.connecting:
        return const Color(0xFFFF9800); // Naranja
      case P2PState.error:
        return const Color(0xFFF44336); // Rojo
      case P2PState.disabled:
        return const Color(0xFF9E9E9E); // Gris
      default:
        return const Color(0xFF607D8B); // Gris azulado
    }
  }

  /// Diagnóstico del sistema P2P
  Map<String, dynamic> getDiagnosticInfo() {
    return {
      'state': _currentState.name,
      'initialized': _isInitialized,
      'config': _currentConfig?.toJson(),
      'stats': {
        'peers': _currentStats.peers,
        'ratio': _currentStats.p2pRatio,
        'downloaded_mb': (_currentStats.totalDownloaded / 1024 / 1024).toStringAsFixed(2),
        'uploaded_mb': (_currentStats.p2pUploaded / 1024 / 1024).toStringAsFixed(2),
      },
      'performance': getPerformanceStats(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Restart del sistema P2P
  Future<void> restart() async {
    P2PUtils.logP2PEvent('Restarting P2P system');

    _updateState(P2PState.initializing);
    _updateStats(P2PStats.empty);

    await _sendToWebView(P2PUtils.createWebViewMessage('restart'));
  }

  /// Cleanup y dispose
  @override
  void dispose() {
    P2PUtils.logP2PEvent('Service disposing');

    _webPollingTimer?.cancel();
    _eventController.close();
    _statsController.close();
    _stateController.close();
    _errorController.close();

    P2PUtils.clearEventThrottle();

    super.dispose();
  }

  /// Métodos estáticos de utilidad
  static P2PService? _instance;

  static P2PService get instance {
    _instance ??= P2PService();
    return _instance!;
  }

  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
}