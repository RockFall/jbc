# Epic 1 — Base do app e identidade compartilhada

## Objetivo

Criar a fundação do App JBC (Android): projeto Flutter, navegação entre os três módulos, associação de cada instalação a um dos três perfis fixos, modelo de dados base, persistência remota compartilhada e sincronização entre os três dispositivos, com estados de carregamento e erro tratados de forma básica.

## Escopo desta epic

- Projeto Flutter inicial (Android como plataforma inicial).
- Barra de navegação inferior com **3 abas**, nesta ordem: **Cantinho de Ideias** (esquerda), **Timeline** (centro), **Rolês** (direita).
- Perfis fixos e imutáveis no produto: **Caio**, **Jojo**, **Bibi** (apenas estes três usuários existem).
- Fluxo de **primeira execução** (ou configurações): o usuário escolhe **qual dos três perfis** aquele dispositivo representa; essa escolha persiste localmente e define autor em todas as ações posteriores.
- **Modelo de dados principal** alinhado ao documento de produto (entidades e campos necessários para Timeline, Rolês e Ideias), mesmo que algumas telas ainda sejam placeholders nesta epic.
- **Backend / persistência remota** escolhida e integrada (Firestore, Supabase, Appwrite ou equivalente), com regras que restrinjam o app ao trio (três contas ou um único “espaço” privado — decisão técnica documentada no repositório se necessário).
- **Sincronização em tempo real ou quase real** entre os três celulares para as coleções compartilhadas.
- **Estados de UI**: carregamento (skeleton/spinner/placeholder coerente), lista vazia quando aplicável, erro de rede/servidor com possibilidade de retry.
- Tratamento de **identidade do autor**: `criado por` e, onde couber nesta base, rastreio de **última edição** conforme o perfil do dispositivo.

## Fora do escopo desta epic (entregue nas epics seguintes)

- CRUD completo e UI final de Timeline, Rolês e Ideias (podem existir telas placeholder ou listas mínimas para validar sync).
- Upload de imagens (Epic 2).
- Indisponibilidades, conversão rolê→timeline, ideia→rolê (Epics 3 e 4).

## Tarefas concretas (checklist)

### Projeto e plataforma

- [ ] Criar projeto Flutter com suporte **Android**; configurar `applicationId`, nome do app e ícone mínimo.
- [ ] Definir estrutura de pastas (features por módulo, core, data, domain se aplicável) e dependências (estado, DI, cliente HTTP/SDK do backend).

### Navegação e shell do app

- [ ] Implementar **Scaffold** com **bottom navigation** de 3 itens: Ideias | Timeline | Rolês (rótulos e ícones alinhados ao tom afetivo/simples).
- [ ] Garantir que cada aba tenha um **placeholder** ou tela mínima identificável até as epics de feature.

### Identidade (perfil no dispositivo)

- [ ] Modelar enum/tipo `JbcProfile` com exatamente: Caio, Jojo, Bibi.
- [ ] Persistir localmente (SharedPreferences, Hive, etc.) o perfil selecionado.
- [ ] Tela ou fluxo de **seleção de perfil** na primeira abertura; opção de **alterar perfil** nas configurações (sem criar novos usuários).
- [ ] Expor em todo o app o perfil atual para uso como `criadoPor` / `atualizadoPor` nas escritas.

### Dados e backend

- [ ] Escolher e configurar serviço de backend com dados compartilhados entre os três.
- [ ] Definir esquema inicial (coleções/tabelas) compatível com:
  - eventos da timeline (campos da seção 5.1 do `project_definition.md`);
  - rolês e indisponibilidades (5.2);
  - ideias (5.3).
- [ ] Implementar camada de repositório ou serviço que **assine** mudanças (streams/listeners) para atualizar a UI.
- [ ] Regras de segurança: apenas o trio acessa os dados (documentar como isso é garantido).

### Estados e robustez

- [ ] Padrão único para **loading**, **empty** e **error** nas telas base.
- [ ] Tratamento de falha de rede ao carregar/sincronizar; **retry** explícito ou automático onde fizer sentido.

### Qualidade

- [ ] App compila e roda em dispositivo/emulador Android.
- [ ] README ou nota técnica mínima: como configurar chaves do backend e rodar o projeto (se o repositório for compartilhado).

## Critérios de pronto (Definition of Done)

1. Ao instalar o app, o usuário **associa o dispositivo** a Caio, Jojo ou Bibi e essa escolha **persiste**.
2. As **três abas** são acessíveis e estáveis.
3. Dados gravados no backend por um dispositivo **aparecem** nos outros (validar com dois ambientes ou emulador + dispositivo).
4. **Loading/erro** não deixam o app em tela branca sem feedback.
5. O modelo de dados principal está **definido e utilizável** pelas epics seguintes sem retrabalho estrutural grande.

## Dependências

- Nenhuma (primeira epic).

## Referência

- `docs/project_definition.md` — seções 4, 6, 8 (Epic 1), 9 (Fase 1), 10–11.
