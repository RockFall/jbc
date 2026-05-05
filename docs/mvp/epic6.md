# Epic 6 — Linha do Tempo: camada visual e “alma” da experiência

## Objetivo

Manter o que já funciona bem — **eixo central**, **alternância esquerda/direita**, **progressão espacial proporcional ao tempo** entre memórias — e acrescentar **camadas visuais e microinterações** que tornem a leitura da timeline mais **memorável, calorosa e “JBC”**, sem virar um jogo de luzes nem comprometer legibilidade ou performance (especialmente em aparelhos modestos e na build web).

## Pré-requisitos

- Epic 5 entregue: timeline com ordenação recente → antiga, gaps temporais, detalhe com carrossel, comentários, identidade da AppBar, etc.
- Supabase e migrações atuais aplicadas conforme `docs/supabase_migration_epic5.sql` quando relevante.

## Princípios (não negociar)

1. **A hierarquia continua sendo o conteúdo** (foto, título, trecho da data): efeitos são secundários.
2. **Proporção temporal** na vertical permanece; qualquer “compressão visual” é opcional e **não pode** substituir a lógica atual de distância sem decisão explícita de produto.
3. **Acessibilidade**: contraste mínimo WCAG para textos; animações respeitam `MediaQuery.disableAnimations` / redução de movimento quando possível.
4. **Inclinação e “sorte” visuais**: variações leves (rotação, escala) devem ser **pseudo-aleatórias mas estáveis** — derivadas do `id` do evento (ou hash), para **não saltar** a cada rebuild; com **redução de movimento** ativa, usar rotação 0 e layout neutro.

## Escopo desta epic

### 1. Fundo e atmosfera da tela

- **Gradiente ou wash muito suave** no fundo da lista (ex.: cantos levemente mais quentes, centro mais neutro), alinhado ao `surface` já acolhedor do tema — evitar “papel de parede” que compete com os cartões.
- Opcional: **textura sutil** (noise SVG / asset leve em baixa opacidade) só na área da timeline, desligável se pesar na web.
- **Não** exigir novos assets bloqueantes; se usar imagem, documentar em `pubspec.yaml` e peso alvo.

### 2. Trilho central (“haste”) e nós

- **Gradiente ao longo da linha** (ex.: mais intenso perto do “presente” no topo, mais suave ao descer) ou pulse brand mínimo — reutilizar `primary` / vermelho da marca com opacidade.
- **Nó do evento**: anel suave + **sombra difusa** leve no ponto; micro-escala ao entrar no viewport (**implicitamente** via `Scrollable.ensureVisible` ou listener de visibilidade simples, sem dependências pesadas).

### 3. Cartões de evento na lista

- **Micro-sombra** ou elevação “quase flat” para separar do fundo sem voltar à borda pesada do MVP antigo.
- **Tipografia**: título com peso claro; data com estilo de **“selo”** ou pill muito suave (cor primária terciária) para leitura escaneável.
- **Cantos e ritmo**: leve variação de **padding horizontal** entre lado esquerdo e direito (já existe alternância; reforçar sensação de “conversa” entre os dois lados).
- **Estado “Rolê”**: chip ou ícone mínimo consistente com o detalhe, sem poluir.

### 4. Imagens na lista — destaque, escala e “colagem” ao trilho

Objetivo: as fotos passam a ser o **elemento mais vivo** da timeline — maiores, com presença quase de **polaroid / scrapbook**, sem perder o toque no cartão para abrir o detalhe.

- **Escala maior**: aumentar a área da foto em relação ao cartão atual (ex.: ocupar boa parte da largura útil do lado escolhido); o bloco de título/data pode ficar **abaixo** ou **parcialmente sobreposto** à base da imagem com um **scrim** ou gradiente curto para legibilidade, se necessário.
- **Sobrepor o trilho central (leve)**: permitir que a imagem **invada alguns pixels** por cima da haste (z-order da foto > trilho > fundo), criando profundidade. Definir um **máximo** de invasão (ex.: 8–20 px) para não mascarar o nó de forma confusa; o **área de toque** do cartão deve continuar previsível (testar hit-test no eixo central).
- **Variação de tamanho (sutil)**: entre cartões consecutivos (ou por evento), aplicar **pequenos multiplicadores** de largura/altura (ex.: 0,92–1,08) derivados do `id`, para sensação orgânica sem layout caótico.
- **Inclinação leve**: rotação em torno do centro do bloco da imagem, **poucos graus** (ex.: −4° a +4°), também estável por `id`; alternar sinal opcionalmente com o índice na lista para reforçar o “zigue-zague” já existente.
- **Sem foto**: manter placeholder forte (ícone ou cor) com **mesma gramática** de tamanho/inclinação opcional ou versão neutra (0°) para não parecer “erro” em relação aos vizinhos.
- **Hero transition** (ou transição compartilhada leve) da capa da lista → primeira imagem relevante no detalhe, quando viável sem refatorar todo o roteamento.
- **Placeholder** de carregamento: esqueleto alinhado ao **aspect ratio** alvo da variante de tamanho, não spinner solto no meio do card.
- **Performance**: `ClipRRect` / `Transform.rotate` custam; preferir **uma** `Transform` por cartão-foto e `RepaintBoundary` por item se o profiler mostrar ganho.

### 5. Microinterações e feedback

- **Haptic** leve no toque que abre o detalhe (`HapticFeedback.selectionClick` ou similar) em plataformas que suportam.
- **Pull-to-refresh**: manter funcionalidade; opcional ícone/texto afetivo (“Atualizando memórias…”) só na timeline, sem mudar o comportamento global do app.

### 6. Estado vazio e estados de erro

- **Empty state** ilustrado ou composição tipográfica forte (“Ainda não há memórias…”) com **CTA visual** alinhado ao FAB existente (texto que sugere o +), talvez pequeno desenho geométrico / coração / linha tracejada convidando ao primeiro registro.
- **Erro de rede**: bloco mais amigável (ícone + mensagem curta + botão já existente), harmonizado com a nova atmosfera da tela.

### 7. Performance e web

- Garantir que **CustomPaint** / camadas extras não multipliquem repaints na lista (agrupar pinturas, `RepaintBoundary` onde medido com ganho).
- **Web**: testar scroll + imagens de rede; lazy decode se necessário.

## Fora do escopo desta epic

- Novos campos no Supabase ou novos fluxos de dados (exceto se um item acima exigir flag opcional “destaque” — **não** incluir nesta epic por padrão).
- Reescrita da tela de **detalhe** / **edição** além do mínimo para Hero ou consistência visual listada no item 4.
- Som, vídeo, mapas ou modo “linha curva orgânica” completa (pode constar no **Backlog** abaixo).

## Backlog / ideias futuras (Epic 6+)

- Trilho com **curva suave** (Spline / Bézier) entre nós — alto esforço e risco de bugs de hit-test.
- **Marcadores de década/ano** fixos no eixo ao rolar (sticky) — útil com muitas memórias.
- **Tema noturno** dedicado só para a timeline.
- Confetti ou celebração **só** ao criar a primeira memória (easter egg).

## Critérios de aceitação (resumo)

- [ ] A timeline continua com **mesma ordem** e **mesma lógica de gaps** temporais (salvo mudança documentada e aprovada).
- [ ] Nenhum texto crítico abaixo do contraste aceitável em tema claro.
- [ ] Fotos na lista: **mais grandes** que o estado atual, com **invasão opcional e limitada** da haste central; rotação e escala **estáveis** por evento e **desligadas** com redução de movimento.
- [ ] Toque no cartão (incluindo zona da imagem sobre o trilho) abre o detalhe de forma **fiável**.
- [ ] `flutter analyze` limpo; smoke test manual em **Android** e **Web** na tela da Linha do Tempo.
- [ ] Documentação: este arquivo atualizado se o escopo real implementado divergir (secção “Entregue” opcional no fim da epic).

## Notas de implementação sugeridas

- Concentrar pinturas novas em **widgets dedicados** (ex.: `_TimelineScrim`, `_TimelineRailPainter` evoluído) para não inflar `timeline_screen.dart` indefinidamente.
- Centralizar **constantes visuais** (opacidades, **graus máx. de rotação**, **px máx. de overlap** no trilho, **faixa de escala** da foto) num pequeno `timeline_theme.dart` ou no topo do ficheiro com comentário `// Epic 6`.
- Função utilitária única tipo `timelineVisualVariantFor(String eventId)` → `{ scale, rotationTurns }` (e opcionalmente `widthFactor`) para manter **determinismo** e revisão fácil nos testes.

---

## Entregue (implementação atual no código)

- **`lib/features/timeline/timeline_theme.dart`**: gradiente de fundo da lista, constantes (overlap no trilho, rotação máx., faixa de escala), `timelineVisualVariantFor` (estável por `eventId` + alternância por índice), `timelineRailAlphaForIndex` (haste mais forte no topo).
- **`timeline_screen.dart`**: fundo com `timelineListBackgroundDecoration`; trilho em **duas camadas** (linha atrás dos cartões, **nó por cima** com `drawShadow`); padding assimétrico reforçado; cartões com **elevation** suave, cantos 20, **data em pill**; chip **Rolê**; imagem com **overlap** (`timelineRailOverlapPx`), **rotação + escala** (`Transform.rotate` + `Transform.scale`), gradiente na base da foto; skeleton de loading; empty/error redesenhados; **haptic** + `RefreshIndicator` com cor da marca; `RepaintBoundary` por item.
- **Não implementado nesta passagem** (fica para iterar): Hero para detalhe; textos custom no pull-to-refresh; textura noise; animação explícita de entrada por visibilidade; testes de profiler web dedicados.

---

*Epic 6 — proposta de produto; implementação em uma ou mais PRs incrementais.*
