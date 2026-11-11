import 'dart:async';
import 'dart:convert';

import 'package:buscador_de_gifs/core/env.dart';
import 'package:buscador_de_gifs/models/gif.dart';
import 'package:http/http.dart' as http;

/// Página de resultados retornada pela camada de dados.
class GifPage {
  const GifPage({
    required this.gifs,
    required this.totalCount,
    required this.offset,
  });

  final List<Gif> gifs;
  final int totalCount;
  final int offset;
}

/// Erro de domínio com mensagem amigável para ser exibida na interface.
class GifApiException implements Exception {
  const GifApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contrato da camada de dados. Facilita testes com implementações falsas.
abstract class GifApi {
  Future<GifPage> fetch({
    String? query,
    required int offset,
    int limit = 20,
  });

  void close();
}

/// Implementação da API do Giphy.
class GiphyApi implements GifApi {
  GiphyApi({
    http.Client? client,
    String? apiKey,
    this.timeout = const Duration(seconds: 15),
  })  : _client = client ?? http.Client(),
        _apiKey = (apiKey ?? Env.giphyApiKey).trim(),
        _ownsClient = client == null;

  static const String _host = 'api.giphy.com';

  final http.Client _client;
  final String _apiKey;
  final bool _ownsClient;
  final Duration timeout;

  @override
  Future<GifPage> fetch({
    String? query,
    required int offset,
    int limit = 20,
  }) async {
    if (_apiKey.isEmpty) {
      throw const GifApiException(
        'Chave da API não configurada. Execute o app com '
        '--dart-define=GIPHY_API_KEY=SuaChave.',
      );
    }

    final normalizedQuery = query?.trim();
    final isSearch = normalizedQuery != null && normalizedQuery.isNotEmpty;

    final endpoint = isSearch ? '/v1/gifs/search' : '/v1/gifs/trending';
    final parameters = <String, String>{
      'api_key': _apiKey,
      'limit': '$limit',
      'offset': '$offset',
      'rating': 'g',
      'bundle': 'messaging_non_clips',
      if (isSearch) ...{
        'q': normalizedQuery,
        'lang': 'pt',
      },
    };

    final uri = Uri.https(_host, endpoint, parameters);

    try {
      final response = await _client.get(uri).timeout(timeout);

      if (response.statusCode != 200) {
        throw GifApiException(
          'Falha ao carregar GIFs (HTTP ${response.statusCode}).',
        );
      }

      return _parseResponse(response.body, offset);
    } on TimeoutException {
      throw const GifApiException(
        'A requisição demorou demais. Verifique sua conexão e tente novamente.',
      );
    } on http.ClientException {
      throw const GifApiException(
        'Não foi possível conectar. Verifique sua internet.',
      );
    } on FormatException {
      throw const GifApiException('Resposta inválida da API.');
    }
  }

  GifPage _parseResponse(String responseBody, int offset) {
    final body = jsonDecode(responseBody);

    if (body is! Map<String, dynamic>) {
      throw const GifApiException('Resposta inválida da API.');
    }

    final data = body['data'];
    if (data is! List) {
      throw const GifApiException('Resposta inválida da API.');
    }

    final gifs = data
        .whereType<Map<String, dynamic>>()
        .map(Gif.fromJson)
        .whereType<Gif>()
        .toList(growable: false);

    final pagination = body['pagination'];
    final totalCount = pagination is Map
        ? _asInt(pagination['total_count']) ?? gifs.length
        : gifs.length;

    return GifPage(gifs: gifs, totalCount: totalCount, offset: offset);
  }

  @override
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
