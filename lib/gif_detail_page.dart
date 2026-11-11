
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class GifDetailPage extends StatefulWidget {
  final String gifUrl;

  const GifDetailPage({
    super.key,
    required this.gifUrl,
  });

  @override
  State<GifDetailPage> createState() => _GifDetailPageState();
}

class _GifDetailPageState extends State<GifDetailPage> {
  bool _isSharing = false;

  Future<void> _shareGif() async {
    setState(() {
      _isSharing = true;
    });

    try {
      // Baixa o GIF da internet
      final response = await http.get(
        Uri.parse(widget.gifUrl),
      );

      if (response.statusCode != 200) {
        throw Exception('Não foi possível baixar o GIF');
      }

      // Compartilha o arquivo GIF
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              response.bodyBytes,
              mimeType: 'image/gif',
            ),
          ],
          fileNameOverrides: ['giphy.gif'],
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao compartilhar: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Detalhes do GIF',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                widget.gifUrl,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : _shareGif,
                  icon: const Icon(Icons.share),
                  label: Text(
                    _isSharing
                        ? 'Preparando GIF...'
                        : 'Compartilhar GIF',
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
