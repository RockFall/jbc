# Epic 11 — Detalhe da timeline em modo “colagem”

## Objetivo

Transformar o ecrã de **detalhe de um evento da timeline** numa experiência memorável: uma **colagem viva** que parece página de álbum ou mesa de trabalho criativa — não uma ficha técnica. O trio deve sentir orgulho de abrir uma memória: fotos com hierarquia clara, texto que respira, comentários como **notas coladas** e **reações emoji** que parecem carimbos ou stickers, tudo com **personalidade** e **legibilidade** em primeiro lugar.

## Conceito criativo: “mesa de memórias”

Imagina que cada evento é uma **folha sobre uma mesa de madeira clara** (ou tecido neutro): por cima vêm recortes de fotos, uma etiqueta com título e data, um bilhete com a descrição, fitas e detalhes gráficos discretos, e à volta os comentários do trio como **post-its** ou etiquetas de scrapbook. Nada grita; o protagonista são **as vossas fotos** e **as vossas palavras**. O app sugere calor humano com **textura**, **sombra suave** e **pequenas imperfeições controladas** (ligeiras rotações, sobreposição leve), nunca com “efeito Instagram” pesado.

### Tom visual (direção de arte)

- **Paleta:** fundo em tons quentes neutros (creme, bege rosado ou cinza muito quente) para contrastar com o vermelho da marca na shell sem competir; cartões em off-white com sombra difusa.
- **Materiais sugeridos:** “papel” mate nos cartões, **washi tape** abstrata (faixas sem padrão licenciado problemático: formas geométricas suaves), **clip** ou **alfinete** decorativo como ícone, não como foto realista.
- **Tipografia:** título com personalidade (pode alinhar à família manuscrita da lista, ex. Caveat/Patrick Hand, desde que contraste AA em tamanhos grandes); descrição e comentários em sans-serif legível (corpo do tema).
- **Luz:** sombras curtas e difusas (elevação baixa), como luz de secretária, não holofote de teatro.

## Princípios de composição (obrigatórios)

1. **Hierarquia:** fotos primeiro (área visual maior), depois título e data, depois descrição, depois reações e comentários.
2. **Ritmo:** alternar blocos cheios e vazios; evitar “parede de texto” antes de mostrar imagens.
3. **Uma só narrativa visual:** um fundo contínuo (textura ou gradiente muito suave) com elementos “colados” por cima — evitar sensação de vários cartões Material empilhados sem relação.
4. **Responsividade:** em ecrã estreito, colagem em **coluna** com scroll vertical; em ecrã largo (tablet), permitir **duas colunas** (fotos à esquerda, texto e comentários à direita) ou grelha mais larga, sem perder a leitura.
5. **Determinismo:** posições “orgânicas” (ligeira rotação, deslocamento em X/Y) derivadas de `eventId` com hash estável, para **todos verem a mesma colagem** em todos os dispositivos.

## Escopo visual e UX por zona

### Zona A — Fotos (hero)

- **Composição:** mistura de **sobreposição orgânica** (2–5 fotos com leve rotação e overlap) e, se houver muitas fotos, **faixa horizontal** ou **grelha irregular** (tamanhos ligeiramente diferentes, estilo “mural”, não grelha Excel).
- **Interação:** toque numa foto abre **lightbox** ou pager a tela cheia (reutilizar padrão mental da galeria atual, se existir); gesto de pinça opcional no lightbox.
- **Capa:** destacar visualmente a foto principal (borda, “fita” por baixo, ou ligeiro aumento), alinhado ao `primary_image_index` já existente.
- **Performance:** `cached_network_image`, limites de decode, hero opcional; com ~10 imagens, lista virtualizada ou secções lazy.

### Zona B — Título e data

- Integrados na colagem como **etiqueta** ou **faixa de polaroid alargada** (metáfora coerente com a lista), com data legível (formato local PT-BR).
- Se o evento for **vindo de rolê**, manter um **selo** ou chip discreto (“Rolê”) integrado ao layout, não flutuando sem contexto.

### Zona C — Descrição

- Bloco tipo **cartão de notas** ou **folha pautada suave** (linhas muito desaturadas ou sem linhas, só textura), cantos arredondados, padding generoso.
- Texto longo: expansão “ler mais” **opcional** só se quebrar o layout; preferir scroll da página inteira antes de truncar agressivamente.

### Zona D — Reações emoji (um por perfil)

- **Regra de produto:** cada um de Caio, Jojo e Bibi pode colocar **exatamente um** emoji por evento; escolher outro **substitui** o anterior.
- **UI:** faixa “**Carimbos do trio**” com três posições fixas (silhuetas ou iniciais quando vazio); toque abre **selector** compacto (grade de emojis curados + busca opcional).
- **Dados:** nova tabela `timeline_event_reactions` (ou nome equivalente) com `timeline_event_id`, `profile`, `emoji` (string Unicode), `updated_at`; RLS trio; Realtime como nos comentários.

### Zona E — Comentários (scrapbook)

- **Comentários** já existem no modelo atual (`timeline_event_comments`); manter autor, texto e tempo.
- Apresentação: **cartões pequenos** com sombra, ligeira rotação alternada, ou **linha vertical** estilo “fio de costura” com bolhas alternadas esquerda/direita conforme autor (opcional, mas deve parecer colagem, não chat corporativo).
- Ações: enviar, apagar só o próprio (regra já existente), estados vazio com ilustração ou copy acolhedora (“Ainda não há notas nesta memória”).

### Ornamentos (2–4 assets reutilizáveis)

- SVG ou PNG leve: cantoneira, mancha de aquarela muito suave, fita diagonal, “clip” metálico estilizado.
- **Colocação:** cantos ou margens, nunca em cima de texto essencial; opacidade baixa.
- **Reduzir movimento (SO):** sem parallax; rotações fixas ou zero; sem autoplay de vídeo (não há vídeo nesta epic).

### Navegação e transição

- Abrir o detalhe a partir da lista: transição suave; **shared element** da foto principal é *nice to have*, não bloqueante.
- AppBar do detalhe: ações de **editar** e **apagar** (se já existirem) integradas sem quebrar o mood (ícones claros, fundo coerente com a colagem ou transparente sobre gradiente).

## Acessibilidade e conteúdo

- Contraste **WCAG AA** para todo o texto longo (descrição, comentários); títulos grandes podem usar contraste calculado com cuidado.
- `Semantics` nos botões (“Enviar comentário”, “Escolher emoji”, “Abrir foto em ecrã completo”).
- Leitor de ecrã: ordem lógica (título → descrição → fotos com labels “Foto 1 de N” se fizer sentido).

## Estados a desenhar explicitamente

- **Sem fotos:** colagem com “moldura vazia” ou ilustração minimalista, foco no título e descrição.
- **Uma foto:** hero grande, menos ruído decorativo.
- **Muitas fotos:** composição em camadas + entrada na galeria secundária.
- **Sem comentários e sem reações:** CTAs suaves (“Deixa um emoji”, “Primeira nota”).
- **Erro / offline:** mensagem dentro do estilo (cartão de aviso), com retry.

## Fora do escopo

- Editor livre em que o utilizador arrasta cliparts ou redesenha a colagem.
- Threads de comentários aninhadas além de um nível.
- Vídeo, áudio ou animações Lottie pesadas em loop.

## Tarefas (checklist)

- [ ] Moodboard interno (3–5 referências de estilo) + decisão de paleta e texturas no issue ou Figma.
- [ ] Layout responsivo (telefone e, se viável, tablet) com anotações de medidas-chave (margens, raios, elevações).
- [ ] Novo ecrã ou widget raiz `TimelineEventCollageDetail` (nome final à escolha da equipa) substituindo o detalhe atual.
- [ ] Schema Supabase + RLS para **reações**; comentários: **reutilizar** tabela existente; habilitar Realtime na nova tabela se necessário.
- [ ] Stream combinado: evento atualizado + comentários + reações (Riverpod / repositório alinhado ao padrão atual).
- [ ] Selector de emoji curado (lista fixa inicial ~40 emojis + “outros” opcional) para evitar picker infinito pouco legível.
- [ ] Testes de widget: estado vazio, uma foto, várias fotos, comentário novo, troca de emoji.
- [ ] Pass de performance com 10 imagens e scroll longo.

## Critérios de pronto (DoD)

1. O detalhe é **visualmente distinto** da lista e transmite intenção de “colagem / álbum” sem sacrificar leitura.
2. Comentário criado noutro telemóvel **aparece** no detalhe aberto, sem reiniciar a app (Realtime).
3. Cada perfil tem **no máximo um** emoji visível; ao alterar, o anterior desaparece de forma clara.
4. Scroll e abertura de imagens mantêm-se fluidos com ~10 fotos no evento (sem jank óbvio em aparelho médio).
5. Com **reduzir movimento** ativado, a colagem permanece estável (sem animações decorativas desnecessárias).

## Dependências

- `docs/mvp/` — timeline, comentários, polaroid na lista.
- `docs/v1/epic10.md` — fotos 4:3 e multi-upload alinham o hero visual.

## Riscos e mitigação

- **Sobrecarga visual:** limitar a 2–3 ornamentos visíveis por ecrã e opacidade baixa; revisão com o trio.
- **Complexidade de layout:** começar por composição em coluna única bem resolvida antes de variantes tablet.
- **Emoji ambíguo em leitores de ecrã:** sempre associar label ao emoji escolhido (“Reação de Bibi: coração”).

## Referência

- Scrapbook digital, álbuns de viagem e moodboards no Pinterest (uso interno de inspiração; não copiar assets de terceiros).
