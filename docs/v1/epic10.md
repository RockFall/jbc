# Epic 10 — Fotos: multi-seleção na galeria e editor de corte centralizado

## Objetivo

Melhorar o fluxo de **anexar fotos** à timeline (e, se aplicável, a outros módulos que reutilizem o mesmo fluxo): permitir escolher **várias imagens de uma vez** na galeria do celular e, antes de confirmar o envio, permitir **cortar e centralizar** cada foto (ou um fluxo “crop por foto” em sequência).

## Escopo

### Multi-seleção

- No fluxo “adicionar da galeria”, usar picker com **`pickMultiImage`** (ou API equivalente na versão do `image_picker`/plugin adotado).
- Limite máximo de fotos por operação (definir número razoável, ex.: 20, ou alinhar ao limite do backend).
- Pré-visualização da lista selecionada antes de crop/upload com opção de remover itens.

### Crop e centralização

- Para cada imagem (ou fluxo em lote com “pular crop” opcional): tela ou bottom sheet com **crop interativo** (proporção fixa opcional — ex. 4:3 para combinar com cards da timeline, ou livre).
- **Centralizar** enquadramento: gestos de zoom/pan; botão “resetar enquadramento”.
- Saída: arquivo otimizado (JPEG/WebP conforme política atual do app) pronto para upload ao bucket existente (`timeline-images`).

### Integração

- Reutilizar upload Supabase atual; garantir ordem das fotos na memória.
- Acessibilidade: labels em botões de confirmar/cancelar.

## Fora do escopo

- Filtros estilo Instagram, stickers sobre a foto, ou colagens na edição (isso é outra epic).
- Captura pela câmera com multi-frame burst.

## Tarefas (checklist)

- [ ] Atualizar dependências se necessário (`image_picker`, pacote de crop estável, ex. `crop_your_image` ou `image_cropper`).
- [ ] Fluxo UX: galeria → (opcional crop por item) → confirmação → upload com progresso.
- [ ] Tratamento de memória em lote (não carregar 20 RAW gigantes de uma vez sem downscale).
- [ ] Integração com **Epic 9**: ao concluir upload em lote, uma notificação agregada do tipo “Adicionou N fotos”.

## Critérios de pronto (DoD)

1. Utilizador seleciona **≥2 fotos** num único gesto na galeria e consegue publicar todas.
2. Pelo menos um crop manual **antes** do envio altera o ficheiro guardado (validar por hash ou dimensão).
3. Falha num item do lote não apaga silenciosamente os outros (feedback claro).

## Dependências

- `docs/mvp/epic2.md` (upload timeline) e código atual de mídia.
- `docs/v1/epic9.md` — notificação opcional mas recomendada na entrega.

## Referência

- Documentar limites e formatos no README técnico se mudarem defaults.
