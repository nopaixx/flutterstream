import 'package:flutter/material.dart';
import '../../core/models/p2p_models.dart';
import '../../core/theme/app_theme.dart';

/// Indicador visual del estado de conexión P2P
class P2PConnectionIndicator extends StatefulWidget {
  final P2PState state;
  final int peers;
  final bool showPeerCount;
  final bool compact;
  final VoidCallback? onTap;

  const P2PConnectionIndicator({
    Key? key,
    required this.state,
    this.peers = 0,
    this.showPeerCount = true,
    this.compact = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<P2PConnectionIndicator> createState() => _P2PConnectionIndicatorState();
}

class _P2PConnectionIndicatorState extends State<P2PConnectionIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _updateAnimations();
  }

  @override
  void didUpdateWidget(P2PConnectionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    switch (widget.state) {
      case P2PState.connecting:
        _rotationController.repeat();
        _pulseController.stop();
        break;
      case P2PState.sharing:
        _pulseController.repeat(reverse: true);
        _rotationController.stop();
        break;
      case P2PState.connected:
        _pulseController.forward();
        _rotationController.stop();
        break;
      default:
        _pulseController.stop();
        _rotationController.stop();
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactIndicator();
    }
    return _buildFullIndicator();
  }

  Widget _buildCompactIndicator() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStateColor().withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStateColor().withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(size: 12),
            const SizedBox(width: 4),
            Text(
              _getShortStatusText(),
              style: TextStyle(
                color: _getStateColor(),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullIndicator() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getStateColor().withOpacity(0.1),
              _getStateColor().withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStateColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusIcon(size: 20),
                const SizedBox(width: 8),
                Text(
                  'P2P',
                  style: TextStyle(
                    color: _getStateColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.state.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.showPeerCount && widget.peers > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStateColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.peers} peer${widget.peers != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: _getStateColor(),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon({required double size}) {
    Widget icon;

    switch (widget.state) {
      case P2PState.initializing:
        icon = Icon(
          Icons.sync,
          size: size,
          color: _getStateColor(),
        );
        break;
      case P2PState.connecting:
        icon = RotationTransition(
          turns: _rotationAnimation,
          child: Icon(
            Icons.sync,
            size: size,
            color: _getStateColor(),
          ),
        );
        break;
      case P2PState.connected:
        icon = ScaleTransition(
          scale: _pulseAnimation,
          child: Icon(
            Icons.people,
            size: size,
            color: _getStateColor(),
          ),
        );
        break;
      case P2PState.sharing:
        icon = ScaleTransition(
          scale: _pulseAnimation,
          child: Icon(
            Icons.share,
            size: size,
            color: _getStateColor(),
          ),
        );
        break;
      case P2PState.error:
        icon = Icon(
          Icons.error_outline,
          size: size,
          color: _getStateColor(),
        );
        break;
      case P2PState.disabled:
        icon = Icon(
          Icons.wifi_off,
          size: size,
          color: _getStateColor(),
        );
        break;
      case P2PState.stopped:
        icon = Icon(
          Icons.stop_circle_outlined,
          size: size,
          color: _getStateColor(),
        );
        break;
    }

    return icon;
  }

  Color _getStateColor() {
    switch (widget.state) {
      case P2PState.sharing:
        return const Color(0xFF4CAF50); // Verde
      case P2PState.connected:
        return AppTheme.primaryViolet; // Violeta
      case P2PState.connecting:
      case P2PState.initializing:
        return const Color(0xFFFF9800); // Naranja
      case P2PState.error:
        return const Color(0xFFF44336); // Rojo
      case P2PState.disabled:
      case P2PState.stopped:
        return const Color(0xFF9E9E9E); // Gris
    }
  }

  String _getShortStatusText() {
    switch (widget.state) {
      case P2PState.initializing:
        return 'Init';
      case P2PState.connecting:
        return 'Conn';
      case P2PState.connected:
        return 'P2P';
      case P2PState.sharing:
        return 'Share';
      case P2PState.error:
        return 'Error';
      case P2PState.disabled:
        return 'Off';
      case P2PState.stopped:
        return 'Stop';
    }
  }
}

/// Indicador simple en línea para barras de estado
class P2PStatusDot extends StatefulWidget {
  final P2PState state;
  final double size;

  const P2PStatusDot({
    Key? key,
    required this.state,
    this.size = 8.0,
  }) : super(key: key);

  @override
  State<P2PStatusDot> createState() => _P2PStatusDotState();
}

class _P2PStatusDotState extends State<P2PStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _updateAnimation();
  }

  @override
  void didUpdateWidget(P2PStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.state == P2PState.sharing ||
        widget.state == P2PState.connecting) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _getStateColor().withOpacity(_animation.value),
            shape: BoxShape.circle,
            boxShadow: widget.state.isActive
                ? [
              BoxShadow(
                color: _getStateColor().withOpacity(0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ]
                : null,
          ),
        );
      },
    );
  }

  Color _getStateColor() {
    switch (widget.state) {
      case P2PState.sharing:
        return const Color(0xFF4CAF50);
      case P2PState.connected:
        return AppTheme.primaryViolet;
      case P2PState.connecting:
      case P2PState.initializing:
        return const Color(0xFFFF9800);
      case P2PState.error:
        return const Color(0xFFF44336);
      case P2PState.disabled:
      case P2PState.stopped:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Widget de estado P2P para toolbars
class P2PToolbarIndicator extends StatelessWidget {
  final P2PState state;
  final int peers;
  final VoidCallback? onTap;

  const P2PToolbarIndicator({
    Key? key,
    required this.state,
    this.peers = 0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            P2PStatusDot(state: state, size: 6),
            const SizedBox(width: 6),
            Text(
              state.isActive && peers > 0 ? '$peers' : _getStatusText(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (state) {
      case P2PState.connecting:
        return '...';
      case P2PState.connected:
        return 'P2P';
      case P2PState.sharing:
        return 'LIVE';
      case P2PState.error:
        return 'ERR';
      case P2PState.disabled:
        return 'OFF';
      default:
        return '---';
    }
  }
}