
import 'dart:convert';

import 'package:buscador_de_gifs/gif_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _apiKey = "MqgVLqBg1cfz1ZZjv7jxAwRhOFVHBYKB";

  final http.Client client = http.Client();

  final List<Map<String, dynamic>> _gifs = [];

  String? _search;

  int _offset = 0;

  bool _isLoading = false;
  bool _hasMore = true;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGifs(reset: true);
  }

  Future<void> _loadGifs({bool reset = false}) async {
    if (_isLoading || (!reset && !_hasMore)) return;

    if (reset) {
      setState(() {
        _gifs.clear();
        _offset = 0;
        _hasMore = true;
        _error = null;
      });
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final endpoint = _search == null
          ? '/v1/gifs/trending'
          : '/v1/gifs/search';

      final parameters = {
        'api_key': _apiKey,
        'limit': '20',
        'offset': '$_offset',
        'rating': 'g',
        'bundle': 'messaging_non_clips',
      };

      if (_search != null) {
        parameters['q'] = _search!;
        parameters['lang'] = 'en';
      }

      final uri = Uri.https(
        'api.giphy.com',
        endpoint,
        parameters,
      );

      final response = await client.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }

      final result = json.decode(response.body);

      final List<Map<String, dynamic>> newGifs =
          (result['data'] as List).cast<Map<String, dynamic>>();

      if (!mounted) return;

      setState(() {
        _gifs.addAll(newGifs);
        _offset += newGifs.length;
        _hasMore = newGifs.length == 20;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Image.network(
          'https://developers.giphy.com/branch/master/static/header-logo-0fec0225d189bc0eae27dac3e3770582.gif',
          height: 40,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Pesquise aqui!!',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
              onSubmitted: (text) {
                _search = text.trim().isEmpty ? null : text.trim();
                _loadGifs(reset: true);
              },
            ),
          ),

          Expanded(
            child: _buildGifGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildGifGrid() {
    if (_gifs.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_gifs.isEmpty && _error != null) {
      return Center(
        child: Text(
          'Erro ao carregar GIFs: $_error',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (_gifs.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum GIF encontrado.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _gifs.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _gifs.length) {
          final gif = _gifs[index];

          final gifUrl =
              gif['images']['fixed_height']['url'] as String;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GifDetailPage(
                    gifUrl: gifUrl,
                  ),
                ),
              );
            },
            child: Image.network(
              gifUrl,
              fit: BoxFit.cover,
            ),
          );
        }

        return GestureDetector(
          onTap: _isLoading ? null : () => _loadGifs(),
          child: Container(
            color: Colors.grey[900],
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 70,
                        ),
                        Text(
                          _error != null
                              ? 'Tentar novamente'
                              : 'Carregar mais...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
