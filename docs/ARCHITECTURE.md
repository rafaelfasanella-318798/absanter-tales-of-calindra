# Absanter – Tales of Calindra · Arquitetura e plano do pivô 3D

> **Referência única** do projeto para o **Copilot** (planeja e revisa), o **Agy** (executa) e **você** (decide e valida).
> Status das tarefas: [§8.1](#81-tabela-de-status). Revisão atual: **rev. 2 · 29/09/2026** ([§10](#10-histórico-de-revisões)).

## Sumário

0. [Como usar este documento](#0-como-usar-este-documento)
1. [Papéis e protocolo](#1-papéis-e-protocolo)
2. [Visão e pilares Grandia](#2-visão-e-pilares-grandia)
3. [Decisões técnicas](#3-decisões-técnicas)
4. [Arquitetura](#4-arquitetura)
5. [Sistemas e regras](#5-sistemas-e-regras)
6. [Assets 3D e visual toon](#6-assets-3d-e-visual-toon)
7. [Testes, verificação e convenções](#7-testes-verificação-e-convenções)
8. [Backlog do Agy](#8-backlog-do-agy)
9. [Pendências do usuário](#9-pendências-do-usuário)
10. [Histórico de revisões](#10-histórico-de-revisões)

---

## 0. Como usar este documento

| Quem | Lê | Mantém |
|---|---|---|
| Agy | §1, §3, §4, §7 e o cartão da tarefa no §8 **antes de cada tarefa** | Status no §8.1 e relatórios `docs/RELATORIO-Gx.md` |
| Copilot | Tudo, mais os relatórios e commits do Agy | §2–§9 (refina cartões, revisa entregas, registra decisões) |
| Você | §8.1 (andamento), §9 (decisões pendentes) e os relatórios | Respostas `[VOCÊ]` e aprovação (`OK`) dos milestones |

### 0.1 Como acionar o Agy (WSL)

```bash
cd "/mnt/c/Users/rafae/absanter - tales of calindra" && agy
```

| Objetivo | Prompt |
|---|---|
| Próxima tarefa | `Leia docs/ARCHITECTURE.md e execute a próxima tarefa TODO do §8 seguindo o protocolo do §1.` |
| Milestone inteiro | `Execute todas as tarefas TODO do milestone G0 de docs/ARCHITECTURE.md §8 seguindo o protocolo do §1. Pare ao concluir o relatório do milestone.` |
| Tarefa específica | `Execute somente a tarefa G0-01 de docs/ARCHITECTURE.md §8 seguindo o protocolo do §1.` |
| Correções da revisão | `Aplique as correções da seção "Revisão" de docs/RELATORIO-G0.md seguindo o protocolo do §1.` |

### 0.2 Como acionar o Copilot

| Objetivo | Prompt |
|---|---|
| Revisar um milestone | `Revise docs/RELATORIO-G0.md e os commits do G0; atualize o §8 e o §9 do ARCHITECTURE.md.` |
| Refinar rascunho | `Transforme o milestone G5 do ARCHITECTURE.md em cartões completos.` |
| Mudar uma decisão | `Quero mudar a decisão X; atualize o §3 e os cartões afetados.` |

---

## 1. Papéis e protocolo

### 1.1 Papéis

| Papel | Quem | Faz | Não faz |
|---|---|---|---|
| Decisor | Você | Responde `[VOCÊ]`, valida relatórios e marca milestones como `OK` | — |
| Planejador e revisor | Copilot | Mantém este documento, escreve e refina cartões, revisa commits e relatórios | Não implementa código do jogo, salvo pedido explícito seu |
| Executor | Agy | Implementa as tarefas `TODO` do §8 (código, cenas, dados, testes, commits, push e relatórios) | Não muda decisões do §3 nem cartões; não executa `RASCUNHO` |

### 1.2 Status das tarefas

| Status | Significado | Quem define |
|---|---|---|
| `RASCUNHO` | Ideia ainda sem cartão completo. **Não executar** | Copilot |
| `TODO` | Cartão completo, pronto para execução | Copilot |
| `DOING` | Em execução | Agy |
| `DONE` | Concluída pelo Agy, com a definição de pronto (§1.5) atendida | Agy |
| `BLOCKED` | Impedida; motivo na coluna Notas e no relatório | Agy |
| `OK` | Revisada e aceita | Você (ou o Copilot, a seu pedido) |

### 1.3 Ciclo de cada tarefa (Agy)

1. Escolha a **primeira** tarefa `TODO` da tabela §8.1 cujas dependências estejam `DONE` ou `OK`.
2. Leia o cartão inteiro e as seções que ele cita. Marque `DOING` no §8.1.
3. Implemente somente o escopo do cartão. Dados de jogo vão para `data/`, nunca para o código.
4. Rode `./lint.sh` e `./test.sh` na sua cópia de trabalho.
5. Atualize a documentação afetada: §4 se a arquitetura mudou, `docs/CREDITS.md` se entrou asset.
6. Marque `DONE` no §8.1 e faça o commit local com **todos os arquivos novos** (`.gd`, `.tscn`, `.tres`, `.json`, `.uid`):
   `feat(3d): [G1-03] descrição curta` (tipos: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`).
7. A partir da G0-01, rode `./verify.sh`: ele testa a **HEAD** (o commit que você acabou de fazer) num clone limpo.
   - Passou: faça push para `origin/main` (autorizado por você em 29/09/2026).
   - Falhou: não faça push. Corrija e rode de novo (pode usar `git commit --amend`, porque o commit ainda não foi enviado).
     Se não conseguir, guarde o trabalho num branch (`git branch wip/Gx-yy && git reset --hard HEAD~1`),
     marque a tarefa `BLOCKED` no §8.1 com o motivo e siga para a próxima tarefa independente.
8. Ao concluir a tarefa de relatório do milestone, **pare** e aguarde a revisão.

### 1.4 Regras invioláveis

- A `main` precisa abrir e passar nos testes num **clone limpo**. Todo arquivo referenciado vai no mesmo commit.
- Nunca reescrever histórico publicado (sem `--force`, sem rebase de commits enviados).
- Não executar `RASCUNHO` nem criar tarefas por conta própria: proponha no relatório (seção Propostas).
- Não parar para perguntar no meio: registre o bloqueio, marque `BLOCKED` e siga para a próxima tarefa independente.
- Sem teclas, eixos ou botões hardcoded: use as ações do Input Map (§3.16).
- Assets só CC0 ou com licença compatível, registrados em `docs/CREDITS.md` (§6).
- Os testes do 2D legado continuam passando até a remoção do 2D (G6).

### 1.5 Definição de pronto (vale para toda tarefa)

- Critérios de aceite do cartão atendidos e demonstráveis.
- `./lint.sh` sem erros e `./test.sh` 100% verde antes do commit; `./verify.sh` verde no commit da tarefa, antes do push (a partir da G0-01).
- Cenas afetadas abrem sem `SCRIPT ERROR` (smoke headless).
- Nenhum dado de jogo novo no código e nenhuma tecla hardcoded.
- Lógica nova coberta por testes (regras puras em `scripts/core/` com testes unitários).
- §8.1 atualizado e commit com o ID da tarefa.

### 1.6 Relatório de milestone (`docs/RELATORIO-Gx.md`)

~~~markdown
# Relatório Gx · <nome do milestone>
## Resumo (3–5 linhas)
## Tarefas e commits (ID · status · hash · o que mudou)
## Verificação (lint · testes N/N · verify em clone limpo · tempo · CI)
## Como testar em 5 minutos (comandos play/cenários e o que observar)
## Capturas (arquivos em captures/, gerados pelo capture)
## Assets adicionados (nome · pacote · licença · link)
## Itens do CHECKLIST marcados
## Bloqueios e riscos
## Propostas (mudanças sugeridas ao plano)
## Pendências [VOCÊ]
~~~

---

## 2. Visão e pilares Grandia

**Absanter – Tales of Calindra** é um JRPG 3D estilizado (cel/toon em HD) inspirado na série **Grandia** (I, II e III).
Ragg (protagonista) e Calindra (companheira jogável) exploram vilas e masmorras com câmera rotacionável,
veem os inimigos no mapa e lutam num combate em que **tempo e posição importam**.

| # | Pilar | O que trazemos de Grandia | Por quê |
|---|---|---|---|
| 1 | Barra IP visível | Todos avançam numa linha do tempo: COM = escolher o comando, ACT = executar | Dá para ver quem vai agir e quando |
| 2 | Combo × Crítico × Cancelamento | Combo = dano em vários golpes; Crítico = golpe que **cancela** quem está preparando uma ação e o empurra na barra | Escolha entre dano e controle do tempo |
| 3 | Posição na arena | Quem ataca se desloca até o alvo e fica onde atacou; habilidades em área pegam quem está perto | Posicionamento vira estratégia |
| 4 | Aerial (Grandia III) | O Crítico que cancela lança o alvo; o parceiro com SP faz o Aerial Combo | Já implementado pelo Agy; mantido e ajustável |
| 5 | Encontros visíveis | Inimigos andam no mapa; tocar pelas costas dá **Surpresa**, ser pego pelas costas dá **Emboscada** | Sem batalhas aleatórias |
| 6 | Exploração 3D | Câmera que gira, vilas vivas, NPCs, baús e pontos de save | Senso de lugar |
| 7 | Calor da party | Acampamento e jantar com conversas; Calindra com personalidade e reações | Coração narrativo de Grandia |

**Fora do escopo:** mundo aberto, combate de ação em tempo real, multiplayer e gráficos realistas.

---

## 3. Decisões técnicas

Decisões fechadas. Só você muda (peça ao Copilot para atualizar este documento e os cartões afetados).

| # | Tema | Decisão | Estado em 29/09 | Tarefa |
|---|---|---|---|---|
| 3.1 | Engine | Godot **4.7.2**, GDScript; testes com GUT | ✅ | — |
| 3.2 | Renderer | **Compatibility** (`gl_compatibility`) em desktop, mobile e Web. A Web só roda Compatibility, então o jogo todo usa o mesmo | ❌ não definido (Forward+ no desktop) | G0-03 |
| 3.3 | Tela | Base **1280×720**, stretch `canvas_items`, aspect `expand`; MSAA 3D 2×; FXAA só se funcionar no Compatibility | ⚠ stretch `disabled` (a UI não escala) | G0-03 |
| 3.4 | Entrada | Só ações do Input Map (§3.16). Nada de `KEY_*`, `JOY_*` ou `get_joy_axis(0, …)` no código de jogo | ❌ câmera lê mouse e analógico crus | G0-03, G1-02 |
| 3.5 | Visual | Shader toon (2–3 faixas de luz, rim, `flash_amount`) + contorno por casco invertido; sem SDFGI, SSAO, SSR ou névoa volumétrica; partículas com `CPUParticles3D` | ❌ primitivas sem toon | G0-08 |
| 3.6 | Modelos | `.glb`, Y para cima, 1 unidade = 1 metro, humanos com ~1,7 m; animações com nomes padrão (§6.2) | ❌ cápsulas e caixas | G1-01, G2-02 |
| 3.7 | Física | Camadas nomeadas: 1 `world`, 2 `player`, 3 `party`, 4 `enemy`, 5 `interactable`, 6 `trigger`, 7 `camera_block` | ❌ | G0-03 |
| 3.8 | Navegação | `NavigationRegion3D` + `NavigationAgent3D` para inimigos e NPCs que andam | ❌ movimento direto | G2-03 |
| 3.9 | Dados | Todo dado de jogo em `data/` (`.tres` ou `.json`); constantes de regra em `data/battle/battle_config.tres` | ❌ muito dado hardcoded no 3D | G1-05, G3-01 |
| 3.10 | Lógica | Regras puras em `scripts/core/` (sem nós e sem acessar autoloads: tudo chega por parâmetro), testadas em headless; os nós só orquestram | ❌ `battle_3d.gd` monolítico | G3 |
| 3.11 | Save | JSON **v2**: mapa, posição 3D + yaw, yaw da câmera, estado da party (nível, XP, HP, MP, SP), inventário, flags e quests; migra o save 1.0 | ❌ só `Vector2` | G1-07 |
| 3.12 | Binários | **Sem Git LFS**: os binários já estão no Git como blobs normais (0 arquivos no LFS; o maior tem 229 KB). O `.gitattributes` marca `binary` | ⚠ `.gitattributes` ainda declara LFS → 686 arquivos "modificados" no Windows | G0-02 |
| 3.13 | Web | Export sem threads (`variant/thread_support=false`) para dispensar COOP/COEP; meta ≥ 30 fps | ❌ não validado | G0-09 |
| 3.14 | Legado 2D | Congelado na tag `v0.3.0-2d` (commit `eb891b1`) e removido na G6 | ❌ tag não existe | G0-02 |
| 3.15 | Git | Commits `tipo(3d): [Gx-yy] descrição`; `.uid` sempre junto; push só depois do `verify` verde | ⚠ commits sem ID e HEAD incompleta | G0-01 |

### 3.16 Mapa de entrada (alvo)

| Ação | Teclado e mouse | Gamepad (Xbox) |
|---|---|---|
| `move_up`, `move_down`, `move_left`, `move_right` | WASD, setas | Analógico esquerdo, D-pad |
| `run` | Shift | X |
| `interact` | Enter, Espaço (**sem E**, que passa a girar a câmera) | A |
| `cancel` | Esc, X | B |
| `menu` | Tab, M | Start |
| `camera_rotate_left`, `camera_rotate_right` (giro de 45°) | Q, E | LB, RB |
| `camera_orbit_left`, `camera_orbit_right`, `camera_orbit_up`, `camera_orbit_down` | — | Analógico direito |
| `camera_orbit_hold` (arrastar o mouse para orbitar) | Botão direito do mouse | — |
| `camera_zoom_in`, `camera_zoom_out` | Roda do mouse, R, F | — |
| `camera_zoom_cycle` | — | R3 |
| `debug_console` (só em build de debug) | `` ` `` (crase), F12 | — |

O movimento do mouse só é lido (via `InputEventMouseMotion`) enquanto `camera_orbit_hold` estiver pressionado. O mouse é capturado apenas durante esse arrasto.

---

## 4. Arquitetura

### 4.1 Autoloads

| Ordem | Autoload | Responsabilidade | Mudança planejada |
|---|---|---|---|
| 1 | `EventBus` | Sinais globais desacoplados | Sinais novos (§4.6) |
| 2 | `GameState` | Modo atual, flags e tempo de jogo | `battle_context: BattleContext` substitui `encounter_type: String`; `field_state` guarda inimigos derrotados por mapa até sair dele (G2-05) |
| 3 | `SaveManager` | Save JSON em `user://saves/` | Save v2 + migração do 1.0 (G1-07) |
| 4 | `AudioManager` | Música e efeitos | — |
| 5 | `SceneManager` | Troca de cena com fade | `change_map(map_id, spawn_id)` (G1-06); `return_to_field(context)`, acionado por `battle_finished` (G2-05) |
| 6 | `DialogueManager` | Sequências de fala | Carrega `data/dialogues/*.json` com condições e efeitos (G1-05) |
| 7 | `QuestManager` | Quests e estágios | — |
| 8 | `InventoryManager` | Itens e ouro | — |
| 9 | `PartyManager` | Membros, equipamento e atributos efetivos | Estado persistente por membro (nível, XP, HP, MP, SP) e `restore_all(hp_ratio, mp_ratio)` (G1-07) |
| 10 | `Localization` | `pt_BR` e `en`; textos de UI por chave (`data/localization/strings.csv`) | — (os diálogos trazem o texto de cada idioma no próprio JSON, §4.4; o `DialogueManager` escolhe por `Localization.get_locale()`) |
| 11 | `DebugConsole` (cena) | Console F12 | Comandos novos (G0-05) |
| 12 | `DebugBoot` | Aplica cenários de debug | Novo, só em build de debug (G0-05) |

`SceneManager.change_scene(path, fade)` faz o fade preto de ~0,4 s entre cenas.

### 4.2 Estado atual do 3D (29/09/2026)

Protótipo feito pelo Agy nos commits `2b77cd0`..`e189cc9` (ainda sem push), mais arquivos que ficaram fora do Git.

```
scenes/world_3d/
├── kakariko_3d.tscn        Mapa greybox: Player3D, Follower3D, NPC3D, CameraRig (SpringArm3D + Camera3D),
│                           SlimeWanderer (EnemyWanderer3D) e BattlePortal (Area3D)
├── player_3d.tscn          CharacterBody3D (Ragg)            ← fora do Git
├── follower_3d.tscn        CharacterBody3D (Calindra)        ← fora do Git
├── npc_3d.tscn             StaticBody3D (Tav)                ← fora do Git
├── enemy_wanderer_3d.tscn  Area3D com patrulha aleatória e Label3D "!"
└── camp_3d.tscn            Fogueira (OmniLight3D pulsante), assentos, UI de diálogo e restauração
scenes/battle_3d/
└── battle_3d.tscn          Arena: Camera3D, Ragg3D, Calindra3D, Slime3D, Golem3D e UI (barra IP, comandos, alvo, banners)
```

| Script | Classe | O que faz hoje |
|---|---|---|
| `scripts/world_3d/player_3d.gd` | `Player3D` | Movimento nos eixos do mundo, gravidade, rastro de posições, interação por RayCast3D |
| `scripts/world_3d/follower_3d.gd` | `Follower3D` | Segue o rastro do `Player3D` |
| `scripts/world_3d/npc_3d.gd` | `NPC3D` | Falas fixas no código, enviadas ao `DialogueManager` |
| `scripts/world_3d/kakariko_3d.gd` | `Kakariko3D` | Mapa + câmera orbital (mouse com botão direito e analógico direito, pitch −15° a 55°) + portal de batalha |
| `scripts/world_3d/enemy_wanderer_3d.gd` | `EnemyWanderer3D` | Patrulha aleatória; no contato classifica o encontro, grava `GameState.encounter_type`, emite `EventBus.field_encounter_started` e troca para a batalha |
| `scripts/world_3d/camp_3d.gd` | `Camp3D` | 3 conversas rotativas (flag `camp_count`), "restauração" e volta a Kakariko |
| `scripts/battle_3d/battle_3d.gd` | `Battle3D` | Monólito de 1052 linhas: combatentes em `Dictionary`, IP no `_process`, UI por botões, IA aleatória, Combo, Crítico, Cancel, Aerial, Habilidade, Defender e Evasão |

#### 4.2.1 Dívidas encontradas na revisão de 29/09

Severidade: **P0** impede abrir ou testar num clone limpo · **P1** recurso não funciona como anunciado · **P2** dívida que a arquitetura alvo remove · **P3** higiene.

| # | Sev. | Onde | Problema | Corrige em |
|---|---|---|---|---|
| D1 | P0 | `kakariko_3d.tscn`, `kakariko_3d.gd`, `enemy_wanderer_3d.gd`, `test_3d_mode.gd`, `test_all_scenes_smoke.gd` | Referenciam `player_3d`, `follower_3d` e `npc_3d` (`.gd` e `.tscn`), que estão **fora do Git**. Num clone limpo: parse error (`Player3D`/`Follower3D`), cenas ausentes, 75 testes em vez de 105 e 1 falha | G0-01 |
| D2 | P1 | 11 `.uid`, `scenes/main/main.gd` e `.tscn`, `data/balance_summary.csv.import` | Fora do Git ou modificados sem commit; o CSV é importado como tradução (`csv_translation`) | G0-01 |
| D3 | P1 | `enemy_wanderer_3d.gd:110-146`, `player_3d.gd:40-44`, `enemy_wanderer_3d.gd:68-70` | A classificação usa a `basis` do **nó raiz**, mas os dois só giram o nó visual: a "frente" é sempre −Z do mundo. Surpresa/emboscada dependem só da direção do contato no mundo, não de quem está de costas. E as convenções se contradizem: o movimento vira o visual com `atan2(x, z)` (frente = +Z) e a classificação usa −Z. Alvo: frente = −Z do nó raiz (§6.2) | G1-03, G2-03, G2-04 |
| D4 | P1 | `player_3d.gd:33-34` | Movimento nos eixos do mundo: com a câmera girada, "para cima" não vai para a frente da tela | G1-03 |
| D5 | P1 | `camp_3d.gd:91-100` | Chama `PartyManager.restore_all` só se o método existir (`has_method`); ele não existe, então nada é restaurado e nenhum erro aparece | G1-07 |
| D6 | P1 | `battle_3d.gd:123-210` | A batalha é sempre Ragg + Calindra × Slime + Golem: a party não vem de `PartyManager.active_members`, e o inimigo tocado e o `enemy_data_path` são ignorados. Depois da vitória o inimigo reaparece e o líder volta ao spawn padrão | G2-05, G4-02 |
| D7 | P1 | `battle_3d.gd:128-173, 567, 609, 641-652` | SPD e MAG da party fixos (11/13 e 5/18), nomes de habilidade fixos e três fórmulas de dano próprias (Combo, Crítico e Habilidade) em vez do `BattleFormulas` e das `SkillData` de `data/skills/`. O item 5 do CHECKLIST ("sem hardcode") vale só para os inimigos | G3-01, G3-02, G4-02 |
| D8 | P1 | `battle_3d.gd:412-414, 520` | Defender não reduz dano: só zera a IP | G3-04, G4-02 |
| D9 | P2 | `battle_3d.gd` (fim de batalha) | Vitória sem XP, ouro e drops; derrota só mostra texto (D23); sem Item e Fugir; Habilidade não gasta MP; HP/MP começam sempre cheios e nada volta ao `PartyManager` | G1-07, G2-05 (derrota), G3-04, G4-02, G4-07 |
| D10 | P2 | `battle_3d.gd:315+` | Sem fila de execução: ações e tweens podem se sobrepor | G3-03, G4-02 |
| D11 | P2 | `kakariko_3d.gd:47, 53-101` | Câmera embutida no mapa, com mouse e analógico crus (`get_joy_axis(0, …)`), e mouse capturado desde o `_ready` | G1-02 |
| D12 | P2 | `npc_3d.gd:15-34`, `camp_3d.gd:15` | Falas fixas no código | G1-05 |
| D13 | P2 | `project.godot` (inclusive l. 103-105) | Stretch `disabled` (a UI não escala) e renderer não definido. O filtro de textura do canvas virou linear e o snap 2D foi desligado, o que borra o 2D em pixel art | G0-03 |
| D14 | P2 | `scenes/main/main.gd:48-53` (botão 3D) | Estado inicial fixo no código (ouro 100, party) e sem limpar as quests, que o Novo Jogo 2D limpa | G1-11 |
| D15 | P3 | `debug_console.gd:28-40, 115-126` | Teclas cruas (`KEY_QUOTELEFT`, `KEY_F12`, `KEY_ESCAPE`, `KEY_UP`, `KEY_DOWN`) para abrir, fechar e navegar no histórico; o `help` não lista os comandos 3D | G0-05 |
| D16 | P3 | Testes | 53 órfãos; smoke com lista fixa de cenas; asserts que sempre passam (`test_3d_mode.gd:141` confere `ip >= 0.0`; a l. 280 faz `assert_not_null` num `Vector3`) | G0-04 |
| D17 | P3 | `.gitattributes` | Declara LFS, mas nenhum arquivo está no LFS → 686 binários "modificados" no Windows | G0-02 |
| D18 | P3 | `CHECKLIST.md`, commits | "105/105" só valia nesta máquina (já anotado no CHECKLIST; o número final sai do `verify`). Os 9 commits não têm ID de tarefa e usam o autor `cdr-projects-2025`: o histórico fica como está (nada de reescrever); ID e identidade valem para os próximos commits | G0-01 (número de testes), §7.7 (ID nos próximos commits), V7 (autor) |
| D19 | P1 | `battle_3d.gd:572-574, 634-639` | O Combo cancela qualquer alvo em ACT e toda Habilidade também cancela; em Grandia só o Crítico e as habilidades com `can_cancel` cancelam (§5.4, regra 3). O núcleo novo **não** deve preservar esse comportamento | G0-06 (Combo), G3-01 (`can_cancel`), G3-04, G4-02 |
| D20 | P1 | `.gdlintrc`; `battle_3d.gd` (1052 linhas); 18 linhas com mais de 100 colunas em `battle_3d.gd`, `camp_3d.gd`, `kakariko_3d.gd`, `enemy_wanderer_3d.gd` e `test_3d_mode.gd`; `camp_3d.gd:9, 15` | O `./lint.sh` falha (`max-file-lines: 1000`, `max-line-length: 100` e `class-definitions-order`, com `@export` antes de `const`). O CI fica vermelho no primeiro push, e o `verify` também | G0-01 |
| D21 | P1 | `battle_3d.gd:325-343, 376-377` | Softlock: se dois heróis chegam ao COM no mesmo quadro, o laço continua depois de parar o tempo e o segundo sobrescreve `active_player_index`; o primeiro fica em `command` para sempre. Provável na Surpresa (IP inicial 0,70) e a 30 fps | G0-06, G3-03, G4-02 |
| D22 | P1 | `battle_3d.gd:625, 718-728` | `_find_aerial_partner` só filtra `is_player`: quando um inimigo cancela um herói, outro herói gasta 30 SP e faz o Aerial na própria party | G0-06, G3-04 |
| D23 | P1 | `battle_3d.gd:1027-1029` | A derrota trava: o texto manda apertar ESC, mas a batalha não trata entrada nem oferece saída | G0-06, G2-05 |
| D24 | P1 | `enemy_wanderer_3d.gd:106-107`, `kakariko_3d.gd:47` | O encontro no campo troca de cena com o mouse capturado; a batalha não libera o mouse nem dá foco a um botão, então os comandos ficam inacessíveis (só o portal e o ESC liberam o mouse) | G0-06, G1-02, G4-04 |
| D25 | P1 | `kakariko_3d.gd:22, 72`; `kakariko_3d.tscn` (`SpringArm3D` de 7 m, `Camera3D` a −20°) | Sinal do pitch invertido: o `SpringArm3D` projeta em +Z local, então pitch positivo aponta o braço para baixo. Com os 20° padrão a câmera bate no chão atrás do líder e olha na horizontal; quase toda a faixa −15°…55° mira o chão | G0-06, G1-02 |
| D26 | P1 | `dialogue_box.gd:52-56`, `dialogue_manager.gd:16-17` | O diálogo só trava o `Player` 2D: o `Player3D` anda durante a fala, e o `interact` que fecha a última fala reabre o diálogo. Trocar de cena com diálogo aberto deixa `DialogueManager.is_active = true`, e todo diálogo seguinte (2D incluso) é ignorado | G0-06, G1-03, G1-05 |
| D27 | P3 | `battle_3d.gd:89`, `kakariko_3d.gd:41` | `play_music` recebe o caminho completo, mas espera o nome da faixa (`audio_manager.gd:45`): mesmo com as faixas (D33), a música nunca tocaria no 3D | G0-06 |
| D28 | P2 | `battle_3d.gd:91-93, 296` | `_setup_ui()` roda depois de `_apply_encounter_type()` e apaga o banner de Surpresa/Emboscada | G0-06 |
| D29 | P2 | `battle_3d.gd:345, 906-977` | `_update_ip_markers` apaga e recria os marcadores da barra IP a cada quadro (centenas de nós por segundo); `ip_gauge_bar` não é usado | G4-04 |
| D30 | P2 | `battle_3d.gd:23-25, 443-452, 567, 609` | Balanço: o Crítico sem cancelamento dá ~2× o dano do Combo com o mesmo tempo de ACT, então domina. A Evasão custa só 0,15 IP e sorteia a posição em torno do centro da arena, podendo parar colada num inimigo | G3-04, G3-06 |
| D31 | P2 | `camp_3d.gd:68`, `save_manager.gd:86-87` | Depois de salvar e carregar, as flags numéricas voltam do JSON como `float`, e `float % int` dá erro no `_ready` do acampamento | G1-07 |
| D32 | P2 | `pause_menu.gd:124`, `kakariko_3d.gd:98-102` | No 3D não há pausa (o menu exige o modo `exploration`) e o ESC volta direto ao título | G1-11 |
| D33 | P3 | `assets/audio/`, `audio_manager.gd:38-53` | O projeto não tem nenhuma música (`assets/audio/music/` e `sfx/` só têm `.gitkeep`); os efeitos são bipes gerados em código. O `AudioManager` usa só o bus Master e ignora o fade, embora o CHECKLIST §13 marque buses e crossfade como feitos | G0-10 (CHECKLIST), G1-09, G4-06, V9 |

**Manter** do protótipo: a barra IP com linha COM e mini-SP, a separação Combo × Crítico, o Aerial, a Evasão, o `SpringArm3D`,
a regra de ângulo (depois de corrigida), o `Camp3D` e os testes existentes.

### 4.3 Estrutura alvo

```
scripts/
├── core/                        Regras puras (sem Node), testadas em headless
│   ├── camera_math.gd           CameraMath: yaw em passos, zoom, direção relativa à câmera
│   ├── encounter_math.gd        EncounterMath: normal / surprise / ambush (Enums.Advantage)
│   ├── save_migration.gd        SaveMigration: 1.0 → 2
│   └── battle/
│       ├── battle_formulas.gd   BattleFormulas (movido de scripts/battle/ na G3-02): dano, cura, XP e fuga
│       ├── battle_context.gd    BattleContext: encontro, vantagem e retorno ao campo
│       ├── battle_result.gd     BattleResult: resultado, XP, ouro e drops
│       ├── combatant_state.gd   CombatantState: atributos, HP/MP/SP, IP, fase e posição
│       ├── ip_timeline.gd       IPTimeline: WAIT → COM → ACT → EXECUTE, fila e pausas
│       ├── action_outcome.gd    ActionOutcome: dano, cura, cancelamentos, IP, movimentos, custos e itens gastos
│       ├── action_resolver.gd   ActionResolver: Combo, Crítico, Cancel, Aerial, Habilidade, Item, Defender, Mover, Fugir
│       └── battle_ai.gd         BattleAI: aplica AIRuleData
├── data/                        Resources existentes + BattleConfigData, EncounterData, AIRuleData
├── autoload/                    Singletons (+ debug_boot.gd)
├── world_3d/                    player_3d, follower_3d, npc_3d, camera_rig_3d, character_model_3d, party_spawner_3d,
│                                interactable_3d, chest_3d, map_transition_3d, save_point_3d, field_map_3d,
│                                field_enemy_3d, camp_3d
├── battle_3d/                   battle_controller_3d, combatant_3d, battle_camera_3d,
│                                ui/ (ip_gauge, command_menu, party_panel, target_selector_3d)
└── ui/                          hud_3d, tema e telas (título, pausa, loja, diálogo)
scenes/   world_3d/ · battle_3d/ · ui/ · dev/ (toon_showcase)
data/     characters/ · enemies/ · skills/ · encounters/ · maps/ · dialogues/*.json · battle/battle_config.tres
          · ai/ · debug/scenarios/*.json
assets/   models/{characters,enemies,environment,props}/ · shaders/ · materials/ · audio/ · fonts/
tests/    unit/core/ · unit/ · integration/
```

As pastas do 2D (`scenes/world`, `scenes/battle`, `scripts/world`, `scripts/battle`) ficam até a G6.

### 4.4 Modelo de dados

Recursos existentes em `scripts/data/` e o que muda:

| Recurso | Campos atuais (resumo) | Extensões | Tarefa |
|---|---|---|---|
| `CharacterData` | `id`, nome, `max_hp`, `max_mp`, `attack`, `defense`, `magic`, `speed`, crescimento, `starting_skills`, `portrait`, `sprite_frames` | `model_scene: PackedScene`, `ip_marker_color`, `ip_marker_icon` | G1-01 |
| `EnemyData` | `id`, nome, afinidade e fraqueza, atributos, XP, ouro, drops, `skills`, `sprite`, `tile_index` | `model_scene`, `field_behavior` (`idle`/`patrol`/`chase`), `detection_radius`, `field_speed`, `ai_rules: Array[AIRuleData]`, `ip_marker_color`, `ip_marker_icon` | G2-01, G2-02 (`model_scene`), G3-05 (`ai_rules`) |
| `SkillData` | `id`, nome, elemento, `target_type`, `cost_mp`, `power_multiplier`, `base_value`, cura/buff, `animation_name` | `cast_time` (velocidade da fase ACT), `ip_knockback`, `can_cancel`, `hits`, `aoe_shape` (`none`/`circle`/`line`/`cone`), `aoe_radius`, `range`, `cost_sp` | G3-01 |
| `MapData` | `id`, nome, `scene_path`, música, `can_save`, `can_fast_travel` | `default_spawn_id`, `default_camera_yaw`, `field_encounters` (os spawns são nós `Marker3D` no grupo `spawn`, nomeados pelo id) | G1-06, G2-01 |
| `BattleConfigData` (novo) | — | Todas as constantes do §5.4 | G3-01 |
| `EncounterData` (novo) | — | `id`, `enemies: Array[EnemyData]`, `formation: Array[Vector3]`, `arena_scene`, `music`, `can_escape`, `is_boss` | G2-01 |
| `AIRuleData` (novo) | — | `condition` (`always`, `hp_below`, `target_in_act`, `every_n_turns`), `action` (`combo`, `critical`, `skill:<id>`, `defend`), `target_rule` (`random`, `lowest_hp`, `in_act`), `weight` | G3-05 |
| Diálogos (JSON, novo) | — | `data/dialogues/<id>.json`: falas com `speaker`, `text: {pt_BR, en}` (o `DialogueManager` escolhe por `Localization.get_locale()`, com `pt_BR` como reserva), `conditions` (flags, quest) e `effects` (flags, itens, quest) | G1-05 |

### 4.5 Fluxo campo ↔ batalha (alvo)

```
FieldEnemy3D (contato com o líder)
 ├─ EncounterMath.classify(...) → normal | surprise | ambush
 ├─ GameState.battle_context = BattleContext{encounter_id, advantage, return_map_id,
 │                                           return_position, return_yaw, field_enemy_uid}
 ├─ EventBus.field_encounter_started(encounter_id, advantage)
 └─ SceneManager.change_scene(arena da EncounterData)
BattleController3D (até a G4-02, o battle_3d.gd)
 ├─ lê o battle_context → CombatantState da party (o controlador lê o PartyManager) e dos inimigos (EncounterData)
 ├─ IPTimeline + ActionResolver + BattleAI (núcleo puro; o controlador aplica os efeitos nos autoloads)
 └─ EventBus.battle_finished(result: BattleResult)          sinal criado na G2-05
     ├─ SceneManager.return_to_field(context) (G2-05): vitória e fuga voltam ao mapa, na posição e yaw salvos;
     │                                                derrota abre o game over → último save ou título
     ├─ vitória: PartyManager, InventoryManager e QuestManager aplicam XP, ouro e drops (G4-07);
     │           o inimigo some até você sair do mapa
     └─ fuga:    2 s de invulnerabilidade no campo
```

### 4.6 Sinais do EventBus

| Sinal | Situação | Emissor → ouvintes |
|---|---|---|
| `field_encounter_started(enemy_id, encounter_type)` | Existe; passa a ser `(encounter_id, advantage)` na G2-05 | `FieldEnemy3D` → HUD, áudio |
| `battle_finished(result: BattleResult)` | Novo (G2-05) | `battle_3d.gd` (depois `BattleController3D`, G4-02) → `SceneManager` (G2-05); `PartyManager`, `InventoryManager`, `QuestManager` (G4-07); HUD |
| `battle_ended(victory: bool)` | Existe (2D); fica até a G6 | Batalha 2D |
| `map_changed(map_id: String)` | Novo (G1-06) | `SceneManager` → HUD (banner), áudio |
| `interaction_available(prompt: String)` / `interaction_cleared()` | Novos (G1-05) | `Interactable3D` → HUD |
| `camera_yaw_changed(yaw_deg: float)` | Novo (G1-02) | `CameraRig3D` → bússola do HUD |
| `party_state_changed(member_id: String)` | Novo (G1-07) | `PartyManager` → HUD e menus |

---

## 5. Sistemas e regras

### 5.1 Exploração

- `Player3D` anda **relativo à câmera** (o input é girado pelo yaw da câmera) e corre com `run`. A frente do personagem é a do nó raiz (a rotação vai no `CharacterBody3D`, não só no visual).
- `interact` aciona o `Interactable3D` à frente (NPC, baú, porta, ponto de save), com prompt no HUD.
- Movimento travado durante diálogo, menu e cutscene.
- A party segue o rastro do líder, com teleporte se ficar a mais de 6 m.
- Cada mapa tem uma raiz `FieldMap3D` com `MapData`, spawns, navmesh e yaw inicial da câmera.

### 5.2 Câmera de campo

- `CameraRig3D` segue o líder com suavização; o `SpringArm3D` evita atravessar paredes (camadas `world` e `camera_block`).
- Órbita livre: arrastar o mouse com o botão direito ou usar o analógico direito; pitch entre −15° e 55°.
- Giro em passos de 45° (`camera_rotate_left/right`) com tween de ~0,25 s.
- Zoom em 3 níveis (perto, médio, longe) com tween.
- Bússola no HUD aponta o norte do mapa.

### 5.3 Encontros no campo

- `FieldEnemy3D` alterna `idle` → `patrol` → `chase` (líder dentro de `detection_radius`) → `return` (longe da origem), com navmesh.
- Classificação no contato (`EncounterMath`, usando a frente **real** de cada um):
  - **Surpresa** (`surprise`): o líder toca o inimigo pelas costas → a party começa perto do COM.
  - **Emboscada** (`ambush`): o inimigo toca o líder pelas costas → os inimigos começam perto do COM.
  - **Normal** (`normal`): os demais casos → IP inicial baixa e aleatória.
  - Se os dois estiverem de costas um para o outro, vale `surprise`, como no protótipo.
- Identificadores: `normal`, `surprise` e `ambush` em texto (cenários, console, JSON), como no protótipo;
  `Enums.Advantage` (`NORMAL`, `SURPRISE`, `AMBUSH`) no código (`scripts/data/enums.gd`); "Normal", "Surpresa" e "Emboscada" na tela.
- Janela de "costas": `backstab_angle_deg` = 60° (±30° em torno das costas).
- Um contato dispara uma única batalha. Depois da vitória o inimigo some até você sair do mapa; depois da fuga, 2 s de invulnerabilidade.

### 5.4 Combate IP

Regras alvo (G3), mantendo os recursos que o Agy já criou:

1. **WAIT**: a IP sobe de 0 até o ponto COM, proporcional ao SPD.
2. **COM**: se for da party, o tempo para (modo Wait) e o menu abre; se for inimigo, a `BattleAI` escolhe. Heróis que chegam
   ao COM juntos entram numa fila, e o menu abre um de cada vez (D21).
3. **ACT**: a ação escolhida define a velocidade até 1,0 (`cast_time`: Combo e Crítico rápidos, habilidades mais lentas). Quem está em ACT pode ser **cancelado** por Crítico ou por habilidade com `can_cancel`.
4. **EXECUTE**: ao chegar em 1,0 entra na **fila de execução**. Uma ação por vez; a timeline pausa durante a animação e o dano entra no impacto.
5. Depois de agir volta a WAIT com IP 0.
6. Se o alvo morrer antes do golpe, redireciona para o inimigo vivo mais próximo.
7. Quem ataca vai até o alvo e fica lá; habilidades em área usam a distância real na arena.
8. Mover/Evadir: o jogador escolhe o destino dentro de um raio em torno do próprio herói (não do centro da arena, D30); gasta IP.
9. Defender: dano ×0,5 até o próximo COM.
10. Fugir: chance pura `BattleFormulas.escape_chance` sorteada com o RNG injetado; se falhar, IP volta a 0.
11. Dano: uma única fórmula (`BattleFormulas.calculate_damage`) com o multiplicador da ação (`action_multiplier`).

Valores atuais do protótipo, que viram campos de `data/battle/battle_config.tres` na G3-01 (todas as linhas, menos a IA, que é da G3-05):

| Parâmetro | Valor atual (`battle_3d.gd`) | Campo |
|---|---|---|
| Ponto COM | 0,75 | `com_point` |
| Avanço da IP | `speed × 0,035` por segundo | `ip_speed_factor` |
| Aceleração na fase ACT | ×1,5 (igual para toda ação) | `act_speed_multiplier` (+ `SkillData.cast_time`) |
| Combo | 2 golpes (×0,80 e ×0,65); alvo −0,20 IP; +8 SP | `combo_hit_multipliers`, `combo_ip_push`, `combo_sp_gain` |
| Crítico | ×2,20; se o alvo está em ACT: CANCEL, −0,55 IP e dano ×1,45 | `critical_multiplier`, `cancel_ip_push`, `cancel_damage_bonus` |
| Habilidade | ×1,80; não gasta MP (dívida) | `SkillData.power_multiplier`, `SkillData.cost_mp` |
| Aerial | parceiro com SP ≥ 30 e IP ≥ 0,5: 3 golpes ×0,90 + finalização ×2,20; −0,70 IP; altura 2,5 m | `aerial_sp_cost`, `aerial_min_ip`, `aerial_hits`, `aerial_hit_multiplier`, `aerial_smash_multiplier`, `aerial_ip_push`, `aerial_height` |
| Evasão | −0,15 IP; posição sorteada até 2,5 m do centro da arena | `evade_ip_cost`, `move_radius` |
| Defender | sem efeito hoje (dívida) | `defend_damage_multiplier` = 0,5 |
| SP máximo | 100 | `max_sp` |
| Surpresa / Emboscada | party 0,70 / inimigos 0,72 | `surprise_party_ip`, `ambush_enemy_ip` |
| Janela de costas | 60° (±30° em torno das costas) | `backstab_angle_deg` |
| Cancelamento pelo Combo | cancela qualquer alvo em ACT (D19) | — (alvo: o Combo só empurra a IP, `combo_ip_push`) |
| Cancelamento por Habilidade | toda habilidade cancela um alvo em ACT (D19) | `SkillData.can_cancel` |
| IA inimiga | 30% Crítico, alvo aleatório | `AIRuleData` (G3-05) |

### 5.5 Progressão (`RASCUNHO`)

Depende da sua escolha na G5-01: A) nível por uso de arma e elemento (Grandia I); B) moedas e ovos de mana/livros de
habilidade (Grandia II); C) manter o XP atual. Até lá vale o XP atual (`40 × nível^1,45`).

### 5.6 Acampamento

O `Camp3D` do Agy vira a base: pontos de acampamento no mapa, restauração pelo `PartyManager` (100% HP e 75% MP)
e conversas em `data/dialogues/camp_*.json`, com condições por flag e quest. Hoje ele só abre pelo console
(`debug_console.gd:124`), e a partir da G0-05 também pelo cenário `camp_party_ferida`; os pontos no mapa, o jantar e as
escolhas de conversa ficam para a G7.

### 5.7 Save v2

```json
{
  "version": 2,
  "map_id": "kakariko",
  "spawn_id": "",
  "position": [0.0, 0.0, 0.0],
  "yaw": 90.0,
  "camera_yaw": 45.0,
  "party": {
    "active": ["ragg", "calindra"],
    "members": { "ragg": { "level": 3, "xp": 120, "hp": 80, "mp": 10, "sp": 0 } }
  },
  "inventory": {}, "gold": 100, "flags": {}, "quests": {}, "playtime": 0.0
}
```

A migração do 1.0 converte a cena 2D para o `map_id` equivalente e usa o spawn padrão do mapa.


---

## 6. Assets 3D e visual toon

### 6.1 Fontes de assets (CC0)

| Uso | Pacotes sugeridos | Onde |
|---|---|---|
| Ragg, Calindra e NPCs (placeholders) | KayKit Adventurers (Knight, Barbarian, Mage, Rogue) | kaylousberg.itch.io |
| Inimigos | KayKit Skeletons; Quaternius Ultimate Monsters | kaylousberg.itch.io · quaternius.com |
| Vila de Kakariko | Kenney Fantasy Town Kit | kenney.nl/assets |
| Natureza | Kenney Nature Kit; KayKit Forest Nature Pack | kenney.nl/assets · kaylousberg.itch.io |
| Caverna e câmara do Guardião | KayKit Dungeon Remastered | kaylousberg.itch.io |
| Props (baú, fogueira, móveis) | Kenney Survival Kit, Furniture Kit | kenney.nl/assets |

Cada asset entra em `docs/CREDITS.md` com nome, pacote, autor, licença e link. Licenças diferentes de CC0 exigem aprovação sua no relatório.

### 6.2 Convenções de importação

- Pastas: `assets/models/<categoria>/<id>/` (`characters`, `enemies`, `environment`, `props`), com texturas junto do `.glb`.
- Escala 1 unidade = 1 metro; origem nos pés; humanos com ~1,7 m.
- Cada modelo tem uma cena `<id>_model.tscn` que corrige rotação e escala para o personagem olhar para **−Z** (frente do Godot).
- Nomes padrão de animação, mapeados por `CharacterModel3D.anim_map` (os pacotes usam nomes diferentes, por exemplo `Idle`, `Walking_A`, `1H_Melee_Attack_Chop` no KayKit):

  | Padrão | Uso |
  |---|---|
  | `idle`, `walk`, `run` | Campo e arena (em loop) |
  | `attack_1`, `attack_2` | Combo e Crítico |
  | `cast` | Preparação de habilidade (fase ACT) |
  | `hit`, `ko`, `victory`, `defend` | Reações e fim de batalha |
  | `launch` | Aerial Combo |

- Sem root motion; `idle`, `walk` e `run` em loop.
- Materiais do pacote são trocados pelo material toon (§6.3), preservando a textura de cor.

### 6.3 Visual toon (Compatibility)

| Arquivo | Conteúdo |
|---|---|
| `assets/shaders/toon.gdshader` | Spatial; `light()` com 2–3 faixas; uniforms `albedo_texture`, `tint`, `bands`, `band_softness`, `shadow_color`, `rim_strength`, `rim_color` e `flash_amount` (0–1, flash branco ao levar dano) |
| `assets/shaders/outline.gdshader` | `render_mode unshaded, cull_front`; cresce o vértice na normal por `outline_width`; `outline_color`; usado como `next_pass` do material toon |
| `assets/materials/` | Materiais `.tres` prontos (personagem, inimigo, cenário) |
| `scenes/dev/toon_showcase.tscn` | Vitrine: esfera, cápsula, personagem e chão com luz girando, para validar os parâmetros com você |

Iluminação: um `DirectionalLight3D` com sombra e `WorldEnvironment` com luz ambiente e tonemap. Sem GI dinâmico.
Efeitos só entram se funcionarem no Compatibility e na Web (valide na G0-09).

### 6.4 Orçamento de desempenho (a Web é a referência)

| Item | Meta |
|---|---|
| Triângulos em tela | ≤ 150 mil |
| Draw calls | ≤ 200 |
| Texturas | ≤ 1024×1024 |
| Luzes | 1 direcional com sombra; até 8 `OmniLight3D` sem sombra por cena |
| Download Web (vertical slice) | ≤ 60 MB |
| FPS | 60 no desktop; ≥ 30 na Web em notebook médio |

---

## 7. Testes, verificação e convenções

### 7.1 Convenções de código

- Arquivos e pastas em `snake_case`; classes em `PascalCase` com `class_name`; sinais e métodos em `snake_case`;
  constantes em `SCREAMING_SNAKE_CASE`.
- Dados de jogo em `data/` (§3.9). Sistemas grandes conversam pelo `EventBus`.
- Regras puras em `scripts/core/` (classes `RefCounted` ou funções estáticas, sem `Node` e sem acessar autoloads: quem chama
  passa os dados), testadas em headless.
- Entrada só por ações do Input Map (§3.16).
- Todo `.gd` e `.gdshader` novo vai no commit com seu `.uid` (cenas e recursos guardam o uid no próprio arquivo).
  Nunca commitar `.godot/`, `export/` ou `captures/`.
- Comentários só onde a intenção não é óbvia; preserve os existentes.

### 7.2 Camadas de teste

| Camada | O que cobre | Onde | Quando |
|---|---|---|---|
| Unitário (core) | IP, dano, ações, IA, encontros, câmera, migração de save | `tests/unit/core/` | Toda mudança |
| Unitário (nós) | Cenas instanciam, sinais, estados | `tests/unit/` | Toda mudança |
| Integração | Campo → batalha → campo, save/load, quests | `tests/integration/` | Toda mudança |
| Smoke | Todas as cenas carregam e rodam sem `SCRIPT ERROR` (lista descoberta automaticamente) | `test_all_scenes_smoke.gd` e `verify` | Todo commit |
| Clone limpo | Tudo acima numa worktree limpa da HEAD | `verify` | Antes de todo push (hook) |
| Visual | 3 capturas por cena-chave | `capture` | Fim de milestone |
| Playtest | Roteiro de 5 minutos com cenários de debug | Você | Fim de milestone |

### 7.3 Como testar hoje (comandos verificados em 29/09/2026)

No Windows (PowerShell, na raiz do projeto):

```powershell
$godot = ".\tools\godot-win\Godot_v4.7.2-stable_win64_console.exe"

# Todos os testes (~4 s)
& $godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit

# Um arquivo, filtrando testes pelo nome (~3 s)
& $godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit -gtest=res://tests/unit/test_3d_mode.gd -gunit_test_name=encounter

# Abrir o jogo direto numa cena, em velocidade 2x, com colisões visíveis e FPS no terminal
& $godot --path . --time-scale 2 --debug-collisions --print-fps res://scenes/battle_3d/battle_3d.tscn
```

No WSL (Agy): `./test.sh`, `./test.sh -gtest=res://tests/unit/test_3d_mode.gd`, `./lint.sh` e `./run.sh res://scenes/world_3d/kakariko_3d.tscn`.

Dentro do jogo, **F12** ou a **crase** (`` ` ``) abre o console de debug: `3d`, `battle3d`, `camp`, `tp <kakariko|house|cave|boss>`,
`battle <inimigo>`, `god`, `heal`, `level [n]`, `item <id> [qtd]`, `gold <n>`, `flag <nome> <valor>` e `quest <id> <estágio>`.

Tempos medidos em 29/09: suíte completa 4,3 s; um arquivo filtrado 2,6 s; cena 3D em headless ~1,7 s;
verificação em worktree limpa (import + testes) ~18 s.

### 7.4 Kit de teste (G0-01, G0-04, G0-05 e G0-07)

| Comando (Windows · WSL) | O que faz | Meta |
|---|---|---|
| `.\test.ps1` · `./test.sh` | GUT headless; `-File`/`-Name` (ps1) e `-gtest`/`-gunit_test_name` (sh) | ≤ 10 s |
| `.\verify.ps1` · `./verify.sh` | Worktree limpa da HEAD → `--import` → lint → GUT → smoke das cenas principais → remove a worktree | ≤ 60 s |
| `.\play.ps1 battle -Speed 2` · `./play.sh battle --speed 2` | Abre direto numa cena (`title`, `kakariko`, `battle`, `camp`, `showcase`) com velocidade, colisões, navegação, FPS, cenário ou editor | Segundos |
| `.\capture.ps1` · `./capture.sh` | Movie Maker: 3 PNGs por cena-chave em `captures/` | ≤ 2 min |
| Tarefas do VS Code | Testes (todos / arquivo atual), jogar a cena aberta, verify | — |
| Hook `pre-push` | Roda o verify antes de cada push | — |

### 7.5 Cenários de debug

Arquivos `data/debug/scenarios/<id>.json`, aplicados pelo autoload `DebugBoot` **somente em build de debug**, quando o jogo
recebe `-- --scenario=<id>` (os scripts `play` repassam) ou o comando `scenario <id>` no console:

```json
{
  "id": "chefe_golem_lv8",
  "descricao": "Luta contra o Golem com a party no nível 8 e Calindra ferida",
  "scene": "res://scenes/battle_3d/battle_3d.tscn",
  "party": { "ragg": { "level": 8 }, "calindra": { "level": 8, "hp_ratio": 0.5 } },
  "inventory": { "potion": 5 },
  "gold": 500,
  "flags": { "kakariko_mimic": true },
  "battle": { "encounter_id": "kakariko_golem", "advantage": "normal" },
  "time_scale": 1.0
}
```

Campos que o jogo ainda não suporta são ignorados com aviso (por exemplo, `party.level` antes da G1-07 e `battle.encounter_id` antes da G2-05).
`battle.advantage` aceita `normal`, `surprise` ou `ambush` (os nomes do `Enums.Advantage`, em minúsculas).

### 7.6 Build, importação e dados

| Comando (WSL) | Uso |
|---|---|
| `tools/godot/godot --headless --path . --import` | Reimporta os assets |
| `tools/godot/godot --headless --path . -s scripts/tools/run_data_validator.gd` | Valida os recursos de `data/` |
| `tools/godot/godot --headless --path . -s scripts/tools/run_battle_simulation.gd` | Simulação de balanceamento |
| `./build.sh [linux\|windows\|web]` | Exporta para `export/` |

### 7.7 Commits

`tipo(3d): [Gx-yy] descrição` — por exemplo `fix(3d): [G0-01] commitar arquivos 3D ausentes, corrigir o lint e criar verify em clone limpo`.
Um commit por tarefa (ou poucos, todos com o ID). O corpo diz o que mudou e como foi verificado.

---

## 8. Backlog do Agy

Regras: execute na ordem da tabela, respeitando as dependências. A **primeira tarefa de cada milestone** exige o relatório
anterior com status `OK` (validado por você). Tarefas `RASCUNHO` não são executadas: o Copilot as transforma em cartões antes.

### 8.1 Tabela de status

Única fonte de status. O Agy atualiza as colunas Status e Notas.

| ID | Tarefa | Depende de | Status | Notas |
|---|---|---|---|---|
| **G0** | **Estabilizar e fundar** | | | |
| G0-01 | HEAD íntegra, lint verde e `verify` em clone limpo (**P0**) | — | DONE | 105/105 testes, lint verde, verify criado |
| G0-02 | Higiene do repositório: tag do 2D, sem LFS, CI | G0-01 | DONE | Tag v0.3.0-2d criada/enviada, sem LFS, captures/ no gitignore |
| G0-03 | `project.godot`: renderer, tela, Input Map e camadas | G0-01 | DONE | gl_compatibility, 1280x720 canvas_items, camadas e ações do §3.16 |
| G0-04 | `test.ps1`, `play`, VS Code, hook `pre-push`, smoke automático, zero órfãos | G0-01 | DONE | test.ps1, play.{sh,ps1}, tasks VS Code, hook pre-push, smoke dinâmico, 0 órfãos |
| G0-05 | Cenários de debug e comandos novos no console | G0-03, G0-04 | DONE | 6 cenários, DebugBoot autoload, ações e novos comandos no console, 120 testes |
| G0-06 | Estabilizar o protótipo para playtest (softlocks, mouse, câmera, diálogo e música) | G0-05 | DONE | D19, D21, D22, D23, D24, D25, D26, D27, D28 corrigidos, bot de playtest, 134 testes |
| G0-07 | Captura visual (Movie Maker) | G0-04 | DONE | capture.{sh,ps1} funcionando em ~27s, grava 01,02,03.png por cena |
| G0-08 | Shader toon, contorno e cena vitrine | G0-03 | DONE | toon/outline shaders, 3 materiais com next_pass, toon_showcase e 138 testes |
| G0-09 | Export Web do 3D validado | G0-06, G0-08 | TODO | |
| G0-10 | Relatório G0 + reconciliar o CHECKLIST | G0-01…G0-09 | TODO | Parar para revisão |
| **G1** | **Exploração 3D** | | | |
| G1-01 | Modelos CC0 de Ragg e Calindra + `CharacterModel3D` | G0-10 `OK` | TODO | |
| G1-02 | `CameraRig3D` + `CameraMath` | G0-10 `OK` | TODO | |
| G1-03 | `Player3D` relativo à câmera, corrida, animações e trava | G1-01, G1-02 | TODO | |
| G1-04 | `PartySpawner3D` e seguidores para N membros | G1-03 | TODO | |
| G1-05 | Diálogos em JSON + `Interactable3D` | G1-03 | TODO | |
| G1-06 | `FieldMap3D`, `MapData`, `change_map` e transições | G1-04, G1-05 | TODO | |
| G1-07 | Estado persistente da party + `restore_all` + save v2 | G1-06 | TODO | |
| G1-08 | Props: `Chest3D` e `SavePoint3D` | G1-05, G1-07 | TODO | |
| G1-09 | Kakariko 3D greybox com kit CC0 | G1-06, G1-08 | TODO | |
| G1-10 | Tema de UI HD + HUD de exploração | G1-06, G1-07 | TODO | |
| G1-11 | Telas em 1280×720 e Novo Jogo no 3D | G1-07, G1-09, G1-10 | TODO | |
| G1-12 | Relatório G1 | G1-01…G1-11 | TODO | Parar para revisão |
| **G2** | **Encontros visíveis** | | | |
| G2-01 | `EncounterData` e encontros de Kakariko | G1-12 `OK` | TODO | |
| G2-02 | Modelos CC0 dos inimigos | G2-01 | TODO | |
| G2-03 | `FieldEnemy3D` com navmesh | G2-02 | TODO | |
| G2-04 | `EncounterMath` puro e testado | G2-03 | TODO | |
| G2-05 | `BattleContext` e fluxo campo → batalha → campo | G2-04 | TODO | |
| G2-06 | Relatório G2 | G2-01…G2-05 | TODO | Parar para revisão |
| **G3** | **Núcleo Grandia (lógica pura)** | | | |
| G3-01 | `BattleConfigData` + campos de IP em `SkillData` | G2-06 `OK` | TODO | |
| G3-02 | `CombatantState` a partir de dados | G3-01 | TODO | |
| G3-03 | `IPTimeline` com fila de execução | G3-02 | TODO | |
| G3-04 | `ActionResolver` com todas as ações | G3-03 | TODO | |
| G3-05 | `BattleAI` por `AIRuleData` | G3-04 | TODO | |
| G3-06 | Simulador de balanceamento com IP | G3-05 | TODO | |
| G3-07 | Relatório G3 + valores para validar `[JUNTOS]` | G3-01…G3-06 | TODO | Parar para revisão |
| **G4** | **Arena de combate 3D** | | | |
| G4-01 | Arena e `Combatant3D` | G3-07 `OK` | TODO | |
| G4-02 | `BattleController3D` substitui o monólito | G4-01 | TODO | |
| G4-03 | Câmera de batalha | G4-02 | TODO | |
| G4-04 | UI de batalha com foco por teclado e gamepad | G4-02 | TODO | |
| G4-05 | Alvo 3D + prévia de área | G4-04 | TODO | |
| G4-06 | Feedback (números, banners, flash, partículas) | G4-02, G4-03 | TODO | |
| G4-07 | Fim de batalha, recompensas e integrações | G4-02 | TODO | |
| G4-08 | Playthrough automatizado (GUT `InputSender`) | G4-04, G4-05, G4-07 | TODO | |
| G4-09 | Relatório G4 + checklist de playtest | G4-01…G4-08 | TODO | Parar para revisão |
| G5 | Progressão estilo Grandia | G4-09 `OK`, G5-01 `[VOCÊ]` | RASCUNHO | §8.7 |
| G6 | Vertical slice 3D e remoção do 2D | G5 | RASCUNHO | §8.7 |
| G7 | Sabor Grandia e polish | G6 | RASCUNHO | §8.7 |

Formato dos cartões: **Objetivo** · **Depende de** · **Arquivos** · **Aceite** · **Testes** · **Commit**.
Todo cartão inclui a definição de pronto (§1.5), mesmo sem repeti-la.

### 8.2 G0 · Estabilizar e fundar

#### G0-01 · HEAD íntegra, lint verde e `verify` em clone limpo (P0)

- **Objetivo:** a `main` abrir e passar nos testes num clone limpo, e ter um comando que prove isso antes de todo push.
- **Depende de:** —
- **Antes de começar:** se `docs/ARCHITECTURE.md`, `CLAUDE.md`, `AGENTS.md` e `CHECKLIST.md` aparecerem modificados no
  `git status`, é a revisão do Copilot ainda sem commit. Commite só esses 4 arquivos, separado, com
  `docs: pivô 3D estilo Grandia — revisão do trabalho do Agy, papéis, arquitetura, kit de teste e backlog G0–G7`.
- **Arquivos:**
  - commitar os arquivos de D1 e D2 (§4.2.1): `scripts/world_3d/{player_3d,follower_3d,npc_3d}.gd`,
    `scenes/world_3d/{player_3d,follower_3d,npc_3d}.tscn`, os 11 `.uid` fora do Git e `scenes/main/main.gd` + `main.tscn`
    (como estão; o botão 3D sai na G1-11);
  - `data/balance_summary.csv.import` com `importer="keep"`;
  - correções de lint (D20) em `battle_3d.gd`, `camp_3d.gd`, `kakariko_3d.gd`, `enemy_wanderer_3d.gd` e `test_3d_mode.gd`;
  - novos `verify.sh` e `verify.ps1`; `CHECKLIST.md` (linha **Testes** da seção "Protótipo 3D do Agy").
- **Aceite:**
  - `git status` sem `??` nem `M` em `scripts/`, `scenes/`, `tests/` e `data/`.
  - `./lint.sh` passa sem afrouxar o `.gdlintrc` (D20): as 18 linhas longas quebradas, `const` antes de `@export` no
    `camp_3d.gd` e o `battle_3d.gd` com até 1000 linhas, sem mudar o comportamento (por exemplo, extraindo a montagem
    da UI para um script auxiliar em `scripts/battle_3d/`).
  - `verify [ref]` (padrão `HEAD`):
    1. cria uma worktree limpa da ref numa pasta temporária fora do repo (`git worktree add --detach`);
    2. roda `--import` com o Godot de `tools/` do repo principal (`tools/` não vai para a worktree);
    3. roda o lint; sem `gdlint`/`gdformat` instalados, **falha** e mostra como instalar (`pip install gdtoolkit`).
       `--skip-lint`/`-SkipLint` roda o resto e termina com "verificação parcial: não apta para push"; o hook nunca usa essa opção;
    4. roda o GUT com `.gutconfig.json` e falha se algum teste falhar ou se nenhum rodar;
    5. roda cada cena principal (`main`, `kakariko_3d`, `battle_3d`, `camp_3d`) em headless com `--quit-after 180`
       e falha se a saída tiver `SCRIPT ERROR` ou `Parse Error`;
    6. remove a worktree sempre, mesmo em falha (`trap` / `try-finally`);
    7. imprime um resumo com o número de testes e o tempo total; sai com código ≠ 0 em qualquer falha.
  - `./verify.sh e189cc9` **falha** (prova de que o verify pega o P0) e `./verify.sh` passa com o mesmo número de testes
    do `./test.sh`. As duas saídas vão no relatório do G0.
  - Linha **Testes** do CHECKLIST com o número que o verify mostrar (D18).
  - Push de todos os commits locais (os 9 do protótipo, o de documentação do Copilot e este) e CI verde no GitHub Actions.
- **Testes:** o próprio `verify`, nas duas plataformas.
- **Commit:** `fix(3d): [G0-01] commitar arquivos 3D ausentes, corrigir o lint e criar verify em clone limpo`

#### G0-02 · Higiene do repositório

- **Objetivo:** congelar o 2D e fazer o `git status` mostrar só o que importa (D17).
- **Depende de:** G0-01
- **Arquivos:** `.gitattributes`, `.github/workflows/ci.yml`, `.gitignore`.
- **Aceite:**
  - Tag anotada `v0.3.0-2d` no commit `eb891b1` (último commit do 2D, pai de `2b77cd0`), enviada com `git push origin v0.3.0-2d`.
  - `.gitattributes` sem LFS: `*.png`, `*.ogg`, `*.wav`, `*.ttf`, `*.otf`, `*.glb`, `*.jpg`, `*.webp`, `*.exr`, `*.hdr` e `*.blend` marcados como `binary`.
  - CI com `lfs: false` no checkout.
  - `.gitignore` com `captures/`.
  - No Windows, `git.exe status --porcelain` não lista binários (valide pelo interop do WSL ou registre no relatório para eu validar).
- **Testes:** `verify` verde.
- **Commit:** `chore(repo): [G0-02] tag do 2D, remover LFS e ajustar CI`

#### G0-03 · `project.godot` para o 3D

- **Objetivo:** renderer, tela, entrada e física conforme o §3.
- **Depende de:** G0-01
- **Arquivos:** `project.godot`, novo `tests/unit/test_project_settings.gd`.
- **Aceite:**
  - `rendering/renderer/rendering_method` e `rendering_method.mobile` = `gl_compatibility`.
  - 1280×720, `stretch/mode="canvas_items"`, `stretch/aspect="expand"`, MSAA 3D 2×. Teste o FXAA no Compatibility:
    se não tiver efeito, desligue e registre.
  - Todas as ações do §3.16 no Input Map, com `E` fora de `interact`. As ações existentes continuam funcionando no 2D.
  - Nomes das camadas de física 3D do §3.7.
  - Filtro de textura do canvas linear (UI em HD), decidido de propósito (D13): o 2D legado fica borrado, e isso é aceito,
    porque o 2D jogável fica na tag `v0.3.0-2d`.
- **Testes:** `test_project_settings.gd` confere renderer, tamanho, stretch, cada ação do §3.16 (`InputMap.has_action`),
  ausência de `KEY_E` em `interact` e os nomes das camadas.
- **Commit:** `feat(3d): [G0-03] Compatibility, 1280x720 canvas_items, Input Map e camadas de física`

#### G0-04 · Scripts de teste e jogo, VS Code, hook e smoke automático

- **Objetivo:** testar e abrir o jogo com um comando, no Windows e no WSL.
- **Depende de:** G0-01
- **Arquivos:** novos `test.ps1`, `play.ps1`, `play.sh`, `.vscode/tasks.json`, `.vscode/extensions.json` e `.githooks/pre-push`;
  `tests/integration/test_all_scenes_smoke.gd`; testes com órfãos; §7.3 e §7.4 deste documento.
- **Aceite:**
  - `test.ps1` espelha o `test.sh`: sem argumentos roda tudo; `-File <caminho>` e `-Name <texto>` viram `-gtest` e
    `-gunit_test_name`; devolve o código de saída do GUT.
  - `play.ps1`/`play.sh <atalho|res://…>` com atalhos `title`, `kakariko`, `battle`, `camp` e `showcase` (a partir da G0-08).
    Opções: `-Speed`/`--speed` (`--time-scale`), `-Colisoes`/`--colisoes`, `-Nav`/`--nav`, `-Fps`/`--fps`,
    `-Scenario`/`--scenario` (repassa `-- --scenario=<id>`) e `-Editor`/`--editor`.
  - Tarefas do VS Code: testes (todos e arquivo atual), jogar a cena aberta e verify. `extensions.json` com `geequlim.godot-tools`.
  - O smoke descobre sozinho todas as `.tscn` de `res://scenes/` (exceções numa constante `SKIP`, com motivo).
  - Zero órfãos no resumo do GUT (`autofree`, `add_child_autofree`).
  - Asserts que sempre passam (D16: `test_3d_mode.gd:141` e `:280`) viram asserts reais (valor esperado da IP;
    `home_pos` diferente do original depois da Evasão).
  - `.githooks/pre-push` executável: no Git Bash do Windows chama o `verify.ps1`; no Linux/WSL, o `verify.sh`.
    §7.3 explica como ativar (`git config core.hooksPath .githooks`).
- **Testes:** suíte completa com 0 órfãos; `.\test.ps1 -File res://tests/unit/test_3d_mode.gd` funciona.
- **Commit:** `chore(test): [G0-04] test.ps1, play, tarefas do VS Code, hook pre-push e smoke automático`

#### G0-05 · Cenários de debug e comandos do console

- **Objetivo:** chegar a qualquer situação de teste em segundos.
- **Depende de:** G0-03, G0-04
- **Arquivos:** novo `scripts/autoload/debug_boot.gd` (autoload `DebugBoot`, depois do `DebugConsole`);
  `data/debug/scenarios/*.json`; `scripts/ui/debug_console.gd`; `project.godot`; novo `tests/unit/test_debug_boot.gd`.
- **Aceite:**
  - `DebugBoot` só age em build de debug (`OS.is_debug_build()`). Lê `--scenario=<id>` de `OS.get_cmdline_user_args()`,
    aplica o JSON do §7.5 e troca para a `scene`. Campos ainda não suportados geram `push_warning`, nunca erro.
    A aplicação do estado fica numa função separada da troca de cena, para ser testável.
  - Cenários: `kakariko_inicio`, `batalha_normal`, `batalha_surpresa`, `batalha_emboscada`, `chefe_golem_lv8` e `camp_party_ferida`.
  - O console troca as teclas cruas de `debug_console.gd:28-40` (D15) por ações: `debug_console` abre e fecha
    (hoje `KEY_QUOTELEFT` e `KEY_F12`), `ui_cancel` fecha (hoje `KEY_ESCAPE`), `ui_up` e `ui_down` navegam no
    histórico (hoje `KEY_UP` e `KEY_DOWN`). Comandos novos:
    - `scenario [id]` (sem id, lista os cenários);
    - `speed <x>` (`Engine.time_scale`);
    - `fps` (liga e desliga um overlay com FPS, draw calls e primitivas via `Performance.get_monitor`);
    - `encounter <normal|surprise|ambush>` (vantagem da próxima batalha; aceita também `surpresa` e `emboscada`);
    - `restart` (recarrega a cena atual).
  - O `help` lista também `3d`, `battle3d` e `camp`.
- **Testes:** todo JSON de cenário é válido e aponta para uma cena existente; aplicar um cenário de teste altera
  ouro, inventário e flags; campo desconhecido não quebra.
- **Commit:** `feat(debug): [G0-05] cenários de debug e comandos novos no console`

#### G0-06 · Estabilizar o protótipo para playtest

- **Objetivo:** jogar o protótipo de ponta a ponta (Kakariko → encontro → batalha → volta) sem travar, até a G1 e a G4
  substituírem esse código. Só correções pontuais: nada de refatorar o monólito.
- **Depende de:** G0-05
- **Arquivos:** `scripts/battle_3d/battle_3d.gd` (e o script auxiliar, se a G0-01 criou um), `scenes/battle_3d/battle_3d.tscn`,
  `scripts/world_3d/{kakariko_3d,enemy_wanderer_3d}.gd`, `scripts/ui/dialogue_box.gd`, `scripts/autoload/dialogue_manager.gd`,
  `tests/unit/test_3d_mode.gd` ou novo `tests/unit/test_3d_prototype_fixes.gd`.
- **Aceite:**
  - D21: heróis que chegam ao COM no mesmo quadro entram numa fila; abre um menu por vez e ninguém fica preso em `command`.
    O laço para de avançar a IP no quadro em que o tempo para.
  - D22: o parceiro do Aerial é do mesmo lado de quem lançou e diferente do alvo; Crítico de inimigo não gera Aerial contra a party.
  - D23: a derrota abre um painel com "Tentar de novo" (recarrega a batalha com o mesmo encontro) e "Título"; o texto não fala mais em ESC.
  - D24: a batalha deixa o mouse visível no `_ready` e dá foco ao primeiro comando sempre que o menu abre; dá para jogar
    só com teclado ou gamepad. Kakariko libera o mouse no `_exit_tree`.
  - D25: pitch com o sinal certo: no valor padrão a câmera fica acima do líder, olhando para baixo, e nenhum valor da faixa
    de órbita leva a câmera para dentro do chão.
  - D26: o diálogo trava também o `Player3D`; o `interact` que fecha a última fala não reabre o diálogo; trocar de cena com
    diálogo aberto encerra o diálogo (`DialogueManager.is_active` volta a `false`).
  - D27: `play_music("title_theme")` e `play_music("battle_theme")` (nome da faixa), conferido pelo sinal `music_started`.
    Ainda não há faixas no projeto (D33): tocar de verdade fica para a G1-09.
  - D28: o banner de Surpresa/Emboscada aparece no início da batalha.
  - D19 (parte): o Combo deixa de cancelar; só empurra a IP do alvo, que continua em ACT. O cancelamento por Habilidade
    fica até a G3-04 (`can_cancel`).
  - Vitória ou derrota no meio do laço não abre o menu de comando (confere `is_battle_over`).
  - Os cenários `batalha_normal`, `batalha_surpresa` e `batalha_emboscada` terminam em vitória ou derrota jogando só com o teclado.
- **Testes:** um teste de regressão por item acima. Para D21, Surpresa + `_process(0.2)`: um menu aberto e o segundo herói na fila.
  Para D25, a cena de Kakariko depois de 2 quadros de física: `camera.global_position.y` maior que a do líder + 1 m. `verify` verde.
- **Commit:** `fix(3d): [G0-06] softlocks, mouse, câmera, diálogo e música do protótipo`

#### G0-07 · Captura visual

- **Objetivo:** ver o jogo sem abrir o editor, com imagens para relatórios e revisões.
- **Depende de:** G0-04
- **Arquivos:** novos `capture.ps1` e `capture.sh`.
- **Aceite:**
  - Para cada cena-chave (`title`, `kakariko`, `battle`, `camp` e `showcase` quando existir), roda
    `--write-movie captures/<cena>/frame.png --fixed-fps 30 --quit-after 150` e guarda 3 quadros (início, meio e fim)
    como `01.png`, `02.png` e `03.png`, apagando os outros. Aceita `-Scenario`.
  - O Movie Maker precisa de janela, não roda em headless: no WSL depende do WSLg; no Windows funciona direto.
  - Tudo em ≤ 2 min.
- **Testes:** rodar uma vez e citar as capturas no relatório.
- **Commit:** `chore(tools): [G0-07] captura de telas com Movie Maker`

#### G0-08 · Shader toon, contorno e vitrine

- **Objetivo:** definir o visual toon no Compatibility e validar os parâmetros com você.
- **Depende de:** G0-03
- **Arquivos:** `assets/shaders/toon.gdshader`, `assets/shaders/outline.gdshader`,
  `assets/materials/{toon_character,toon_enemy,toon_environment}.tres`, `scenes/dev/toon_showcase.tscn` + script,
  novo `tests/unit/test_toon_assets.gd`.
- **Aceite:**
  - Shaders e materiais conforme o §6.3; contorno como `next_pass` do material toon.
  - A vitrine tem luz girando e um painel com sliders (mouse) para `bands`, `band_softness`, `rim_strength` e `outline_width`,
    mostrando os valores para você escolher.
  - Material toon aplicado aos personagens e inimigos do protótipo (Kakariko 3D, batalha e acampamento).
  - Capturas da vitrine no relatório (G0-07).
- **Testes:** shaders e materiais carregam; o material toon tem o contorno como `next_pass`.
- **Commit:** `feat(3d): [G0-08] shader toon, contorno e cena vitrine`

#### G0-09 · Export Web do 3D validado

- **Objetivo:** garantir cedo que o 3D roda no navegador.
- **Depende de:** G0-06, G0-08
- **Arquivos:** `export_presets.cfg`; `build.sh` se precisar.
- **Aceite:**
  - Preset Web com `variant/thread_support=false` explícito.
  - `./build.sh web` gera `export/web/`. Servir com `python3 -m http.server 8060 -d export/web` e abrir no Chrome.
  - Kakariko 3D, batalha e vitrine rodam no navegador.
  - No relatório: FPS (overlay `fps`), tamanho do download, e se MSAA, FXAA, glow e fog funcionam no Compatibility e na Web.
  - A batalha do protótipo recria os marcadores da barra IP a cada quadro (D29): anote o FPS, mas não otimize (a G4-04 substitui).
  - Sem os export templates 4.7.2 instalados, instale-os ou marque `BLOCKED` com o motivo.
- **Testes:** `verify` verde; checagem manual descrita no relatório.
- **Commit:** `chore(web): [G0-09] export Web do 3D validado`

#### G0-10 · Relatório G0 e reconciliação do CHECKLIST

- **Objetivo:** fechar o G0 com evidências e alinhar o CHECKLIST ao plano.
- **Depende de:** G0-01…G0-09
- **Arquivos:** novo `docs/RELATORIO-G0.md`; `CHECKLIST.md`.
- **Aceite:**
  - Relatório no formato do §1.6, com a saída do `verify` (incluindo a falha em `e189cc9`), capturas e roteiro de playtest de 5 minutos.
  - Na seção "Protótipo 3D do Agy" do CHECKLIST, atualize os itens que o G0 fechou ou mudou (por exemplo, o 9 após a G0-03
    e os itens 1, 2 e 6 após a G0-06).
  - Marcar os `[VOCÊ]` já respondidos (encontros visíveis; combate por IP estilo Grandia).
  - No §13 do CHECKLIST, desmarcar o item do `AudioManager` (buses e crossfade não existem) e citar a D33.
  - **Parar** e aguardar a revisão.
- **Testes:** —
- **Commit:** `docs: [G0-10] relatório do G0`

### 8.3 G1 · Exploração 3D

#### G1-01 · Modelos CC0 de Ragg e Calindra + `CharacterModel3D`

- **Objetivo:** trocar as cápsulas por personagens animados com o visual toon.
- **Depende de:** G0-10 `OK`
- **Arquivos:** `assets/models/characters/{ragg,calindra}/` (`.glb` + `<id>_model.tscn`), novo `scripts/world_3d/character_model_3d.gd`,
  `scripts/data/character_data.gd`, `data/characters/{ragg,calindra}.tres`, `docs/CREDITS.md`, novo `tests/unit/test_character_model_3d.gd`.
- **Aceite:**
  - Placeholders do KayKit Adventurers (Ragg = Barbarian, Calindra = Mage) até a sua decisão V1 (§9).
  - `CharacterModel3D.play(anim)` usa os nomes padrão do §6.2 via `anim_map` exportado; material toon aplicado.
  - `CharacterData` ganha `model_scene`, `ip_marker_color` e `ip_marker_icon`; `Player3D` e `Follower3D` instanciam o modelo a partir dele.
- **Testes:** todo `CharacterData` da party tem `model_scene` válido; cada nome padrão existe no `anim_map`.
- **Commit:** `feat(3d): [G1-01] modelos CC0 de Ragg e Calindra com CharacterModel3D`

#### G1-02 · `CameraRig3D` + `CameraMath`

- **Objetivo:** câmera de exploração reutilizável e testável, só com ações do Input Map (D11).
- **Depende de:** G0-10 `OK`
- **Arquivos:** novos `scripts/world_3d/camera_rig_3d.gd`, `scenes/world_3d/camera_rig_3d.tscn`, `scripts/core/camera_math.gd`
  e `tests/unit/core/test_camera_math.gd`; `scripts/autoload/event_bus.gd` (sinal `camera_yaw_changed`);
  `kakariko_3d.gd` e `.tscn` (a câmera embutida sai).
- **Aceite:**
  - Comportamento do §5.2 e ações do §3.16.
  - Mouse capturado só durante `camera_orbit_hold` e liberado ao sair da cena (D24).
  - Em toda a faixa de pitch a câmera fica acima do líder, olhando para ele (D25).
  - `SpringArm3D` colide com `world` e `camera_block`.
  - Declara e emite `EventBus.camera_yaw_changed`; expõe `get_yaw()` para o `Player3D`.
  - `grep -rE "KEY_|JOY_|get_joy_axis" scripts/world_3d` vazio.
- **Testes:** `CameraMath`: passos de 45°, yaw em 0–360°, limite de pitch, ciclo de zoom, direção relativa
  (entrada "para cima" com yaw 0°, 90° e 180°) e deslocamento da órbita com `y > 0` no pitch mínimo e no máximo (D25).
- **Commit:** `feat(3d): [G1-02] CameraRig3D com giro de 45°, órbita, zoom e CameraMath`

#### G1-03 · `Player3D` relativo à câmera

- **Objetivo:** corrigir o movimento (D4), a frente do personagem (parte de D3) e a trava em diálogo (D26).
- **Depende de:** G1-01, G1-02
- **Arquivos:** `scripts/world_3d/player_3d.gd`, `scenes/world_3d/player_3d.tscn`, novo `tests/unit/test_player_3d.gd`.
- **Aceite:**
  - Direção = `CameraMath` aplicado à entrada e ao yaw da câmera.
  - O **nó raiz** gira para a direção do movimento (`-global_basis.z` é a frente real).
  - `run` com velocidades `@export`.
  - Animações `idle`/`walk`/`run` via `CharacterModel3D`.
  - Sem mover nem interagir entre `EventBus.dialogue_started` e `dialogue_ended`, com menu aberto ou em cutscene.
    O `interact` que fecha a última fala não reabre o diálogo (D26).
  - O rastro de posições para os seguidores continua.
- **Testes:** cálculo da velocidade (função pura) para yaw 0°, 90° e 180°; a frente do nó raiz acompanha o movimento;
  entrada ignorada durante diálogo.
- **Commit:** `fix(3d): [G1-03] movimento relativo à câmera, frente real, corrida e animações`

#### G1-04 · `PartySpawner3D` e seguidores

- **Objetivo:** a party ativa do `PartyManager` aparecer no campo, na ordem, seguindo o líder.
- **Depende de:** G1-03
- **Arquivos:** novo `scripts/world_3d/party_spawner_3d.gd`; `scripts/world_3d/follower_3d.gd`; `kakariko_3d.tscn`;
  novo `tests/unit/test_party_spawner_3d.gd`.
- **Aceite:**
  - O spawner lê `PartyManager.active_members` e instancia o líder e os seguidores com o `model_scene` de cada um.
  - O seguidor N segue o rastro com atraso proporcional a N e teleporta se ficar a mais de 6 m.
  - Nenhum membro fixo na cena do mapa.
- **Testes:** com 1, 2 e 3 membros, o spawner cria a quantidade certa; seguidor distante teleporta.
- **Commit:** `feat(3d): [G1-04] PartySpawner3D e seguidores para N membros`

#### G1-05 · Diálogos em JSON + `Interactable3D`

- **Objetivo:** tirar as falas do código (D12) e padronizar a interação.
- **Depende de:** G1-03
- **Arquivos:**
  - `data/dialogues/*.json` (`tav_3d_greeting` e `camp_*`);
  - `scripts/autoload/dialogue_manager.gd`, `scripts/autoload/event_bus.gd` (sinais `interaction_available` e
    `interaction_cleared`), `scripts/ui/dialogue_box.gd`;
  - novo `scripts/world_3d/interactable_3d.gd`; `npc_3d.gd`, `camp_3d.gd`;
  - `scripts/tools/data_validator.gd`; novo `tests/unit/test_dialogue_data.gd`.
- **Aceite:**
  - Formato do §4.4. `DialogueManager.start_dialogue(id)` escolhe as falas pelas `conditions` e aplica os `effects`.
  - `Interactable3D` é um `Area3D` na camada `interactable`, com `prompt` e sinal `interacted`.
    Declara e emite `interaction_available` e `interaction_cleared` no `EventBus`.
  - O texto de cada fala vem de `text.pt_BR`/`text.en`, escolhido por `Localization.get_locale()` (§4.4); os textos de UI
    continuam no CSV do `Localization`.
  - Trocar de cena com diálogo aberto encerra o diálogo: `DialogueManager.is_active` nunca fica preso (D26).
  - `NPC3D` e `Camp3D` sem nenhuma fala no código.
  - O validador confere todos os diálogos: falantes conhecidos e texto em `pt_BR` e `en`.
- **Testes:** todos os JSONs carregam; a condição por flag escolhe a fala certa; o efeito grava a flag; com o idioma `en`
  sai o texto em inglês; trocar de cena no meio do diálogo zera `is_active`.
- **Commit:** `feat(3d): [G1-05] diálogos em JSON e Interactable3D`

#### G1-06 · `FieldMap3D`, `MapData` e troca de mapa

- **Objetivo:** mapas 3D descritos por dados, com spawns e transições.
- **Depende de:** G1-04, G1-05
- **Arquivos:**
  - novos `scripts/world_3d/field_map_3d.gd`, `scripts/world_3d/map_transition_3d.gd` + cena;
  - `scripts/data/map_data.gd`, `data/maps/kakariko_3d.tres`;
  - `scripts/autoload/scene_manager.gd`, `scripts/autoload/event_bus.gd`;
  - `kakariko_3d.tscn`; novo `tests/unit/test_field_map_3d.gd`.
- **Aceite:**
  - `FieldMap3D` é a raiz de cada mapa, com `@export var map_data: MapData`. Ao entrar, põe a party no spawn pedido
    (ou em `default_spawn_id`) e a câmera em `default_camera_yaw`.
  - `SceneManager.change_map(map_id, spawn_id)` acha o `MapData` em `data/maps/`, faz o fade e emite `map_changed`.
  - `MapTransition3D` é um `Area3D` na camada `trigger`, com `target_map_id` e `target_spawn_id`.
  - O Kakariko 3D vira um `FieldMap3D`; o validador confere se cada `MapData` aponta para uma cena existente.
- **Testes:** `map_id` inválido dá erro claro e não troca de cena; o spawn por id posiciona certo.
- **Commit:** `feat(3d): [G1-06] FieldMap3D, MapData e SceneManager.change_map`

#### G1-07 · Estado persistente da party + save v2

- **Objetivo:** nível, XP, HP, MP e SP persistirem entre batalhas, mapas e saves (parte de D9); a posição 3D ir para o save.
- **Depende de:** G1-06
- **Arquivos:**
  - `scripts/autoload/party_manager.gd`, `scripts/autoload/save_manager.gd`, `scripts/autoload/event_bus.gd`
    (sinal `party_state_changed`);
  - novo `scripts/core/save_migration.gd`; `camp_3d.gd`;
  - novos `tests/unit/core/test_save_migration.gd`, `tests/unit/test_party_state.gd` e `tests/integration/test_save_load_3d.gd`.
- **Aceite:**
  - `PartyManager` guarda o estado de cada membro (§4.1), inicializado pelo `CharacterData`. API:
    `get_member_state(id)`, `set_member_state(id, state)`, `restore_all(hp_ratio, mp_ratio)` e sinal `party_state_changed`.
  - `Camp3D` restaura de verdade, sem `has_method` (D5).
  - Save v2 conforme o §5.7; carregar leva ao mapa, posição e yaw salvos.
  - Save 1.0 migrado por `SaveMigration.migrate(data)`.
  - Flags inteiras voltam do save como `int` (o JSON devolve `float`); o `Camp3D` funciona depois de carregar (D31).
  - A API de save usada pelo 2D continua funcionando até a G6.
- **Testes:** migração 1.0 → 2 com um JSON 1.0 real como fixture; save/load v2 ida e volta (inclusive uma flag inteira);
  `restore_all` restaura a proporção certa; HP persiste ao trocar de mapa.
- **Commit:** `feat(3d): [G1-07] estado persistente da party, restore_all e save v2 com migração`

#### G1-08 · Props: `Chest3D` e `SavePoint3D`

- **Objetivo:** recompensas e save na exploração 3D.
- **Depende de:** G1-05, G1-07
- **Arquivos:** novos `scripts/world_3d/{chest_3d,save_point_3d}.gd` e cenas em `scenes/world_3d/props/`;
  modelos CC0 em `assets/models/props/`; `docs/CREDITS.md`; novo `tests/unit/test_props_3d.gd`.
- **Aceite:**
  - Os dois usam `Interactable3D`.
  - `Chest3D`:
    - exporta `item_id`, `quantity`, `gold` e `flag_id`;
    - anima a tampa;
    - fica aberto depois de sair do mapa e de carregar o save.
  - `SavePoint3D` abre o save e só funciona se `MapData.can_save`.
- **Testes:** o baú entrega o item uma única vez; a flag sobrevive ao save v2.
- **Commit:** `feat(3d): [G1-08] Chest3D e SavePoint3D`

#### G1-09 · Kakariko 3D greybox com kit CC0

- **Objetivo:** a vila de Kakariko em 3D, explorável de ponta a ponta.
- **Depende de:** G1-06, G1-08
- **Arquivos:** `scenes/world_3d/kakariko_3d.tscn`, novo `scenes/world_3d/kakariko_house_3d.tscn`, `data/maps/*.tres`,
  `assets/models/environment/` (Kenney Fantasy Town Kit e Nature Kit), `assets/audio/music/`, `default_bus_layout.tres`,
  `scripts/autoload/audio_manager.gd`, `docs/CREDITS.md`,
  novo `tests/integration/test_kakariko_3d.gd`.
- **Aceite:**
  - Layout inspirado no Kakariko 2D: casas, praça e saída para a caverna (bloqueada por enquanto).
  - Colisão na camada `world`; `camera_block` onde a câmera não deve passar; `NavigationRegion3D` assado (para a G2-03).
  - Conteúdo: Tav com o diálogo da G1-05, um baú, um ponto de save e uma transição para dentro de uma casa (ida e volta).
  - Música (D33, V9): faixas CC0 `title_theme`, `kakariko_theme` e `battle_theme` em `assets/audio/music/`, creditadas no
    `docs/CREDITS.md`; o `FieldMap3D` toca o `MapData.background_music` ao entrar. O `AudioManager` ganha os buses Music e
    SFX e o fade que hoje é ignorado.
  - Orçamento do §6.4 respeitado; os valores do overlay `fps` vão no relatório.
- **Testes:** entrar na casa e sair devolve a party ao spawn da porta; o smoke cobre as cenas novas.
- **Commit:** `feat(3d): [G1-09] Kakariko 3D greybox com kit CC0`

#### G1-10 · Tema de UI HD + HUD

- **Objetivo:** UI legível em 1280×720 e um HUD de exploração.
- **Depende de:** G1-06, G1-07
- **Arquivos:** novo `assets/ui/theme_hd.tres`; fonte OFL ou CC0 em `assets/fonts/` (até a sua decisão V2);
  novos `scenes/ui/hud_3d.tscn`, `scripts/ui/hud_3d.gd` e `tests/unit/test_hud_3d.gd`.
- **Aceite:**
  - Um `Theme` único: fonte, tamanhos, painéis e foco visível para gamepad.
  - O HUD mostra:
    - bússola (`camera_yaw_changed`);
    - prompt de interação (`interaction_available`/`interaction_cleared`);
    - banner do mapa (`map_changed`, some em 2 s);
    - notificações (item recebido, quest);
    - HP e MP da party (`party_state_changed`).
  - Textos via `Localization`.
- **Testes:** cada sinal atualiza o elemento certo do HUD.
- **Commit:** `feat(ui): [G1-10] tema HD e HUD de exploração`

#### G1-11 · Telas em 1280×720 e Novo Jogo no 3D

- **Objetivo:** o fluxo título → jogo acontecer todo no 3D.
- **Depende de:** G1-07, G1-09, G1-10
- **Arquivos:** `scenes/main/main.tscn` e `main.gd`; `scenes/ui/{dialogue_box,pause_menu,shop_menu}.tscn` e scripts;
  novo `data/new_game.json`; novo `tests/integration/test_new_game_3d.gd`.
- **Aceite:**
  - Título, caixa de diálogo, pausa e loja com o tema HD, navegáveis por teclado e gamepad.
  - "Novo Jogo" inicia no Kakariko 3D. Party, ouro, itens, flags, mapa e spawn iniciais vêm de `data/new_game.json`, e as
    quests são reiniciadas (D14).
  - A pausa funciona no 3D (o `PauseMenu` aceita o modo `exploration_3d`) e o ESC no campo abre a pausa em vez de voltar ao título (D32).
  - "Continuar" carrega o save v2.
  - O botão "3D" sai; o 2D continua acessível pela tag `v0.3.0-2d` e pelo console até a G6.
- **Testes:** Novo Jogo abre o `kakariko_3d` com o estado do JSON.
- **Commit:** `feat(3d): [G1-11] telas HD e Novo Jogo no Kakariko 3D`

#### G1-12 · Relatório G1

- **Depende de:** G1-01…G1-11
- **Aceite:** relatório do §1.6. O roteiro de 5 minutos cobre: andar, girar a câmera, falar com Tav, abrir o baú,
  entrar e sair da casa, salvar, voltar ao título e continuar. **Parar** para revisão.
- **Commit:** `docs: [G1-12] relatório do G1`

### 8.4 G2 · Encontros visíveis

#### G2-01 · `EncounterData` e encontros de Kakariko

- **Objetivo:** cada inimigo do campo apontar para um encontro descrito por dados.
- **Depende de:** G1-12 `OK`
- **Arquivos:** novo `scripts/data/encounter_data.gd`; `scripts/data/enemy_data.gd` (extensões do §4.4, menos `model_scene`
  e `ai_rules`); `data/encounters/{kakariko_slime,cave_bat,kakariko_mimic,kakariko_golem}.tres`; `scripts/data/map_data.gd`
  (`field_encounters`); `scripts/tools/data_validator.gd`; novo `tests/unit/test_encounter_data.gd`.
- **Aceite:**
  - Campos do §4.4, com os inimigos existentes em `data/enemies/`.
  - O validador confere: inimigos existem, `formation` tem o mesmo tamanho de `enemies`, `arena_scene` existe.
- **Testes:** os 4 encontros carregam; o validador acusa um encontro inválido (fixture).
- **Commit:** `feat(3d): [G2-01] EncounterData e encontros de Kakariko`

#### G2-02 · Modelos CC0 dos inimigos

- **Objetivo:** slime, morcego, mímico e golem com modelo 3D.
- **Depende de:** G2-01
- **Arquivos:** `assets/models/enemies/<id>/`; `scripts/data/enemy_data.gd` (campo `model_scene`); `EnemyData.model_scene`
  nos `.tres`; `docs/CREDITS.md`.
- **Aceite:** `CharacterModel3D` com `idle`, `walk`, `attack_1`, `hit` e `ko`; material toon; escala coerente (golem com ~3 m).
- **Testes:** todo `EnemyData` usado em encontros tem `model_scene` válido.
- **Commit:** `feat(3d): [G2-02] modelos CC0 dos inimigos`

#### G2-03 · `FieldEnemy3D` com navmesh

- **Objetivo:** inimigos que patrulham, percebem e perseguem a party.
- **Depende de:** G2-02
- **Arquivos:** novo `scripts/world_3d/field_enemy_3d.gd` + cena (evolui e substitui o `enemy_wanderer_3d`); `kakariko_3d.tscn`;
  referências em testes e smoke; novo `tests/unit/test_field_enemy_3d.gd`.
- **Aceite:**
  - Estados do §5.3 com `NavigationAgent3D`. Na perseguição, "!" aparece por 0,5 s.
  - `@export var encounter: EncounterData`; `field_behavior`, `detection_radius` e `field_speed` vêm do `EnemyData`.
  - O **nó raiz** gira para onde anda (fecha D3 com a G1-03).
  - `enemy_wanderer_3d` removido.
- **Testes:** transições de estado pela distância ao líder (sem física, com posições simuladas).
- **Commit:** `feat(3d): [G2-03] FieldEnemy3D com patrulha e perseguição por navmesh`

#### G2-04 · `EncounterMath`

- **Objetivo:** a regra de vantagem numa função pura, com testes dos três casos.
- **Depende de:** G2-03
- **Arquivos:** novo `scripts/core/encounter_math.gd`; `scripts/data/enums.gd` (enum `Advantage`); `field_enemy_3d.gd`;
  novo `tests/unit/core/test_encounter_math.gd`.
- **Aceite:**
  - `EncounterMath.classify(leader_pos, leader_forward, enemy_pos, enemy_forward, backstab_angle_deg)` devolve
    `Enums.Advantage` (`NORMAL`, `SURPRISE` ou `AMBUSH`) pela regra do §5.3, com a frente real dos dois (`-global_basis.z`).
  - Se os dois estiverem de costas um para o outro, vale `SURPRISE`, como no protótipo.
  - `backstab_angle_deg` com padrão 60°; vai para o `BattleConfigData` na G3-01.
- **Testes:** pelo menos 8 casos: costas exatas; limites de 150° e 149°; frente a frente; de lado; os dois de costas;
  inimigo girado (prova que D3 acabou).
- **Commit:** `refactor(3d): [G2-04] EncounterMath puro e testado`

#### G2-05 · `BattleContext` e fluxo campo → batalha → campo

- **Objetivo:** a batalha usar o encontro tocado e devolver a party ao ponto certo (D6).
- **Depende de:** G2-04
- **Arquivos:**
  - novos `scripts/core/battle/battle_context.gd` e `battle_result.gd`;
  - `scripts/autoload/game_state.gd`, `scripts/autoload/event_bus.gd`, `scripts/autoload/scene_manager.gd`;
  - `field_enemy_3d.gd`, `field_map_3d.gd`;
  - `scripts/battle_3d/battle_3d.gd` (só entrada e saída; o monólito fica até a G4-02);
  - nova `scenes/ui/game_over.tscn`; `debug_console.gd`; cenários de debug;
  - novo `tests/integration/test_field_battle_flow.gd`.
- **Aceite:**
  - Fluxo do §4.5: o contexto é gravado antes da troca de cena; a batalha monta os inimigos da `EncounterData`
    (fim do Slime + Golem fixo) e aplica a vantagem.
  - Sinal novo `EventBus.battle_finished(result: BattleResult)`, emitido pelo `battle_3d.gd` no fim da luta.
    `SceneManager.return_to_field(context)` trata os três resultados.
  - Vitória: volta ao mapa na posição e yaw salvos; o inimigo some até a party sair do mapa (`field_state`).
  - Resultado `escaped`: 2 s de invulnerabilidade (contatos ignorados, party piscando). O comando Fugir entra na G4-02.
  - Derrota: game over com "Continuar" (último save) e "Título"; substitui o painel provisório da G0-06 (D9, D23).
  - `GameState.encounter_type` removido; `field_encounter_started(encounter_id, advantage)`.
  - `battle3d <encounter_id>` no console; cenários de debug usam `battle.encounter_id`.
- **Testes:** integração com `BattleResult` simulado para vitória, fuga e derrota; contexto limpo no fim.
- **Commit:** `feat(3d): [G2-05] BattleContext e fluxo campo-batalha-campo`

#### G2-06 · Relatório G2

- **Depende de:** G2-01…G2-05
- **Aceite:** relatório do §1.6. O roteiro cobre:
  - tocar um inimigo pelas costas (surpresa) e ser pego pelas costas (emboscada);
  - vencer (o inimigo some), sair e voltar ao mapa (o inimigo volta);
  - perder.

  **Parar** para revisão.
- **Commit:** `docs: [G2-06] relatório do G2`

### 8.5 G3 · Núcleo Grandia (lógica pura)

#### G3-01 · `BattleConfigData` + campos de IP em `SkillData`

- **Objetivo:** todas as constantes do combate em dados (parte de D7).
- **Depende de:** G2-06 `OK`
- **Arquivos:** novos `scripts/data/battle_config_data.gd` e `data/battle/battle_config.tres`; `scripts/data/skill_data.gd`;
  `data/skills/*.tres`; `battle_3d.gd`; `encounter_math.gd`; `scripts/world_3d/field_enemy_3d.gd`; `data_validator.gd`;
  novo `tests/unit/test_battle_config.gd`.
- **Aceite:**
  - Todas as linhas da tabela do §5.4, menos a IA (G3-05), com os valores atuais. O `field_enemy_3d.gd` lê o
    `backstab_angle_deg` do config.
  - `SkillData` com os campos de IP do §4.4; `can_cancel` ligado só nas habilidades que devem cancelar.
  - `battle_3d.gd` sem constantes de regra; habilidades vêm das `SkillData` de `data/skills/` (fim dos nomes fixos).
    O jogo se comporta igual, exceto que só as habilidades com `can_cancel` cancelam (D19).
- **Testes:** o `.tres` carrega; o validador acusa valores fora da faixa (por exemplo, `com_point` fora de 0–1).
- **Commit:** `refactor(battle): [G3-01] BattleConfigData e campos de IP em SkillData`

#### G3-02 · `CombatantState`

- **Objetivo:** um estado de combatente tipado, montado só a partir de dados.
- **Depende de:** G3-01
- **Arquivos:** novos `scripts/core/battle/combatant_state.gd` e `tests/unit/core/test_combatant_state.gd`;
  `git mv scripts/battle/battle_formulas.gd scripts/core/battle/battle_formulas.gd` (e o `.uid` junto);
  `tests/unit/test_battle_formulas.gd`.
- **Aceite:**
  - `RefCounted` com: id, nome, lado, atributos efetivos, HP/MP/SP, IP, fase (`WAIT`, `COM`, `ACT`, `EXECUTE`),
    ação escolhida, posição (`Vector3`), `defending` e `airborne`.
  - Fábricas `from_party_member(data: CharacterData, member_state: Dictionary, effective_stats: Dictionary)` e
    `from_enemy(data: EnemyData)`. Quem lê o `PartyManager` é o controlador (G4-02), nunca o núcleo (§7.1).
  - Fim de SPD e MAG fixos (D7).
  - `BattleFormulas` vai para `scripts/core/battle/`; o 2D continua funcionando pelo `class_name` (usado em `battle_manager.gd`,
    `battle_simulator.gd` e `test_battle_formulas.gd`, sem preload por caminho).
  - `calculate_damage` ganha o parâmetro opcional `action_multiplier: float = 1.0` no fim; o padrão deixa o 2D igual.
    O Crítico do Grandia é uma ação (`critical_multiplier` do config), não o crítico sorteado do 2D (`CRITICAL_MULTIPLIER`).
  - Dano sempre pelo `BattleFormulas.calculate_damage`, com o multiplicador da ação.
- **Testes:** mudar o `.tres` de teste muda o estado; o dano bate com o `BattleFormulas`; os testes do `BattleFormulas`
  continuam verdes depois do `git mv`.
- **Commit:** `feat(battle): [G3-02] CombatantState a partir de dados`

#### G3-03 · `IPTimeline`

- **Objetivo:** a linha do tempo Grandia como lógica pura, com fila de execução (D10).
- **Depende de:** G3-02
- **Arquivos:** novos `scripts/core/battle/ip_timeline.gd` e `tests/unit/core/test_ip_timeline.gd`.
- **Aceite:**
  - Regras 1–5 do §5.4 (a regra 6, redirecionar o alvo, é da G3-04).
  - `advance(delta)`; sinais `command_ready` e `action_ready`. Empates no COM viram fila: um `command_ready` por vez (D21).
  - Pausa no COM da party (modo Wait) e durante a execução (`pause_during_execution`, configurável).
  - `apply_advantage(advantage)`; `cancel(target, push)` só em ACT.
  - RNG com semente injetável (determinístico).
- **Testes:**
  - ordem de ação pelo SPD; pausa no COM; cancel fora de ACT não faz nada;
  - na surpresa a party age primeiro; dois heróis com o mesmo SPD recebem o menu um depois do outro;
  - 1.000 ticks sem ninguém pular o COM.
- **Commit:** `feat(battle): [G3-03] IPTimeline pura com fila de execução`

#### G3-04 · `ActionResolver`

- **Objetivo:** todas as ações num lugar só, testáveis sem cena (D8, D9).
- **Depende de:** G3-03
- **Arquivos:** novos `scripts/core/battle/action_resolver.gd`, `scripts/core/battle/action_outcome.gd` e
  `tests/unit/core/test_action_resolver.gd`; `scripts/core/battle/battle_formulas.gd` (`escape_chance`).
- **Aceite:**
  - Ações (o comportamento D19 do protótipo **não** é preservado):
    - Combo (só empurra a IP, nunca cancela), Crítico/Cancel;
    - Aerial: o parceiro é do mesmo lado de quem lançou e nunca o alvo (D22);
    - Habilidade: gasta MP/SP, cancela só com `can_cancel`, área por `aoe_shape` e distância real;
    - Item: recebe o `ItemData` e devolve o gasto em `items_consumed` (quem mexe no `InventoryManager` é o controlador);
    - Defender ×0,5 até o próximo COM;
    - Mover/Evadir: destino num raio em torno do próprio herói, longe dos inimigos (D30);
    - Fugir: `BattleFormulas.escape_chance(...) -> float` (nova, pura), sorteada com o RNG injetado; se falhar, IP 0.
      A `calculate_escape_chance` antiga fica para o 2D.
  - Regra 6: se o alvo morrer, o golpe vai para o inimigo vivo mais próximo.
  - Devolve um `ActionOutcome` (`RefCounted`): `damages` (`target_id`, `amount`, `is_critical`, `is_weakness`), `heals`,
    `cancels`, `ip_changes`, `moves`, `costs`, `items_consumed`, `escaped` e `text_keys`. Sem nós e sem autoloads.
- **Testes:** um por ação, mais bordas: alvo morto, cancel fora de ACT, MP insuficiente, Combo que não cancela, Habilidade
  sem `can_cancel`, Aerial sem parceiro válido, Fugir com semente fixa.
- **Commit:** `feat(battle): [G3-04] ActionResolver com todas as ações Grandia`

#### G3-05 · `BattleAI` por dados

- **Objetivo:** IA de inimigos descrita em dados, com fases de chefe.
- **Depende de:** G3-04
- **Arquivos:** novos `scripts/data/ai_rule_data.gd`, `scripts/core/battle/battle_ai.gd`, `data/ai/*.tres` e
  `tests/unit/core/test_battle_ai.gd`; `EnemyData.ai_rules`.
- **Aceite:**
  - Regras do §4.4, avaliadas em ordem e sorteadas por peso.
  - Sem regras: comportamento atual (30% Crítico, alvo aleatório).
  - Golem com fase abaixo de 50% de HP.
- **Testes:** cada condição; com a mesma semente, a mesma escolha.
- **Commit:** `feat(battle): [G3-05] IA de batalha por AIRuleData`

#### G3-06 · Simulador de balanceamento com IP

- **Objetivo:** números para ajustar o combate sem jogar centenas de lutas.
- **Depende de:** G3-05
- **Arquivos:** `scripts/tools/run_battle_simulation.gd`, `scripts/tools/export_balance_csv.gd`,
  `data/balance/ip_simulation.csv` (+ `.import` com `importer="keep"`), §7.6.
- **Aceite:**
  - N batalhas em headless, só com o núcleo: party × cada encontro, níveis 1–10.
  - CSV com: % de vitória, turnos médios, duração em segundos de jogo, dano médio por ação e cancels por batalha.
  - O CSV compara Combo × Crítico (dano por segundo de jogo e cancels) e o custo × benefício da Evasão (D30), para a G3-07
    propor os valores.
- **Testes:** com semente fixa, o resultado é idêntico entre execuções.
- **Commit:** `feat(tools): [G3-06] simulador de balanceamento com IP`

#### G3-07 · Relatório G3

- **Depende de:** G3-01…G3-06
- **Aceite:** relatório do §1.6 com a tabela "valor atual × proposto × motivo", baseada no CSV, para validarmos juntos (J1).
  **Parar** para revisão.
- **Commit:** `docs: [G3-07] relatório do G3`

### 8.6 G4 · Arena de combate 3D

#### G4-01 · Arena e `Combatant3D`

- **Objetivo:** arena 3D com modelos que andam, atacam e reagem.
- **Depende de:** G3-07 `OK`
- **Arquivos:** nova `scenes/battle_3d/arenas/kakariko_field.tscn` (escolhida por `EncounterData.arena_scene`);
  novos `scripts/battle_3d/combatant_3d.gd` + cena e `tests/unit/test_combatant_3d.gd`.
- **Aceite:**
  - `Combatant3D` liga um `CombatantState` a um `CharacterModel3D`: `move_to(pos)`, `play_action(anim)` com sinal `impact`
    no quadro do golpe, reação a dano, KO e marcador de alvo.
  - Formação inicial da `EncounterData` e da party.
  - Flash de dano pelo `flash_amount` do toon.
- **Testes:** `move_to` termina na posição; `impact` é emitido.
- **Commit:** `feat(battle): [G4-01] arena 3D e Combatant3D`

#### G4-02 · `BattleController3D` substitui o monólito

- **Objetivo:** a cena de batalha só orquestra o núcleo, com paridade com o protótipo.
- **Depende de:** G4-01
- **Arquivos:** novo `scripts/battle_3d/battle_controller_3d.gd`; `scenes/battle_3d/battle_3d.tscn`; remover
  `scripts/battle_3d/battle_3d.gd`; novo `tests/integration/test_battle_3d_flow.gd`.
- **Aceite:**
  - Monta os combatentes pelo `BattleContext`; a party vem de `PartyManager.active_members`, com o estado de cada membro
    (D6). `IPTimeline`, `ActionResolver` e `BattleAI` conduzem a luta.
  - O controlador aplica cada `ActionOutcome` nos nós e autoloads (por exemplo, tira os `items_consumed` do `InventoryManager`)
    e emite `EventBus.battle_finished(result: BattleResult)` no fim, como o protótipo desde a G2-05.
  - A fila executa uma ação por vez, com animação e dano no `impact`.
  - Todos os comandos: Combo, Crítico, Habilidade, Item, Defender, Mover/Evadir e Fugir, além do Aerial.
  - Nenhum dado de jogo no controlador; ≤ 400 linhas.
  - Fecha no jogo as dívidas de combate do protótipo: D7, D8, D9 (Item, Fugir e MP), D10, D19 e D21.
- **Testes:** batalha completa com IA dos dois lados (party em modo automático de teste) termina sem erro.
- **Commit:** `refactor(battle): [G4-02] BattleController3D sobre o núcleo puro`

#### G4-03 · Câmera de batalha

- **Objetivo:** câmera que mostra quem age e valoriza Crítico, Cancel e Aerial.
- **Depende de:** G4-02
- **Arquivos:** novo `scripts/battle_3d/battle_camera_3d.gd`.
- **Aceite:**
  - Plano geral na espera; foco em quem está em COM; acompanha o atacante na execução.
  - Ângulo especial em Crítico, Cancel e Aerial.
  - Transições de até 0,4 s; opção de câmera fixa (`@export var dynamic`).
- **Testes:** troca de alvo da câmera por sinal da timeline.
- **Commit:** `feat(battle): [G4-03] câmera de batalha dinâmica`

#### G4-04 · UI de batalha

- **Objetivo:** barra IP, painel da party e comandos jogáveis por teclado e gamepad.
- **Depende de:** G4-02
- **Arquivos:** novos `scripts/battle_3d/ui/{ip_gauge,command_menu,party_panel}.gd` e cenas.
- **Aceite:**
  - Barra IP com os ícones e cores de `ip_marker_*`, linha COM e fase atual. Os marcadores são criados uma vez e só
    reposicionados a cada quadro (D29).
  - Painel com HP, MP e SP.
  - Menu de comandos e submenus (habilidades, itens) com foco visível; tema HD; textos via `Localization`.
  - Mouse visível durante a batalha; o primeiro comando recebe o foco sempre que o menu abre (D24).
- **Testes:** navegação por ações do Input Map (GUT `InputSender`).
- **Commit:** `feat(battle): [G4-04] UI de batalha com foco por teclado e gamepad`

#### G4-05 · Alvo 3D + prévia de área

- **Objetivo:** escolher alvos e posições na arena de forma clara.
- **Depende de:** G4-04
- **Arquivos:** novo `scripts/battle_3d/ui/target_selector_3d.gd` + cena.
- **Aceite:**
  - Troca de alvo pela ordem na tela (esquerda/direita), com marcador sobre o alvo.
  - Prévia da área no chão conforme `aoe_shape`, destacando quem será atingido.
  - Mover/Evadir escolhe um ponto dentro de `move_radius`.
- **Testes:** ordem dos alvos pela posição na tela; alvos dentro da área.
- **Commit:** `feat(battle): [G4-05] seleção de alvo 3D e prévia de área`

#### G4-06 · Feedback

- **Objetivo:** cada golpe ser legível e ter impacto.
- **Depende de:** G4-02, G4-03
- **Arquivos:** `scripts/battle_3d/` (efeitos), `scenes/battle_3d/fx/`.
- **Aceite:**
  - Números de dano e cura (`Label3D` com tween) e banners COMBO, CRÍTICO, CANCEL e AERIAL.
  - Flash toon; `CPUParticles3D` por elemento; tremor de câmera no Crítico; efeitos via `AudioManager.play_sfx`, trocando os
    bipes gerados por sons CC0 em `assets/audio/sfx/` (D33), creditados no `docs/CREDITS.md`.
- **Testes:** smoke; capturas no relatório.
- **Commit:** `feat(battle): [G4-06] feedback de combate`

#### G4-07 · Fim de batalha, recompensas e integrações

- **Objetivo:** a batalha ter consequência no jogo (D9).
- **Depende de:** G4-02
- **Arquivos:** `battle_controller_3d.gd`, nova tela de resultados, `party_manager.gd`, `inventory_manager.gd`,
  `quest_manager.gd`, novo `tests/integration/test_battle_rewards.gd`.
- **Aceite:**
  - Vitória: XP, ouro e drops do `EnemyData`, subida de nível com mensagem, quests de derrotar atualizadas e tela de resultados.
  - Derrota e fuga seguem o fluxo da G2-05.
  - `PartyManager`, `InventoryManager` e `QuestManager` escutam o `EventBus.battle_finished(result: BattleResult)` criado na
    G2-05 (nenhum sinal novo): aplicam XP, ouro e drops e gravam HP, MP e SP da party.
- **Testes:** as recompensas batem com o `EnemyData`; o nível sobe ao passar do XP necessário.
- **Commit:** `feat(battle): [G4-07] recompensas, resultados e integrações`

#### G4-08 · Playthrough automatizado

- **Objetivo:** um teste que joga o fluxo principal sozinho.
- **Depende de:** G4-04, G4-05, G4-07
- **Arquivos:** novo `tests/integration/test_playthrough_3d.gd`.
- **Aceite:**
  - GUT `InputSender`: título → Novo Jogo → andar até um inimigo e tocá-lo pelas costas → vencer só com Combo →
    voltar ao campo → salvar → carregar.
  - Roda no `./test.sh` em ≤ 30 s (com `Engine.time_scale` alto).
- **Testes:** o próprio playthrough.
- **Commit:** `test(3d): [G4-08] playthrough automatizado campo-batalha-save`

#### G4-09 · Relatório G4

- **Depende de:** G4-01…G4-08
- **Aceite:** relatório do §1.6 com um checklist de playtest da batalha (cada comando, Cancel, Aerial, área, fuga e derrota).
  **Parar** para revisão.
- **Commit:** `docs: [G4-09] relatório do G4`

### 8.7 G5–G7 (`RASCUNHO`)

O Copilot transforma estes itens em cartões completos depois da G4 (e da sua decisão V4).

- **G5 · Progressão estilo Grandia**
  - G5-01 `[VOCÊ]` escolher o modelo (§5.5).
  - G5-02 implementar o modelo.
  - G5-03 técnicas combinadas Ragg + Calindra na IP.
  - G5-04 UI de progressão.
- **G6 · Vertical slice e remoção do 2D**
  - Casa com tetos que somem.
  - Caverna dos Murmúrios; Câmara do Guardião com o Golem em fases.
  - Quest de Kakariko de ponta a ponta (Tav, mímico, Barnaby).
  - Console de debug 100% 3D (`tp <map_id>`).
  - Remoção do 2D, com README e CHECKLIST atualizados.
  - Builds e desempenho nas 3 plataformas; relatório.
- **G7 · Sabor Grandia e polish**
  - Pontos de acampamento no mapa; jantar com conversas e escolhas (J3).
  - Mapa-múndi com pontos de viagem; marcadores de quest.
  - Cutscenes 3D.
  - Acessibilidade: velocidade de texto, tamanho da fonte, câmera fixa e modo Active/Wait.
  - Ícones de gamepad.

---

## 9. Pendências do usuário

`[VOCÊ]`: só você decide. Até lá, vale o padrão e a tarefa segue.

| # | Pergunta | Padrão até decidir | Afeta |
|---|---|---|---|
| V1 | Aparência final de Ragg e Calindra (referências, cores, roupas) | KayKit Barbarian (Ragg) e Mage (Calindra) | G1-01 |
| V2 | Fonte da UI | Fonte OFL ou CC0 escolhida pelo Agy | G1-10 |
| V3 | Parâmetros do toon (faixas, rim, contorno) | Valores da vitrine da G0-08 | G1-01 em diante |
| V4 | Modelo de progressão (A, B ou C do §5.5) | C (XP atual) | G5 |
| V5 | Manter o Aerial (Grandia III) | Sim | G3-04 |
| V6 | Modo de batalha: Wait (o tempo para no COM da party) ou Active | Wait; Active como opção na G7 | G3-03 |
| V7 | Identidade dos commits do Agy (`cdr-projects-2025`) | Manter; ou configurar `user.name`/`user.email` da sua conta no WSL | Commits |
| V8 | Remover o LFS | Sim (G0-02); vete antes da G0-02 se preferir manter | G0-02 |
| V9 | Estilo e fonte da música e dos sons (hoje não há nenhuma faixa, D33) | Faixas CC0 escolhidas pelo Agy na G1-09; trilha definitiva na G6 | G1-09, G6 |
| V10 | Idiomas e plataformas: confirmar PT-BR + EN e se haverá mobile | PT-BR + EN; Windows, Linux e Web (Web confirmada); sem mobile | G1-05, G6 |

`[JUNTOS]`: você descreve e valida; o Agy implementa.

| # | Tema | Quando |
|---|---|---|
| J1 | Valores de balanceamento da IP | Relatório G3-07 |
| J2 | Roteiro do vertical slice | Antes da G6 |
| J3 | Conversas do acampamento | Antes da G7 |

---

## 10. Histórico de revisões

| Rev. | Data | Autor | Mudança |
|---|---|---|---|
| 0 | M0 | — | Diagrama de autoloads e fluxo de cenas do 2D |
| 1 | 29/09/2026 | Agy | Seção "Estado 3D" (commit `e189cc9`) |
| 2 | 29/09/2026 | Copilot | Reescrita completa: papéis e protocolo, revisão do protótipo (P0 e dívidas D1–D33, incluindo a revisão de código do protótipo), decisões, arquitetura alvo, kit de teste e backlog G0–G7 |
