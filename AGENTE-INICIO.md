# AGENTE-INICIO.md · Roteiro do milestone M0

Documento de execução para o agente de código (Claude Code, OpenCode, Cline ou equivalente).

**Missão:** montar o esqueleto técnico do RPG *Absanter – Tales of Calindra* em Godot 4, até o jogo abrir numa cena "Hello Ragg" e a suíte de testes passar. Nada de lore, arte própria ou decisão de design entra aqui.

**Ambiente:**

- WSL2 Ubuntu, projeto em `/mnt/c/Users/rafae/absanter - tales of calindra/`
- Windows 11 no host, com Git, GitHub CLI e VS Code já instalados
- Godot ainda **não** instalado, em lugar nenhum
- CPU Ryzen 7 9800X3D, GPU RTX 3070 8 GB, ~83 GB livres no disco C:

**Regras de execução:**

1. Ler `CHECKLIST.md` antes de começar. Ele é a fonte de verdade do projeto.
2. Marcar `[x]` no `CHECKLIST.md` em cada item concluído, conforme avança.
3. Nunca deixar o projeto num estado que não abre. Commitar só com o jogo funcionando.
4. Não perguntar nada ao usuário durante a execução. Se algo bloquear, registrar no relatório e seguir para o próximo passo.
5. Ao final, escrever `docs/RELATORIO-M0.md` (formato no fim deste arquivo).

---

## Passos

### 1. Godot 4 para Linux (WSL, headless e testes)

Baixar a última estável 4.x de `github.com/godotengine/godot/releases` (build `linux.x86_64`, não o `mono`) para `tools/godot/`, descompactar, `chmod +x`, criar symlink `tools/godot/godot` apontando para o binário versionado.

Verificar:

```bash
tools/godot/godot --version --headless
```

Baixar também os **export templates** (`.tpz`) da mesma versão e descompactar em `~/.local/share/godot/export_templates/<versão>/`.

### 2. Godot 4 para Windows (edição visual pelo usuário)

Baixar o `.exe` da **mesma versão** para `tools/godot-win/` e registrar o caminho Windows completo no relatório. Não instalar nada no Windows além de copiar o arquivo.

### 3. Git

`git init`. Criar `.gitignore` oficial de Godot 4 incluindo `.godot/`, `export/`, `tools/godot*/`. Criar `.gitattributes` declarando LFS para `*.png *.ogg *.wav *.ttf` (rodar `git lfs install` se disponível; se não, só deixar declarado e anotar no relatório). Primeiro commit.

### 4. Ferramentas Python

```bash
pip install --user gdtoolkit
```

Criar `.gdlintrc` padrão. Criar `.pre-commit-config.yaml` se `pre-commit` estiver disponível; caso contrário, apenas documentar em `docs/ARCHITECTURE.md` como rodar manualmente.

### 5. Árvore de pastas

Criar exatamente:

```
scenes/{main,world,battle,ui}
scripts/{autoload,world,battle,ui,data}
data/{characters,enemies,skills,items,quests,dialogues,maps}
assets/{sprites,tilesets,audio/music,audio/sfx,fonts,ui}
addons/
tests/{unit,integration}
docs/
tools/
export/
```

Colocar `.gitkeep` nas pastas vazias.

### 6. `project.godot`

- Nome: `Absanter – Tales of Calindra`
- `run/main_scene = res://scenes/main/main.tscn`
- Viewport base 320x180
- `window/stretch/mode = viewport`, `stretch/aspect = keep`
- `textures/canvas_textures/default_texture_filter = 0` (nearest)
- `rendering/2d/snap/snap_2d_transforms_to_pixel = true` e `snap_2d_vertices_to_pixel = true`
- Input map: `move_up`, `move_down`, `move_left`, `move_right`, `interact`, `cancel`, `menu`, mapeados para WASD + setas + gamepad

### 7. Autoloads

Em `scripts/autoload/`, um arquivo por singleton, cada um com `class_name`, `extends Node`, docstring e sinais mínimos. **Sem lógica de jogo.**

`GameState`, `SaveManager`, `AudioManager`, `SceneManager`, `EventBus`, `DialogueManager`, `QuestManager`, `InventoryManager`, `PartyManager`, `Localization`.

Registrar todos em `project.godot` na ordem: `EventBus` → `GameState` → os demais.

### 8. Enums e constantes

`scripts/data/enums.gd` com `Element`, `StatusEffect`, `ItemType`, `Direction`, `BattleState`. Apenas nomes genéricos, sem valores de jogo.

### 9. Resources base

Em `scripts/data/`: `CharacterData`, `EnemyData`, `SkillData`, `ItemData`, `QuestData`, `MapData`, todos `extends Resource` com `@export` dos campos óbvios e **sem números**.

Criar `data/characters/ragg.tres` e `data/characters/calindra.tres` apenas com o campo de nome preenchido.

### 10. Cena `Main`

`scenes/main/main.tscn`: fundo preto, `Label` centralizado com "Hello Ragg" em fonte pixel, e `SceneManager` funcional fazendo troca de cena com fade preto.

Baixar uma fonte pixel livre (m5x7 ou Pixel Operator, licença CC0 ou OFL) para `assets/fonts/` e registrar a licença em `docs/CREDITS.md`.

### 11. Addon GUT

Clonar a última release compatível com Godot 4 em `addons/gut/`, ativar em `project.godot`, criar `.gutconfig.json` e `tests/unit/test_smoke.gd` que asserta que todos os autoloads existem e que `Main` carrega.

### 12. Placeholders CC0

Baixar 1 pack Kenney compatível com top-down 16x16 (Tiny Town, Tiny Dungeon ou RPG Urban) para `assets/tilesets/placeholder/` e 1 pack de UI para `assets/ui/placeholder/`. Registrar licenças em `docs/CREDITS.md`. Configurar import como nearest e sem mipmaps.

### 13. Scripts de operação (raiz do projeto)

| Script | Função |
|---|---|
| `run.sh` | Roda o jogo pelo Godot Linux. Anotar no cabeçalho que precisa de WSLg ou servidor X para abrir janela |
| `run.ps1` | Abre o projeto com o `.exe` Windows de `tools/godot-win/` |
| `test.sh` | `godot --headless -s addons/gut/gut_cmdln.gd -gexit` |
| `build.sh` | Exporta Windows, Linux e Web para `export/` usando os presets |
| `lint.sh` | `gdlint` + `gdformat --check` |

### 14. `export_presets.cfg`

Presets para Windows Desktop, Linux/X11 e Web, com saída em `export/<plataforma>/`.

### 15. `CLAUDE.md` e `AGENTS.md`

`CLAUDE.md` na raiz com: visão do projeto, tabela de decisões (copiada do `CHECKLIST.md`), convenções (snake_case em arquivos, PascalCase em classes, `class_name` em tudo reutilizável, dados nunca hardcoded), como rodar cada script de operação, onde ficam os docs, e a regra "ler `CHECKLIST.md` e marcar itens concluídos".

Copiar o mesmo conteúdo para `AGENTS.md`, para uso pela IA local.

### 16. Esqueletos em `docs/`

- `GDD.md` com os títulos de seção da seção 3 do checklist e corpo vazio
- `characters/ragg.md` e `characters/calindra.md`, esqueletos
- `CREDITS.md` com os assets já baixados
- `ARCHITECTURE.md` com diagrama em texto dos autoloads e do fluxo de cena
- `local-ai.md`, esqueleto para a seção 1b do checklist

### 17. CI (opcional)

`.github/workflows/ci.yml` rodando lint + GUT headless, via action `chickensoft-games/setup-godot` ou download direto. Só criar o arquivo; não exige repositório remoto.

### 18. Verificação final obrigatória

```bash
tools/godot/godot --headless --quit   # sem erros
./test.sh                              # passando
./lint.sh                              # limpo
./build.sh                             # gera ao menos o export Linux
git status                             # limpo após o commit
```

Commit final: `M0: esqueleto do projeto`.

---

## O que NÃO fazer

- **Não inventar lore.** Nomes de lugares, stats, habilidades, aparência de Ragg e Calindra são todos `[VOCÊ]` no checklist.
- **Não instalar nada no Windows** além de copiar o `.exe` do Godot. Nada de Ollama, modelos de IA ou ComfyUI.
- **Não instalar Dialogic, LDtk ou Tiled ainda.** Dependem de decisão `[JUNTOS]` das seções 1 e 9 do checklist.
- **Não criar arte própria.** Só placeholders CC0 com licença registrada.
- **Não perguntar ao usuário durante a execução.** Se um download falhar, documentar no relatório e seguir.

---

## Relatório ao terminar

Escrever `docs/RELATORIO-M0.md` com:

1. Versão do Godot instalada e caminhos completos (Linux no WSL e `.exe` no Windows)
2. Lista de addons e pacotes baixados, com versão e licença
3. Resultado de `test.sh`, `lint.sh` e `build.sh`
4. Itens do `CHECKLIST.md` marcados nesta sessão
5. O que ficou bloqueado e por quê
6. Os próximos itens `[VOCÊ]` que destravam o M1
