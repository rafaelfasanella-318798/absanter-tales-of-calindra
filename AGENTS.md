# CLAUDE.md · Absanter – Tales of Calindra

Instruções e diretrizes de desenvolvimento para agentes de IA neste repositório.

## Visão do Projeto

*Absanter – Tales of Calindra* é um RPG clássico estilo JRPG 2D pixel art top-down construído em Godot 4.
- Protagonista: **Ragg**
- Companheira de party: **Calindra** (habilidades próprias, suporte e dinâmica narrativa)

A fonte de verdade do projeto é o arquivo [`CHECKLIST.md`](file:///mnt/c/Users/rafae/absanter%20-%20tales%20of%20calindra/CHECKLIST.md). Sempre consulte-o e marque `[x]` conforme as tarefas forem concluídas.

---

## Tabela de Decisões Fundamentais

| Item | Decisão |
|---|---|
| Engine | Godot 4.x (GDScript) |
| Visual | 2D pixel art top-down (tiles 16x16, estética Chrono Trigger / Stardew Valley) |
| Combate | Turnos clássico JRPG |
| Party principal | Ragg + Calindra jogáveis |
| Idioma principal | PT-BR inicial, suporte a EN via Localization |
| Plataformas alvo | Linux, Windows, Web (HTML5) |
| Resolução base | 320x180 (Pixel Perfect, viewport stretch) |

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
   - Atributos, inimigos, diálogos, itens e mapas devem residir em `data/` (`.tres` ou `.json`).
4. **Comunicação por Sinais**:
   - Utilize o `EventBus` (`scripts/autoload/event_bus.gd`) para desacoplar sistemas grandes.

---

## Scripts Operacionais

| Script | Finalidade | Como executar |
|---|---|---|
| `./run.sh` | Executa o jogo via Godot Linux (requer WSLg ou X11) | `./run.sh` |
| `run.ps1` | Inicia o jogo ou editor no Godot Windows nativo | `powershell.exe -File run.ps1` |
| `./test.sh` | Executa testes unitários com GUT em modo headless | `./test.sh` |
| `./lint.sh` | Executa `gdlint` e `gdformat --check` | `./lint.sh` |
| `./build.sh` | Exporta builds para `export/{linux,windows,web}` | `./build.sh [linux|windows|web]` |

---

## Estrutura de Documentação

- `docs/GDD.md`: Game Design Document (visão do mundo, história, mecânicas).
- `docs/ARCHITECTURE.md`: Diagrama técnico de autoloads e transições de cena.
- `docs/CREDITS.md`: Licenças de assets e fontes CC0/livres.
- `docs/local-ai.md`: Guia de configuração e uso de LLM local (Ollama/Qwen).
- `docs/characters/`: Fichas e descrições narrativas de personagens.
- `docs/RELATORIO-M0.md`: Relatório de entrega do Milestone 0.

---

## Regras de Execução

- Nunca commite o projeto em um estado que impeça sua abertura.
- Sempre rode `./test.sh` e `./lint.sh` antes de finalizar commits de milestones.
- Mantenha comentários existentes e integridade do código.
