import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../data/library_images.dart';
import '../../../theme/theme.dart';

/// Full-screen photo viewer for the "Library Pictures" gallery in About.
/// Pushed as a transparent route so the screen underneath (About) stays
/// visible but blurred/darkened behind it, lightbox-style. Swipe left/right
/// (or tap the arrow buttons) to move through [images], starting at
/// [initialIndex].
class PhotoViewerScreen extends StatefulWidget {
  final List<LibraryImage> images;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  /// Pushes the viewer as a transparent/blurred overlay route.
  static void open(
      BuildContext context, {
        required List<LibraryImage> images,
        required int initialIndex,
      }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: PhotoViewerScreen(images: images, initialIndex: initialIndex),
        ),
      ),
    );
  }

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller =
  PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred + dimmed backdrop over whatever screen is underneath.
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
          ),

          // Swipeable photo pages.
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final img = widget.images[i];
              return Center(
                child: Hero(
                  tag: 'library-photo-${img.key}',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Image.asset(img.assetPath, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Close button.
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            right: AppSpacing.md,
            child: _RoundIconButton(
              icon: LucideIcons.x,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // Back arrow (hidden on first image).
          if (_index > 0)
            Positioned(
              left: AppSpacing.sm,
              top: 0,
              bottom: 0,
              child: Center(
                child: _RoundIconButton(
                  icon: LucideIcons.chevron_left,
                  onTap: () => _controller.previousPage(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
            ),

          // Forward arrow (hidden on last image).
          if (_index < widget.images.length - 1)
            Positioned(
              right: AppSpacing.sm,
              top: 0,
              bottom: 0,
              child: Center(
                child: _RoundIconButton(
                  icon: LucideIcons.chevron_right,
                  onTap: () => _controller.nextPage(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
            ),

          // Caption + "x / n" counter.
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: Column(
              children: [
                Text(
                  widget.images[_index].caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_index + 1} / ${widget.images.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}