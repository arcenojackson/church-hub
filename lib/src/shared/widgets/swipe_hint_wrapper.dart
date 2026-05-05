import 'package:flutter/material.dart';

import '../services/swipe_hint_service.dart';

/// Wraps the inner card (child of Dismissible).
/// On first visit to [screenKey], slides the card left to reveal the red
/// delete background, then slides back — teaching the swipe gesture.
class SwipeHintWrapper extends StatefulWidget {
  const SwipeHintWrapper({
    super.key,
    required this.child,
    required this.screenKey,
  });

  final Widget child;
  final String screenKey;

  @override
  State<SwipeHintWrapper> createState() => _SwipeHintWrapperState();
}

class _SwipeHintWrapperState extends State<SwipeHintWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(-0.18, 0))
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
                begin: const Offset(-0.18, 0), end: const Offset(-0.18, 0))
            .chain(CurveTween(curve: Curves.linear)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-0.18, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 45,
      ),
    ]).animate(_controller);

    _maybeAnimate();
  }

  Future<void> _maybeAnimate() async {
    final should = await SwipeHintService.shouldShow(widget.screenKey);
    if (!should || !mounted) return;
    await SwipeHintService.markShown(widget.screenKey);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.white),
          ),
        ),
        SlideTransition(
          position: _slide,
          child: widget.child,
        ),
      ],
    );
  }
}
