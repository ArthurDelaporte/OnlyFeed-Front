// features/like/widgets/like_button.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../service/like_service.dart';
import '../model/like_model.dart';
import 'like_animation.dart';

class LikeButton extends StatefulWidget {
  final String postId;
  final int initialLikeCount;
  final bool initialIsLiked;
  final Function(LikeResponse)? onLikeChanged;
  final LikeButtonStyle style;
  final bool showCount;

  const LikeButton({
    Key? key,
    required this.postId,
    required this.initialLikeCount,
    required this.initialIsLiked,
    this.onLikeChanged,
    this.style = LikeButtonStyle.standard,
    this.showCount = true,
  }) : super(key: key);

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

enum LikeButtonStyle { 
  standard, 
  compact, 
  large,
  minimal
}

class _LikeButtonState extends State<LikeButton> with SingleTickerProviderStateMixin {
  final LikeService _likeService = LikeService();
  late int _likeCount;
  late bool _isLiked;
  bool _isLoading = false;
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.initialLikeCount;
    _isLiked = widget.initialIsLiked;
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Animation optimiste
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    try {
      final response = await _likeService.toggleLike(widget.postId);
      
      setState(() {
        _likeCount = response.likeCount;
        _isLiked = response.isLiked;
        _isLoading = false;
      });

      // Callback pour notifier le parent
      widget.onLikeChanged?.call(response);

      // Feedback haptique
      if (_isLiked) {
        // HapticFeedback.lightImpact(); // Décommentez si vous voulez du feedback haptique
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case LikeButtonStyle.compact:
        return _buildCompactButton();
      case LikeButtonStyle.large:
        return _buildLargeButton();
      case LikeButtonStyle.minimal:
        return _buildMinimalButton();
      default:
        return _buildStandardButton();
    }
  }

  Widget _buildStandardButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LikeAnimation(
          isLiked: _isLiked,
          animationController: _animationController,
          child: IconButton(
            onPressed: _isLoading ? null : _toggleLike,
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.grey[600],
                    size: 24,
                  ),
            splashRadius: 24,
          ),
        ),
        if (widget.showCount) ...[
          SizedBox(width: 4),
          Text(
            _formatLikeCount(_likeCount),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: _isLiked ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactButton() {
    return InkWell(
      onTap: _isLoading ? null : _toggleLike,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isLiked ? Colors.red : Colors.grey[300]!,
            width: 1,
          ),
          color: _isLiked ? Colors.red.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LikeAnimation(
              isLiked: _isLiked,
              animationController: _animationController,
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.grey[600],
                size: 16,
              ),
            ),
            if (widget.showCount) ...[
              SizedBox(width: 6),
              Text(
                _formatLikeCount(_likeCount),
                style: TextStyle(
                  fontSize: 12,
                  color: _isLiked ? Colors.red : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLargeButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LikeAnimation(
          isLiked: _isLiked,
          animationController: _animationController,
          child: IconButton(
            onPressed: _isLoading ? null : _toggleLike,
            icon: _isLoading
                ? CircularProgressIndicator(strokeWidth: 2)
                : Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.grey[600],
                    size: 32,
                  ),
            splashRadius: 28,
          ),
        ),
        if (widget.showCount)
          Text(
            _formatLikeCount(_likeCount),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: _isLiked ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
      ],
    );
  }

  Widget _buildMinimalButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _toggleLike,
      child: LikeAnimation(
        isLiked: _isLiked,
        animationController: _animationController,
        child: Icon(
          _isLiked ? Icons.favorite : Icons.favorite_border,
          color: _isLiked ? Colors.red : Colors.grey[400],
          size: 20,
        ),
      ),
    );
  }

  String _formatLikeCount(int count) {
    if (count == 0) return "0";
    if (count < 1000) return count.toString();
    if (count < 1000000) return "${(count / 1000).toStringAsFixed(1)}k";
    return "${(count / 1000000).toStringAsFixed(1)}M";
  }
}