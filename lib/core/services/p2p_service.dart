// lib/core/services/p2p_service.dart - COMUNICACIÓN WEB COMPLETAMENTE CORREGIDA

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

  /// Queue de mensajes para web
  final List<String> _pendingMessages = [];

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
      // En web, usamos DOM events + polling
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

  /// ✅ NUEVA COMUNICACIÓN WEB VIA DOM EVENTS
  Future<void> _setupWebCommunication() async {
    try {
      P2PUtils.logP2PEvent('Setting up web communication via DOM events');

      // Setup DOM-based communication
      await _webViewController!.evaluateJavascript(source: '''
        // ✅ NUEVO SISTEMA DE COMUNICACIÓN VIA DOM
        console.log('🔧 Setting up DOM-based communication...');
        
        // Queue para mensajes de Flutter
        window.flutterMessageQueue = [];
        
        // Queue para mensajes hacia Flutter  
        window.toFlutterQueue = [];
        
        // ✅ LISTENER PARA EVENTOS DOM PERSONALIZADOS
        document.addEventListener('flutter-message', function(event) {
          console.log('📨 DOM Event received:', event.detail);
          
          if (window.lvhPlayer && window.lvhPlayer.handleFlutterMessage) {
            window.lvhPlayer.handleFlutterMessage(event.detail);
          } else {
            console.log('⚠️ Player not ready, queuing message');
            window.flutterMessageQueue.push(event.detail);
          }
        });
        
        // ✅ FUNCIÓN PARA QUE EL PLAYER ENVÍE MENSAJES
        window.sendToFlutter = function(data) {
          console.log('📤 Sending to Flutter via DOM:', data);
          window.toFlutterQueue.push(JSON.stringify(data));
        };
        
        // ✅ FUNCIÓN PARA PROCESAR MENSAJES PENDIENTES
        window.processQueuedMessages = function() {
          if (window.lvhPlayer && window.flutterMessageQueue.length > 0) {
            console.log('🔄 Processing', window.flutterMessageQueue.length, 'queued messages');
            const messages = window.flutterMessageQueue.splice(0);
            messages.forEach(msg => window.lvhPlayer.handleFlutterMessage(msg));
          }
        };
        
        console.log('✅ DOM communication setup complete');
        true;
      ''');

      // Iniciar polling para mensajes bidireccionales
      _startWebMessagePolling();

      // Timeout para forzar player ready si no llega
      Timer(const Duration(seconds: 5), () {
        if (!_isInitialized) {
          P2PUtils.logP2PEvent('Forcing player ready in web');
          _handleWebViewMessage('{"type":"player_ready","timestamp":${DateTime.now().millisecondsSinceEpoch}}');
        }
      });

      P2PUtils.logP2PEvent('Web DOM communication setup successful');
    } catch (e) {
      P2PUtils.logP2PError('Web communication setup failed', e);
      _updateState(P2PState.disabled);
    }
  }

  /// ✅ POLLING MEJORADO PARA WEB
  void _startWebMessagePolling() {
    _webPollingTimer?.cancel();
    _webPollingTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_webViewController == null) {
        timer.cancel();
        return;
      }

      try {
        // Recibir mensajes del player
        final result = await _webViewController!.evaluateJavascript(source: '''
          if (window.toFlutterQueue && window.toFlutterQueue.length > 0) {
            const messages = window.toFlutterQueue.splice(0);
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

        // Procesar mensajes pendientes si el player ya está listo
        if (_isInitialized) {
          await _webViewController!.evaluateJavascript(source: '''
            if (window.processQueuedMessages) {
              window.processQueuedMessages();
            }
          ''');
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

    final message = {
      'action': 'loadVideo',
      'url': url,
      'options': {
        'isLive': url.contains('.m3u8'),
        'enableP2P': _currentConfig!.isP2PEnabled,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    P2PUtils.logP2PEvent('Sending loadVideo message', {
      'message': json.encode(message),
      'platform': kIsWeb ? 'web' : 'native',
    });

    await _sendToWebView(message);
  }

  /// Controles de reproducción
  Future<void> play() async {
    await _sendToWebView({'action': 'play', 'timestamp': DateTime.now().millisecondsSinceEpoch});
  }

  Future<void> pause() async {
    await _sendToWebView({'action': 'pause', 'timestamp': DateTime.now().millisecondsSinceEpoch});
  }

  Future<void> seekTo(double time) async {
    await _sendToWebView({
      'action': 'seekTo',
      'time': time,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> setVolume(double volume) async {
    await _sendToWebView({
      'action': 'setVolume',
      'volume': volume,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Configuración P2P dinámica
  Future<void> enableP2P() async {
    await _sendToWebView({'action': 'enableP2P', 'timestamp': DateTime.now().millisecondsSinceEpoch});
  }

  Future<void> disableP2P() async {
    await _sendToWebView({'action': 'disableP2P', 'timestamp': DateTime.now().millisecondsSinceEpoch});
    _updateState(P2PState.disabled);
  }

  /// Toggle estadísticas P2P en UI
  Future<void> toggleP2PStats(bool show) async {
    await _sendToWebView({
      'action': 'toggleStats',
      'show': show,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Manejo de mensajes del WebView
  void _handleWebViewMessage(String message) {
    if (P2PUtils.shouldThrottleEvent('webview_message', throttleMs: 50)) {
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

        // Procesar mensajes pendientes
        _processPendingMessages();
        break;

      case P2PEventType.videoLoading:
        P2PUtils.logP2PEvent('Video loading started');
        break;

      case P2PEventType.videoReady:
        P2PUtils.logP2PEvent('Video ready');
        break;

      case P2PEventType.stateChanged:
        final stateString = event.data['state'] ?? '';
        final newState = _parseStateFromString(stateString);
        _updateState(newState);
        break;

      case P2PEventType.statsUpdate:
        final statsData = event.data['stats'];
        if (statsData != null) {
          _updateStats(P2PStats.fromJson(Map<String, dynamic>.from(statsData)));
        }
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
        final error = P2PError(
          code: event.data['code'] ?? 'UNKNOWN',
          message: event.data['message'] ?? 'Error desconocido',
          details: event.data,
        );
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

  /// Parse estado desde string
  P2PState _parseStateFromString(String stateString) {
    switch (stateString.toLowerCase()) {
      case 'connecting':
        return P2PState.connecting;
      case 'connected':
        return P2PState.connected;
      case 'sharing':
        return P2PState.sharing;
      case 'error':
        return P2PState.error;
      case 'disabled':
        return P2PState.disabled;
      case 'stopped':
        return P2PState.stopped;
      default:
        return P2PState.initializing;
    }
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

  /// ✅ ENVÍO DE MENSAJES COMPLETAMENTE REESCRITO PARA WEB
  Future<void> _sendToWebView(Map<String, dynamic> messageData) async {
    if (_webViewController == null) return;

    final messageJson = json.encode(messageData);

    try {
      if (kIsWeb) {
        // ✅ NUEVO MÉTODO: DOM EVENTS
        P2PUtils.logP2PEvent('Sending message via DOM event', {'message': messageJson});

        // Si el player no está listo, guardar mensaje
        if (!_isInitialized) {
          _pendingMessages.add(messageJson);
          P2PUtils.logP2PEvent('Player not ready, message queued', {'pendingCount': _pendingMessages.length});
          return;
        }

        await _webViewController!.evaluateJavascript(source: '''
          console.log('🚀 Dispatching DOM event with message:', ${json.encode(messageData)});
          
          // Crear y disparar evento DOM personalizado
          const event = new CustomEvent('flutter-message', {
            detail: ${json.encode(messageData)}
          });
          
          document.dispatchEvent(event);
          console.log('✅ DOM event dispatched successfully');
        ''');
      } else {
        // Para móvil/desktop - método original
        await _webViewController!.evaluateJavascript(source: '''
          if (window.lvhPlayer && window.lvhPlayer.handleFlutterMessage) {
            window.lvhPlayer.handleFlutterMessage($messageJson);
          } else if (window.sendMessageToPlayer) {
            window.sendMessageToPlayer($messageJson);
          } else {
            console.log('Player not ready for message: $messageJson');
          }
        ''');
      }

      P2PUtils.logP2PEvent('Message sent successfully');
    } catch (e) {
      P2PUtils.logP2PError('Error sending to WebView', e);
    }
  }

  /// Procesar mensajes pendientes cuando el player esté listo
  Future<void> _processPendingMessages() async {
    if (_pendingMessages.isEmpty || !kIsWeb) return;

    P2PUtils.logP2PEvent('Processing pending messages', {'count': _pendingMessages.length});

    for (final messageJson in _pendingMessages) {
      try {
        final messageData = json.decode(messageJson) as Map<String, dynamic>;
        await _sendToWebView(messageData);
        // Pequeña pausa entre mensajes
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        P2PUtils.logP2PError('Error processing pending message', e);
      }
    }

    _pendingMessages.clear();
  }

  /// Obtener estadísticas de rendimiento
  Map<String, dynamic> getPerformanceStats() {
    return P2PUtils.calculatePerformanceStats(_currentStats);
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
      'pending_messages': _pendingMessages.length,
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
    _pendingMessages.clear();

    await _sendToWebView({'action': 'restart', 'timestamp': DateTime.now().millisecondsSinceEpoch});
  }

  /// Cleanup y dispose
  @override
  void dispose() {
    P2PUtils.logP2PEvent('Service disposing');

    _webPollingTimer?.cancel();
    _pendingMessages.clear();
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