# Relatório de Conclusão · Milestone M1 (Andar, Falar e Baú Mímico)

Documento oficial de entrega do Milestone M1 de *Absanter – Tales of Calindra*.

---

## 1. Visão Geral da Entrega

O Milestone M1 implementa o ciclo fundamental de exploração top-down e narrativa interativa (Walk and Talk), integrando diretamente os requisitos de mundo e narrativa:
- **Vila Kakariko**: Mapa exterior da vila com casas, caminhos, limites de câmera e marcadores de spawn.
- **Interior da Casa de Tav**: Mapa interior conectado via portas de transição com fade out/in.
- **NPC Tav**: Habitante de Kakariko que alerta sobre o perigo na vila e reage após o mímico ser eliminado.
- **Baú Mímico**: Baú suspeito que se revela um monstro ao ser interagido, requer combate/derrota, e recompensa os heróis com a **Lâmina de Kakariko** (`lamina_kakariko`) e 50 moedas de ouro.
- **Companheira Calindra**: Seguidora que acompanha Ragg em conga-line fluida baseada no rastro de posições (`position_history`).
- **HUD & Diálogos**: Interface completa com retrato, tags de orador, efeito de máquina de escrever, notificações de itens e rastreador de ouro.
- **Persistência Completa**: Save/load funcional em JSON com restauração total de flags, inventário, ouro e posições.

---

## 2. Componentes e Sistemas Implementados

### 2.1. Controle do Jogador (`scripts/world/player.gd`, `scenes/world/player.tscn`)
- Movimentação top-down em 4 direções com `CharacterBody2D` e colisão circular.
- Sistema de mira de interação com `RayCast2D` alinhado à direção para a qual o personagem está olhando.
- Gravação de histórico de passos (`RECORD_STEP_DISTANCE = 10.0`) para sincronização com companheiros de equipe.
- Trava de movimento (`is_movement_locked`) acionada automaticamente durante diálogos e transições.

### 2.2. Seguidora Calindra (`scripts/world/follower.gd`, `scenes/world/follower.tscn`)
- Companheira com sprite dedicado que segue o protagonista em "conga-line" suave.
- Amostragem dinâmica do histórico de posições do jogador (`follow_distance_steps = 5`).
- Detecção e orientação automática do sprite (`facing_direction`).

### 2.3. Sistema de Diálogo e Caixa de Diálogo (`scripts/ui/dialogue_box.gd`, `scenes/ui/dialogue_box.tscn`)
- Layout estilizado para resolução base 320x180 com NinePatch de madeira e fonte pixel.
- Retratos dinâmicos de Ragg, Calindra, Tav e Mímico carregados em tempo de execução via `TextureLoader`.
- Suporte a sequências encadeadas de diálogos com eventos de finalização emitidos no `EventBus`.

### 2.4. NPC Tav (`scripts/world/npc.gd`, `scenes/world/npc.tscn`)
- Diálogo dinâmico condicionado ao estado do mundo (`GameState.flags`):
  - **Antes de derrotar o mímico**: Alerta Ragg e Calindra para não tocarem no baú estranho perto da cerca da vila.
  - **Após derrotar o mímico**: Agradece e elogia a coragem de Ragg e o suporte mágico de Calindra.
- Reorientação automática para encarar o jogador ao iniciar conversa.

### 2.5. Baú Mímico (`scripts/world/chest.gd`, `scenes/world/chest.tscn`)
- Estado persistido via flag global `mimic_defeated`.
- Quando abordado pela primeira vez:
  1. O baú se transforma no sprite do monstro mímico.
  2. Inicia o diálogo de confronto entre Calindra, Ragg e a criatura.
  3. Ao ser derrotado, concede `lamina_kakariko` (1) e 50 de ouro ao `InventoryManager`.
  4. Dispara a notificação visual de recompensa no `HUD`.
  5. Atualiza o sprite para baú aberto e desativa interações adicionais.

### 2.6. Transição de Mapas e Portas (`scripts/world/door.gd`, `scenes/world/door.tscn`)
- Disparo de transição por aproximação (`Area2D`).
- Integração com `SceneManager.change_scene_with_transition()` para fade preto suave e teleporte para o ponto de spawn correto.

### 2.7. HUD de Exploração (`scripts/ui/hud.gd`, `scenes/ui/hud.tscn`)
- Banner de boas-vindas na entrada de áreas ("Vila Kakariko", "Casa de Tav").
- Contador de ouro sincronizado com o sinal `currency_updated` de `InventoryManager`.
- Toasts de notificação de itens adquiridos ("Obteve: Lâmina de Kakariko x1").

### 2.8. Persistência e Salvamento (`scripts/autoload/save_manager.gd`)
- Gravação de slots em `user://saves/slot_*.json`.
- Restauração validada com testes automatizados para todas as variáveis do jogo.

---

## 3. Resultados dos Testes Automatizados (`./test.sh`)

Todos os 13 testes unitários e de integração foram executados com **GUT 9.6.1** em modo headless no Godot 4.7.2:

```text
==============================================
= Run Summary
==============================================

Totals
------
Scripts               7
Tests                13
Passing Tests        13
Asserts              53
Time              0.644s

---- All tests passed! ----
```

| Suíte de Testes | Arquivo | Casos de Teste | Asserções | Status |
|---|---|---|---|---|
| Inicialização & Autoloads | `tests/unit/test_smoke.gd` | 2 | 12 | PASSOU |
| Movimentação do Jogador | `tests/unit/test_player.gd` | 3 | 11 | PASSOU |
| Seguidor Calindra | `tests/unit/test_follower.gd` | 2 | 3 | PASSOU |
| Interação com NPC Tav | `tests/unit/test_npc.gd` | 1 | 4 | PASSOU |
| Baú Mímico & Recompensa | `tests/unit/test_mimic.gd` | 2 | 9 | PASSOU |
| Serialização Save / Load | `tests/unit/test_save_load.gd` | 1 | 8 | PASSOU |
| Integração Kakariko Overworld | `tests/integration/test_kakariko_world.gd` | 2 | 6 | PASSOU |

---

## 4. Conformidade de Código e Linter (`./lint.sh`)

- `gdlint`: 0 avisos, 0 erros em todos os 36 arquivos do projeto.
- `gdformat`: 100% de conformidade com as regras de estilo de Godot e limite de 100 colunas.

---

## 5. Como Executar e Testar

### No Windows (Nativo):
```powershell
powershell.exe -File run.ps1
```
Pressione Enter na tela inicial para iniciar em Kakariko. Use as setas ou WASD para andar, e Enter ou Espaço para interagir com o Tav e com o baú mímico.

### No Linux / WSL (Headless / Testes):
```bash
./test.sh
./lint.sh
```
