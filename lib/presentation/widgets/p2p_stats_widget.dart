import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/p2p_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/p2p_utils.dart';
import 'p2p_connection_indicator.dart';

/// Widget para mostrar estadísticas P2P detalladas
class P2PStatsWidget extends StatefulWidget {
  final P2PStats stats;
  final P2PState state;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final VoidCallback? onClose;

  const P2PStatsWidget({
    Key? key,
    required this.stats,
    required this.state,
    this.isExpanded = true,
    this.onToggle,
    this.onClose,
  }) : super(key: key);

  @override
  State<P2PStatsWidget> createState() => _P2PStatsWidgetState();
}

class _P2PStatsWidgetState extends State<P2PStatsWidget>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _fadeController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    if (widget.isExpanded) {
      _expandController.forward();
    }
    _fadeController.forward();
  }

  @override
  void didUpdateWidget(P2PStatsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isExpanded != widget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryPurple.withOpacity(0.9),
              AppTheme.primaryViolet.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: _buildExpandedContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          P2PConnectionIndicator(
            state: widget.state,
            peers: widget.stats.peers,
            compact: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Red P2P LiveVaultHub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getHeaderSubtitle(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onToggle != null)
            IconButton(
              icon: AnimatedRotation(
                turns: widget.isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(
                  Icons.expand_more,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: widget.onToggle,
              visualDensity: VisualDensity.compact,
            ),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
              onPressed: widget.onClose,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          _buildMainStats(),
          const SizedBox(height: 16),
          _buildDetailedStats(),
          const SizedBox(height: 12),
          _buildPerformanceIndicator(),
        ],
      ),
    );
  }

  Widget _buildMainStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            label: 'Peers',
            value: widget.stats.peers.toString(),
            color: _getPeerCountColor(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.share,
            label: 'Ratio P2P',
            value: widget.stats.p2pRatioFormatted,
            color: _getRatioColor(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.download,
            label: 'Descargado',
            value: widget.stats.downloadedMB,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildStatRow('Subido P2P', widget.stats.uploadedMB),
          _buildStatRow('Estado', widget.state.description),
          _buildStatRow(
            'Última actualización',
            DateFormat('HH:mm:ss').format(widget.stats.timestamp),
          ),
          if (widget.stats.peers > 0)
            _buildStatRow(
              'Eficiencia',
              P2PUtils.calculatePerformanceStats(widget.stats)['efficiency'] + '%',
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator() {
    final ratio = widget.stats.p2pRatio / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rendimiento P2P',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _getPerformanceText(),
              style: TextStyle(
                color: _getRatioColor(),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_getRatioColor()),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  String _getHeaderSubtitle() {
    if (widget.stats.peers == 0) {
      return 'Buscando peers...';
    }

    final efficiency = widget.stats.p2pRatio;
    if (efficiency > 80) return 'Rendimiento excelente';
    if (efficiency > 60) return 'Buen rendimiento';
    if (efficiency > 30) return 'Rendimiento moderado';
    return 'Conectando...';
  }

  String _getPerformanceText() {
    final ratio = widget.stats.p2pRatio;
    if (ratio > 80) return 'Excelente';
    if (ratio > 60) return 'Bueno';
    if (ratio > 30) return 'Regular';
    return 'Bajo';
  }

  Color _getPeerCountColor() {
    if (widget.stats.peers == 0) return Colors.orange;
    if (widget.stats.peers < 5) return Colors.yellow;
    return const Color(0xFF4CAF50);
  }

  Color _getRatioColor() {
    final ratio = widget.stats.p2pRatio;
    if (ratio > 80) return const Color(0xFF4CAF50); // Verde
    if (ratio > 60) return const Color(0xFF8BC34A); // Verde claro
    if (ratio > 30) return const Color(0xFFFF9800); // Naranja
    return const Color(0xFFF44336); // Rojo
  }
}

/// Widget compacto para estadísticas P2P en overlay
class P2PStatsOverlay extends StatelessWidget {
  final P2PStats stats;
  final P2PState state;
  final VoidCallback? onTap;

  const P2PStatsOverlay({
    Key? key,
    required this.stats,
    required this.state,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                P2PStatusDot(state: state, size: 8),
                const SizedBox(width: 8),
                Text(
                  'P2P',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.peers} peers • ${stats.p2pRatioFormatted}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '↓ ${stats.downloadedMB} • ↑ ${stats.uploadedMB}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge simple para mostrar estado P2P
class P2PStatsBadge extends StatelessWidget {
  final P2PStats stats;
  final P2PState state;

  const P2PStatsBadge({
    Key? key,
    required this.stats,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!state.isActive) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient.scale(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'P2P ${stats.p2pRatioFormatted}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Extension helper para gradientes
extension GradientExtension on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((color) => color.withOpacity(opacity)).toList(),
    );
  }
}