# Epic 12 — Modo “Uber” de conchinha

## Objetivo

Criar um fluxo lúdico e claro para **pedir conchinha** (apoio presencial / companhia): interface **análoga ao fluxo de pedir Uber** — mapa ou campo de **endereço**, confirmação de local, botão **Pedir conchinha**. O pedido **notifica** os outros dois perfis; **um ou mais** podem **aceitar**; o solicitante vê quem aceitou e pode **encerrar** ou **cancelar** o pedido.

> Nota de produto: “conchinha” aqui é o nome afetivo do recurso; manter copy consistente com o resto do app.

## Escopo

### Telas

- **Home do modo**: campo de busca de endereço (Places API ou equivalente) + mapa opcional mostrando pin.
- **Resumo**: endereço textual normalizado, tempo estimado de deslocamento (nice to have), botão **Pedir**.
- **Estados do pedido**: `aberto`, `aceito_por_1+`, `concluído`, `cancelado`.
- Lista de **aceitações** com avatar/nome do perfil e horário.

### Regras de negócio

- Apenas **um pedido ativo** por perfil por vez (MVP do modo) OU permitir vários — **decidir na implementação**; padrão sugerido: um ativo simplifica UX.
- **Múltiplos aceites** permitidos (não é corrida “quem chega primeiro” obrigatoriamente); o solicitante pode ver todos.
- **Cancelamento** pelo solicitante liberta os aceites pendentes.

### Backend

- Tabela `conchinha_requests` (nome ilustrativo): solicitante, endereço (JSON: lat, lng, label), status, timestamps.
- Tabela `conchinha_acceptances`: request_id, perfil, created_at.
- Realtime para atualizar telas.

### Notificações

- **In-app** (Epic 9): “X pediu conchinha em [bairro/endereço curto]”.
- **Push** (recomendado): mesmo gatilho; na epic 9 a regra inicial era timeline/rolê — **estender** contrato de push para `conchinha_request_created` (ou reutilizar canal genérico “alertas do trio”).

## Fora do escopo

- Pagamentos ou gorjetas.
- Chat em tempo real dentro do pedido (pode usar notificações + comentário fixo).
- Matching otimizado por distância real sem APIs de mapa.

## Tarefas (checklist)

- [ ] Definir entrada no shell: nova aba, item em menu, ou modo dentro de Rolês (decisão de IA de produto: **modo dedicado** acessível a partir de shell ou hub de “modos”).
- [ ] Integração endereços (chave API em `dart_defines`, não commitar segredos).
- [ ] UI estilo Uber (tipografia, botão primário inferior, mapa em card).
- [ ] Fluxo aceitar/recusar no cartão da notificação in-app.
- [ ] Push + deep link para o pedido aberto.

## Critérios de pronto (DoD)

1. Utilizador A pede com endereço plausível; B e C recebem notificação **≤ poucos segundos** (rede ok).
2. B e C podem ambos aceitar; A vê os dois aceites.
3. Cancelamento por A muda estado e notifica aceitantes (in-app mínimo).

## Dependências

- `docs/v1/epic9.md` — centro de notificações e push.
- Perfis fixos do trio.

## Referência

- Screenshots de referência do Uber (uso interno de design, não redistribuir assets protegidos).
