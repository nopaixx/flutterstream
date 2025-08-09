import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../models/p2p_models.dart';

/// Utilidades para el sistema P2P de LiveVaultHub
class P2PUtils {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  /// Generar swarm ID único para un stream
  static String generateSwarmId(String movieId, {String? userId}) {
    final base = 'livevaulthub_$movieId';
    if (userId != null) {
      return '${base}_$userId';
    }
    return base;
  }

  /// Formatear bytes a unidad legible
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Formatear duración en segundos a formato legible
  static String formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${secs.toString().padLeft(2, '0')}';
    }
  }

  /// Formatear timestamp a hora legible
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm:ss').format(time);
  }

  /// Calcular ratio P2P
  static double calculateP2PRatio(int p2pBytes, int totalBytes) {
    if (totalBytes == 0) return 0.0;
    return (p2pBytes / totalBytes * 100).clamp(0.0, 100.0);
  }

  /// Validar JSON del WebView
  static Map<String, dynamic>? parseWebViewMessage(String message) {
    try {
      return json.decode(message) as Map<String, dynamic>;
    } catch (e) {
      _logger.w('Error parsing WebView message: $e');
      return null;
    }
  }

  /// Crear mensaje para enviar al WebView
  static String createWebViewMessage(String action, [Map<String, dynamic>? data]) {
    final message = {
      'action': action,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      if (data != null) ...data,
    };
    return json.encode(message);
  }

  /// Determinar si el dispositivo soporta P2P
  static bool isP2PSupported() {
    // En Flutter Web, verificar WebRTC support sería más complejo
    // Por ahora asumimos que todos los dispositivos lo soportan
    return true;
  }

  /// Generar configuración P2P optimizada
  static P2PConfig createOptimalConfig(String movieId, {
    bool isLive = false,
    bool enableDebug = false,
  }) {
    final segmentCount = isLive ? 10 : 20;

    return P2PConfig(
      swarmId: generateSwarmId(movieId),
      forwardSegmentCount: segmentCount,
      debugEnabled: enableDebug,
    );
  }

  /// Calcular estadísticas de rendimiento
  static Map<String, dynamic> calculatePerformanceStats(P2PStats stats) {
    final efficiency = stats.totalDownloaded > 0
        ? (stats.p2pDownloaded / stats.totalDownloaded * 100)
        : 0.0;

    final savingsRatio = stats.p2pRatio / 100.0;
    final estimatedSavings = stats.totalDownloaded * savingsRatio;

    return {
      'efficiency': efficiency.toStringAsFixed(1),
      'bandwidth_saved': formatBytes(estimatedSavings.toInt()),
      'upload_ratio': stats.p2pUploaded > 0 && stats.p2pDownloaded > 0
          ? (stats.p2pUploaded / stats.p2pDownloaded).toStringAsFixed(2)
          : '0.00',
      'connection_quality': _calculateConnectionQuality(stats),
    };
  }

  /// Calcular calidad de conexión P2P
  static String _calculateConnectionQuality(P2PStats stats) {
    if (stats.peers == 0) return 'Sin conexión';
    if (stats.p2pRatio > 80) return 'Excelente';
    if (stats.p2pRatio > 60) return 'Buena';
    if (stats.p2pRatio > 30) return 'Regular';
    return 'Baja';
  }

  /// Generar color para UI basado en ratio P2P
  static int getP2PRatioColor(double ratio) {
    if (ratio > 80) return 0xFF4CAF50; // Verde
    if (ratio > 60) return 0xFF8BC34A; // Verde claro
    if (ratio > 30) return 0xFFFF9800; // Naranja
    return 0xFFF44336; // Rojo
  }

  /// Logging específico para P2P
  static void logP2PEvent(String event, [Map<String, dynamic>? data]) {
    _logger.i('🚀 P2P: $event', error: data);
  }

  static void logP2PError(String error, [dynamic details]) {
    _logger.e('❌ P2P Error: $error', error: details);
  }

  static void logP2PDebug(String message, [dynamic data]) {
    _logger.d('🔍 P2P Debug: $message', error: data);
  }

  /// Validar URL de stream
  static bool isValidStreamUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final validExtensions = ['.m3u8', '.mpd'];
    return validExtensions.any((ext) => url.toLowerCase().contains(ext));
  }

  /// Extraer ID de stream desde URL
  static String? extractStreamId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // Extraer de diferentes formatos de URL
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      return segments.last.split('.').first;
    }

    return null;
  }

  /// Generar hash simple para swarm ID
  static String generateSimpleHash(String input) {
    var hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xffffffff;
    }
    return hash.abs().toRadixString(36);
  }

  /// Limpiar datos sensibles de logs
  static Map<String, dynamic> sanitizeLogData(Map<String, dynamic> data) {
    final cleaned = Map<String, dynamic>.from(data);

    // Remover URLs completas, solo mantener el final
    if (cleaned.containsKey('url')) {
      final url = cleaned['url'] as String;
      cleaned['url'] = '...${url.substring(max(0, url.length - 20))}';
    }

    // Remover otros datos sensibles
    cleaned.removeWhere((key, value) =>
    key.toLowerCase().contains('token') ||
        key.toLowerCase().contains('key') ||
        key.toLowerCase().contains('secret'));

    return cleaned;
  }

  /// Throttle para evitar spam de eventos
  static final Map<String, DateTime> _lastEventTimes = {};

  static bool shouldThrottleEvent(String eventType, {int throttleMs = 1000}) {
    final now = DateTime.now();
    final lastTime = _lastEventTimes[eventType];

    if (lastTime == null || now.difference(lastTime).inMilliseconds > throttleMs) {
      _lastEventTimes[eventType] = now;
      return false;
    }

    return true;
  }

  /// Limpiar cache de throttle
  static void clearEventThrottle() {
    _lastEventTimes.clear();
  }

  /// Crear configuración de trackers según entorno
  static List<String> getOptimalTrackers({bool isProduction = true}) {
    if (isProduction) {
      return [
        'wss://tracker.novage.com.ua:443/announce',
        'wss://tracker.webtorrent.dev:443/announce',
        'wss://openwebtorrent.com:443/announce',
      ];
    } else {
      // Para desarrollo, usar trackers más permisivos
      return [
        'wss://tracker.webtorrent.dev:443/announce',
        'wss://openwebtorrent.com:443/announce',
      ];
    }
  }

  /// Crear configuración STUN según entorno
  static List<String> getOptimalStunServers() {
    return [
      'stun:stun.l.google.com:19302',
      'stun:global.stun.twilio.com:3478',
      'stun:stun1.l.google.com:19302',
      'stun:stun2.l.google.com:19302',
    ];
  }
}