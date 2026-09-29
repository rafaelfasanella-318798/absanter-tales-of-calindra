# Arquitetura do Sistema · Absanter – Tales of Calindra

Documento técnico descrevendo a topologia de nós, singletons (Autoloads) e fluxo de dados.

---

## 1. Topologia de Autoloads (Singletons)

A ordem de carregamento em `project.godot` garante que eventos e estado global existam antes de subsistemas dependentes:

```
                  ┌──────────────┐
                  │   EventBus   │  (Sinais globais desacoplados)
                  └──────┬───────┘
                         │
                  ┌──────┴───────┐
                  │  GameState   │  (Flags, modo de jogo, tempo)
                  └──────┬───────┘
     ┌───────────┬───────┼───────────┬──────────────┬─────────────┐
     │           │       │           │              │             │
┌────┴──────┐ ┌──┴───┐ ┌─┴────┐ ┌────┴─────┐ ┌──────┴──────┐ ┌────┴─────┐
│SceneManage│ │Save  │ │Audio │ │Dialogue  │ │Inventory/   │ │Localiz.  │
│(Transições│ │Manage│ │Manage│ │& Quest   │ │Party Manager│ │          │
└───────────┘ └──────┘ └──────┘ └──────────┘ └─────────────┘ └──────────┘
```

### Detalhamento dos Autoloads

1. **`EventBus`**: Barramento assíncrono para notificações entre mapas, UI e combates sem acoplamento direto.
2. **`GameState`**: Armazena flags de progresso, estado atual (`exploration`, `battle`, `dialogue`, `cutscene`) e cronômetros.
3. **`SceneManager`**: Controla mudanças de cena com transição visual (`CanvasLayer` com fade tweening preto).
4. **`SaveManager`**: Serializa e desserializa o estado do jogo em JSON (`user://saves/`).
5. **`AudioManager`**: Gerencia reprodução e transições cruzadas de música e disparos de efeitos sonoros.
6. **`DialogueManager`**: Conduz diálogos, escolhas e gatilhos de eventos durante conversas.
7. **`QuestManager`**: Rastreia progresso de missões ativas e concluídas.
8. **`InventoryManager`**: Gerencia consumíveis, equipamentos, itens-chave e saldo de moedas.
9. **`PartyManager`**: Mantém lista de membros ativos (Ragg, Calindra) e reservas.
10. **`Localization`**: Responsável por alternância de idiomas (`pt_BR`, `en`).

---

## 2. Fluxo de Cenas e Transições

```
[Início do Jogo]
       │
       ▼
[scenes/main/main.tscn] ("Hello Ragg")
       │
       ▼ (SceneManager.change_scene)
[Fade Out Preto: 0.5s]
       │
       ▼
[Carregamento do Mapa / Batalha]
       │
       ▼
[Fade In Transparente: 0.5s]
       │
       ▼
[Cena Ativa]
```

---

## 3. Guia de Qualidade e Lint Manual

Como o utilitário `pre-commit` é opcional, a verificação manual deve ser realizada via script dedicado:

```bash
# Executar análise estática e verificação de formatação
./lint.sh

# Executar suíte de testes de fumaça e unidade
./test.sh
```

---

## 4. Sistemas 3D — Grandia III Style (adicionado em 29/09/2026)

### 4.1 Hierarquia de Cenas 3D

```
scenes/world_3d/
├── kakariko_3d.tscn       ← Mapa de exploração principal
│   ├── Player3D            ← CharacterBody3D (Ragg)
│   ├── Follower3D          ← CharacterBody3D (Calindra) com delay
│   ├── CameraRig           ← Node3D que segue o Player com lerp
│   │   └── SpringArm3D     ← Braço de câmera anti-colisão (7u)
│   │       └── Camera3D    ← Câmera principal (current=true)
│   ├── SlimeWanderer       ← EnemyWanderer3D (patrulha aleatória)
│   └── BattlePortal        ← Area3D (portal para arena de batalha)
│
├── enemy_wanderer_3d.tscn  ← Inimigo errante reutilizável
│   ├── Visual              ← MeshInstance3D (aparência visual)
│   ├── CollisionShape3D    ← Detecção de colisão com player
│   └── ExclamationLabel    ← Label3D "!/SURPRISE/AMBUSH"
│
└── camp_3d.tscn            ← Cena de acampamento
    ├── Campfire
    │   ├── Flame           ← MeshInstance3D emissivo
    │   └── OmniLight3D     ← Luz laranja pulsante (Tween loop)
    ├── Seats
    │   ├── RaggSeat        ← Capsule azul + NameLabel
    │   └── CalindraSeat    ← Capsule roxa + NameLabel
    └── UI (CanvasLayer)
        ├── RestoreLabel    ← HP/MP restaurado
        ├── DialoguePanel   ← Speaker + Texto + BtnNext/Skip
        └── BtnLeave        ← Aparecer ao fim do diálogo

scenes/battle_3d/
└── battle_3d.tscn          ← Arena de combate 3D
    ├── Camera3D            ← Câmera de batalha
    ├── Combatants          ← Ragg3D, Calindra3D, Slime3D, Golem3D
    └── UI (CanvasLayer)
        ├── IPGaugeContainer    ← Barra IP + Markers + mini-SP bars
        ├── CommandPanel        ← BtnCombo/Critical/Skill/Defend/Evade
        ├── TargetPanel         ← Seleção de alvo
        ├── CancelBanner        ← "CANCEL!" (aparecer no evento)
        ├── ActionBanner        ← Narração da ação
        └── StatusPanel         ← HP/MP/SP da party
```

### 4.2 Fluxo do Sistema de Encontro

```
[EnemyWanderer3D] → body_entered(Player3D)
        │
        ▼
[_classify_encounter()]
        │
   ┌────┴────┐
   │         │
(ângulo     (ângulo
 traseiro    traseiro
 do inimigo) do player)
   │         │
"surprise" "ambush"    → "normal" (encontro frontal)
   │
   ▼
GameState.encounter_type = tipo
EventBus.field_encounter_started.emit(enemy_id, tipo)
        │
        ▼ (delay 0.55s)
SceneManager.change_scene("battle_3d.tscn")
        │
        ▼
Battle3D._ready() → _apply_encounter_type()
   • surprise → party IP = 0.70
   • ambush   → inimigos IP = 0.72
   • normal   → IPs padrão
```

### 4.3 Campo `encounter_type` no GameState
O `GameState` expõe o campo `encounter_type: String = "normal"` como handshake entre exploração e batalha. Após lido em `_apply_encounter_type()`, é resetado para `"normal"`.

### 4.4 Sinal EventBus adicionado
```gdscript
signal field_encounter_started(enemy_id: String, encounter_type: String)
```
Emitido pelo `EnemyWanderer3D` antes da troca de cena. Outros sistemas podem observar sem acoplar ao wanderer diretamente.
