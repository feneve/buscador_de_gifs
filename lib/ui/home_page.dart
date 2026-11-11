import 'dart:async';

import 'package:buscador_de_gifs/controllers/gif_controller.dart';
import 'package:buscador_de_gifs/data/gif_api.dart';
import 'package:buscador_de_gifs/models/gif.dart';
import 'package:buscador_de_gifs/ui/gif_detail_page.dart';
import 'package:buscador_de_gifs/ui/widgets/network_gif_image.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.api,
    this.searchDebounce = const Duration(milliseconds: 450),
  });

  /// Permite injetar uma implementação de [GifApi] (útil em testes).
  final GifApi? api;
  final Duration searchDebounce;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final GifController _controller;
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = GifController(api: widget.api ?? GiphyApi());
    _searchController = TextEditingController()
      ..addListener(_onSearchTextChanged);
    unawaited(_controller.refresh());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_onSearchTextChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(widget.searchDebounce, () {
      _controller.search(_searchController.text);
    });
  }

  void _submitSearch(String value) {
    _debounce?.cancel();
    _controller.search(value);
  }

  void _openGif(Gif gif) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GifDetailPage(gif: gif),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const _AppLogo(),
        titleSpacing: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: _SearchField(
                controller: _searchController,
                onSubmitted: _submitSearch,
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _buildContent(_controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(GifController controller) {
    if (controller.isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (controller.error != null && controller.gifs.isEmpty) {
      return _ErrorState(
        message: controller.error!,
        onRetry: controller.refresh,
      );
    }

    if (controller.isEmpty) {
      return const _EmptyState();
    }

    return _buildGrid(controller);
  }

  Widget _buildGrid(GifController controller) {
    final gifs = controller.gifs;
    final showFooter = controller.hasMore;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: gifs.length + (showFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < gifs.length) {
          final gif = gifs[index];
          return _GifTile(gif: gif, onTap: () => _openGif(gif));
        }

        return _LoadMoreTile(
          isLoading: controller.isLoading,
          error: controller.error,
          onPressed: controller.loadMore,
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: 'Pesquise GIFs',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'Limpar busca',
              icon: const Icon(Icons.clear),
              onPressed: controller.clear,
            );
          },
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Image.network(
      'https://developers.giphy.com/branch/master/static/header-logo-0fec0225d189bc0eae27dac3e3770582.gif',
      height: 36,
      errorBuilder: (context, error, stackTrace) => Text(
        'GIPHY',
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _GifTile extends StatelessWidget {
  const _GifTile({
    required this.gif,
    required this.onTap,
  });

  final Gif gif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: gif.title.isEmpty ? 'Abrir GIF' : gif.title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: NetworkGifImage(url: gif.previewUrl),
        ),
      ),
    );
  }
}

class _LoadMoreTile extends StatelessWidget {
  const _LoadMoreTile({
    required this.isLoading,
    required this.error,
    required this.onPressed,
  });

  final bool isLoading;
  final String? error;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            error == null ? Icons.add : Icons.refresh,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            error == null ? 'Carregar mais' : 'Tentar novamente',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white70,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.gif_box_outlined,
            size: 56,
            color: Colors.white38,
          ),
          SizedBox(height: 12),
          Text(
            'Nenhum GIF encontrado.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
