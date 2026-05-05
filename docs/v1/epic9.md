# Epic 9 — Sistema de notificações (in-app + push)

## Objetivo

Dar ao trio visibilidade imediata do que mudou no app: **centro de notificações** na interface, **regras de agregação** para não spammar em edições rápidas na timeline, e **push no celular** para eventos de alto valor (novo item na timeline, novo rolê). A implementação deve ser **fácil de estender**: qualquer módulo novo chama uma API única do tipo “registrar notificação” com **módulo**, **ator** e **payload descritivo**.

## Escopo

### UI — sininho e lista

- Ícone de **sininho** no **canto superior direito**, **à esquerda** do ícone de **configurações** (engrenagem).
- **Badge numérico** com a contagem de notificações **não lidas** (ou total pendente — definir na implementação e documentar; padrão sugerido: não lidas).
- Toque no sininho abre **painel ou tela** com lista cronológica das notificações (mais recentes primeiro).
- Cada item mostra pelo menos: **quem** fez a mudança (perfil), **o quê** em linguagem natural (ex.: “Adicionou 3 fotos”, “Criou um rolê”), **contexto do módulo** (timeline, rolês, ideias, e futuros: conchinha, piaditas, etc.).

### Tipos de evento (mínimo v1)

- **Novo item** em qualquer módulo que participe do sistema (timeline, rolês, ideias, e os novos modos v1 conforme forem entregues).
- **Edições na timeline** (incluindo anexos, texto, metadados que forem relevantes): **várias edições do mesmo ator no mesmo evento dentro de uma janela curta** (ex.: 30–120 s, configurável) **viram uma única notificação**, com **resumo das alterações** (ex.: “Adicionou 3 fotos”, “Alterou a descrição”, “Moveu a data” — combinar numa linha legível).
- Extensibilidade: contrato de notificação aceita **código de tipo** + **parâmetros** para renderizar a mensagem (i18n-ready se quiserem depois).

### API de desenvolvimento

- Função/serviço central (ex.: `NotificationCenter.record(...)` ou `JbcNotifications.emit(...)`) recebendo:
  - **módulo** (enum ou string estável);
  - **ator** (`JbcProfile` ou id);
  - **ação / diff resumido** (estrutura serializável: lista de “mudanças” com tipo + contagem + snippets opcionais).
- **Persistência** compartilhada (Supabase): tabela `notifications` (ou equivalente) com leitura por todos os perfis, marcação de lida, eventual expiração/arquivamento.
- **Realtime** (ou poll leve) para atualizar badge e lista sem reiniciar o app.

### Push (mobile)

- Disparar **notificação no sistema** quando:
  - um **novo item** for adicionado na **timeline**;
  - um **novo rolê** for criado.
- Fora desse escopo nesta epic: push para cada edição de timeline (fica no in-app + agregação).
- Requisitos técnicos: FCM (Firebase Cloud Messaging) ou equivalente suportado pelo Flutter + backend (Edge Function / trigger Supabase) para enviar ao tópico ou tokens dos três dispositivos **exceto** o autor da ação (opcional: também silenciar para o autor).

### Agregação (timeline)

- Serviço que **acumula** alterações pendentes por `(evento_id, ator)` com debounce/janela temporal.
- Ao fechar a janela, **gravar uma notificação** com texto derivado do conjunto de operações (priorizar ações de mídia e mudanças estruturais visíveis).

## Fora do escopo

- Notificações por e-mail ou web.
- Preferências granulares por tipo (pode ser epic futura).
- Rich actions na push (aceitar conchinha etc.) — isso entra na epic de conchinha com complemento.

## Tarefas (checklist)

- [ ] Modelo de dados `notifications` + RLS alinhada ao modelo privado do trio.
- [ ] Camada `JbcNotifications` (ou nome equivalente) com `emit` / `emitAggregatedForTimelineEdit`.
- [ ] Provider/stream global para contagem não lida + lista.
- [ ] Widget do **sininho + badge** integrado ao `AppBar` / shell existente.
- [ ] Tela/painel de lista com marcar como lida (individual e “marcar todas”).
- [ ] Instrumentar **módulos existentes** (timeline create/update, rolê create, ideias create/update mínimo) com chamadas à API.
- [ ] Integração **FCM** + registro de token + envio server-side nos gatilhos “novo evento timeline” e “novo rolê”.
- [ ] Testes: agregação (várias edições → uma notificação); badge atualiza com realtime.

## Critérios de pronto (DoD)

1. Qualquer desenvolvedor consegue **adicionar uma linha** (ou bloco mínimo) após uma ação de negócio para gerar notificação consistente.
2. Edições rápidas na mesma memória **não** geram fila de dez notificações; geram **uma** com resumo compreensível.
3. Push recebido em segundo aparelho ao criar memória ou rolê (ambiente configurado).
4. UX do sininho está posicionada conforme especificação (**esquerda** da engrenagem).

## Dependências

- MVP com Supabase e perfis (`docs/mvp/epic1.md` em diante).
- Realtime já usado no projeto (replicar padrão).

## Referência

- `docs/project_definition.md` — alinhar tom de linguagem com o produto.
