Perfeito. Vou manter isso em um nível **funcional e estruturado**, com poucas epics, suficiente para orientar a implementação em **Flutter no Cursor** sem cair em detalhamento excessivo de feature ou em documentação pesada demais.

# Definição funcional v1 — App JBC

## 1. Visão do produto

O **App JBC** é um aplicativo Android privado, feito exclusivamente para **Caio, Jojo e Bibi**, com o objetivo de reunir em um único espaço compartilhado:

* a memória da relação
* o planejamento de rolês
* ideias de experiências futuras

O aplicativo deve ser **simples, íntimo, colaborativo e sincronizado entre os três dispositivos**, sem necessidade de suportar outros usuários além do trio.

---

## 2. Objetivo funcional

Permitir que os três integrantes do JBC possam:

* registrar momentos importantes da relação em uma timeline
* combinar rolês a partir das disponibilidades de cada um
* guardar ideias de coisas que querem fazer juntos
* transformar experiências vividas em memória permanente dentro do app

---

## 3. Princípios do produto

### Privado

O app é fechado para apenas três pessoas.

### Compartilhado

Tudo relevante é visível e sincronizado entre os três.

### Simples

As interações devem ser leves e diretas, sem burocracia.

### Afetivo

A experiência precisa transmitir carinho, intimidade e pertencimento.

### Vivo

O conteúdo do app cresce com o tempo, conforme a relação continua.

---

## 4. Estrutura geral do app

O app terá **3 áreas principais**, acessíveis por navegação inferior:

* **Esquerda:** Cantinho de Ideias
* **Centro:** Timeline
* **Direita:** Rolês

A **Timeline** é o eixo central emocional do app.

---

# 5. Escopo funcional por módulo

## 5.1. Timeline

### Objetivo

Registrar a história do JBC em ordem cronológica.

### O que deve permitir

* visualizar eventos da relação
* adicionar novo evento manualmente
* editar evento existente
* excluir evento
* anexar imagem opcional
* visualizar quem criou o evento
* sincronizar mudanças entre os três dispositivos

### Dados de cada evento

* id
* data do acontecimento
* título
* descrição curta
* imagem opcional
* criado por
* origem do evento:

  * manual
  * vindo de rolê realizado
* data de criação
* data de última edição

### Regras funcionais

* os eventos devem aparecer em ordem cronológica
* qualquer um dos três pode criar evento
* eventos criados em um celular devem aparecer nos outros
* um evento pode existir sem imagem
* eventos vindos de rolê realizado devem manter vínculo com o rolê original

---

## 5.2. Rolês

### Objetivo

Permitir organizar encontros do trio de forma simples.

### O que deve permitir

* registrar indisponibilidades recorrentes por dia da semana
* visualizar indisponibilidades de cada pessoa
* criar rolê planejado
* editar rolê
* cancelar rolê
* marcar rolê como “aconteceu”
* converter rolê realizado em evento da timeline

### Dados de indisponibilidade

* pessoa
* dia da semana
* horário inicial
* horário final

### Dados de rolê

* id
* título
* descrição opcional
* data
* horário inicial
* horário final opcional
* status:

  * planejado
  * aconteceu
  * cancelado
* criado por
* observações opcionais
* vínculo com evento da timeline, se existir

### Regras funcionais

* indisponibilidades são recorrentes por dia da semana
* cada pessoa consegue cadastrar e editar sua própria indisponibilidade
* todos conseguem visualizar a disponibilidade consolidada do trio
* um rolê pode ser criado mesmo com conflito de agenda, mas o app deve deixar isso visível
* ao marcar um rolê como “aconteceu”, ele pode virar evento na timeline
* a conversão para timeline deve permitir complementar título, descrição e imagem antes de salvar

---

## 5.3. Cantinho de Ideias

### Objetivo

Guardar inspirações para experiências futuras do JBC.

### O que deve permitir

* adicionar ideia
* editar ideia
* excluir ideia
* visualizar ideias de todos
* marcar ideia como realizada ou arquivada
* opcionalmente transformar ideia em rolê

### Dados de cada ideia

* id
* título
* descrição opcional
* categoria opcional:

  * rolê
  * comida
  * filme
  * série
  * viagem
  * outro
* status:

  * ativa
  * realizada
  * arquivada
* criado por
* data de criação
* data de última edição

### Regras funcionais

* qualquer integrante pode criar ideias
* todas as ideias são compartilhadas
* a lista deve ser simples de consultar
* uma ideia realizada pode continuar visível como histórico ou ser arquivada
* uma ideia pode servir de base para criar um rolê, sem desaparecer obrigatoriamente

---

# 6. Regras de acesso e colaboração

## Usuários do sistema

O sistema terá **apenas 3 usuários fixos**:

* Caio
* Jojo
* Bibi

## Identidade de usuário

Cada instalação do app deve estar associada a um desses três perfis, para que seja possível saber:

* quem criou algo
* quem editou algo
* de quem é cada indisponibilidade

## Permissões

Para manter o app simples:

* todos podem visualizar tudo
* todos podem criar conteúdo
* todos podem editar conteúdos compartilhados
* exclusão também pode ser compartilhada entre os três

Essa decisão privilegia leveza e intimidade, em vez de controle rígido.

---

# 7. Fluxos principais

## Fluxo 1 — Adicionar memória manualmente

1. usuário abre Timeline
2. toca no botão "+"
3. preenche data, título, descrição e imagem opcional
4. salva
5. evento aparece na timeline de todos

## Fluxo 2 — Registrar disponibilidade

1. usuário abre Rolês
2. acessa sua área de indisponibilidades
3. adiciona faixa de horário indisponível para um dia da semana
4. salva
5. indisponibilidade passa a compor a visão compartilhada

## Fluxo 3 — Criar rolê

1. usuário abre Rolês
2. cria novo rolê
3. define título, data e horário
4. verifica visualmente conflitos ou compatibilidades
5. salva
6. rolê fica visível para os três

## Fluxo 4 — Converter rolê em memória

1. um rolê realizado é aberto
2. usuário marca como “aconteceu”
3. app abre etapa de complemento da memória
4. usuário ajusta título, descrição e imagem
5. salva
6. evento é criado na timeline com vínculo ao rolê

## Fluxo 5 — Registrar ideia

1. usuário abre Cantinho de Ideias
2. toca em adicionar
3. informa título e descrição opcional
4. define categoria, se quiser
5. salva
6. ideia fica visível para os três

## Fluxo 6 — Transformar ideia em rolê

1. usuário abre uma ideia
2. seleciona ação “transformar em rolê”
3. app abre criação de rolê já preenchida com base na ideia
4. usuário ajusta data/horário
5. salva

---

# 8. Epics do produto

Vou dividir em **4 epics**, para manter poucas frentes e dar tração real ao desenvolvimento.

---

## Epic 1 — Base do app e identidade compartilhada

### Objetivo

Criar a fundação do aplicativo, com estrutura de navegação, associação de cada dispositivo a um dos três perfis e sincronização entre dispositivos.

### Inclui

* projeto Flutter inicial
* navegação inferior com 3 áreas
* definição dos perfis fixos: Caio, Jojo e Bibi
* associação do dispositivo a um perfil
* modelo de dados principal
* persistência remota compartilhada
* sincronização de alterações entre os três celulares
* tratamento básico de estados de carregamento e erro

### Resultado esperado

O app já abre com identidade definida, possui estrutura navegável e está pronto para compartilhar dados entre os três.

---

## Epic 2 — Timeline afetiva da relação

### Objetivo

Entregar a área central do app como mural vivo da história do JBC.

### Inclui

* listagem cronológica dos eventos
* criação manual de eventos
* edição de eventos
* exclusão de eventos
* upload/associação de imagem opcional
* exibição de autor e data
* atualização sincronizada para os três usuários

### Resultado esperado

Os três conseguem registrar e acompanhar momentos da relação em uma timeline compartilhada.

---

## Epic 3 — Planejamento de rolês e conversão em memória

### Objetivo

Permitir organizar encontros e transformar vivências em eventos da timeline.

### Inclui

* cadastro de indisponibilidades recorrentes por dia da semana
* visualização consolidada das agendas
* criação de rolês
* edição e cancelamento de rolês
* marcação de rolê como “aconteceu”
* fluxo de conversão de rolê em evento da timeline
* vínculo entre rolê e memória gerada

### Resultado esperado

O módulo de rolês funciona como ponte entre planejamento e lembrança registrada.

---

## Epic 4 — Cantinho de Ideias compartilhado

### Objetivo

Criar o espaço de inspiração contínua do trio.

### Inclui

* listagem de ideias
* criação de ideia
* edição de ideia
* exclusão de ideia
* categorização simples
* mudança de status entre ativa, realizada e arquivada
* ação opcional de transformar ideia em rolê

### Resultado esperado

O trio consegue guardar vontades, referências e planos soltos em um espaço leve e reutilizável.

---

# 9. Ordem sugerida de implementação

Para Flutter + Cursor, a ordem mais inteligente é:

## Fase 1

**Epic 1 + estrutura mínima da Epic 2**

* base do app
* navegação
* perfis
* backend/sincronização
* leitura e criação simples de eventos da timeline

## Fase 2

**Completar Epic 2**

* edição
* exclusão
* imagens
* refinamento visual da timeline

## Fase 3

**Epic 4**

* ideias são simples e rápidas de implementar
* ajudam a consolidar o padrão de conteúdo compartilhado

## Fase 4

**Epic 3**

* módulo mais “lógico”
* depende de estrutura bem resolvida para agenda, estados e conversão em timeline

Essa sequência reduz complexidade e coloca cedo no ar a parte mais simbólica do app: a timeline.

---

# 10. Critérios de pronto do produto inicial

O app pode ser considerado funcionalmente pronto em sua primeira versão quando:

* os três conseguem usar o app em seus próprios dispositivos
* o conteúdo sincroniza corretamente entre eles
* a timeline permite registrar e visualizar memórias
* o módulo de rolês permite planejar encontros e marcar como realizados
* o cantinho de ideias permite guardar sugestões compartilhadas
* a navegação é simples e estável
* a experiência já transmite intimidade e leveza

---

# 11. Decisões funcionais assumidas nesta versão

Para evitar ambiguidade, esta definição já assume:

* apenas **3 usuários fixos**
* todos podem editar tudo
* indisponibilidades são **recorrentes por dia da semana**
* conflitos de agenda são **sinalizados**, não bloqueiam criação de rolê
* rolê marcado como “aconteceu” gera um fluxo de criação de memória na timeline
* ideias podem virar rolês
* imagens são obrigatoriamente opcionais
* Android é a plataforma inicial

---

# 12. Resumo executivo

O App JBC é um aplicativo Android privado e compartilhado entre Caio, Jojo e Bibi, estruturado em três módulos centrais: **Timeline**, **Rolês** e **Cantinho de Ideias**. Sua função é conectar memória, planejamento e inspiração em uma experiência simples e afetiva. Para implementação, o escopo pode ser organizado em **4 epics principais**: base e sincronização, timeline, rolês e ideias.

O próximo passo mais útil agora é transformar isso em um **backlog inicial com stories técnicas e funcionais por epic**, já pensando em implementação no Flutter com Cursor.
