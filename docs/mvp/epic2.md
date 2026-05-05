# Epic 2 — Timeline afetiva da relação

## Objetivo

Entregar o módulo **Timeline** como eixo central do app: listagem cronológica de memórias, criação manual de eventos, edição, exclusão, imagem opcional, exibição de autor e datas, com sincronização para os três usuários.

## Pré-requisitos

- Epic 1 concluída: perfil no dispositivo, backend, streams/sync, navegação com aba Timeline.

## Escopo desta epic

### Funcional (alinhado à seção 5.1)

- Listar eventos em **ordem cronológica** pela **data do acontecimento**: por padrão, do **mais antigo ao mais recente** (leitura como linha do tempo da relação). Se o time preferir “últimas memórias primeiro”, documentar a escolha no app/README.
- **Criar** evento manualmente: data do acontecimento, título, descrição curta, imagem opcional.
- **Editar** evento existente (qualquer um dos três pode editar, conforme regras do produto).
- **Excluir** evento.
- **Anexar imagem opcional** (upload, armazenamento e URL/referência no documento do evento).
- Exibir **quem criou** o evento (`criado por`: Caio | Jojo | Bibi).
- Campos de auditoria: **data de criação**, **data de última edição** (atualizadas no servidor ou cliente de forma consistente).
- Campo **origem do evento**:
  - `manual` para eventos criados nesta epic pelo fluxo “+”.
  - Prever no modelo `vindo de rolê realizado` e vínculo com id do rolê (preenchido na Epic 3); na Epic 2, eventos manuais usam apenas `manual`.

### Sincronização

- Criação/edição/exclusão refletem nos **três dispositivos** via backend já integrado na Epic 1.

## Fluxos cobertos

- **Fluxo 1** (`project_definition.md` §7): abrir Timeline → "+" → preencher → salvar → evento visível para todos.

## Fora do escopo desta epic

- Marcar rolê como acontecido e **converter rolê em evento** (Epic 3).
- Qualquer lógica de **conflito de agenda** (Epic 3).

## Modelo de dados do evento (implementação)

Garantir persistência dos campos:

| Campo | Obrigatório |
|-------|-------------|
| id | sim |
| data do acontecimento | sim |
| título | sim |
| descrição curta | sim (pode ser string vazia se o produto permitir; se não, validar no app) |
| imagem opcional | não |
| criado por | sim (perfil) |
| origem | `manual` \| `fromHangout` (ou nomes equivalentes) |
| id do rolê origem | obrigatório apenas se origem = rolê |
| data de criação | sim |
| data de última edição | sim |

## Tarefas concretas (checklist)

### UI — lista

- [ ] Tela Timeline com lista rolável dos eventos ordenados por data do acontecimento.
- [ ] Em cada card/item: título, data formatada, trecho da descrição, **autor**, thumbnail se houver imagem.
- [ ] Estado vazio amigável (“Nenhuma memória ainda…”).
- [ ] Pull-to-refresh se fizer sentido com o backend escolhido.

### UI — criar/editar

- [ ] Botão flutuante ou equivalente **"+"** para novo evento.
- [ ] Formulário: data (picker), título, descrição, **opcional** imagem da galeria/câmera.
- [ ] Validações mínimas (título e data obrigatórios).
- [ ] Tela de **edição** reutilizando o mesmo formulário com dados carregados.
- [ ] Ação de **excluir** com confirmação (dialog).

### Imagem

- [ ] Seleção de imagem; upload para storage compatível com o backend (Firebase Storage, bucket S3, etc.).
- [ ] Salvar no documento do evento referência estável à imagem; tratar falha de upload com mensagem clara.

### Dados e regras

- [ ] Ao criar manualmente: `origem = manual`, sem id de rolê.
- [ ] `criado por` = perfil atual do dispositivo; em edições, atualizar `data de última edição` (e opcionalmente campo “editado por” se o modelo da Epic 1 incluir — não exigido pelo doc v1, apenas última edição).

### Sincronização e testes manuais

- [ ] Verificar em dois clientes: criar, editar, excluir e ver imagem propagando corretamente.

## Critérios de pronto (Definition of Done)

1. Os três perfis podem **ver** a mesma timeline ordenada cronologicamente.
2. Qualquer um pode **criar, editar e excluir** eventos (com confirmação na exclusão).
3. Evento **com ou sem imagem** funciona end-to-end.
4. **Autor** e **datas** (acontecimento, criação, última edição) aparecem conforme definido.
5. Eventos manuais têm `origem` manual e o modelo permite **vínculo futuro** com rolê sem migração quebrada.

## Dependências

- Epic 1.

## Referência

- `docs/project_definition.md` — seções 5.1, 7 (Fluxo 1), 8 (Epic 2), 9 (Fases 1–2), 10–11.
