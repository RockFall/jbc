# Epic 16 — Visão “semana” do trio (estilo Google Agenda)

## Objetivo

Evoluir a **visão de horários em trio** (indisponibilidades + rolês) para um formato **semanal** semelhante ao **modo semana do Google Calendar**: **grade temporal** com **blocos visuais** de ocupação, sobreposições claras, e navegação **semana anterior / seguinte**.

## Escopo

### Visualização

- Colunas por **dia** (7 dias da semana local) e eixo vertical de **horas** (ex.: 6h–24h ou scrollável 0h–24h).
- **Blocos**:
  - **Indisponibilidades** de cada perfil com **cor por perfil** (Caio / Jojo / Bibi) e padrão semi-transparente se sobrepostos.
  - **Rolês** como blocos sólidos (ou padrão distinto) com título e intervalo de tempo.
- Legenda de cores e toggle **mostrar/ocultar** por perfil.

### Interações

- Toque em um bloco de rolê → navegar para detalhe/edição existente.
- Toque em um slot vazio (opcional v1): **atalho** para criar indisponibilidade ou rolê (nice to have).
- **Hoje** destacado; linha ou marcador de **hora atual** no dia de hoje.

### Dados e fuso

- Reutilizar modelos `availabilities` e `hangouts`; respeitar **dia civil local** como no MVP (sem alterar eventos incorretamente por causa do fuso horário).
- Performance: para uma semana, carregar apenas eventos que intersectam o intervalo `[start, end)`.

## Fora do escopo

- Sincronização com Google Calendar externo.
- Vista mensal completa (pode ser outra epic).
- Drag-and-drop para mover rolês na grade (fase 2).

## Tarefas (checklist)

- [ ] Componente `WeekGrid` (nome ilustrativo) com layout custom (`CustomMultiChildLayout` ou pacote de calendar avaliado).
- [ ] Camada que **normaliza** eventos para retângulos `top/height` na grade.
- [ ] Testes de layout com DST (mudança de horário de verão) se aplicável à região.
- [ ] Integração na aba **visão do trio** existente (substituir ou alternar vista dia/lista).

## Critérios de pronto (DoD)

1. Usuário reconhece o padrão “**agenda semanal**” sem treinamento (validação com o trio).
2. Dois rolês no mesmo horário aparecem **lado a lado** ou **empilhados** de forma legível (definir regra e documentar).
3. Semana muda ao deslizar ou com chevrons; dados corretos após troca.

## Dependências

- `docs/mvp/epic3.md` / epics de rolês e indisponibilidades (conforme implementação atual).

## Referência

- Google Calendar Android — modo semana (comportamento de referência, não cópia pixel-perfect).
