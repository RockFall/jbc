# Epic 8 — Polaroid “de verdade”: um cartão, título na impressão, manuscrito

## Objetivo

Corrigir a leitura visual da timeline quando há **foto de capa**: hoje há sensação de **dois cartões** (bloco polaroid inclinado + bloco retangular com título/data em eixo vertical). O alvo é **um único cartão Material** onde **foto + moldura polaroid + título (e data na faixa da polaroid)** partilham a **mesma transformação** (translação de overlap, rotação, escala), como uma **fotografia física** com legenda escrita na borda branca.

## Escopo

1. **Layout**
   - **Um** `Material` / `InkWell` por evento com capa.
   - Dentro dos `Transform` (translate → rotate → scale): **coluna** = imagem (aspect 4:3) + **zona de legenda** na margem inferior tipo polaroid (papel contínuo com a foto).
   - **Fora** dos `Transform` (ainda no mesmo cartão): texto longo — **descrição** (e chip **Rolê** se aplicável), em tipografia normal, para legibilidade e acessibilidade.

2. **Tipografia do título**
   - Estilo **manuscrito / caneta** na legenda da polaroid (ex.: **Caveat** ou **Patrick Hand** via `google_fonts`), cor escura sobre o “papel”, tamanho legível, `maxLines` + `ellipsis` se necessário.
   - **Data** na mesma faixa polaroid, ligeiramente menor (ainda script ou variante da mesma família).

3. **Epic 6/7**
   - Manter overlap no trilho, `RepaintBoundary`, cache de imagem, redução de movimento (rotação 0, escala moderada).

## Fora do escopo

- Alterar o ecrã de **detalhe** ou **editor** (só lista).
- Vectorizar assinaturas reais por utilizador.

## Critérios de aceitação

- [ ] Com capa: **título + data** visíveis na **mesma inclinação** que a foto.
- [ ] Um único bloco elevado/sombreado (não “cartão dentro de cartão” desalinhado).
- [ ] Sem capa: mantém título + data + descrição como hoje (sem polaroid vazia).
- [ ] `flutter analyze` limpo; fonte carrega em Android (primeira abertura pode ir à rede para cache do `google_fonts`).

## Entregue (implementação)

- **`docs/epic8.md`** + **`pubspec.yaml`**: dependência **`google_fonts`**.
- **`timeline_screen.dart`**: polaroid inclinada; **sem imagem** = sem slot 4:3 (só papel + título/data); **descrição** só no detalhe — na lista, ícone `notes` + `celebration` discretos na legenda quando há texto / rolê; **`Stack` da linha**: haste + nó **antes** do `Row` para os cartões cobrirem a haste.
- **`timeline_theme.dart`**: paddings da polaroid ligeiramente menores; constante **`timelinePolaroidImageBoost`**.

---

*Epic 8 — incremento visual sobre Epic 7.*
