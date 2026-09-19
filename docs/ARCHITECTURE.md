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
