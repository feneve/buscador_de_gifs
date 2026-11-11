// Parâmetros nomeados não podem começar com "_", então os campos privados
// precisam ser atribuídos manualmente no inicializador.
// ignore_for_file: prefer_initializing_formals

import 'package:buscador_de_gifs/data/gif_api.dart';
import 'package:buscador_de_gifs/models/gif.dart';
import 'package:flutter/foundation.dart';

/// Controla o estado da busca e da paginação de GIFs.
///
/// Mantém a lógica de carregamento fora da interface, deixando os widgets
/// responsáveis apenas por renderizar o estado atual.
class GifController extends ChangeNotifier {
  GifController({
    required GifApi api,
    int pageSize = 20,
  })  : _api = api,
        _pageSize = pageSize;

  final GifApi _api;
  final int _pageSize;

  final List<Gif> _gifs = <Gif>[];
  List<Gif> get gifs => List<Gif>.unmodifiable(_gifs);

  String? _query;
  String? get query => _query;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _error;
  String? get error => _error;

  bool _disposed = false;

  /// Identifica a requisição mais recente. Respostas antigas são descartadas,
  /// evitando que buscas rápidas misturem resultados.
  int _requestId = 0;

  int _offset = 0;

  bool get isInitialLoading => _isLoading && _gifs.isEmpty;
  bool get isEmpty => !_isLoading && _error == null && _gifs.isEmpty;

  /// Busca por [query]. Texto vazio volta a exibir os GIFs em alta.
  Future<void> search(String query) {
    final normalized = query.trim();
    final nextQuery = normalized.isEmpty ? null : normalized;

    if (nextQuery == _query && (_gifs.isNotEmpty || _isLoading)) {
      return Future<void>.value();
    }

    _query = nextQuery;
    return _reload();
  }

  /// Recarrega os resultados atuais do início.
  Future<void> refresh() => _reload();

  /// Carrega a próxima página de resultados.
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    final requestId = _requestId;
    _error = null;
    _setLoading(value: true, requestId: requestId);
    await _fetchPage(requestId: requestId);
  }

  Future<void> _reload() async {
    final requestId = ++_requestId;

    _gifs.clear();
    _offset = 0;
    _hasMore = true;
    _error = null;
    _setLoading(value: true, requestId: requestId);

    await _fetchPage(requestId: requestId);
  }

  Future<void> _fetchPage({required int requestId}) async {
    try {
      final page = await _api.fetch(
        query: _query,
        offset: _offset,
        limit: _pageSize,
      );

      if (_isStale(requestId)) return;

      _gifs.addAll(page.gifs);
      _offset += page.gifs.length;
      _hasMore = _computeHasMore(page);

      _setLoading(value: false, requestId: requestId);
    } on GifApiException catch (exception) {
      if (_isStale(requestId)) return;

      _error = exception.message;
      if (_gifs.isEmpty) {
        _hasMore = false;
      }
      _setLoading(value: false, requestId: requestId);
    } catch (exception) {
      if (_isStale(requestId)) return;

      _error = 'Ocorreu um erro inesperado. Tente novamente.';
      if (_gifs.isEmpty) {
        _hasMore = false;
      }
      _setLoading(value: false, requestId: requestId);
    }
  }

  bool _computeHasMore(GifPage page) {
    if (page.gifs.isEmpty) return false;
    if (page.totalCount > 0) return _offset < page.totalCount;
    return page.gifs.length == _pageSize;
  }

  bool _isStale(int requestId) => _disposed || requestId != _requestId;

  void _setLoading({required bool value, required int requestId}) {
    if (_isStale(requestId)) return;

    _isLoading = value;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _api.close();
    super.dispose();
  }
}
