import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Viewer plein ecran pour une image network, avec pinch-to-zoom
/// (InteractiveViewer 1x..5x) et tap pour fermer. Caption optionnelle
/// affichee en bas, dans une barre semi-transparente.
class ArenaImageViewer extends StatelessWidget {
  const ArenaImageViewer({
    required this.imageUrl,
    this.caption,
    super.key,
  });

  final String imageUrl;
  final String? caption;

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? caption,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (_, __, ___) => ArenaImageViewer(
          imageUrl: imageUrl,
          caption: caption,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCaption = caption != null && caption!.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const CircularProgressIndicator(
                          color: ArenaColors.silver,
                        );
                      },
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: ArenaColors.silver.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (hasCaption)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.lg,
                    vertical: ArenaSpacing.md,
                  ),
                  child: Text(
                    caption!,
                    style: ArenaText.body.copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
