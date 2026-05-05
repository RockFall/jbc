# Epic 7 — Timeline “viva”: fotos maiores, polaroid, cache local e fundo narrativo

## Objetivo

Elevar a **Linha do tempo** com quatro frentes coordenadas:

1. **Presença da foto** — área visual até ~**1,5×** maior que a referência da Epic 6, com **mais invasão** controlada da haste central, mantendo hit-test fiável e redução de movimento.
2. **Gramática polaroid** — leitura de **“foto impressa”** (margem clara tipo papel, sombra suave, cantos discretos) **sem** peso de assets nem `CustomClipper` pesado.
3. **Cache em disco** — imagens de capa (lista) e carrossel (detalhe) servidas via **`cached_network_image`**: após o primeiro download, **reabrir app ou ecrã** deve mostrar fotos **a partir do cache** quando ainda válido; refresh pode **pré-aquecer** URLs conhecidas.
4. **Fundo da timeline** — deixar de parecer **branco plano**: camadas **sutis** (gradiente + lavagens em cantos / faixa inferior), **fixas ao ecrã**, sem formas que “acompanham” o scroll (efeito weird).

## Princípios

- **Conteúdo primeiro**: fundo e moldura nunca roubam contraste ao texto nem às fotos.
- **Performance**: um `Transform` por foto onde possível; `RepaintBoundary` por item; pintura de fundo com `shouldRepaint` com limiar de scroll para não repintar a 60 fps desnecessariamente.
- **Determinismo**: escala/rotação estáveis por `eventId` (como na Epic 6); polaroid é **uniforme** (não aleatório).
- **Sem novos campos Supabase** nesta epic (só cliente e UI).

## Escopo

| Área | Entrega |
|------|--------|
| Tema / constantes | `timeline_theme.dart`: overlap maior, faixa de `widthFactor` ~1,0–1,42, constantes polaroid, eventual cor “papel”. |
| Lista | `timeline_screen.dart`: polaroid em volta do bloco foto; `CachedNetworkImage`; `precacheImage` para capas após dados; fundo com **pintor dedicado** (lista com eventos). |
| Detalhe | `timeline_event_detail_screen.dart`: `CachedNetworkImage` no carrossel (mesma chave de cache por URL). |
| Dependência | `cached_network_image` (+ `flutter_cache_manager` transitivo). |

## Fora do escopo (Epic 7+)

- Editor de evento com galeria cacheada (pode seguir o mesmo padrão noutra PR).
- Política agressiva de LRU / tamanho máximo de cache customizado (usar defaults do pacote salvo decisão de produto).
- Textura bitmap (noise) em full-bleed na web se perfilar como pesado.

## Critérios de aceitação

- [ ] Fotos na lista perceptivelmente **maiores** (até ~1,5× vs. Epic 6) e **mais overlap** na haste, sem regressão de `padding`/layout assert.
- [ ] Aparência **polaroid leve** (margem + sombra) coerente com tema claro.
- [ ] Modo **reduzir movimento**: sem rotação; escala pode ficar num valor fixo “grande mas calmo”.
- [ ] Com rede lenta na **primeira** visita: skeleton; na **segunda** abertura (sem invalidar cache): imagem **rápida** a partir de disco quando aplicável.
- [ ] Fundo da lista **não** homogéneo branco; **atmosfera** subtil (gradiente + lavagens), sem distrair do conteúdo.
- [ ] `flutter analyze` limpo; smoke **Android** (e **Web** se for alvo).

## Notas de implementação

- URLs assinadas (Supabase Storage) podem **expirar**: se as imagens falharem após TTL, o utilizador vê `errorWidget` até novo fetch — documentar em QA; mitigação futura: refresh de URLs no repositório.
- `precacheImage(CachedNetworkImageProvider(url), context)` após `addPostFrameCallback` na lista ordenada; em `didUpdateWidget` precache apenas URLs novas.

## Entregue (primeira passagem)

- **`timeline_theme.dart`**: overlap **26 px**; `widthFactor` **1,0–1,42**; modo redução de movimento com escala **1,2**; cores e paddings da moldura polaroid.
- **`timeline_scroll_background_painter.dart`**: **`TimelineDocumentBackgroundPainter`** — gradiente + **muitas formas orgânicas** (polígonos suavizáveis) claras/escuras ao longo da **altura do documento**; camada deslocada com o scroll (`Transform.translate`) para ficarem **fixas no conteúdo** e saírem do ecrã ao descer.
- **`timeline_screen.dart`**: **Stack** + `AnimatedBuilder` + altura estimada / `maxScrollExtent`; **`CachedNetworkImage`** + **`precacheImage`**, polaroid, `maxWidth` **410**.
- **`timeline_event_detail_screen.dart`**: carrossel com **`CachedNetworkImage`** (mesmo cache por URL).
- **`pubspec.yaml`**: dependência **`cached_network_image`**.

---

*Epic 7 — incremento sobre Epic 6; implementação referenciada nos ficheiros acima.*
