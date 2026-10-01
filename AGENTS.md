# AGENTS.md · Absanter – Tales of Calindra

Instruções para agentes de IA neste repositório. **Leia primeiro [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)**:
é a referência única de papéis, protocolo, decisões, arquitetura e backlog.

## Papéis

| Papel | Quem | Resumo |
|---|---|---|
| Decisor | Usuário | Responde `[VOCÊ]` e aprova os milestones (`OK`) |
| Planejador e revisor | Copilot (GitHub Copilot CLI) | Mantém o `docs/ARCHITECTURE.md`, escreve cartões e revisa entregas; não implementa código do jogo, salvo pedido explícito |
| Executor | Agy (Google Antigravity CLI, no WSL) | Executa as tarefas `TODO` do §8 do ARCHITECTURE seguindo o protocolo do §1 |

## Visão do Projeto

*Absanter – Tales of Calindra* é um JRPG **3D estilizado (cel/toon em HD) inspirado em Grandia**, feito em Godot 4.
- Protagonista: **Ragg**
- Companheira de party: **Calindra** (jogável, com habilidades próprias, suporte e dinâmica narrativa)
- O jogo 2D pixel art (M0–M3) fica congelado na tag `v0.3.0-2d` e é removido na G6.

Progresso: [`CHECKLIST.md`](CHECKLIST.md) (itens do jogo; marque `[x]` ao concluir) e §8.1 do ARCHITECTURE (tarefas do pivô 3D).

---

## Tabela de Decisões Fundamentais

| Item | Decisão |
|---|---|
| Engine | Godot 4.7.2 (GDScript), testes com GUT |
| Visual | 3D cel/toon HD; modelos `.glb` CC0 |
| Renderer | Compatibility em todas as plataformas |
| Resolução base | 1280×720, stretch `canvas_items`, aspect `expand` |
| Combate | Grandia: barra IP, Combo × Crítico × Cancel, Aerial, posição na arena |
| Câmera | Rotacionável (giro de 45°, órbita e zoom) |
| Encontros | Inimigos visíveis no mapa; surpresa e emboscada pelo ângulo de contato |
| Party principal | Ragg + Calindra jogáveis |
| Idioma principal | PT-BR inicial, suporte a EN via Localization (assumido; pendência V10 do ARCHITECTURE) |
| Plataformas alvo | Linux, Windows, Web (HTML5); Web confirmada, mobile em aberto (pendência V10) |

Detalhes e estado atual de cada decisão: §3 do ARCHITECTURE.

---

## Convenções de Código e Arquitetura

1. **Nomenclatura**:
   - Arquivos e pastas: `snake_case` (ex.: `save_manager.gd`, `character_data.gd`).
   - Classes e tipos: `PascalCase` (ex.: `class_name CharacterData`).
   - Sinais e métodos: `snake_case` (ex.: `signal quest_updated(quest_id, stage)`).
   - Constantes e enums: `SCREAMING_SNAKE_CASE` / `PascalCase` para o enum.
2. **Reutilização**:
   - Sempre use `class_name` para recursos e nós reutilizáveis.
3. **Desacoplamento de Dados**:
   - **NUNCA** deixe dados de jogo hardcoded no código.
   - Atributos, inimigos, encontros, diálogos, itens, mapas e constantes de regra devem residir em `data/` (`.tres` ou `.json`).
4. **Comunicação por Sinais**:
   - Utilize o `EventBus` (`scripts/autoload/event_bus.gd`) para desacoplar sistemas grandes.
5. **Lógica pura**:
   - Regras (IP, dano, encontros, câmera, migração de save) ficam em `scripts/core/`, sem nós, com testes unitários.
6. **Entrada**:
   - Só ações do Input Map (§3.16 do ARCHITECTURE); nada de `KEY_*`, `JOY_*` ou `get_joy_axis` no código de jogo.
7. **Git**:
   - Todo `.gd` e `.gdshader` novo vai no commit com seu `.uid`.
   - Commits no formato `tipo(3d): [Gx-yy] descrição`.

---

## Scripts Operacionais

| Script | Finalidade | Como executar |
|---|---|---|
| `./run.sh` | Executa o jogo via Godot Linux (requer WSLg ou X11); aceita uma cena | `./run.sh [res://cena.tscn]` |
| `run.ps1` | Executa o jogo pelo Godot Windows nativo | `powershell.exe -File run.ps1` |
| `./test.sh` | Executa testes unitários com GUT em modo headless | `./test.sh` |
| `./lint.sh` | Executa `gdlint` e `gdformat --check` | `./lint.sh` |
| `./build.sh` | Exporta builds para `export/{linux,windows,web}` | `./build.sh [linux|windows|web]` |

Testes no Windows (PowerShell, verificado em 29/09/2026):
`& .\tools\godot-win\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s addons/gut/gut_cmdln.gd -gexit`.
O kit de teste (`verify`, `play`, `capture` e `test.ps1`) chega na G0 (§7.4 do ARCHITECTURE).

---

## Estrutura de Documentação

- `docs/ARCHITECTURE.md`: **referência única** (papéis, protocolo, decisões, arquitetura, kit de teste, backlog e pendências).
- `docs/RELATORIO-Gx.md`: relatórios dos milestones do pivô 3D (escritos pelo Agy).
- `docs/GDD.md`: Game Design Document (visão do mundo, história, mecânicas).
- `docs/CREDITS.md`: Licenças de assets e fontes CC0/livres.
- `docs/local-ai.md`: Guia de configuração e uso de LLM local (Ollama/Qwen).
- `docs/characters/`: Fichas e descrições narrativas de personagens.
- `docs/RELATORIO-M0.md`: Relatório de entrega do Milestone 0 (2D).

---

## Regras de Execução

- Nunca commite o projeto em um estado que impeça sua abertura **num clone limpo**: todo arquivo referenciado vai no mesmo commit.
- Sempre rode `./test.sh` e `./lint.sh` antes de cada commit; a partir da G0-01, rode também `./verify.sh` depois do commit
  e antes do push (§1.3 do ARCHITECTURE).
- O Agy pode fazer push para `origin/main` somente depois do `verify` verde. Nunca reescreva histórico publicado.
- Mantenha comentários existentes e integridade do código.
