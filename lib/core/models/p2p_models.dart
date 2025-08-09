// 🚀 LIVEVAULTHUB P2P MODELS
// Modelos para el sistema P2P basado en P2P Media Loader

/// Estados posibles del sistema P2P
enum P2PState {
  /// Inicializando el engine P2P
  initializing,

  /// Conectando a trackers WebTorrent
  connecting,

  /// Conectado, buscando peers
  connected,

  /// Activamente compartiendo/recibiendo datos
  sharing,

  /// Error en el sistema P2P
  error,

  /// P2P deshabilitado (fallback a HTTP)
  disabled,

  /// Desconectado/detenido
  stopped;

  /// Obtener descripción legible del estado
  String get description {
    switch (this) {
      case P2PState.initializing:
        return 'Inicializando P2P...';
      case P2PState.connecting:
        return 'Conectando a red P2P...';
      case P2PState.connected:
        return 'Conectado a red P2P';
      case P2PState.sharing:
        return 'Compartiendo datos P2P';
      case P2PState.error:
        return 'Error en conexión P2P';
      case P2PState.disabled:
        return 'P2P deshabilitado';
      case P2PState.stopped:
        return 'P2P detenido';
    }
  }

  /// Determinar si el estado es considerado "activo"
  bool get isActive =>
      this == P2PState.connected ||
          this == P2PState.sharing;

  /// Determinar si hay error
  bool get hasError => this == P2PState.error;
}

/// Estadísticas en tiempo real del sistema P2P
class P2PStats {
  /// Número de peers conectados
  final int peers;

  /// Total descargado en bytes
  final int totalDownloaded;

  /// Total descargado via P2P en bytes
  final int p2pDownloaded;

  /// Total descargado via HTTP en bytes
  final int httpDownloaded;

  /// Total subido via P2P en bytes
  final int p2pUploaded;

  /// Ratio P2P (0-100%)
  final double p2pRatio;

  /// Estado de conexión
  final P2PState state;

  /// Timestamp de la última actualización
  final DateTime timestamp;

  P2PStats({
    this.peers = 0,
    this.totalDownloaded = 0,
    this.p2pDownloaded = 0,
    this.httpDownloaded = 0,
    this.p2pUploaded = 0,
    this.p2pRatio = 0.0,
    this.state = P2PState.initializing,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Stats vacías por defecto
  static final P2PStats empty = P2PStats();

  /// Crear desde JSON recibido del WebView
  factory P2PStats.fromJson(Map<String, dynamic> json) {
    final totalDown = json['totalHTTPDownloaded'] ?? 0;
    final p2pDown = json['totalP2PDownloaded'] ?? 0;
    final httpDown = json['totalHTTPDownloaded'] ?? 0;
    final p2pUp = json['totalP2PUploaded'] ?? 0;

    final total = totalDown + p2pDown;
    final ratio = total > 0 ? (p2pDown / total * 100) : 0.0;

    return P2PStats(
      peers: json['numPeers'] ?? 0,
      totalDownloaded: total,
      p2pDownloaded: p2pDown,
      httpDownloaded: httpDown,
      p2pUploaded: p2pUp,
      p2pRatio: ratio,
      state: _parseState(json['status']),
    );
  }

  /// Parse estado desde string
  static P2PState _parseState(String? status) {
    switch (status?.toLowerCase()) {
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

  /// Formatear bytes a MB
  String get downloadedMB => '${(totalDownloaded / 1024 / 1024).toStringAsFixed(1)} MB';
  String get uploadedMB => '${(p2pUploaded / 1024 / 1024).toStringAsFixed(1)} MB';
  String get p2pRatioFormatted => '${p2pRatio.toStringAsFixed(1)}%';

  /// Copiar con nuevos valores
  P2PStats copyWith({
    int? peers,
    int? totalDownloaded,
    int? p2pDownloaded,
    int? httpDownloaded,
    int? p2pUploaded,
    double? p2pRatio,
    P2PState? state,
    DateTime? timestamp,
  }) {
    return P2PStats(
      peers: peers ?? this.peers,
      totalDownloaded: totalDownloaded ?? this.totalDownloaded,
      p2pDownloaded: p2pDownloaded ?? this.p2pDownloaded,
      httpDownloaded: httpDownloaded ?? this.httpDownloaded,
      p2pUploaded: p2pUploaded ?? this.p2pUploaded,
      p2pRatio: p2pRatio ?? this.p2pRatio,
      state: state ?? this.state,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'P2PStats(peers: $peers, ratio: $p2pRatioFormatted, state: ${state.description})';
  }
}

/// Tipos de eventos P2P que pueden ocurrir
enum P2PEventType {
  /// Player listo para funcionar
  playerReady,

  /// Video comenzó a cargar
  videoLoading,

  /// Video listo para reproducir
  videoReady,

  /// Metadatos del video cargados
  metadataLoaded,

  /// Reproducción iniciada
  play,

  /// Reproducción pausada
  pause,

  /// Tiempo de reproducción actualizado
  timeUpdate,

  /// Video terminado
  ended,

  /// Error de reproducción
  error,

  /// Peer conectado
  peerConnect,

  /// Peer desconectado
  peerDisconnect,

  /// Segmento descargado
  segmentLoaded,

  /// Chunk descargado
  chunkDownloaded,

  /// Estadísticas P2P actualizadas
  statsUpdate,

  /// Estado P2P cambiado
  stateChanged;

  /// Determinar si es un evento de P2P
  bool get isP2PEvent => [
    P2PEventType.peerConnect,
    P2PEventType.peerDisconnect,
    P2PEventType.segmentLoaded,
    P2PEventType.chunkDownloaded,
    P2PEventType.statsUpdate,
    P2PEventType.stateChanged,
  ].contains(this);

  /// Determinar si es un evento de video
  bool get isVideoEvent => [
    P2PEventType.playerReady,
    P2PEventType.videoLoading,
    P2PEventType.videoReady,
    P2PEventType.metadataLoaded,
    P2PEventType.play,
    P2PEventType.pause,
    P2PEventType.timeUpdate,
    P2PEventType.ended,
    P2PEventType.error,
  ].contains(this);
}

/// Evento P2P genérico
class P2PEvent {
  /// Tipo de evento
  final P2PEventType type;

  /// Datos del evento
  final Map<String, dynamic> data;

  /// Timestamp del evento
  final DateTime timestamp;

  P2PEvent({
    required this.type,
    this.data = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Crear desde JSON del WebView
  factory P2PEvent.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] ?? '';
    final type = _parseEventType(typeString);

    return P2PEvent(
      type: type,
      data: Map<String, dynamic>.from(json)..remove('type'),
    );
  }

  /// Parse tipo de evento desde string
  static P2PEventType _parseEventType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'player_ready':
        return P2PEventType.playerReady;
      case 'video_loading':
        return P2PEventType.videoLoading;
      case 'video_ready':
        return P2PEventType.videoReady;
      case 'loadedmetadata':
        return P2PEventType.metadataLoaded;
      case 'play':
        return P2PEventType.play;
      case 'pause':
        return P2PEventType.pause;
      case 'timeupdate':
        return P2PEventType.timeUpdate;
      case 'ended':
        return P2PEventType.ended;
      case 'error':
        return P2PEventType.error;
      case 'peer_connect':
        return P2PEventType.peerConnect;
      case 'peer_disconnect':
        return P2PEventType.peerDisconnect;
      case 'segment_loaded':
        return P2PEventType.segmentLoaded;
      case 'chunk_downloaded':
        return P2PEventType.chunkDownloaded;
      case 'stats_update':
        return P2PEventType.statsUpdate;
      case 'state_changed':
        return P2PEventType.stateChanged;
      default:
        return P2PEventType.error;
    }
  }

  @override
  String toString() {
    return 'P2PEvent(type: $type, data: $data)';
  }
}

/// Configuración del engine P2P
class P2PConfig {
  /// ID del swarm (stream) - debe ser único por contenido
  final String swarmId;

  /// Trackers WebTorrent a usar
  final List<String> trackers;

  /// Servidores STUN para WebRTC
  final List<String> stunServers;

  /// Número de segmentos a mantener en adelante
  final int forwardSegmentCount;

  /// Habilitar/deshabilitar P2P
  final bool isP2PEnabled;

  /// Habilitar logs de debug
  final bool debugEnabled;

  const P2PConfig({
    required this.swarmId,
    this.trackers = const [
      'wss://tracker.novage.com.ua:443/announce',
      'wss://tracker.webtorrent.dev:443/announce',
      'wss://openwebtorrent.com:443/announce',
    ],
    this.stunServers = const [
      'stun:stun.l.google.com:19302',
      'stun:global.stun.twilio.com:3478',
    ],
    this.forwardSegmentCount = 20,
    this.isP2PEnabled = true,
    this.debugEnabled = false,
  });

  /// Crear configuración desde movie
  factory P2PConfig.forMovie(String movieId, {bool debug = false}) {
    return P2PConfig(
      swarmId: 'livevaulthub_$movieId',
      debugEnabled: debug,
    );
  }

  /// Convertir a JSON para WebView
  Map<String, dynamic> toJson() {
    return {
      'swarmId': swarmId,
      'trackerAnnounce': trackers,
      'rtcConfig': {
        'iceServers': stunServers.map((server) => {'urls': server}).toList(),
      },
      'segments': {
        'forwardSegmentCount': forwardSegmentCount,
      },
      'isP2PEnabled': isP2PEnabled,
      'debug': debugEnabled,
    };
  }
}

/// Errores específicos del sistema P2P
class P2PError {
  /// Código de error
  final String code;

  /// Mensaje de error
  final String message;

  /// Detalles adicionales
  final Map<String, dynamic> details;

  /// Timestamp del error
  final DateTime timestamp;

  P2PError({
    required this.code,
    required this.message,
    this.details = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Errores predefinidos
  static final P2PError connectionFailed = P2PError(
    code: 'CONNECTION_FAILED',
    message: 'No se pudo conectar a la red P2P',
  );

  static final P2PError noTrackers = P2PError(
    code: 'NO_TRACKERS',
    message: 'No hay trackers WebTorrent disponibles',
  );

  static final P2PError webrtcFailed = P2PError(
    code: 'WEBRTC_FAILED',
    message: 'WebRTC no soportado o falló',
  );

  static final P2PError playerFailed = P2PError(
    code: 'PLAYER_FAILED',
    message: 'Error en el reproductor de video',
  );

  /// Crear desde JSON
  factory P2PError.fromJson(Map<String, dynamic> json) {
    return P2PError(
      code: json['code'] ?? 'UNKNOWN',
      message: json['message'] ?? 'Error desconocido',
      details: json['details'] ?? {},
    );
  }

  @override
  String toString() {
    return 'P2PError($code: $message)';
  }
}

/// Información de calidad de video
class VideoQuality {
  /// Resolución (ej: "1080p", "720p")
  final String resolution;

  /// Bitrate en kbps
  final int bitrate;

  /// URL del manifest para esta calidad
  final String url;

  /// Si es la calidad por defecto
  final bool isDefault;

  const VideoQuality({
    required this.resolution,
    required this.bitrate,
    required this.url,
    this.isDefault = false,
  });

  /// Crear desde JSON
  factory VideoQuality.fromJson(Map<String, dynamic> json) {
    return VideoQuality(
      resolution: json['resolution'] ?? 'auto',
      bitrate: json['bitrate'] ?? 0,
      url: json['url'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }

  /// Comparar calidades
  int compareTo(VideoQuality other) {
    return bitrate.compareTo(other.bitrate);
  }

  @override
  String toString() {
    return 'VideoQuality($resolution - ${bitrate}kbps)';
  }
}