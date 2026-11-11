/// Configurações de ambiente da aplicação.
///
/// A chave padrão abaixo é usada para rodar o projeto de estudo em debug.
/// O valor pode ser sobrescrito em tempo de build:
///
/// ```sh
/// flutter run --dart-define=GIPHY_API_KEY=sua_chave
/// ```
class Env {
  Env._();

  static const String giphyApiKey = String.fromEnvironment(
    'GIPHY_API_KEY',
    defaultValue: 'MqgVLqBg1cfz1ZZjv7jxAwRhOFVHBYKB',
  );

  static bool get hasGiphyApiKey => giphyApiKey.trim().isNotEmpty;
}
