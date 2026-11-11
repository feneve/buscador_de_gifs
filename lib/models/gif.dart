/// Modelo imutável que representa um GIF retornado pela API do Giphy.
class Gif {
  const Gif({
    required this.id,
    required this.title,
    required this.previewUrl,
    required this.originalUrl,
  });

  final String id;
  final String title;

  /// URL otimizada para exibição em grade.
  final String previewUrl;

  /// URL do GIF em resolução original, usada no compartilhamento.
  final String originalUrl;

  /// Constrói um [Gif] a partir do JSON da API.
  ///
  /// Retorna `null` quando o objeto não possui uma URL válida, evitando
  /// que itens inválidos quebrem a listagem.
  static Gif? fromJson(Map<String, dynamic> json) {
    final images = _asMap(json['images']);
    final fixedHeight = _asMap(images['fixed_height']);
    final original = _asMap(images['original']);

    final previewUrl = _asString(fixedHeight['url']);
    if (previewUrl.isEmpty) {
      return null;
    }

    final originalUrl = _asString(original['url']);

    return Gif(
      id: _asString(json['id']),
      title: _asString(json['title']),
      previewUrl: previewUrl,
      originalUrl: originalUrl.isEmpty ? previewUrl : originalUrl,
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return const <String, dynamic>{};
}

String _asString(Object? value) => value is String ? value : '';
