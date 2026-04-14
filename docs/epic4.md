# Epic 4 — Cantinho de Ideias compartilhado

## Objetivo

Entregar o módulo **Cantinho de Ideias**: lista colaborativa de ideias, CRUD, categorização simples, transição de status (ativa / realizada / arquivada) e ação **opcional** de **transformar ideia em rolê**, reaproveitando o fluxo de criação de rolê da Epic 3 sem obrigar a ideia a sumir.

## Pré-requisitos

- Epic 1 concluída (perfil, sync, aba Ideias na navegação).
- Epic 3 concluída para a ação “transformar em rolê” abrir o formulário de rolê com dados pré-preenchidos e salvar no mesmo backend de rolês.

## Escopo desta epic

### Funcional (seção 5.3)

- **Listar** ideias de todos (lista simples e fácil de consultar — cards ou lista densa com título + status + categoria).
- **Adicionar** ideia: título, descrição opcional, categoria opcional.
- **Editar** e **excluir** ideia (qualquer um dos três).
- **Categorias opcionais** (enum fixo): rolê, comida, filme, série, viagem, outro.
- **Status**: ativa → realizada ou arquivada; permitir consultar realizadas/arquivadas (filtro, abas ou seções).
- Regra de produto: ideia **realizada** pode permanecer visível como histórico ou ser **arquivada**; implementar transições de status de forma explícita na UI.

### Transformar ideia em rolê (Fluxo 6)

- Na tela de detalhe ou menu da ideia: ação **“Transformar em rolê”**.
- Abrir criação de rolê com:
  - título (e descrição/observações se fizer sentido) **pré-preenhidos** a partir da ideia;
  - usuário ajusta **data** e **horários**;
  - ao salvar, criar rolê com status **planejado** e `criado por` = perfil atual.
- A **ideia não desaparece obrigatoriamente**: após criar o rolê, sugerir marcar ideia como **realizada** ou deixar **ativa** (UX clara; opção de marcar realizada em um passo).

## Fluxos cobertos

- **Fluxo 5**: Cantinho → adicionar → título, descrição, categoria → salvar → visível para os três.
- **Fluxo 6**: abrir ideia → transformar em rolê → ajustar data/hora → salvar rolê.

## Fora do escopo desta epic

- Lógica de indisponibilidade e conflitos (já na Epic 3); apenas abrir o fluxo de novo rolê.
- Edição profunda do módulo Timeline além do que já existe.

## Modelo de dados da ideia

| Campo | Obrigatório |
|-------|-------------|
| id | sim |
| título | sim |
| descrição opcional | não |
| categoria opcional | enum: rolê, comida, filme, série, viagem, outro |
| status | ativa \| realizada \| arquivada |
| criado por | sim |
| data de criação | sim |
| data de última edição | sim |

Opcional futuro: id do rolê criado a partir da ideia (útil para rastreio); incluir se custo for baixo.

## Tarefas concretas (checklist)

### Lista e navegação

- [ ] Tela principal do Cantinho com lista de ideias; estado vazio.
- [ ] Filtro ou segmentação: **ativas** (default), **realizadas**, **arquivadas** (ou combinação que cubra a regra de histórico).
- [ ] Busca simples por título (opcional mas recomendada se pouco esforço).

### CRUD

- [ ] Formulário criar/editar com validação de título.
- [ ] Seletor de categoria (incluindo “nenhuma”).
- [ ] Ações para mudar status: ex. “Marcar como realizada”, “Arquivar”, “Reativar” onde aplicável.
- [ ] Excluir com confirmação.

### Integração com Rolês

- [ ] Ação **Transformar em rolê** navegando para a tela de novo rolê (Epic 3) com **arguments** ou estado compartilhado (título/descrição da ideia).
- [ ] Após sucesso, feedback e opção de atualizar status da ideia para **realizada**.

### Sincronização

- [ ] Todas as operações refletem nos três dispositivos.

### Polimento

- [ ] Cores/typography alinhadas ao restante do app (afetivo, leve).

## Critérios de pronto (Definition of Done)

1. Os três perfis veem a **mesma lista** de ideias atualizada.
2. CRUD completo + categorias + **três status** com UX clara.
3. **Transformar em rolê** pré-preenche o formulário e cria rolê planejado; ideia permanece a menos que o usuário opte por marcar como realizada.
4. Nenhuma contradição com as permissões globais (todos editam tudo, conforme doc).

## Dependências

- Epic 1 obrigatória; **Epic 3 obrigatória** para a integração “ideia → rolê” completa (pode-se entregar CRUD de ideias antes, mas esta epic só fecha com o link ao rolê).

## Referência

- `docs/project_definition.md` — seções 5.3, 7 (Fluxos 5–6), 8 (Epic 4), 9 (Fase 3), 10–11.
