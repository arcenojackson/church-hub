import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BackgroundImageWithOverlay extends StatelessWidget {
  const BackgroundImageWithOverlay({
    super.key,
    required this.imageUrl,
    required this.child,
    this.overlayIntensity = 0.65,
    this.enableBlur = true,
    this.autoContrast = true,
    this.enableVignette = true,
    this.blurAmount = 0.65,
    this.blurSigmaX,
    this.blurSigmaY,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final Widget child;
  final double overlayIntensity;
  final bool enableBlur;
  final bool autoContrast;
  final bool enableVignette;
  final double blurAmount;
  final double? blurSigmaX;
  final double? blurSigmaY;
  final Widget? placeholder;
  final Widget? errorWidget;

  static double _topOpacity(double intensity, bool autoContrast) {
    final base = 0.35 + (0.55 - 0.35) * intensity.clamp(0.0, 1.0);
    return autoContrast ? (base + 0.06).clamp(0.0, 1.0) : base;
  }

  static double _bottomOpacity(double intensity, bool autoContrast) {
    final base = 0.50 + (0.70 - 0.50) * intensity.clamp(0.0, 1.0);
    return autoContrast ? (base + 0.04).clamp(0.0, 1.0) : base;
  }

  @override
  Widget build(BuildContext context) {
    final topOp = _topOpacity(overlayIntensity, autoContrast);
    final bottomOp = _bottomOpacity(overlayIntensity, autoContrast);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                placeholder ??
                Container(
                  color: const Color(0xFF1A1F2E),
                  child: const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            errorWidget: (_, __, ___) =>
                errorWidget ??
                Container(
                  color: const Color(0xFF1A1F2E),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.white38, size: 48),
                  ),
                ),
          ),
        ),
        if (enableBlur &&
            (blurSigmaX != null ? blurSigmaX! : blurAmount * 12) > 0)
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: (blurSigmaX ?? blurAmount * 12).clamp(0.0, 12.0),
                  sigmaY: (blurSigmaY ?? blurAmount * 12).clamp(0.0, 12.0),
                ),
                child: const DecoratedBox(
                    decoration: BoxDecoration(color: Colors.transparent)),
              ),
            ),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: topOp),
                  Colors.black.withValues(alpha: bottomOp),
                ],
              ),
            ),
          ),
        ),
        if (enableVignette)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.18)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(child: child),
      ],
    );
  }
}
