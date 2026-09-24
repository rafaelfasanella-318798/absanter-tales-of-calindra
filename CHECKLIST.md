# Absanter – Tales of Calindra · CHECKLIST do projeto

Checklist completo para construir o RPG **Absanter – Tales of Calindra**, onde o protagonista é **Ragg** e a companheira de party é **Calindra**.

Divisão de trabalho combinada: **você descreve** (lore, personagens, regras, estilo, decisões) e **o agente desenvolve** a maior parte (código, estrutura, instalação de engine e bibliotecas, testes, builds).

Origem: plano aprovado na sessão do Claude Code de 18/09/2026 e reconstruído em 19/09/2026 (a sessão original foi encerrada antes de o arquivo ser gravado).

Este arquivo é a fonte de verdade do progresso. Marque `[x]` conforme os itens forem concluídos. O roteiro de execução do primeiro milestone (M0) está em `AGENTE-INICIO.md`.

---

## Legenda das etiquetas

| Etiqueta | Significado |
|---|---|
| `[VOCÊ]` | Decisão ou descrição que só o usuário pode dar |
| `[AGENTE]` | O agente implementa, instala ou gera sozinho |
| `[JUNTOS]` | O usuário descreve, o agente implementa e devolve para validação |

---

## Decisões já tomadas

| Item | Decisão |
|---|---|
| Engine | Godot 4.x (GDScript) |
| Visual | 2D pixel art top-down (tiles 16x16, estilo Chrono Trigger / Stardew Valley) |
| Combate | Turnos clássico JRPG |
| Calindra | Companheira jogável em party, com habilidades próprias |
| Idioma do jogo | PT-BR primeiro, EN como segundo (assumido; confirmar na seção 0) |
| Plataformas | Windows + Linux + Web (assumido; mobile opcional; confirmar na seção 0) |

---

## Hardware detectado (para a IA local)

Leitura feita em 18/09/2026 a partir do WSL.

| Componente | Valor | Impacto |
|---|---|---|
| CPU | AMD Ryzen 7 9800X3D (8 núcleos / 16 threads) | Ótimo para offload de camadas para CPU |
| GPU | NVIDIA RTX 3070, **8 GB VRAM**, driver 616.92 | Limite principal: modelos até ~7–9B cabem 100% na VRAM em Q4 |
| RAM | 16 GB visíveis no WSL (cap em `.wslconfig`); host provavelmente 32 GB (**confirmar**) | Modelos maiores rodam com parte na RAM |
| Disco C: | 932 GB, **só ~83 GB livres (92% cheio)** | Cada modelo ocupa 5–20 GB; liberar espaço ou usar outro disco |
| Software já instalado | Git, GitHub CLI, VS Code, Antigravity | Nenhum runtime de LLM local ainda (Ollama / LM Studio ausentes) |

### Recomendação de IA local

**Runtime:** Ollama instalado **no Windows** (não no WSL), para usar a GPU nativamente e toda a RAM do host. O WSL e o agente acessam via `http://localhost:11434`.

**Modelos, em ordem de preferência:**

1. **Qwen3-Coder-30B-A3B** (Q4_K_M, ~18 GB). Melhor qualidade de código que roda nessa máquina. É MoE com 3B ativos, então fica rápido mesmo com parte na RAM (~15–25 tok/s esperado). Exige host com 32 GB.
2. **Qwen2.5-Coder-7B** ou **Qwen3-8B** (Q4_K_M, ~5 GB). Cabe inteiro na VRAM, ~40–60 tok/s. Usar como modelo "rápido" para edições pequenas e autocomplete.
3. **Devstral Small 2 (24B)** (Q4, ~14 GB). Forte em uso agêntico, mas mais lento por não ser MoE.

**Frontend agêntico** (o "agente" que edita arquivos e roda comandos): **OpenCode** (CLI, funciona com Ollama, terminal igual ao Claude Code) ou **Cline / Roo Code** dentro do VS Code já instalado. **Aider** como alternativa mais leve. **Continue.dev** para autocomplete no editor.

**Geração de assets local (opcional):** ComfyUI + SD 1.5 / SDXL com LoRA de pixel art cabe em 8 GB VRAM. Música local é fraca em 8 GB; usar bibliotecas livres.

**Aviso honesto:** modelos locais nesse hardware são bem mais fracos que Claude em tarefas agênticas longas. Fluxo híbrido sugerido: IA local para trabalho em massa (gerar dados JSON, diálogos, testes, refatorações simples) e Claude Code para arquitetura, sistemas complexos e depuração difícil.

---

## 0. Decisões fundamentais

- [ ] `[VOCÊ]` Confirmar nome final do jogo ("Absanter – Tales of Calindra"?) e significado de "Absanter"
- [ ] `[VOCÊ]` Pitch em 2 frases: o que o jogador faz e por que se importa
- [ ] `[VOCÊ]` Referências de tom (ex.: Chrono Trigger, Earthbound, Undertale, Sea of Stars) e o que copiar de cada
- [ ] `[VOCÊ]` Duração alvo (ex.: 3h demo / 15h campanha) e escopo do primeiro lançamento (demo, acesso antecipado, completo)
- [ ] `[VOCÊ]` Classificação etária / temas sensíveis permitidos
- [ ] `[VOCÊ]` Idiomas: PT-BR obrigatório; EN sim/não
- [ ] `[VOCÊ]` Plataformas: Windows, Linux, Web (itch.io), mobile?
- [ ] `[VOCÊ]` Controles: teclado + gamepad; mouse opcional?
- [ ] `[JUNTOS]` Definir versão do Godot (4.3+ estável) e se usa GDScript puro ou C# (recomendado: GDScript)

## 1. Ambiente e ferramentas (setup)

> Roteiro de execução deste bloco: `AGENTE-INICIO.md` (milestone M0). O agente executa tudo sem perguntar.

- [x] `[AGENTE]` Instalar Godot 4.x (binário Linux no WSL para headless/testes + `.exe` Windows para editar visualmente)
- [x] `[AGENTE]` Instalar export templates da mesma versão
- [x] `[AGENTE]` `git init` + `.gitignore` de Godot + `.gitattributes` (LFS para PNG/OGG grandes)
- [x] `[AGENTE]` Instalar `gdtoolkit` (gdformat + gdlint) via pip para formatação/lint
- [x] `[AGENTE]` Instalar addon **GUT** (Godot Unit Test) para testes automatizados
- [ ] `[AGENTE]` Instalar addon de diálogo (**Dialogic 2** ou sistema próprio em JSON; decidir na seção 9)
- [ ] `[AGENTE]` Instalar **LDtk** ou **Tiled** + importer Godot para mapas (recomendado: LDtk)
- [ ] `[AGENTE]` Instalar **Aseprite** (pago) ou **LibreSprite / Pixelorama** (grátis) para pixel art
- [x] `[AGENTE]` Configurar `project.godot`: resolução base 320x180 ou 480x270, stretch mode `viewport`, filtro `nearest`, snap 2D, pixel-perfect
- [x] `[AGENTE]` Criar `CLAUDE.md` com convenções do projeto (nomes, pastas, como rodar testes/build); mesmo conteúdo serve de base para o `AGENTS.md` da IA local (seção 1b)
- [x] `[AGENTE]` Scripts `run.sh` / `run.ps1` para rodar o jogo, `test.sh` para rodar GUT headless, `build.sh` para exportar, `lint.sh` para lint/format
- [x] `[AGENTE]` CI no GitHub Actions: lint + testes + export a cada push (opcional, se houver repo remoto)
- [ ] `[VOCÊ]` Criar conta itch.io e repositório GitHub (se quiser publicação/CI)

## 1b. IA local para desenvolvimento

- [ ] `[VOCÊ]` Confirmar RAM total do Windows (32 GB?); define se o modelo 30B-A3B é viável
- [ ] `[VOCÊ]` Liberar pelo menos 60 GB no disco C: ou apontar outro disco para modelos (`OLLAMA_MODELS`)
- [ ] `[VOCÊ]` Instalar **Ollama para Windows** (instalador gráfico; o agente não consegue instalar no Windows a partir do WSL)
- [ ] `[VOCÊ]` Atualizar driver NVIDIA se o Ollama reclamar (driver atual 616.92 deve servir)
- [ ] `[AGENTE]` Verificar que o WSL alcança `http://localhost:11434` (senão, ativar `networkingMode=mirrored` no `.wslconfig`)
- [ ] `[AGENTE]` Baixar modelos: `ollama pull qwen3-coder:30b` (principal) e `ollama pull qwen2.5-coder:7b` (rápido)
- [ ] `[AGENTE]` Benchmark rápido: medir tok/s de cada modelo e registrar em `docs/local-ai.md`
- [ ] `[AGENTE]` Configurar contexto de 32k+ tokens no Ollama (`num_ctx`); necessário para o agente ver vários arquivos
- [ ] `[AGENTE]` Instalar **OpenCode** (CLI) no WSL apontando para o Ollama; alternativa: extensão **Cline** no VS Code
- [ ] `[AGENTE]` Instalar **Continue.dev** no VS Code para autocomplete com o modelo 7B
- [ ] `[AGENTE]` Escrever `docs/local-ai.md`: qual modelo usar para cada tipo de tarefa, prompts prontos para GDScript, limites conhecidos
- [ ] `[AGENTE]` Criar arquivo de regras do agente local (`AGENTS.md` / `.clinerules`) espelhando o `CLAUDE.md`
- [ ] `[AGENTE]` Testar o fluxo: IA local gera um `ItemData.tres` + teste GUT a partir de descrição em texto
- [ ] `[VOCÊ]` (Opcional) Instalar ComfyUI no Windows + SD 1.5 com LoRA pixel art para gerar sprites/tilesets
- [ ] `[AGENTE]` (Opcional) Workflow ComfyUI salvo em `tools/comfyui/` para sprite 16x16 4 direções + tileset
- [ ] `[JUNTOS]` Definir divisão de trabalho: IA local para tarefas em massa; Claude Code para arquitetura e bugs difíceis

## 2. Estrutura do projeto

- [x] `[AGENTE]` Árvore de pastas: `scenes/`, `scripts/`, `data/` (JSON/Resources), `assets/{sprites,tilesets,audio,fonts,ui}`, `addons/`, `tests/`, `docs/`, `tools/`
- [x] `[AGENTE]` Autoloads (singletons): `GameState`, `SaveManager`, `AudioManager`, `SceneManager`, `EventBus`, `DialogueManager`, `QuestManager`, `InventoryManager`, `PartyManager`, `Localization`
- [x] `[AGENTE]` Cena raiz `Main` com troca de cenas via `SceneManager` e transições (fade)
- [x] `[AGENTE]` Padrão de Resources (`.tres`) para dados: `CharacterData`, `EnemyData`, `SkillData`, `ItemData`, `QuestData`, `MapData`
- [x] `[AGENTE]` Convenções: snake_case para arquivos, PascalCase para classes, `class_name` em tudo reutilizável
- [x] `[AGENTE]` Sistema de constantes/enums globais (elementos, status, tipos de item, direções)

## 3. Documento de design (GDD) – o que você descreve

- [ ] `[VOCÊ]` Mundo: nome do continente/reino, geografia geral, tecnologia/magia, era
- [ ] `[VOCÊ]` Lore: mito de criação, conflito central, facções, o que é "Absanter"
- [ ] `[VOCÊ]` Sinopse da história do início ao fim (3 atos), com reviravoltas
- [ ] `[VOCÊ]` Vilão principal + motivação; vilões secundários
- [ ] `[VOCÊ]` Lista de regiões/cidades/dungeons (nome, clima, quem vive lá, o que acontece lá)
- [ ] `[VOCÊ]` Temas e mensagem do jogo
- [ ] `[VOCÊ]` Tom do humor e dos diálogos (sério, leve, sarcástico?)
- [ ] `[AGENTE]` Consolidar tudo em `docs/GDD.md` e manter atualizado

## 4. Personagens

### Ragg (protagonista)

- [ ] `[VOCÊ]` Aparência (altura, cabelo, roupa, cores, marcas), idade, origem
- [ ] `[VOCÊ]` Personalidade, falhas, medos, objetivo pessoal, arco de mudança
- [ ] `[VOCÊ]` Classe/estilo de luta (espadachim? bruto? híbrido?), arma inicial
- [ ] `[VOCÊ]` Atributos base e curva de crescimento (ou deixar o agente propor)
- [ ] `[VOCÊ]` Lista de habilidades (nome, descrição, efeito, nível em que aprende)
- [ ] `[VOCÊ]` Habilidade especial / limite (ultimate)
- [ ] `[VOCÊ]` Frases marcantes, forma de falar

### Calindra (companheira e assistente)

- [ ] `[VOCÊ]` Aparência, idade, origem, o que ela é (humana, espírito, construto, maga?)
- [ ] `[VOCÊ]` Personalidade e como contrasta/complementa Ragg
- [ ] `[VOCÊ]` Relação com Ragg no início e como evolui (amizade, mentoria, romance, rivalidade?)
- [ ] `[VOCÊ]` Papel em combate (suporte, mago, curandeira, controle?) e lista de habilidades
- [ ] `[VOCÊ]` Como entra na party (já começa junto? recrutada no capítulo 1?)
- [ ] `[VOCÊ]` Função como "assistente": dá dicas? explica mecânicas? comenta o mundo? tem menu próprio?
- [ ] `[VOCÊ]` Banter: 20+ falas curtas dela para situações (entrar em cidade, achar baú, vitória, derrota, item novo, level up)
- [ ] `[VOCÊ]` Segredo / reviravolta dela (se houver)

### Outros

- [ ] `[VOCÊ]` Outros membros de party (nome, classe, quando entram) ou confirmar que são só Ragg + Calindra
- [ ] `[VOCÊ]` NPCs importantes (10–20): nome, cidade, função, quest ligada
- [ ] `[VOCÊ]` Bestiário: lista de inimigos por região (nome, aparência, comportamento, fraqueza)
- [ ] `[VOCÊ]` Bosses: nome, arena, fases, mecânica única de cada
- [ ] `[AGENTE]` Criar `CharacterData.tres` de Ragg e Calindra + todos os inimigos em `data/enemies/`
- [ ] `[AGENTE]` Fichas em `docs/characters/` a partir das descrições

## 5. Exploração (overworld)

- [x] `[AGENTE]` Player controller top-down 4 direções (8 opcional), aceleração, colisão via `CharacterBody2D`
- [ ] `[AGENTE]` Animações idle/walk/run por direção via `AnimationPlayer` + `AnimatedSprite2D`
- [x] `[AGENTE]` Seguidores de party (Calindra segue Ragg estilo "conga line" com histórico de posições)
- [x] `[AGENTE]` Câmera com limites por mapa, suavização, zoom fixo pixel-perfect
- [x] `[AGENTE]` Sistema de interação (`Area2D` + prompt): falar, examinar, abrir baú, ler placa
- [ ] `[AGENTE]` TileMap com camadas (chão, decoração, colisão, acima do jogador), Y-sort
- [ ] `[AGENTE]` Importer LDtk/Tiled → cenas Godot com entidades (NPCs, baús, portas, triggers)
- [x] `[AGENTE]` Portas/transições entre mapas com spawn points nomeados
- [x] `[AGENTE]` Baús, itens no chão, portas trancadas com chave, alavancas, blocos empurráveis
- [ ] `[VOCÊ]` Encontros: inimigos visíveis no mapa que perseguem (recomendado) ou encontros aleatórios?
- [ ] `[AGENTE]` Implementar o sistema de encontros escolhido acima
- [ ] `[AGENTE]` Mapa-múndi / mapa de região com pontos de viagem rápida
- [x] `[AGENTE]` Pontos de save (cristais/fogueiras) e pousadas (curar)
- [ ] `[VOCÊ]` Ciclo dia/noite e clima? (sim/não; afeta escopo)
- [ ] `[AGENTE]` Sistema de cutscene (mover personagens, câmera, diálogo, fade) via script ou `AnimationPlayer`
- [ ] `[AGENTE]` Puzzles básicos reutilizáveis (pressure plates, ordem de alavancas, empurrar blocos)

## 6. Combate por turnos

- [ ] `[VOCÊ]` Estilo de turno: turnos fixos por velocidade, ATB (barra) ou CTB (timeline visível)?
- [ ] `[VOCÊ]` Quantos na party ao mesmo tempo (2? 3? 4?) e quantos inimigos por batalha
- [ ] `[VOCÊ]` Elementos (fogo, gelo, raio, terra, luz, trevas…) e tabela de fraqueza/resistência
- [ ] `[VOCÊ]` Status (veneno, paralisia, sono, silêncio, buff/debuff de atributos…)
- [ ] `[VOCÊ]` Recursos: HP + MP? Stamina? Sistema único tipo "Foco"?
- [ ] `[VOCÊ]` Mecânica única do jogo (ex.: combos Ragg+Calindra, timing de botão, sistema de "sinergia")
- [ ] `[VOCÊ]` Ações disponíveis: Atacar, Habilidade, Item, Defender, Trocar, Fugir; confirmar lista
- [ ] `[JUNTOS]` Fórmulas de dano, crítico, esquiva, ordem de turno (agente propõe, você valida)
- [x] `[AGENTE]` Cena de batalha separada com transição (swirl/flash), fundo por região
- [x] `[AGENTE]` Máquina de estados de batalha: início → turno → seleção → resolução → checagem de fim → vitória/derrota
- [x] `[AGENTE]` Menu de comandos, seleção de alvo (único/todos/aliado), cursor
- [x] `[AGENTE]` IA de inimigos por dados (padrões, prioridades, fases de boss)
- [x] `[AGENTE]` Animações de ataque/hit/morte, números de dano flutuantes, shake, flash
- [x] `[AGENTE]` Tela de resultado: XP, gold, itens, level up, novas habilidades
- [x] `[AGENTE]` Game over com retry / voltar ao save
- [x] `[AGENTE]` Habilidades combinadas Ragg+Calindra (se escolhido acima)
- [x] `[AGENTE]` Script de simulação de balanceamento (roda 1000 batalhas headless e reporta win rate)
- [x] `[AGENTE]` Testes GUT das fórmulas e da máquina de estados

## 7. Progressão

- [ ] `[VOCÊ]` Atributos (HP, MP, ATK, DEF, MAG, RES, SPD, LUCK?); confirmar lista
- [ ] `[VOCÊ]` Nível máximo e ritmo (quantos níveis por hora)
- [ ] `[VOCÊ]` Como aprender habilidades: por nível, skill tree, equipamento ou evento?
- [ ] `[VOCÊ]` Sistema de equipamento: slots (arma, armadura, acessório x2?)
- [x] `[AGENTE]` Curva de XP e tabela de stats por nível gerada por fórmula em `data/`
- [ ] `[AGENTE]` Skill tree UI (se escolhido)
- [x] `[AGENTE]` Aplicação de equipamento nos stats + preview de diferença no menu

## 8. Inventário, itens e economia

- [ ] `[VOCÊ]` Categorias: consumíveis, equipamentos, chave, materiais, importantes
- [ ] `[VOCÊ]` Lista inicial de 30–50 itens (nome, efeito, preço, raridade)
- [ ] `[VOCÊ]` Crafting / forja? (sim/não)
- [ ] `[VOCÊ]` Moeda (nome) e economia (quanto ganha por batalha, preços)
- [x] `[AGENTE]` `InventoryManager` com stack, limite, ordenação, uso fora/dentro de batalha
- [x] `[AGENTE]` Lojas (comprar/vender) com estoque por cidade e desconto por evento
- [x] `[AGENTE]` Drop tables por inimigo com chances
- [x] `[AGENTE]` Testes GUT do inventário

## 9. Diálogo, quests e narrativa

- [ ] `[JUNTOS]` Escolher: Dialogic 2 (visual, rápido) vs sistema próprio em JSON/YAML (mais controle, melhor para o agente gerar em massa); recomendado: **próprio em JSON**
- [x] `[AGENTE]` Caixa de diálogo com retrato, nome, texto letra a letra, avançar/pular, escolhas
- [x] `[AGENTE]` Variáveis/flags globais e condições em diálogos (`if flag_x`)
- [x] `[AGENTE]` Sistema de quests: principal + secundárias, objetivos, estados, recompensas, journal
- [ ] `[AGENTE]` Marcadores de quest no mapa e indicador em NPC (! e ?)
- [x] `[AGENTE]` Comentários contextuais de Calindra (gatilhos por evento)
- [ ] `[AGENTE]` Ferramenta de validação de scripts de diálogo (checa flags inexistentes, nós órfãos)
- [ ] `[VOCÊ]` Roteiro do prólogo + capítulo 1 completo (cenas, falas, escolhas)
- [ ] `[VOCÊ]` Lista de side quests (10+) com resumo
- [ ] `[VOCÊ]` Finais: único ou múltiplos?

## 10. Party

- [x] `[AGENTE]` `PartyManager`: membros ativos/reserva, ordem, líder
- [x] `[AGENTE]` Menu de formação (linha de frente/trás, se houver)
- [x] `[AGENTE]` Eventos de recrutamento/saída de membros por script
- [ ] `[VOCÊ]` Regras: Calindra pode sair da party? Ragg é sempre obrigatório?

## 11. UI / UX

- [ ] `[VOCÊ]` Estilo visual da UI (bordas de pedra? papel? futurista?), paleta, fonte pixel
- [ ] `[AGENTE]` Tema Godot (`Theme` resource) reutilizável com fonte pixel (ex.: m5x7, Pixel Operator)
- [x] `[AGENTE]` Tela de título (Novo Jogo, Continuar, Opções, Sair) + logo
- [x] `[AGENTE]` HUD de exploração mínimo (ou nenhum) + HUD de batalha (HP/MP, turno, status)
- [x] `[AGENTE]` Menu de pausa: Itens, Habilidades, Equipamento, Status, Party, Quests, Mapa, Opções, Salvar
- [x] `[AGENTE]` Opções: volume (master/música/sfx), tela cheia, vsync, velocidade de texto, remapear controles, idioma
- [ ] `[AGENTE]` Suporte completo a gamepad (Xbox/PS) + teclado, ícones de botão dinâmicos
- [ ] `[AGENTE]` Navegação por foco em todos os menus (sem mouse)
- [ ] `[AGENTE]` Acessibilidade: tamanho de fonte, daltonismo nos indicadores, pular cutscene
- [x] `[AGENTE]` Localização: todas as strings em CSV/PO, chaves `tr()`, PT-BR + EN
- [ ] `[AGENTE]` Notificações (item obtido, quest atualizada) e tooltips

## 12. Save / Load

- [x] `[AGENTE]` Serialização de `GameState` em JSON (posição, mapa, flags, party, inventário, quests, tempo jogado)
- [x] `[AGENTE]` 3+ slots + autosave, com thumbnail e resumo (capítulo, local, tempo)
- [x] `[AGENTE]` Versionamento do save + migração entre versões
- [x] `[AGENTE]` Save em `user://`, funcional em Web (IndexedDB)
- [x] `[AGENTE]` Testes GUT de round-trip save/load

## 13. Áudio

- [ ] `[VOCÊ]` Estilo musical (chiptune, orquestral, lo-fi, misto?) e referências
- [ ] `[VOCÊ]` Fonte: você compõe, contrata, usa libs livres (OpenGameArt, Kenney, itch) ou geração por IA?
- [x] `[AGENTE]` `AudioManager` com buses (Master/Music/SFX/UI), crossfade de música, pool de SFX
- [ ] `[AGENTE]` Lista de faixas necessárias: título, cada região, batalha normal, boss, vitória, game over, emocional
- [x] `[AGENTE]` Lista de SFX: menu, passos, ataques, magia, hit, item, baú, porta, level up
- [ ] `[AGENTE]` Baixar e organizar assets livres com licença registrada em `docs/CREDITS.md`

## 14. Arte e assets

- [ ] `[VOCÊ]` Paleta (ex.: Endesga 32, Resurrect 64) e tamanho de tile: 16x16 (recomendado) ou 32x32
- [ ] `[VOCÊ]` Fonte da arte: você desenha, contrata, packs livres ou geração por IA + retoque?
- [ ] `[VOCÊ]` Referências visuais (3–5 imagens/jogos) por região
- [x] `[AGENTE]` Placeholders para tudo (retângulos coloridos / packs Kenney) para desenvolver sem esperar arte final
- [ ] `[AGENTE]` Spec de sprites: Ragg e Calindra com idle/walk/run x 4 direções, sprite de batalha (idle/attack/skill/hit/ko/win)
- [ ] `[AGENTE]` Retratos para diálogo (neutro, feliz, bravo, triste, surpreso) por personagem principal
- [ ] `[AGENTE]` Tilesets por região (chão, paredes, água animada, decoração, interiores)
- [ ] `[AGENTE]` Fundos de batalha por região
- [ ] `[AGENTE]` Sprites de inimigos e bosses (lista do bestiário)
- [ ] `[AGENTE]` VFX: magias por elemento, hit, cura, buff, level up (particles ou spritesheets)
- [ ] `[AGENTE]` Ícones de itens, habilidades, status
- [ ] `[AGENTE]` Pipeline de importação (nearest, sem mipmaps, atlas) e naming padronizado
- [ ] `[AGENTE]` Ícone do jogo, splash, logo

## 15. Conteúdo (por capítulo)

- [ ] `[VOCÊ]` Para cada região: descrição, inimigos, NPCs, quests, boss, música, tesouros
- [ ] `[AGENTE]` Construir mapas no LDtk/Tiled a partir das descrições
- [ ] `[AGENTE]` Popular NPCs, diálogos, baús, encontros
- [ ] `[AGENTE]` Dungeons com puzzles e boss no final
- [ ] `[VOCÊ]` Minigames opcionais? (pesca, arena, cartas?)
- [ ] `[AGENTE]` Implementar os minigames escolhidos (se houver)
- [ ] `[AGENTE]` Conteúdo pós-jogo / superboss (opcional)

## 16. Dados e ferramentas internas

- [x] `[AGENTE]` Todos os dados de jogo em `data/*.json` ou `.tres`; nunca hardcoded
- [x] `[AGENTE]` Validador de dados (referências quebradas, IDs duplicados, stats fora da curva)
- [x] `[AGENTE]` Console de debug in-game: teleporte, dar item, setar flag, level up, god mode, iniciar batalha X
- [x] `[AGENTE]` Planilha/CSV gerado de balanceamento (todos os inimigos vs nível esperado)
- [ ] `[AGENTE]` Editor de encontros/drops (planilha → JSON)

## 17. Testes e qualidade

- [x] `[AGENTE]` GUT: testes de combate, inventário, save, quests, diálogo, progressão
- [x] `[AGENTE]` Smoke test headless: abrir cada mapa sem erro
- [x] `[AGENTE]` Lint (`gdlint`) + format (`gdformat`) em pre-commit
- [ ] `[AGENTE]` Checklist de playtest por milestone (bugs, sensação, dificuldade)
- [ ] `[VOCÊ]` Jogar cada milestone e devolver feedback
- [ ] `[AGENTE]` Performance: 60 fps estável, memória em Web, tempo de load
- [ ] `[AGENTE]` Testar em Windows nativo, Linux, navegador (Chrome/Firefox), gamepad

## 18. Build e distribuição

- [x] `[AGENTE]` Presets de export: Windows (`.exe`), Linux, Web (HTML5)
- [x] `[AGENTE]` Script de build com número de versão automático (`v0.3.0`)
- [ ] `[AGENTE]` Publicar Web build no itch.io via `butler` (CLI do itch)
- [ ] `[AGENTE]` Página itch.io: descrição, screenshots, GIF, tags
- [ ] `[AGENTE]` `CHANGELOG.md` por versão
- [ ] `[VOCÊ]` Preço (grátis, pague o que quiser, pago) e Steam sim/não (exige US$ 100 + Steamworks)
- [x] `[AGENTE]` Créditos in-game e licenças de todos os assets

## 19. Marketing e comunidade (opcional)

- [ ] `[VOCÊ]` Redes / onde divulgar (Twitter/X, Bluesky, Reddit r/godot e r/jrpg, Discord)
- [ ] `[AGENTE]` Capturar screenshots/GIFs automáticos por milestone
- [ ] `[AGENTE]` Template de devlog em `docs/devlog/`
- [ ] `[AGENTE]` Roteiro de trailer (você grava ou o agente gera montagem com ffmpeg)

## 20. Roadmap por milestones

- [x] **M0 – Setup (1ª sessão):** seções 1 e 2 completas, jogo abre com tela preta e "Hello Ragg". Roteiro: `AGENTE-INICIO.md`
- [x] **M1 – Andar e falar:** Ragg anda num mapa placeholder, Calindra segue, fala com 1 NPC, abre 1 baú, transição entre 2 mapas, save/load básico
- [x] **M2 – Combate:** batalha completa Ragg+Calindra vs 2 inimigos, XP, level up, itens em batalha, game over
- [x] **M3 – Vertical slice:** prólogo + capítulo 1 jogável do início ao boss, com arte placeholder mas todos os sistemas
- [ ] **M4 – Conteúdo:** todos os capítulos, mapas, quests, bestiário
- [ ] **M5 – Arte e áudio finais:** substituir placeholders, VFX, música
- [ ] **M6 – Polish e release:** balanceamento, acessibilidade, localização, builds, página itch, lançamento
- [ ] `[VOCÊ]` Definir prazo desejado por milestone (ou "sem prazo")

## 21. Como trabalhar com o agente

- [ ] `[VOCÊ]` Preencher os `[VOCÊ]` das seções 0, 3 e 4 primeiro; são pré-requisito de quase tudo
- [ ] `[VOCÊ]` Descrever em texto livre; o agente converte em dados/código
- [ ] `[AGENTE]` A cada sessão: ler `CLAUDE.md` + este checklist, marcar itens feitos, atualizar `docs/`
- [ ] `[AGENTE]` Nunca deixar o jogo em estado que não abre; cada commit roda testes
- [ ] `[AGENTE]` Pedir validação do usuário ao terminar cada milestone, não a cada item

---

## Ordem sugerida de ataque

1. Rodar `AGENTE-INICIO.md` (M0) numa sessão do agente. Não depende de nenhuma resposta sua.
2. Enquanto isso, responder os `[VOCÊ]` das seções 0, 3 e 4 em texto livre (pode ser num arquivo `docs/RESPOSTAS.md` ou direto no chat).
3. Decidir os `[JUNTOS]` das seções 1, 6 e 9 (versão do Godot, fórmulas, sistema de diálogo).
4. Seguir M1 → M6 do roadmap, validando ao fim de cada milestone.
