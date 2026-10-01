# Relatório G0 · Estabilizar e fundar

## Resumo (3–5 linhas)
O Milestone G0 estabeleceu as fundações técnicas e operacionais completas para o pivô 3D estilizado (cel-shading HD inspirado em Grandia). O repositório foi higienizado com a tag `v0.3.0-2d` e remoção do Git LFS, a suíte de testes unitários e de integração alcançou 138/138 testes passando com zero órfãos e linter 100% verde, o kit de ferramentas operacionais (`verify`, `play`, `capture`) foi implementado, os softlocks do protótipo de combate e câmera foram sanados via bot autônomo, e os shaders toon e contorno com vitrine interativa e export Web foram validados com sucesso.

---

## Tarefas e commits (ID · status · hash · o que mudou)

| ID | Status | Commit | O que mudou |
|---|---|---|---|
| **G0-01** | `DONE` | `b3c3e5e` | Adicionados arquivos 3D e `.uid` ausentes, extraída lógica de UI de combate para `scripts/battle_3d/battle_3d_ui.gd` mantendo arquivos sob 1000 linhas, corrigido lint e criado `verify.sh`/`verify.ps1` com worktree limpa. |
| **G0-02** | `DONE` | `07255b1` | Criada e enviada a tag `v0.3.0-2d`, desativado Git LFS em `.gitattributes`, adicionado `captures/` ao `.gitignore` e ajustado workflow de CI. |
| **G0-03** | `DONE` | `c35ae97` | Configurado `project.godot` com renderer `gl_compatibility`, resolução 1280×720 com stretch `canvas_items` e aspect `expand`, camadas 3D de física e Input Map completo com ações do §3.16 sem teclas hardcoded. |
| **G0-04** | `DONE` | `8d3b374` | Criados scripts `test.ps1`, `play.sh`, `play.ps1`, tarefas do VS Code, hook git `pre-push`, teste de fumaça dinâmico `test_all_scenes_smoke.gd` e resolução de todos os nós órfãos no GUT (zero órfãos). |
| **G0-05** | `DONE` | `314c0c9` | Criado autoload `DebugBoot`, 6 cenários de inicialização em `data/debug/scenarios/`, enum `Advantage` em `scripts/data/enums.gd`, suporte a ações de Input Map e novos comandos (`scenario`, `speed`, `fps`, `encounter`, `restart`) no `debug_console.gd`. |
| **G0-06** | `DONE` | `3c5cdc2` | Correção dos softlocks e pendências D19, D21, D22, D23, D24, D25, D26, D27 e D28; implementação de bot de playtest autônomo `PlaytestBot3D` em `test_playtest_3d_bot.gd` que conclui batalhas reais e exploração; 134 testes passando. |
| **G0-07** | `DONE` | `476d80e` | Implementados `capture.sh` e `capture.ps1` com Movie Maker do Godot (grava 150 quadros @ 30 FPS, extrai início, meio e fim como `01.png`, `02.png`, `03.png` e limpa temporários em ~27 segundos). |
| **G0-08** | `DONE` | `c3dbf4e` | Criados `assets/shaders/toon.gdshader` (cel shading, faixas quantizadas, rim light, shadow color, flash branco de dano, suporte a vertex color), `assets/shaders/outline.gdshader` (extrusão na normal invertida com cull front), 3 materiais `.tres` com contorno em `next_pass`, cena `scenes/dev/toon_showcase.tscn` com luz rotativa e sliders interativos, materiais aplicados aos combatentes do protótipo e 138 testes passando. |
| **G0-09** | `DONE` | `c6f6e91` | Configurado preset Web em `export_presets.cfg` com `variant/thread_support=false` explícito; exportação Web validada via `./build.sh web` gerando `export/web/` com tamanho total de 41 MB (dentro da meta de ≤ 60 MB). |
| **G0-10** | `DOING` | — | Relatório de encerramento do Milestone G0 e reconciliação do `CHECKLIST.md`. |

---

## Verificação (lint · testes N/N · verify em clone limpo · tempo · CI)

- **Lint:** `./lint.sh` 100% verde (`gdlint` sem nenhum erro, `gdformat --check` com 85 arquivos validados).
- **Testes automatizados (GUT):** 28 scripts, 138/138 testes passando (0 falhas, 0 erros, 0 órfãos, 0 warnings no GUT).
- **Verificação em worktree limpa (`verify.sh`):**
  - Tempo total: **28 segundos**.
  - Etapas executadas: checkout em worktree temporária em `/tmp`, reimportação de assets pelo Godot, lint completo, execução de 138 testes GUT em modo headless, e smoke test com janela aberta das 4 cenas principais (`main.tscn`, `kakariko_3d.tscn`, `battle_3d.tscn`, `camp_3d.tscn`).
  - Resultado: **SUCESSO - Apta para push**.
- **CI / Git:** Commits com UIDs sincronizados, branch `main` em dia com `origin/main`.

---

## Como testar em 5 minutos (comandos play/cenários e o que observar)

1. **Vitrine do Shader Toon (G0-08):**
   ```bash
   ./play.sh showcase
   ```
   *O que observar:* Uma luz direcional gira suavemente ao redor dos modelos (chão, esfera, cápsula, Ragg estilizado e Slime). O painel à esquerda permite arrastar os sliders com o mouse para alterar bandas (1 a 6), suavidade (0.00 a 0.50), intensidade de rim light (0.0 a 1.0) e espessura do contorno preto.
2. **Exploração e Interação em Kakariko 3D:**
   ```bash
   ./play.sh kakariko
   ```
   *O que observar:* Câmera com SpringArm corrigido (nunca atravessa o chão, mantém elevação positiva acima da cabeça do líder). Ragg e Tav usam os materiais toon com contorno. Interagir com Tav abrindo diálogo e fechando com Espaço/Enter não trava o personagem. Pressionar `F12` abre o console com comandos novos (`scenario`, `fps`, `speed 2`).
3. **Batalha 3D Grandia com Vantagem Tática:**
   ```bash
   ./play.sh battle --scenario=batalha_surpresa
   ```
   *O que observar:* Banner "SURPRESA! Party tem vantagem na barra IP!" aparece no início. Ragg e Calindra iniciam perto da zona COM. Dois heróis alcançando COM no mesmo quadro não travam o jogo (entram na fila sequencial). O botão "Combo" não cancela a ação dos inimigos (apenas empurra IP e gera SP). O botão "Crítico" cancela alvos em ACT e lança Aerial se Calindra tiver SP ≥ 30. Derrota exibe painel com "Tentar de novo" e "Título".
4. **Verificação Completa de Integridade:**
   ```bash
   ./verify.sh
   ```
   *O que observar:* Passa em ~28 segundos em clone limpo sem dependência de estado local.

---

## Capturas (arquivos em captures/, gerados pelo capture)

Geradas em ~36 segundos via `./capture.sh all` (Movie Maker headless com gravação de 150 quadros @ 30 FPS):
- `captures/title/{01,02,03}.png`: Tela de título com menu de navegação.
- `captures/kakariko/{01,02,03}.png`: Vila Kakariko 3D, casas, caminho, Tav NPC e portal de batalha.
- `captures/battle/{01,02,03}.png`: Arena de combate estilo Grandia, timeline IP com marcadores de Ragg, Calindra, Slime e Golem, menu de comandos e banners de ação.
- `captures/camp/{01,02,03}.png`: Acampamento noturno 3D com fogueira acesa, Ragg e Calindra sentados e sistema de diálogo.
- `captures/showcase/{01,02,03}.png`: Vitrine do shader toon demonstrando cel-shading com contorno e painel de ajuste.

---

## Assets adicionados (nome · pacote · licença · link)

Nenhum asset externo proprietário foi adicionado neste milestone.
Foram criados e mantidos no repositório:
- Shaders de autoria própria: `assets/shaders/toon.gdshader` e `assets/shaders/outline.gdshader`.
- Materiais derivados: `assets/materials/toon_character.tres`, `toon_enemy.tres`, `toon_environment.tres`.

---

## Itens do CHECKLIST marcados

- `Protótipo 3D do Agy`: D19 (Combo não cancela), D21 (fila COM multi-herói), D22 (filtro parceiro Aerial), D23 (painel de derrota), D24 (liberação de mouse/foco), D25 (pitch e elevação de câmera), D26 (trava de movimento desacoplada do diálogo), D27 (nomes de trilha de áudio), D28 (ordem de setup do banner de encontro).
- Seção 18 (`Build e distribuição`): Marcado export Web HTML5 com suporte a no-threads.
- Seção 19 (`Marketing`): Marcada captura automática de telas por milestone via Movie Maker.
- Seção 20 (`Roadmap por milestones`): Registrada a conclusão do Milestone G0 (Estabilizar e fundar o 3D).

---

## Bloqueios e riscos

- **Export Templates:** Os templates 4.7.2.stable para Web (`web_nothreads_release.zip`) estão instalados localmente e o build Web gera 41 MB perfeitamente.
- **Risco de Linhas por Arquivo:** `battle_3d.gd` está com 984 linhas (limite 1000). A migração das regras de combate para `scripts/core/` (prevista para os milestones G3 e G4) desacoplará a lógica pura de combate da cena 3D, reduzindo consideravelmente a complexidade do arquivo.

---

## Propostas (mudanças sugeridas ao plano)

1. **Parâmetros Toon na Vitrine:** Sugerimos manter os valores padrão calibrados na vitrine: `bands = 3`, `band_softness = 0.05`, `rim_strength = 0.30`, `outline_width = 0.020`. Apresentam excelente legibilidade visual sem artefatos no Compatibility renderer.
2. **Próximo Passo (G1):** O Milestone G1 iniciará a exploração 3D propriamente dita, com a introdução dos modelos CC0 de Ragg e Calindra (`CharacterModel3D`), novo `CameraRig3D` com rotação em 45°/órbita e movimento relativo à câmera.

---

## Pendências [VOCÊ]

O Milestone G0 está 100% concluído, verificado e enviado para `origin/main`.
Por favor, valide as entregas e responda com a aprovação:

**Aprovado o G0? (OK para iniciar o G1)**
