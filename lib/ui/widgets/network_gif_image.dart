import 'package:flutter/material.dart';

/// Imagem de rede com estados de carregamento, transição suave e erro.
class NetworkGifImage extends StatelessWidget {
  const NetworkGifImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.backgroundColor = const Color(0xFF1A1A1A),
  });

  final String url;
  final BoxFit fit;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Image.network(
        url,
        fit: fit,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;

          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: child,
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return const Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white38,
              size: 32,
            ),
          );
        },
      ),
    );
  }
}
