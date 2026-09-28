# Spotlight inspirado no Raycast

## Acompanhamento (27/09/2026)

Legenda: ✅ implementado · 🟡 parcial · ⬜ pendente.

| Capacidade | Estado | Onde está / próximo passo |
| --- | --- | --- |
| Busca e ranking de aplicativos | ✅ | `SpotlightSearch.qml` |
| Modos `@`, `#`, `:`, `>`, `=`, `;`, `!`, `~` | ✅ | `Spotlight.qml` e componentes especializados |
| Ação primária, secundária e catálogo | ✅ | `SpotlightActionCatalog.qml`; execução ainda usa caminhos por tipo |
| Barra inferior e painel de ações (`→` ou `Ctrl+K`) | ✅ | `SpotlightActionBar.qml` e `SpotlightActionPanel.qml`; `←` fecha o painel |
| Preview de clipboard e modos especializados | ✅ | Interface existente preservada |
| Contrato comum de resultado | 🟡 | Normalização pronta; execução ainda lê campos antigos |
| Providers de apps, janelas e comandos | ✅ | `AppsProvider.qml`, `WindowsProvider.qml`, `CommandsProvider.qml` |
| Controlador de busca | 🟡 | Encaminha três providers; outros modos ainda estão em `Spotlight.qml` |
| Busca universal sem prefixo | ✅ | Apps, janelas e ações renderizados juntos; navegação, painel e Enter verificados |
| Ranking entre providers | 🟡 | Pontuação textual central verificada numa consulta mista; pesos ainda precisam ser avaliados no uso diário |
| Histórico de uso com recência | ⬜ | Persistir em XDG state; uso atual de apps é apenas frequência |
| Favoritos e aliases | ⬜ | Fixar e configurar pelo painel de ações |
| Quicklinks | ⬜ | Templates de URL com argumentos |
| Calculadora na busca raiz | ⬜ | Detectar expressões inequívocas; `=` já funciona |
| Ações avançadas de janela e catálogo de comandos do shell | ⬜ | Ampliar após busca universal |
| Painel genérico de detalhes | 🟡 | Clipboard e painel de ações já mostram detalhes; demais tipos ainda não têm renderer comum |
| Busca nas ações e navegação hierárquica | ⬜ | `Ctrl+K` atual permite navegar, mas não filtrar digitando |
| API de extensões | ⬜ | Somente após estabilizar os contratos |

### Marcos

| Marco | Estado | Critério para concluir |
| --- | --- | --- |
| 2.0 — Arquitetura de providers | 🟡 | Código e validação automática prontos; abertura, clipboard, janelas e `Ctrl+K` vistos em capturas. Ainda falta conferir digitação, outros prefixos e ações por teclado |
| 2.1 — Busca universal | ✅ | Consulta mista, renderização, latência amostral, setas, Ctrl+K, Escape e Enter verificados |
| Evolução posterior | ⬜ | Histórico, favoritos, quicklinks e demais itens, em mudanças separadas |

## Comportamento atual

O launcher já oferece busca de aplicativos e os modos `@` arquivos, `#` clipboard,
`:` ações, `>` comandos, `=` cálculo, `;` emoji, `!` encerramento e `~` janelas.
Há ação primária e secundária, barra inferior contextual, painel `Ctrl+K`,
modos especializados e preview dividido para clipboard. O painel mostra ações
na ordem dos grupos, sem cabeçalhos de grupo visíveis. A interface atual é a
referência visual; esta fase não muda dimensões, cores nem disposição.

`→` também abre as ações quando o cursor está no fim da consulta, sem seleção
de texto; dentro da consulta, mantém a edição normal do cursor. `←` fecha o
painel. Clipboard, tema e emoji preservam sua navegação própria.
Verificado em sequência de teclado e IPC: `→` abriu o painel, `←` o fechou,
`Ctrl+K` continuou abrindo; com o cursor dentro de `ghostty`, `→` apenas moveu
o cursor para o fim.

A busca sem prefixo ainda mostra somente aplicativos. Os modos especializados
continuam com seus backends e fluxos atuais. O orçamento de abertura é 150 ms.

## Marco 2.0 — Arquitetura de providers

Introduzir um contrato comum antes de alterar a apresentação ou misturar fontes:

```qml
{
    id: "app:Firefox",
    kind: "app",
    provider: "apps",
    title: "Firefox",
    subtitle: "Web Browser",
    icon: "firefox",
    score: 900,
    section: "Aplicativos",
    payload: {},
    primaryAction: "open",
    actions: ["open", "open-new", "copy-command"]
}
```

`SpotlightResult.qml` normaliza os resultados, conservando temporariamente os
campos de domínio usados por `activate()` e pelos previews. `AppsProvider.qml`,
`WindowsProvider.qml` e `CommandsProvider.qml` encapsulam as buscas que já
existiam em `SpotlightSearch.qml` e `SpotlightActions.qml`.
`SpotlightSearchController.qml` encaminha consultas para esses providers.
Os outros modos passam pelo normalizador, sem extração de backend nesta etapa.

**Aceite:** os prefixos, ordem e limite dos resultados, Enter, Ctrl+Enter e
Ctrl+K mantêm o comportamento atual; a busca raiz continua só de aplicativos;
nenhum processo novo entra no caminho de abertura; `validate.sh` passa.

## Marco 2.1 — Busca universal

Com texto e sem prefixo, combinar aplicativos, janelas e ações internas. Com
consulta vazia, preservar a lista atual de aplicativos. O rótulo de modo passa
de `Apps` para `Tudo` e a origem aparece no subtítulo; a janela e a lista
mantêm as dimensões atuais. A pontuação inicial
fica em `SpotlightRanking.qml`, com correspondência exata ou por prefixo acima
de uso e preferência de provider.

Evolução posterior: comparar a ordem do ranking em outras consultas e
acompanhar a latência no uso diário.

Preservar os prefixos como atalhos diretos para uma fonte. Medir latência antes
de incluir arquivos ou clipboard. Match textual exato ou por prefixo deve
dominar frequência e recência. Não adicionar seções ou ampliar a janela sem
inspecionar a interface renderizada.

## Evolução posterior

1. **Ranking e histórico de uso:** persistência pequena em XDG state;
   frequência e recência com pesos conservadores.
2. **Favoritos e aliases:** fixar, desfazer e definir nomes alternativos pelo
   painel de ações.
3. **Quicklinks:** templates de URL com argumentos codificados e ações próprias.
4. **Calculadora na raiz:** somente expressões inequívocas, mantendo `=`.
5. **Janelas e comandos:** ampliar ações via `scripts/compositor-dispatch.sh` e
   registrar comandos do shell em um catálogo local; extrair serviço só se
   outro consumidor precisar dele.
6. **Detalhes e ações:** painel de detalhes quando trouxer informação útil,
   busca dentro de `Ctrl+K`, navegação com no máximo dois níveis.
7. **Extensões:** apenas depois de estabilizar contratos de resultado e ação.

Cada extração deve acompanhar a fonte tocada. Não mover todos os modos para uma
nova árvore de diretórios de uma vez. Clipboard, arquivos e emoji mantêm seus
helpers e seus prefixos até haver motivo concreto para mudar.

## Validação e reversão

### Verificação realizada em 27/09/2026

- `./scripts/validate.sh`: 16 verificações aprovadas, 127 testes, uma
  advertência não relacionada (`kdeconnect-cli` ausente), latência medida de
  1 ms pelo verificador.
- Após a implementação inicial do 2.1, `validate.sh` voltou a passar com 80
  arquivos QML verificados e 127 testes. O serviço reiniciou e ficou ativo.
  Essa medida de 1 ms cobre a abertura vazia; ainda não mede a consulta mista.
- `quickshell.service` reiniciou e permaneceu ativo; o journal recente não
  mostrou erros do Spotlight.
- Capturas após IPC confirmaram a busca inicial de aplicativos, o modo `#`
  com lista e preview, o modo `~` com janelas e o painel `Ctrl+K` com ações da
  janela selecionada.
- A primeira tentativa isolada com `wtype` atingiu a janela do Codex. A
  verificação posterior usou uma sequência contínua de IPC e teclado virtual
  para manter o foco no Spotlight.
- No 2.1, uma inspeção temporária dentro do processo Quickshell consultou
  `ghostty` com janelas atualizadas: aplicativo, janelas e ação apareceram
  juntos, com o aplicativo exato em primeiro. A execução da busca levou 14 ms
  nessa amostra, sem contar o transporte IPC. Uma captura da interface mostrou
  os três tipos na janela padrão de 560 px, com origem legível no subtítulo.
  Os pontos de inspeção temporários foram removidos após a medição.
- Em uma sequência contínua de IPC e teclado virtual, a seta para baixo
  selecionou uma janela, `Ctrl+K` abriu suas ações, o primeiro `Escape`
  fechou o painel preservando a consulta e o segundo fechou o Spotlight.
  `Enter` sobre o resultado `ghostty-quake` focou a janela e fechou o launcher.
  `Ctrl+Enter` não foi executado nessa janela porque sua ação é fechá-la; o
  atalho pertence ao caminho existente, sem mudanças no 2.1. Os pontos
  temporários de leitura do estado foram removidos após esses testes.
- A busca universal inclui as ações de sessão já disponíveis no modo `:`.
  Consultas `desligar`, `reiniciar`, `suspender` e `bloquear` foram verificadas
  no processo Quickshell; o ranking não mostra aplicativos só por terem uso
  registrado quando o texto não corresponde.

Executar `./scripts/validate.sh` e verificar os logs após reiniciar o shell.
Testar abertura normal e cada prefixo, seleção, Enter, Ctrl+Enter, Ctrl+K e
Escape. Confirmar que clipboard, tema e emoji preservam navegação e preview.
Medir abertura contra 150 ms. Mudanças na busca universal entram separadas da
arquitetura 2.0, para que cada marco possa ser revertido isoladamente.
