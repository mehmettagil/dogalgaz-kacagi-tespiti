import 'package:flutter/material.dart';

class AnimatedAlarmIcon extends StatefulWidget {
  const AnimatedAlarmIcon({super.key});

  @override
  State<AnimatedAlarmIcon> createState() => _AnimatedAlarmIconState();
}

class _AnimatedAlarmIconState extends State<AnimatedAlarmIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 40,
          ),
        );
      },
    );
  }
}
