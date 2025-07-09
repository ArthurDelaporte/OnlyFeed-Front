// features/like/presentation/like_stats_widget.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../service/like_service.dart';

class LikeStatsWidget extends StatefulWidget {
  final String userId;
  final bool showDetailed;

  const LikeStatsWidget({
    Key? key,
    required this.userId,
    this.showDetailed = false,
  }) : super(key: key);

  @override
  _LikeStatsWidgetState createState() => _LikeStatsWidgetState();
}

class _LikeStatsWidgetState extends State<LikeStatsWidget> {
  final LikeService _likeService = LikeService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _likeService.getUserLikeStats(widget.userId);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_stats == null) {
      return SizedBox.shrink();
    }

    return widget.showDetailed 
        ? _buildDetailedStats() 
        : _buildSimpleStats();
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.grey[400], size: 16),
          SizedBox(width: 8),
          Text(
            "Erreur de chargement",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStats() {
    final totalLikes = _stats!['total_likes_received'] ?? 0;
    
    return Row(
      children: [
        Icon(Icons.favorite, color: Colors.red, size: 16),
        SizedBox(width: 4),
        Text(
          _formatNumber(totalLikes),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(width: 4),
        Text(
          totalLikes <= 1 ? "like" : "likes",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats() {
    final totalLikesReceived = _stats!['total_likes_received'] ?? 0;
    final totalLikesGiven = _stats!['total_likes_given'] ?? 0;
    final mostLikedPost = _stats!['most_liked_post'];
    final likesThisMonth = _stats!['likes_this_month'] ?? 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Statistiques des likes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Likes reçus
            _buildStatRow(
              icon: Icons.favorite,
              color: Colors.red,
              label: "Likes reçus",
              value: _formatNumber(totalLikesReceived),
            ),
            
            SizedBox(height: 8),
            
            // Likes donnés
            _buildStatRow(
              icon: Icons.favorite_border,
              color: Colors.grey[600]!,
              label: "Likes donnés",
              value: _formatNumber(totalLikesGiven),
            ),
            
            SizedBox(height: 8),
            
            // Likes ce mois
            _buildStatRow(
              icon: Icons.trending_up,
              color: Colors.green,
              label: "Ce mois",
              value: _formatNumber(likesThisMonth),
            ),
            
            if (mostLikedPost != null) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Text(
                "Post le plus liké",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              Text(
                mostLikedPost['title'] ?? 'Post sans titre',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "${mostLikedPost['like_count']} likes",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return "${(number / 1000).toStringAsFixed(1)}k";
    return "${(number / 1000000).toStringAsFixed(1)}M";
  }
}