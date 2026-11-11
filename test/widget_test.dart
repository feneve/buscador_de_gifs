import 'package:buscador_de_gifs/data/gif_api.dart';
import 'package:buscador_de_gifs/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGifApi implements GifApi {
  _FakeGifApi({this.error});

  final String? error;
  bool closed = false;

  @override
  Future<GifPage> fetch({
    String? query,
    required int offset,
    int limit = 20,
  }) async {
    if (error != null) {
      throw GifApiException(error!);
    }
    return const GifPage(gifs: [], totalCount: 0, offset: 0);
  }

  @override
  void close() => closed = true;
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('mostra estado vazio quando não há GIFs', (tester) async {
    await tester.pumpWidget(_wrap(HomePage(api: _FakeGifApi())));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum GIF encontrado.'), findsOneWidget);
    expect(find.text('Pesquise GIFs'), findsOneWidget);
  });

  testWidgets('mostra erro e permite tentar novamente', (tester) async {
    await tester.pumpWidget(
      _wrap(HomePage(api: _FakeGifApi(error: 'Falha de teste.'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Falha de teste.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
