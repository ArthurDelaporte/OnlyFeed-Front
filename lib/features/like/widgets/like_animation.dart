// features/like/widgets/like_animation.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class LikeAnimation extends StatefulWidget {
  final Widget child;
  final bool isLiked;
  final AnimationController animationController;

  const LikeAnimation({
    Key? key,
    required this.child,
    required this.isLiked,
    required this.animationController,
  }) : super(key: key);

  @override
  _LikeAnimationState createState() => _LikeAnimationState();
}

class _LikeAnimationState extends State<LikeAnimation> with TickerProviderStateMixin {
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late AnimationController _burstController;
  late Animation<double> _burstAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.elasticOut,
    ));

    _burstController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _burstAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _burstController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(LikeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !oldWidget.isLiked) {
      _burstController.forward().then((_) {
        _burstController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Animation de burst pour les particules
        AnimatedBuilder(
          animation: _burstAnimation,
          builder: (context, child) {
            if (!widget.isLiked || _burstAnimation.value == 0) {
              return SizedBox.shrink();
            }
            return _buildBurstEffect();
          },
        ),
        
        // Widget principal avec animation
        AnimatedBuilder(
          animation: widget.animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: widget.child,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBurstEffect() {
    return Stack(
      children: List.generate(6, (index) {
        final angle = (index * 60.0) * (math.pi / 180.0); // Utiliser math.pi
        final distance = 20.0 * _burstAnimation.value;
        
        return Positioned(
          left: distance * math.cos(angle),
          top: distance * math.sin(angle),
          child: Opacity(
            opacity: 1.0 - _burstAnimation.value,
            child: Transform.scale(
              scale: 0.5 + (0.5 * _burstAnimation.value),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}