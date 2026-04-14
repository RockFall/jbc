# Epic 5 — Identidade visual, perfil, timeline rica, ideias e rolês (pós-MVP)

## Objetivo

Evoluir o app após o **MVP funcional**: alinhar **marca e navegação** (AppBar, logo, textos em português afetivo), refinar **onboarding e troca de perfil** com emojis e cores por pessoa, permitir **várias imagens por memória** com imagem principal, **reconstruir a Linha do Tempo** como experiência visual de timeline central alternada, atualizar **Cantinho de Ideias** (rótulos, categorias, layout e galeria) e **Rolês** (rótulos das abas, título em indisponibilidades, vitrine de próximos rolês).

## Pré-requisitos

- MVP entregue: Epics 1–4 implementadas e app utilizável com Supabase conforme `docs/supabase_schema.sql`.

## Escopo desta epic

### 1. Shell global (AppBar e marca)

- Cor de fundo da **barra superior**: `#C30028`.
- No canto **esquerdo** da barra: logo **`jbc_logo_white_on_red.png`** (adicionar em `assets/`, declarar no `pubspec.yaml`).
- Título da aba de timeline na UI: **"Linha do Tempo"** (em vez de "Timeline"), mantendo o mesmo destino de rota.

### 2. Ajustes

- Substituir o rótulo **"Perfil neste aparelho"** por **"Quem é você"** (ou equivalente na hierarquia atual da tela).

### 3. Escolha inicial e troca de perfil

- Cada nome deve aparecer **logo após um emoji**:
  - **Caio** — calango  
  - **Jojo** — baleia  
  - **Bibi** — morcego  
- Substituir o layout de **três botões empilhados** por uma apresentação **mais rica**: cards ou painéis com **borda / destaque** nas **cores preferidas** de cada pessoa:
  - **Caio**: verde floresta  
  - **Jojo**: azul ciano  
  - **Bibi**: roxo escuro  
- Manter a mesma semântica (um toque seleciona o perfil e segue o fluxo atual).

### 4. Linha do Tempo — dados e imagens

- Um evento pode ter **mais de uma imagem**.
- UI simples para indicar qual imagem é a **principal** (usada como capa na lista e no cartão).
- Ajustar **modelo local**, **repositório** e **persistência** (ver migração abaixo). Fluxos existentes (criação manual, vinda de rolê) devem continuar válidos; definir regra de migração: evento com `image_url` único vira lista de uma imagem + principal = 0.

### 5. Linha do Tempo — reconstrução visual

- **Linha central** vertical como eixo da timeline; sensação de **timeline interativa**.
- Eventos **alternam** entre **esquerda** e **direita** da linha.
- **Cartão** do evento:
  - fundo **igual ao do tema / tela** (sem “card” contrastante com borda visível);
  - **sem borda** explícita no cartão.
- Quando houver imagem(ns): exibir a **primeira imagem** (ou a **principal**, alinhada à regra do item 4) em **destaque grande**; **texto / metadados abaixo**.
- **Remover** da apresentação principal do item:
  - textos do tipo **"Registrada em …"** e **"Atualizada …"**;
  - **nome de quem adicionou** (`criado por` pode permanecer no modelo para sync, mas não na UI da lista/detalhe resumido, salvo decisão contrária de produto).

### 6. Cantinho de Ideias

- Abas / segmentos superiores: **"A fazer"**, **"Já fizemos"**, **"Odiei"** (substitui rótulo de arquivadas); **sem emoticons** nos rótulos.
- Placeholder da busca: **"Busque uma ideia..."**.
- Layout: **barra de busca mais estreita** à esquerda; à **direita**, **seletor de categoria** (filtro).
- **Categorias** (enum / valores persistidos): **Nenhuma**, **Rolê**, **Cozinhaaar**, **Filmin**, **Série/Anime**, **Viajar**, **Hobby**, **Outro** (atualizar modelo, formulários, filtros e migração Supabase).
- Botões de ação **"Transformar em rolê"**, **"Marcar como realizada"** e **"Odiei"** (ou equivalentes): **mais centralizados** na tela de detalhe (ou área de ações), com hierarquia visual clara.
- **Galeria / lista de ideias**: tornar **mais interessante e “bonitinha”** (cards, espaçamento, talvez mini-hierarquia título + categoria + status), sem mudar regras de negócio além do acima.

### 7. Rolês

- Rótulos das três áreas superiores: **"Rolês"**, **"Meus horários"**, **"Horários do trio"** (substituir textos atuais mantendo comportamento).
- **Indisponibilidade** pode ter um **título** opcional (campo novo no modelo + formulário + lista).
- **Próximos rolês**: substituir **galeria vertical “chata”** por uma **vitrine mais rica** (ex.: destaque do próximo, agrupamento por data, chips de status, parallax leve ou cartões horizontais — definir na implementação dentro desta epic).

## Fora do escopo desta epic

- Novos módulos além dos citados.
- Autenticação forte ou mudança de modelo de segurança RLS (salvo o mínimo para novos campos).
- Notificações push ou calendário externo.

## Migração e modelo de dados

### `timeline_events` (Supabase + app)

- Evoluir de `image_url` único para suporte a **múltiplas URLs** e **índice ou id da principal**.
- Sugestão: coluna `image_urls text[]` ou `jsonb` + `primary_image_index int` (default 0), mantendo compatibilidade com dados antigos via script de migração SQL e leitura defensiva no app.
- Atualizar **Storage** / upload: múltiplos objetos por evento, paths estáveis (ver padrão em `timeline_storage_paths`).

### `ideas`

- Atualizar `category` (check constraint / enum) para os novos valores; mapear categorias antigas para as novas onde fizer sentido (ex.: `food` → **Cozinhaaar** ou **Outro**, documentar no script).
- Status **"arquivadas"** na UI passa a **"Odiei"**; pode manter valor `archived` no banco ou introduzir `hated` — preferir **menos churn**: manter `archived` no backend com rótulo **Odiei** na UI, a menos que o produto exija semântica distinta.

### `availabilities`

- Coluna opcional `title text` (ou `label text`), nula por padrão; formulário e listas exibem quando preenchido.

### Artefatos

- Atualizar `docs/supabase_schema.sql` e fornecer bloco de **ALTER / migração** comentado para projetos já existentes.

## Fluxos cobertos

- Abertura do app / shell: AppBar com cor e logo corretos; aba **Linha do Tempo**.
- Onboarding e **Ajustes** → troca de perfil: novo visual com emoji + cores.
- Criar/editar memória com **várias fotos** e escolha da principal; listar na nova timeline.
- Cantinho: filtros por aba e categoria; busca; ações centralizadas no detalhe.
- Rolês: abas renomeadas; criar indisponibilidade com título; ver próximos rolês na nova vitrine.

## Tarefas concretas (checklist)

### Marca e shell

- [ ] Asset `jbc_logo_white_on_red.png` + `pubspec.yaml`.
- [ ] `AppBarTheme` / `ThemeData` ou widget de barra: cor `#C30028`, logo à esquerda, títulos por aba atualizados onde necessário.

### Perfil

- [ ] `profile_picker_screen` (e fluxos relacionados): emojis + layout com bordas/cores (Caio / Jojo / Bibi).
- [ ] `settings_screen`: rótulo "Quem é você".

### Linha do Tempo — dados

- [ ] Modelo `TimelineEvent` com lista de imagens + principal.
- [ ] `SupabaseRepository` / storage: upload múltiplo, update, leitura.
- [ ] Editor de evento: galeria mini + seletor "principal".
- [ ] Migração SQL + testes manuais com eventos antigos.

### Linha do Tempo — UI

- [ ] Lista reconstruída: linha central, alternância esquerda/direita, cartões sem borda e fundo alinhado ao scaffold.
- [ ] Layout com imagem grande + dados abaixo; remover metadatas de registro/atualização e autor da UI principal.

### Cantinho

- [ ] Abas: A fazer / Já fizemos / Odiei (sem ícones nos rótulos se pedido foi explícito).
- [ ] Busca + filtro categoria em linha (busca menor, seletor à direita).
- [ ] Novas categorias ponta a ponta + migração.
- [ ] Detalhe: ações centralizadas.
- [ ] Grid/lista de ideias com visual renovado.

### Rolês

- [ ] Renomear tabs conforme especificação.
- [ ] Campo título em indisponibilidade (UI + API + DB).
- [ ] Nova apresentação de "próximos rolês".

### Qualidade

- [ ] `flutter analyze` limpo.
- [ ] Smoke test nos três perfis (sync opcional conforme ambiente).

## Critérios de pronto (Definition of Done)

1. AppBar vermelha **#C30028** com logo branca no vermelho à esquerda; label **Linha do Tempo** na navegação.
2. Ajustes mostram **"Quem é você"**; picker de perfil com emoji + cores por pessoa.
3. Eventos suportam **N imagens** com **principal** definida; dados migrados sem perda perceptível.
4. Lista da Linha do Tempo segue o **layout de timeline central** alternado, cartões integrados ao fundo, imagem em destaque, sem "Registrada/Atualizada" nem nome do autor na vista principal.
5. Cantinho: rótulos **A fazer / Já fizemos / Odiei**, busca e categorias novas, layout com filtro à direita, ações centralizadas, galeria mais polida.
6. Rolês: três rótulos de aba corretos; indisponibilidade com **título** opcional; próximos rolês com **vitrine** claramente mais rica que a lista vertical simples anterior.
7. Schema/documentação de migração atualizados para quem já rodou o MVP.

## Dependências

- Nenhuma epic nova além do estado atual do repositório; esta epic **altera** contratos de dados (timeline, ideias, availabilities) — coordenar deploy do SQL antes ou junto do release do app.

## Referência

- `docs/project_definition.md` — visão de produto e fluxos gerais.
- `docs/supabase_schema.sql` — baseline a estender com migrações desta epic.
