import 'dart:async';

import 'package:buscador_de_gifs/models/gif.dart';
import 'package:buscador_de_gifs/ui/widgets/network_gif_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class GifDetailPage extends StatefulWidget {
  const GifDetailPage({
    super.key,
    required this.gif,
    this.client,
    this.downloadTimeout = const Duration(seconds: 20),
  });

  final Gif gif;

  /// Permite injetar um [http.Client] (útil em testes).
  final http.Client? client;
  final Duration downloadTimeout;

  @override
  State<GifDetailPage> createState() => _GifDetailPageState();
}

class _GifDetailPageState extends State<GifDetailPage> {
  late final http.Client _client;
  late final bool _ownsClient;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _ownsClient = widget.client == null;
    _client = widget.client ?? http.Client();
  }

  @override
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
    super.dispose();
  }

  Future<void> _shareGif() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      final response = await _client
          .get(Uri.parse(widget.gif.originalUrl))
          .timeout(widget.downloadTimeout);

      if (response.statusCode != 200) {
        throw Exception('Falha ao baixar o GIF (HTTP ${response.statusCode}).');
      }

      final fileName = 'giphy_${widget.gif.id}.gif';

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              response.bodyBytes,
              mimeType: 'image/gif',
              name: fileName,
            ),
          ],
          fileNameOverrides: [fileName],
          text: widget.gif.title.isEmpty ? null : widget.gif.title,
        ),
      );
    } on TimeoutException {
      _showError('O download demorou demais. Tente novamente.');
    } catch (error) {
      _showError('Não foi possível compartilhar o GIF.');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do GIF'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: NetworkGifImage(
                    url: widget.gif.originalUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton.icon(
                  onPressed: _isSharing ? null : _shareGif,
                  icon: _isSharing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share),
                  label: Text(
                    _isSharing ? 'Preparando GIF...' : 'Compartilhar GIF',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
