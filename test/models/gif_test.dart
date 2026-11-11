import 'package:buscador_de_gifs/models/gif.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Gif.fromJson', () {
    test('extrai URLs de preview e original', () {
      final gif = Gif.fromJson({
        'id': 'abc123',
        'title': 'Um gato dançando',
        'images': {
          'fixed_height': {'url': 'https://media.giphy.com/preview.gif'},
          'original': {'url': 'https://media.giphy.com/original.gif'},
        },
      });

      expect(gif, isNotNull);
      expect(gif!.id, 'abc123');
      expect(gif.title, 'Um gato dançando');
      expect(gif.previewUrl, 'https://media.giphy.com/preview.gif');
      expect(gif.originalUrl, 'https://media.giphy.com/original.gif');
    });

    test('usa o preview quando não há URL original', () {
      final gif = Gif.fromJson({
        'id': 'abc123',
        'title': '',
        'images': {
          'fixed_height': {'url': 'https://media.giphy.com/preview.gif'},
        },
      });

      expect(gif, isNotNull);
      expect(gif!.originalUrl, gif.previewUrl);
    });

    test('retorna null quando não existe URL de preview', () {
      final gif = Gif.fromJson({
        'id': 'abc123',
        'title': 'Inválido',
        'images': <String, dynamic>{},
      });

      expect(gif, isNull);
    });

    test('não quebra com campos ausentes ou de tipo inesperado', () {
      final gif = Gif.fromJson({
        'id': 42,
        'images': {'fixed_height': 'não é um mapa'},
      });

      expect(gif, isNull);
    });
  });
}
