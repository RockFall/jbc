# Epic 15 — Continhas: Caixa do JBC + divisão por rolê (Splitwise)

## Visão geral

Este modo junta **duas coisas** que convivem no mesmo produto, mas com responsabilidades claras:

1. **Caixa do JBC** — um **único fundo virtual** do trio: cada perfil pode **depositar** (registro manual de valor em BRL). Gastos marcados como **pagos pela Caixa** debitam esse fundo e **não geram dívida** entre pessoas (ninguém “deve” ninguém por aquela linha).
2. **Divisão por rolê** — gastos ligados a um **rolê** (`hangout_id`): cada um lança **N despesas**; em cada despesa define-se **com quem divide** o custo e se o pagamento foi **próprio** (alguém pagou do bolso e os outros devem parte) ou **da Caixa do JBC** (saída do fundo, sem criar dívidas entre perfis).

Além dos três perfis fixos do app, é possível incluir **outras pessoas** nas contas de um rolê: são **reutilizáveis** (cadastro com **nome + emoji**), aparecem nos splits e no **relatório final** de quem deve quem.

---

## Objetivo

- **Transparência:** ver o que foi gasto no rolê, o que saiu da Caixa e **quem deve a quem** quando o pagamento foi pessoal.
- **Fechamento claro:** ação **“Fechar gastos do rolê”** congela o cálculo daquele rolê e gera um **resultado direto** (saldos líquidos + sugestão mínima de acertos), sem reprocessar despesas antigas de forma confusa.
- **Caixa única:** saldo da Caixa do JBC é **global ao trio** (não por rolê); o que muda por rolê é só **qual despesa** debitou a Caixa.

---

## 1. Caixa do JBC (fundo único)

### Comportamento

- **Depósito:** qualquer perfil registra “coloquei R$ X na Caixa” (valor positivo, data, opcional nota curta). Soma ao saldo disponível da Caixa (ver modelo abaixo: ledger ou saldo materializado).
- **Débito:** quando uma despesa de rolê é salva como **“Pago pela Caixa do JBC”**, o valor total da despesa (ou a parte paga pela Caixa, se no futuro houver split híbrido) gera um **lançamento de saída** na Caixa. **Ninguém deve ninguém** por essa despesa no cálculo de dívidas entre pessoas.
- **Saldo:** tela dedicada “Caixa” mostra saldo atual, últimos lançamentos e quem depositou.

### Regras (v1)

- Moeda única: **BRL**.
- Não permitir débito que deixe saldo negativo **ou** permitir com flag “saldo negativo” visível (decisão de produto na implementação; documentar a escolha no PR).
- Depósitos e débitos de Caixa entram no **histórico global** ordenado por data.

---

## 2. Divisão por rolê (Splitwise)

### Vínculo

- Cada “grupo de continhas de rolê” está associado a **um** `hangout_id` existente (MVP: só rolês; **sem** grupo “Geral” separado na v1, salvo decisão explícita depois).

### Despesa (por lançamento)

Campos conceituais:

| Campo | Descrição |
|--------|-----------|
| Valor | `amount` em BRL (> 0). |
| Quem pagou | Um perfil do trio **ou** (fase 2) participante extra como pagador; v1 pode restringir a perfis do app. |
| **Modo de pagamento** | **Próprio** — quem pagou antecipou; os outros (e extras no split) **devem** sua parte conforme split. **Caixa do JBC** — não gera dívida entre pessoas; exige saldo/lançamento na Caixa. |
| **Com quem divide** | Subconjunto dos participantes daquele rolê: **trio** + **convidados** já vinculados ao rolê (cadastro reutilizável); na criação da despesa, marca-se em quem entra o rateio. v1: **partes iguais** só entre os selecionados (`amount / k`). |
| Descrição / data | Para lista e relatório. |

### Matemática (v1 — partes iguais)

- Se participantes do split = `k` pessoas (perfis + extras contados), cada um “devia” `amount / k` em relação ao pagador **apenas no modo Próprio**.
- **Modo Caixa:** após debitar a Caixa, **peso 0** no grafo de dívidas entre pessoas para essa despesa (todos quitados entre si para esta linha).

### Múltiplos gastos

- Qualquer perfil pode adicionar **N despesas** ao mesmo rolê enquanto o rolê **não estiver fechado**.

---

## 3. Fechar gastos do rolê

### Objetivo de produto

- Encerrar o período “em aberto” daquele rolê: **não soma mais despesa** no cálculo ativo (ou exige “reabrir” com confirmação, se quiserem edição retroativa na fase 2).
- Gera **um resultado único e legível:** saldo líquido por participante (perfis + extras) e **“quem deve a quem”** com **netting** (poucas linhas de sugestão de pagamento entre 3 + extras).

### Comportamento sugerido (v1)

- Estado do vínculo rolê-continhas: `open` | `closed`.
- Ao **Fechar:** persistir **snapshot** (JSON ou tabelas `continhas_settlement`): totais por pessoa, arestas sugeridas, timestamp, quem fechou.
- UI: bloco **“Resultado do fechamento”** em destaque (valores e emojis dos extras).
- Opcional: notificação in-app “Gastos do rolê X foram fechados” (Epic 9).

---

## 4. Pessoas extras (não usuários do app)

### Conceito

- Cadastro global ao trio: **`continhas_guest`** (nome curto + **emoji** único por linha ou composto `emoji` + nome como chave de exibição).
- **Reutilizáveis:** uma vez criados (ex.: “Lu 🎸”, “Vo 🧓”), podem ser **associados a vários rolês** e escolhidos em qualquer split.
- Nos relatórios e no netting, entram como **nós iguais** aos perfis (com saldo líquido e sugestão “Bibi paga R$ Y para Lu” se Lu for extra).

### Regras

- Não têm login; só existem como entidade de dados compartilhada pelo trio.
- Edição/remoção: se removido, tratar rolês antigos (manter histórico com cópia do nome — fase 2); v1 pode **proibir excluir** se ainda referenciado em despesa aberta.

---

## 5. Modelo de dados (sugestão Supabase)

Nomes ilustrativos; ajustar na migração final.

| Tabela | Papel |
|--------|--------|
| `jbc_cash_ledger` | Movimentos da **Caixa**: `type` (`deposit` \| `hangout_expense_debit`), `amount`, `profile` (quem registrou o depósito), `hangout_expense_id` opcional, `created_at`, `note`. |
| `jbc_cash_balance` (opcional) | Uma linha com `balance_brl` atualizado por trigger ou recalculado — simplifica leitura. |
| `continhas_hangout` | `hangout_id` PK/FK, `status` (`open` \| `closed`), `closed_at`, `closed_by`. |
| `continhas_guest` | `id`, `display_name`, `emoji`, `created_at`, `created_by`. |
| `continhas_hangout_guest` | N:N rolê ↔ convidado (quem entrou neste rolê). |
| `continhas_expense` | `id`, `hangout_id`, `amount_brl`, `payer_profile`, `payment_source` (`self` \| `jbc_cash`), `description`, `created_by`, `created_at`. |
| `continhas_expense_share` | `expense_id`, `participant_type` (`profile` \| `guest`), `participant_id` (storageKey ou guest id), **para v1 split igual**: só lista de participantes; `share_ratio` opcional na extensão. |

- **RLS:** mesmo padrão trio-only do restante do projeto.

### Índices

- `continhas_expense (hangout_id, created_at desc)`
- `jbc_cash_ledger (created_at desc)`
- `continhas_guest (created_at desc)` (busca por nome)

---

## 6. UI (macro)

- **Aba / entrada Continhas** com dois atalhos claros: **Caixa do JBC** e **Rolês em aberto** (lista de hangouts com continhas).
- **Tela Caixa:** saldo, lista de lançamentos, botão depositar.
- **Tela rolê — aberto:** lista de despesas, adicionar despesa (modo próprio/Caixa + com quem divide), gestão de convidados do rolê (reutilizar cadastro), botão **Fechar gastos do rolê** (confirmação).
- **Tela rolê — fechado:** só leitura + **resultado** (saldos + quem paga a quem).

---

## 7. Notificações (Epic 9)

- “Nova despesa no [rolê]”
- “X depositou na Caixa do JBC”
- “Gastos do [rolê] foram fechados”
- “Saldos atualizados” / agregação com **debounce** se houver muitas edições em sequência.

---

## Fora do escopo (mantido)

- Integração bancária ou Pix real.
- Câmbio entre moedas.
- Anexos de fatura (fase 2).
- Percentuais / cotas desiguais por participante (documentar como extensão em `continhas_expense_share`).

---

## Tarefas (checklist)

- [ ] Documento curto de **matemática** (split igual + Caixa sem dívida + netting com extras) + exemplos numéricos no repo.
- [ ] Migração SQL Supabase + RLS + Realtime onde fizer sentido.
- [ ] Repositório + Riverpod (Caixa, guests, despesas, fechamento).
- [ ] Algoritmo de saldos + netting com **testes unitários** obrigatórios.
- [ ] UI: Caixa, detalhe rolê (aberto/fechado), CRUD de convidados reutilizáveis.

---

## Critérios de pronto (DoD)

1. Depósito na Caixa e despesa **paga pela Caixa** refletem saldo e **não** geram linhas de dívida entre perfis para essa despesa.
2. Várias despesas **próprias** no mesmo rolê, com subsets diferentes de divisão, produzem **“quem deve a quem”** coerente (testes com valores conhecidos, inclusive com **guest** no split).
3. **Fechar gastos do rolê** gera resultado estável e impede novos lançamentos até reabrir (se reabrir existir) ou comportamento documentado.
4. Convidados com nome + emoji são **reutilizáveis** entre rolês e aparecem no relatório final.
5. Sincronização entre dispositivos (Supabase) para todos os fluxos acima.

---

## Dependências

- Rolês (`hangouts`) já existentes.
- Epic 9 (notificações).

## Referência

- Inspiração: Splitwise / Tricount (sem copiar UI proprietária).
