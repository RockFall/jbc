# JBC

App privado para três pessoas: **memória** (Timeline), **rolês** e **cantinho de ideias**, com sincronização via Supabase.

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK no `pubspec.yaml`)
- Android Studio ou SDK Android para rodar no emulador/dispositivo

## Supabase (sincronização)

1. Crie um projeto em [Supabase](https://supabase.com) e copie **Project URL** e **anon public** key.
2. No SQL Editor, execute o script [`docs/supabase_schema.sql`](docs/supabase_schema.sql) (tabelas, RLS e bucket **`timeline-images`** para fotos da timeline). Se o projeto já existia antes das notificações (Epic 9), execute também [`docs/supabase_notification_epic9.sql`](docs/supabase_notification_epic9.sql). Se já existia antes das reações no detalhe (Epic 11), execute [`docs/supabase_timeline_reactions_epic11.sql`](docs/supabase_timeline_reactions_epic11.sql).
3. Em **Database → Replication**, habilite o **Realtime** para as tabelas `timeline_events`, `hangouts`, `availabilities`, `ideas`, **`jbc_notifications`**, **`fcm_device_tokens`** e **`timeline_event_reactions`** (Epic 11: reações no detalhe da memória).
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

**Fotos na timeline / memória do rolê:** galeria com multi-seleção (até 20 por vez), revisão da lista e enquadramento 4:3 com `crop_your_image` antes do upload; ver `lib/core/media/timeline_photo_limits.dart`.

**Notificações e push (opcional):** com Supabase ativo, o sininho lista avisos guardados em `jbc_notifications`. Para **Firebase Cloud Messaging** no Android, defina `dart_defines` com `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_ANDROID_API_KEY`, `FIREBASE_ANDROID_APP_ID` (e opcionalmente `FIREBASE_STORAGE_BUCKET`). Para o app pedir envio via Edge Function após nova memória ou novo rolê, use `--dart-define=JBC_PUSH_INVOCATION=true` e faça o deploy de `supabase/functions/send-jbc-push` com o secret `FIREBASE_SERVICE_ACCOUNT_JSON`. Veja `dart_defines.example.json`.

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
