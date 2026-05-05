import 'package:flutter/material.dart';

void showSuccessToast(BuildContext context, String message) {
  _showCustomToast(
    context: context,
    message: message,
    backgroundColor: Theme.of(context).colorScheme.primary,
    icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
  );
}

void showErrorToast(BuildContext context, String message) {
  _showCustomToast(
    context: context,
    message: message,
    backgroundColor: const Color(0xFFFF5470),
    icon: const Icon(Icons.error, color: Colors.white, size: 20),
  );
}

void _showCustomToast({
  required BuildContext context,
  required String message,
  required Color backgroundColor,
  required Widget icon,
}) {
  if (!context.mounted) return;
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => _CustomToast(
      message: message,
      backgroundColor: backgroundColor,
      icon: icon,
      onDismiss: () {
        if (overlayEntry.mounted) {
          try {
            overlayEntry.remove();
          } catch (_) {}
        }
      },
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(const Duration(seconds: 3), () {
    if (overlayEntry.mounted) {
      try {
        overlayEntry.remove();
      } catch (_) {}
    }
  });
}

class _CustomToast extends StatefulWidget {
  const _CustomToast({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onDismiss,
  });

  final String message;
  final Color backgroundColor;
  final Widget icon;
  final VoidCallback onDismiss;

  @override
  State<_CustomToast> createState() => _CustomToastState();
}

class _CustomToastState extends State<_CustomToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    Future.delayed(const Duration(seconds: 2, milliseconds: 700), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.icon,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
