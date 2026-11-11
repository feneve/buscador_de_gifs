import 'dart:async';

import 'package:buscador_de_gifs/controllers/gif_controller.dart';
import 'package:buscador_de_gifs/data/gif_api.dart';
import 'package:buscador_de_gifs/models/gif.dart';
import 'package:flutter_test/flutter_test.dart';

class _QueueGifApi implements GifApi {
  final List<Completer<GifPage>> requests = <Completer<GifPage>>[];
  final List<String?> queries = <String?>[];
  final List<int> offsets = <int>[];
  bool closed = false;

  @override
  Future<GifPage> fetch({
    String? query,
    required int offset,
    int limit = 20,
  }) {
    queries.add(query);
    offsets.add(offset);
    final completer = Completer<GifPage>();
    requests.add(completer);
    return completer.future;
  }

  @override
  void close() => closed = true;
}

Gif _gif(String id, {String? url}) {
  return Gif(
    id: id,
    title: 'GIF $id',
    previewUrl: url ?? 'https://media.giphy.com/$id.gif',
    originalUrl: url ?? 'https://media.giphy.com/$id.gif',
  );
}

void main() {
  late _QueueGifApi api;
  late GifController controller;

  setUp(() {
    api = _QueueGifApi();
    controller = GifController(api: api, pageSize: 2);
  });

  tearDown(() {
    controller.dispose();
  });

  test('refresh carrega primeira página', () async {
    final future = controller.refresh();

    api.requests.single.complete(
      GifPage(
        gifs: [_gif('a'), _gif('b')],
        totalCount: 3,
        offset: 0,
      ),
    );
    await future;

    expect(controller.gifs, hasLength(2));
    expect(controller.hasMore, isTrue);
    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
  });

  test('search envia a consulta e limpa resultados anteriores', () async {
    final refresh = controller.refresh();
    api.requests.last.complete(
      GifPage(gifs: [_gif('trending')], totalCount: 1, offset: 0),
    );
    await refresh;

    final search = controller.search('  gatos  ');
    expect(controller.gifs, isEmpty);
    expect(api.queries.last, 'gatos');

    api.requests.last.complete(
      GifPage(gifs: [_gif('gato')], totalCount: 1, offset: 0),
    );
    await search;

    expect(controller.gifs.single.id, 'gato');
    expect(controller.query, 'gatos');
  });

  test('erro da API vira mensagem exibível', () async {
    final future = controller.refresh();

    api.requests.single.completeError(
      const GifApiException('Sem conexão.'),
    );
    await future;

    expect(controller.error, 'Sem conexão.');
    expect(controller.hasMore, isFalse);
    expect(controller.gifs, isEmpty);
  });

  test('loadMore anexa próxima página e encerra ao atingir o total',
      () async {
    final first = controller.refresh();
    api.requests.last.complete(
      GifPage(gifs: [_gif('a'), _gif('b')], totalCount: 3, offset: 0),
    );
    await first;

    final second = controller.loadMore();
    expect(controller.isLoading, isTrue);
    expect(api.offsets.last, 2);

    api.requests.last.complete(
      GifPage(gifs: [_gif('c')], totalCount: 3, offset: 2),
    );
    await second;

    expect(controller.gifs.map((gif) => gif.id), ['a', 'b', 'c']);
    expect(controller.hasMore, isFalse);
  });

  test('resposta antiga é descartada quando uma nova busca começa', () async {
    final firstSearch = controller.search('gatos');
    final secondSearch = controller.search('cachorros');

    api.requests[1].complete(
      GifPage(gifs: [_gif('dog')], totalCount: 1, offset: 0),
    );
    await secondSearch;

    api.requests[0].complete(
      GifPage(gifs: [_gif('cat')], totalCount: 1, offset: 0),
    );
    await firstSearch;

    expect(controller.gifs.map((gif) => gif.id), ['dog']);
    expect(controller.query, 'cachorros');
  });

  test('dispose fecha a API', () {
    final localApi = _QueueGifApi();
    final localController = GifController(api: localApi);

    localController.dispose();

    expect(localApi.closed, isTrue);
  });
}
