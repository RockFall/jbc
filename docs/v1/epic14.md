# Epic 14 — Modo Emoção do momento (stickers)

## Objetivo

Permitir que **cada perfil** expresse **como se sente agora** escolhendo um **sticker** (emoji grande ou ilustração pequena pré-definida). Os três estados ficam **visíveis em conjunto** (ex.: três cartões lado a lado ou círculo do trio), atualizando em **tempo real** quando alguém muda de sticker.

## Escopo

### Catálogo

- Conjunto inicial de **stickers** (12–24) categorizados opcionalmente (feliz, cansado, ansioso, apaixonado, etc.).
- Assets estáticos no bundle (PNG/SVG) ou font emoji com **tamanho grande** — preferência: ilustrações próprias leves para identidade do app.

### Estado “do momento”

- Para cada perfil: **última emoção selecionada** + `updated_at`.
- Modelo: tabela `moment_emotions` com `profile`, `sticker_id`, `updated_at` (upsert por perfil) **ou** colunas em tabela de presença se já existir padrão.

### UI

- Grade de seleção ao tocar no próprio cartão.
- Visualização dos **outros dois** com sticker atual (placeholder se nunca escolheram).
- Opcional: pequena **frase opcional** (até N caracteres) — fora do escopo se quiserem manter só sticker na v1.

### Notificações

- In-app (Epic 9): “Bibi atualizou a emoção do momento” — **agregável** se houver spam de testes (debounce curto).

## Fora do escopo

- Histórico temporal completo de emoções (gráfico) — pode ser fase 2.
- Stickers custom desenhados pelo usuário.

## Tarefas (checklist)

- [ ] Curadoria inicial de stickers + metadata (`id`, `label_a11y`).
- [ ] Tela do modo + integração Realtime.
- [ ] Acessibilidade: `Semantics` com label por sticker.

## Critérios de pronto (DoD)

1. Os três perfis conseguem cada um o seu sticker **independente**.
2. Mudança no dispositivo de A reflete em B em tempo real.
3. App funciona offline com **último estado em cache** e sync ao voltar rede.

## Dependências

- Epic 9 para notificações.
- Perfis fixos.

## Referência

- Alinhar visualmente com Epic 11 (colagem) se compartilharem componentes de “cartão”.
