# Epic 3 — Planejamento de rolês e conversão em memória

## Objetivo

Entregar o módulo **Rolês**: indisponibilidades recorrentes por dia da semana, visão consolidada de disponibilidade, CRUD de rolês com estados (planejado / aconteceu / cancelado), **sinalização visual de conflito** com indisponibilidades (sem bloquear criação), e **fluxo completo** de marcar rolê como “aconteceu” e **gerar evento na Timeline** com vínculo ao rolê original.

## Pré-requisitos

- Epic 1 e Epic 2 concluídas: perfis, backend, Timeline com eventos e campo de origem/vínculo com rolê.

## Escopo desta epic

### Indisponibilidades (seção 5.2)

- Cadastrar faixa: **pessoa** (sempre o perfil do dispositivo ao criar/editar a própria lista), **dia da semana**, **horário inicial**, **horário final**.
- **Editar** e **excluir** apenas as indisponibilidades **da própria pessoa** (cada um gerencia a sua; todos veem todas).
- Visualização **consolidada**: ver indisponibilidades dos três (por pessoa e/ou vista unificada — implementar de forma legível).

### Rolês (seção 5.2)

- Criar rolê: título, descrição opcional, **data**, horário inicial, horário final opcional, status inicial **planejado**, `criado por`, observações opcionais.
- Editar rolê (qualquer um dos três).
- **Cancelar** rolê → status **cancelado**.
- **Marcar como “aconteceu”** → status **aconteceu**.

### Conflitos de agenda

- Ao criar/editar rolê, **comparar** data/hora do rolê com as indisponibilidades recorrentes do trio **no dia da semana correspondente à data do rolê**.
- Se houver sobreposição com alguém, **mostrar aviso visível** (badge, banner ou ícone); **não impedir** salvar.

### Conversão rolê → Timeline (seção 5.2 e Fluxo 4)

- Ao marcar como “aconteceu” (ou ação dedicada “virar memória”): abrir fluxo em **etapas**:
  1. Complementar **título**, **descrição**, **imagem opcional** (pré-preencher com dados do rolê quando fizer sentido).
  2. Ao salvar: criar **evento na Timeline** com:
     - data do acontecimento alinhada ao rolê;
     - origem = vinda de rolê realizado;
     - **vínculo** com id do rolê;
     - `criado por` coerente com o fluxo (perfil atual).
  3. No documento do rolê: preencher **vínculo com evento da timeline** (id do evento criado).
- Garantir **idempotência** ou UX clara: evitar criar **duplicatas** de evento se o usuário repetir a ação (um evento por rolê realizado, salvo se o produto não disser o contrário).

## Fluxos cobertos

- **Fluxo 2**: Rolês → área de indisponibilidades → adicionar faixa → salvar → visão compartilhada.
- **Fluxo 3**: criar rolê com checagem visual de conflitos.
- **Fluxo 4**: rolê realizado → marcar aconteceu → complementar memória → salvar → evento na timeline vinculado.

## Fora do escopo desta epic

- Módulo **Cantinho de Ideias** e transformação ideia → rolê (Epic 4). Se a Epic 4 criar rolê a partir de ideia, apenas expor navegação/API compartilhada na Epic 4.

## Modelo — indisponibilidade

| Campo | Notas |
|-------|--------|
| id | |
| pessoa | Caio \| Jojo \| Bibi |
| dia da semana | domingo … sábado (definir enum índice 0–6 e timezone local do dispositivo para “dia”) |
| horário inicial | |
| horário final | |

Validar `início < fim` no mesmo dia; se cruzar meia-noite, na v1 pode não suportar — documentar limitação ou implementar faixa única por dia.

## Modelo — rolê

| Campo | Notas |
|-------|--------|
| id | |
| título | |
| descrição opcional | |
| data | |
| horário inicial | |
| horário final opcional | |
| status | planejado \| aconteceu \| cancelado |
| criado por | |
| observações opcional | |
| id evento timeline | se existir memória gerada |

## Tarefas concretas (checklist)

### Indisponibilidades

- [ ] UI para listar minhas indisponibilidades e adicionar/editar/remover.
- [ ] UI para **visão consolidada** (calendário semanal simplificado, lista por dia, ou abas por pessoa).
- [ ] Persistência e sync no backend; leitura em tempo real ou refresh.

### Rolês — CRUD e lista

- [ ] Lista de rolês (futuros e passados), filtros mínimos ou ordenação por data.
- [ ] Formulário de criação/edição com todos os campos; status manipulável conforme regras (ex.: cancelado e aconteceu como ações explícitas).

### Conflitos

- [ ] Função pura: dado rolê (data, início, fim opcional) + lista de indisponibilidades de todos → lista de **pessoas em conflito** ou flag.
- [ ] Exibir na criação/edição e no detalhe do rolê.

### Conversão para Timeline

- [ ] A partir de rolê em estado adequado, fluxo “virar memória” com tela de complemento.
- [ ] Criar documento na coleção de eventos (Epic 2) com origem “de rolê” + ids cruzados.
- [ ] Atualizar rolê com referência ao evento.

### Edge cases

- [ ] Rolê **cancelado**: não permitir conversão, ou esconder ação (definir e implementar).
- [ ] **Horário final** opcional: na checagem de conflito, definir regra (ex.: duração mínima de 1h ou só início) e documentar.

## Critérios de pronto (Definition of Done)

1. Cada pessoa gerencia **só** suas indisponibilidades; **todos** veem a consolidação.
2. Rolês podem ser criados, editados, cancelados e marcados como **aconteceu**.
3. **Conflitos** aparecem de forma clara e **não bloqueiam** o salvamento.
4. Fluxo “aconteceu → memória” cria evento na Timeline com **vínculo bidirecional** rolê ↔ evento.
5. Dados sincronizam entre os três dispositivos para rolês e indisponibilidades.

## Dependências

- Epic 1, Epic 2.

## Referência

- `docs/project_definition.md` — seções 5.2, 7 (Fluxos 2–4), 8 (Epic 3), 9 (Fase 4), 10–11.
