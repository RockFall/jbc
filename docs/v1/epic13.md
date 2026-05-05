# Epic 13 — Modo Piaditas (pote de piadas internas)

## Objetivo

Guardar e celebrar **piadas internas** do trio: uma tela com um **pote** (ilustração ou 3D leve em Flutter) **no centro**; o **usuário escreve** uma piada e **deposita** no pote; o conteúdo fica **persistido**, **listável** e **pesquisável** (opcional na primeira versão: só lista cronológica).

## Escopo

### UI

- **Pote central** como foco visual (animação sutil ao “depositar”: confetes discretos ou moeda caindo — respeitar reduzir movimento).
- Campo de texto multilinha + botão **Guardar no pote**.
- Aba ou seção **“Abrir o pote”**: lista das piadas com autor e data; toque expande texto completo.
- Empty state acolhedor quando o pote está vazio.

### Dados

- Tabela `inside_jokes` (nome interno) ou `piaditas`: `id`, `texto`, `autor` (perfil), `created_at`, opcional `tags`.
- RLS trio-only alinhado ao resto do projeto.

### Notificações (opcional mas desejável)

- Epic 9: notificar “X guardou uma piada no pote” (pode ser in-app apenas para não ruído — configurável).

## Fora do escopo

- Moderação ou reporting (app privado).
- Compartilhamento para fora do app.

## Tarefas (checklist)

- [ ] Navegação até o modo Piaditas (hub de modos ou entrada dedicada).
- [ ] Schema Supabase + repository + Riverpod.
- [ ] Animação de depositar (versão simples aceitável na v1).
- [ ] `flutter test` para parser/validação (ex.: trim, max length).

## Critérios de pronto (DoD)

1. Piada criada num celular aparece em outro aparelho via sync.
2. Lista ordenada por data; sem crashes com textos longos.
3. Pote é elemento visual **central** óbvio na primeira abertura do modo.

## Dependências

- MVP + Epic 9 se notificações forem incluídas.

## Referência

- Tom de copy: leve e íntimo, consistente com JBC.
