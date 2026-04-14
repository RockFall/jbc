# JBC

App privado para três pessoas: **memória** (Timeline), **rolês** e **cantinho de ideias**, com sincronização via Supabase.

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK no `pubspec.yaml`)
- Android Studio ou SDK Android para rodar no emulador/dispositivo

## Supabase (sincronização)

1. Crie um projeto em [Supabase](https://supabase.com) e copie **Project URL** e **anon public** key.
2. No SQL Editor, execute o script [`docs/supabase_schema.sql`](docs/supabase_schema.sql) (tabelas, RLS e bucket **`timeline-images`** para fotos da timeline).
3. Em **Database → Replication**, habilite o **Realtime** para as tabelas `timeline_events`, `hangouts`, `availabilities` e `ideas` (necessário para os streams em tempo real).
4. Opcional: em **Authentication → Providers**, habilite **Anonymous** se quiser usar login anônimo; o app funciona com a chave `anon` mesmo com políticas RLS abertas do script de desenvolvimento.

### Rodar com variáveis de ambiente

No PowerShell:

```powershell
flutter run --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co --dart-define=SUPABASE_ANON_KEY=sua-chave-anon
```

Ou crie `dart_defines.json` a partir do modelo versionado (o arquivo real **não** vai para o Git):

```powershell
copy dart_defines.example.json dart_defines.json
# edite dart_defines.json com URL e chave anon do Supabase
flutter run --dart-define-from-file=dart_defines.json
```

Sem `SUPABASE_URL` e `SUPABASE_ANON_KEY`, o app abre em modo **somente local** (sem sincronização entre aparelhos); ainda é possível escolher perfil e navegar nas três abas. Na timeline, **+** abre o formulário de memória, mas salvar exige Supabase configurado.

A **timeline** lista memórias do **mais antigo ao mais recente** (data do acontecimento).

**Rolês:** três abas (rolês, suas indisponibilidades, visão do trio). Conflitos com indisponibilidades são **avisados** e não bloqueiam o salvamento; se o rolê não tiver horário final, o aviso usa **1 hora** a partir do início. Rolê **cancelado** não vira memória. Datas de rolê vêm do Postgres como **dia civil local** (sem deslocar fuso).

**Cantinho de ideias:** segmentos Ativas / Realizadas / Arquivadas, busca por título, CRUD e **Transformar em rolê** (abre o editor de rolê com título/descrição/categoria sugeridos). Depois de salvar o rolê, o app pergunta se marca a ideia como **realizada**; a ideia pode permanecer ativa.

## Segurança

O script SQL inclui políticas RLS **permissivas** (`using (true)`) para facilitar o desenvolvimento de um app **privado** distribuído só ao trio. Isso **não** substitui um modelo de segurança público: para produção, use autenticação (por exemplo usuários fixos no Supabase Auth) e políticas RLS restritivas. Veja também `docs/project_definition.md`.

## Estrutura do projeto

- `lib/core` — tema, perfil no dispositivo, bootstrap, providers Riverpod
- `lib/data` — modelos de domínio e repositório Supabase
- `lib/features` — telas (onboarding, shell, placeholders por módulo)

## Testes

```powershell
flutter test
```

## Git e GitHub

- O `.gitignore` exclui `dart_defines.json`, builds, `.dart_tool/`, etc.
- No GitHub, crie um repositório **vazio** (sem README se já tiver um local).
- Depois do primeiro commit local, associe o remoto e envie:

```powershell
cd c:\fall\dev\jbc
git remote add origin https://github.com/SEU_USUARIO/SEU_REPO.git
git branch -M main
git push -u origin main
```

Substitua a URL pelo repositório real. Use **SSH** (`git@github.com:...`) se preferir.
