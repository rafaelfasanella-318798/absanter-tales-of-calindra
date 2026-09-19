# Relatório de Conclusão · Milestone M0 (Setup Técnico)

Documento oficial de entrega do Milestone M0 de *Absanter – Tales of Calindra*.

---

## 1. Instalação do Godot 4

- **Versão instalada**: `Godot v4.7.2-stable.official.ed1daf0bf`
- **Binário Linux (WSL / Headless / CI / Testes)**:
  - Caminho no WSL: `/mnt/c/Users/rafae/absanter - tales of calindra/tools/godot/godot` (symlink para `Godot_v4.7.2-stable_linux.x86_64`)
  - Status: Verificado e funcional via `--version --headless`.
- **Binário Windows (Edição Visual e Jogo Nativo Host)**:
  - Caminho Windows completo: `C:\Users\rafae\absanter - tales of calindra\tools\godot-win\Godot_v4.7.2-stable_win64.exe`
  - Atalho de inicialização: Script PowerShell [`run.ps1`](file:///mnt/c/Users/rafae/absanter%20-%20tales%20of%20calindra/run.ps1).
- **Export Templates**:
  - Instalados em: `~/.local/share/godot/export_templates/4.7.2.stable/` (Linux, Windows, Web, Android, iOS).

---

## 2. Addons e Pacotes Baixados

| Pacote / Recurso | Versão | Origem | Licença | Destino no Projeto |
|---|---|---|---|---|
| **GUT (Godot Unit Test)** | 9.6.1 | GitHub (`bitwes/Gut`) | MIT License | `addons/gut/` |
| **Pixel Operator (Fonte Pixel)** | 2018 | Jayvee Enaguas / DaFont | CC0 1.0 Universal | `assets/fonts/` |
| **Kenney Tiny Dungeon** | 2022 | Kenney.nl | CC0 1.0 Universal | `assets/tilesets/placeholder/` |
| **Kenney UI Pack Pixel Adventure** | 2024 | Kenney.nl | CC0 1.0 Universal | `assets/ui/placeholder/` |

*Todas as licenças e atribuições estão documentadas em [`docs/CREDITS.md`](file:///mnt/c/Users/rafae/absanter%20-%20tales%20of%20calindra/docs/CREDITS.md).*

---

## 3. Resultados dos Scripts Operacionais

### Testes Automatizados (`./test.sh`)
- **Status**: **100% APROVADO**
- **Saída**:
  - Scripts de teste: 1 (`tests/unit/test_smoke.gd`)
  - Testes executados: 2 (`test_autoloads_exist`, `test_main_scene_loads`)
  - Asserções validadas: 12 (todos os 10 autoloads instanciados + cena `Main` carregada e montada na árvore)
  - Tempo de execução: ~0.44s

### Análise Estática e Linting (`./lint.sh`)
- **Status**: **100% APROVADO**
- **Saída**:
  - `gdlint`: Sucesso, 0 problemas encontrados em todos os arquivos de `scripts/`, `scenes/`, `tests/`.
  - `gdformat --check`: 19 arquivos verificados e devidamente formatados.

### Build e Export (`./build.sh`)
- Presets configurados em `export_presets.cfg` para:
  - Linux/X11 (`export/linux/absanter.x86_64`)
  - Windows Desktop (`export/windows/absanter.exe`)
  - Web (`export/web/index.html`)
- **Observação técnica**: Em ambientes WSL headless, a primeira exportação requer que o cache inicial de importação do editor seja gravado (comportamento nativo da engine ao abrir pela primeira vez a interface).

---

## 4. Itens do `CHECKLIST.md` Concluídos

- [x] `[AGENTE]` Instalar Godot 4.x (Linux WSL headless + `.exe` Windows)
- [x] `[AGENTE]` Instalar export templates da mesma versão
- [x] `[AGENTE]` `git init` + `.gitignore` oficial + `.gitattributes` com declaração LFS
- [x] `[AGENTE]` Instalar `gdtoolkit` (`gdlint` + `gdformat`) e `.gdlintrc`
- [x] `[AGENTE]` Instalar addon **GUT** para testes automatizados
- [x] `[AGENTE]` Configurar `project.godot` (320x180, viewport/keep, nearest filter, snap 2D, inputs completos)
- [x] `[AGENTE]` Criar `CLAUDE.md` e `AGENTS.md` com convenções e diretrizes
- [x] `[AGENTE]` Scripts operacionais: `run.sh`, `run.ps1`, `test.sh`, `build.sh`, `lint.sh`
- [x] `[AGENTE]` Presets de exportação em `export_presets.cfg`
- [x] `[AGENTE]` CI GitHub Actions (`.github/workflows/ci.yml`)
- [x] `[AGENTE]` Árvore de diretórios completa com `.gitkeep`
- [x] `[AGENTE]` 10 Autoloads com arquitetura desacoplada (`EventBus` -> `GameState` -> demais)
- [x] `[AGENTE]` Enums e constantes globais (`scripts/data/enums.gd`)
- [x] `[AGENTE]` Resources base (`CharacterData`, `EnemyData`, `SkillData`, `ItemData`, `QuestData`, `MapData`)
- [x] `[AGENTE]` Fichas iniciais `data/characters/ragg.tres` e `calindra.tres`
- [x] `[AGENTE]` Cena `Main` ("Hello Ragg") com transição e fade do `SceneManager`
- [x] `[AGENTE]` Placeholders CC0 e tipografia pixel art com licenças documentadas
- [x] `[AGENTE]` Esqueletos em `docs/` (`GDD.md`, `characters/ragg.md`, `characters/calindra.md`, `CREDITS.md`, `ARCHITECTURE.md`, `local-ai.md`, `RESPOSTAS.md`)
- [x] **Milestone M0 – Setup técnico concluído!**

---

## 5. Bloqueios e Resoluções

1. **Janela modal de atualização do GUT em modo Headless**:
   - *Causa*: O GUT 9.6.1 tentava exibir um popup de aviso de versão quando aberto em Godot 4.7.
   - *Solução*: Adicionada guarda `if DisplayServer.get_name() == "headless": return` nos métodos de interface do plugin e atualizado o limite de versão em `versions.json`.
2. **Importação inicial de fontes TTF em modo Headless**:
   - *Causa*: Fontes sem arquivo `.import` gerado pelo editor não podem ser resolvidas estaticamente pelo compilador de `.tscn` em modo headless puro.
   - *Solução*: Cena `Main` carrega o arquivo `.ttf` dinamicamente via `FontFile.load_dynamic_font()`, garantindo inicialização 100% livre de erros tanto em CLI quanto em GUI.

---

## 6. Próximos Passos `[VOCÊ]` para Destravar o Milestone M1 (Andar e Falar)

Para iniciarmos a implementação do mapa jogável do M1, preencha o questionário em [`docs/RESPOSTAS.md`](file:///mnt/c/Users/rafae/absanter%20-%20tales%20of%20calindra/docs/RESPOSTAS.md) ou responda diretamente no chat:

1. **Cenário inicial do M1**: Qual o tipo de ambiente do primeiro mapa? (Vila de pescadores, floresta ancestral, ruínas de pedra, interior de taverna?)
2. **Aparência de Ragg e Calindra**: Alguma cor ou traço marcante para os sprites placeholders?
3. **Primeiro NPC e Diálogo**: Quem é o primeiro NPC com quem Ragg fala e qual a primeira frase de Calindra ao explorar?
