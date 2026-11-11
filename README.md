# Buscador de GIFs

Aplicativo Flutter que busca GIFs em alta e por termo usando a
[API do Giphy](https://developers.giphy.com/).

## Funcionalidades

- Lista de GIFs em alta ao abrir o app.
- Busca por texto com debounce (evita uma requisição por tecla).
- Paginação com botão "Carregar mais".
- Tela de detalhes com compartilhamento do GIF.
- Estados de carregamento, erro (com retry) e lista vazia.
- Layout de grade responsivo.

## Como executar

O projeto já vem com uma chave padrão de estudo em `lib/core/env.dart`,
então basta rodar:

```sh
flutter run
```

Para usar outra chave (recomendado em produção), sobrescreva via
`--dart-define`:

```sh
flutter run --dart-define=GIPHY_API_KEY=SuaChaveAqui
```

### 3. Rode os testes

```sh
flutter test
flutter analyze
```

## Estrutura

```
lib/
  core/env.dart              # Configurações de ambiente (chave da API)
  models/gif.dart            # Modelo imutável + parsing null-safe
  data/gif_api.dart          # Cliente HTTP, paginação e erros de domínio
  controllers/gif_controller.dart  # Estado de busca/paginação (ChangeNotifier)
  ui/home_page.dart          # Tela principal
  ui/gif_detail_page.dart    # Detalhes + compartilhamento
  ui/widgets/network_gif_image.dart  # Imagem com loading/fade/erro
  main.dart                  # Tema e entrada do app
```

## Decisões

- **Separação de camadas**: UI não conhece HTTP; a lógica fica no
  `GifController` e na `GifApi`.
- **Sem corrida de requisições**: respostas antigas são descartadas quando uma
  nova busca começa.
- **Tipagem**: JSON é convertido para `Gif`, ignorando itens inválidos em vez
  de quebrar a lista.
- **Configuração**: chave padrão de estudo embutida para facilitar o debug;
  pode ser sobrescrita por `--dart-define=GIPHY_API_KEY=...`.

## Possíveis próximos passos

- Cache de imagens com `cached_network_image`.
- Scroll infinito automático.
- Favoritos locais.
- Testes de integração da tela de detalhes/compartilhamento.
