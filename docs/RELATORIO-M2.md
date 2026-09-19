# Relatório de Conclusão · Milestone M2 (Combate por Turnos)

Documento oficial de entrega do Milestone M2 de *Absanter – Tales of Calindra*.

---

## 1. Visão Geral da Entrega

O Milestone M2 implementa o sistema completo de combate por turnos no estilo clássico JRPG (Chrono Trigger / Final Fantasy), com party de 2 membros (Ragg e Calindra) contra múltiplos inimigos:
- **Ordem de Ação Dinâmica por Velocidade**: Fila de turnos (`turn_queue`) reordenada automaticamente pela velocidade de cada combatente (`speed`).
- **Party Jogável com Sinergia**:
  - **Ragg**: Especialista físico com ataque básico (`slash`), golpe concentrado (`focus_strike`) e sinergia combinada.
  - **Calindra**: Especialista em magia e suporte com centelhas arcanas (`magic_spark`), cura vital (`heal`), proteção mágica (`aegis`) e ataque combinado de sinergia (`arcane_blade`).
- **Inimigos Implementados em Dados (`data/enemies/`)**:
  - **Slime de Kakariko**: Inimigo resistente a ataques neutros e fraco contra fogo (`slime_tackle`).
  - **Morcego da Caverna**: Inimigo veloz com ataque de investida (`bat_bite`).
  - **Mímico de Kakariko**: Mini-chefe voraz com mordida pesada (`mimic_chomp`) e sopro de trevas em área (`dread_breath`).
- **Fórmulas de Combate e Balanceamento (`BattleFormulas`)**:
  - Dano físico baseado em `(ATK * 2 - DEF)` com variância e críticos (1.5x).
  - Dano mágico baseado em `(MAG * 2.2 - DEF * 0.6)` com fraquezas elementais (1.5x).
  - Postura defensiva reduzindo dano em 50%.
  - Curva progressiva de XP por nível e ganhos de atributos automáticos ao subir de nível.
- **Feedback Visual Retro**:
  - Popups numéricos flutuantes (`FloatingText`) coloridos (vermelho para dano, amarelo para crítico, verde para cura, azul para mana e status).
  - Flashes e animações de hit e derrota via tweens.
- **Inventário e Itens no Combate**:
  - Consumo direto de poções (`pocao_vida`, `pocao_mana`) sincronizado com o `InventoryManager`.
- **Telas de Resolução**:
  - **Vitória**: Resumo de XP, Ouro, drops de itens, avisos de Level Up e retorno suave ao mapa anterior.
  - **Derrota**: Tela de Game Over com opção de Tentar Novamente.
  - **Fuga**: Cálculo de chance de fuga baseado na velocidade média das equipes (bloqueado contra chefes).
- **Simulador Headless de Balanceamento (`BattleSimulator`)**:
  - Permite rodar centenas de batalhas automatizadas em milissegundos para validação matemática de win rate, turnos médios e retenção de HP da party.

---

## 2. Estrutura de Arquivos Criados / Atualizados

```text
scripts/
├── battle/
│   ├── battler.gd                 # Componente de combatente (vida, mana, buffs, ações)
│   ├── battle_formulas.gd         # Fórmulas de dano, cura, crítico, fraqueza, XP e fuga
│   ├── battle_manager.gd          # Máquina de estados da batalha, turnos e UI
│   ├── battle_simulator.gd        # Motor de simulação headless para balanceamento
│   └── floating_text.gd           # Números flutuantes de dano e status
data/
├── skills/
│   ├── slash.tres                 # Golpe Espada (Ragg)
│   ├── focus_strike.tres          # Golpe Focado (Ragg)
│   ├── magic_spark.tres           # Lufada Mágica (Calindra)
│   ├── heal.tres                  # Cura Suave (Calindra)
│   ├── aegis.tres                 # Proteção de Calindra (Buff DEF)
│   ├── arcane_blade.tres          # Sinergia: Lâmina Arcana (Ragg + Calindra)
│   ├── slime_tackle.tres          # Investida do Slime
│   ├── bat_bite.tres              # Mordida do Morcego
│   ├── mimic_chomp.tres           # Mordida do Mímico
│   └── dread_breath.tres          # Sopro Macabro do Mímico
├── enemies/
│   ├── slime.tres                 # Dados do Slime de Kakariko
│   ├── cave_bat.tres              # Dados do Morcego da Caverna
│   └── kakariko_mimic.tres        # Dados do Mímico de Kakariko
├── items/
│   ├── potion_hp.tres             # Poção de Vida
│   ├── potion_mp.tres             # Poção de Mana
│   └── kakariko_blade.tres        # Lâmina de Kakariko
scenes/battle/
├── battler.tscn                   # Cena instanciável do combatente
├── battle_scene.tscn              # Cena completa da arena de batalha e UI
└── floating_text.tscn             # Cena dos números flutuantes
tests/unit/
├── test_battle_formulas.gd        # Testes unitários das fórmulas matemáticas
├── test_battler.gd                # Testes unitários do ciclo de vida do Battler
├── test_battle_manager.gd         # Testes da máquina de combate e turnos
└── test_balance_simulation.gd     # Testes de 150 simulações de combate automatizadas
```

---

## 3. Resultados dos Testes Automatizados (`./test.sh`)

Todos os 32 testes foram executados e aprovados com **GUT 9.6.1**:

```text
==============================================
= Run Summary
==============================================

Totals
------
Scripts              11
Tests                32
Passing Tests        32
Asserts             109
Time              10.461s

---- All tests passed! ----
```

### Detalhamento por Suíte de Testes

| Suíte de Testes | Arquivo | Casos de Teste | Asserções | Status |
|---|---|---|---|---|
| Simulação de Balanceamento (150 batalhas) | `tests/unit/test_balance_simulation.gd` | 2 | 5 | PASSOU |
| Fórmulas de Combate | `tests/unit/test_battle_formulas.gd` | 6 | 13 | PASSOU |
| Máquina de Batalha (BattleManager) | `tests/unit/test_battle_manager.gd` | 6 | 11 | PASSOU |
| Componente Battler | `tests/unit/test_battler.gd` | 5 | 19 | PASSOU |
| Seguidor Calindra | `tests/unit/test_follower.gd` | 2 | 3 | PASSOU |
| Baú Mímico & Recompensa | `tests/unit/test_mimic.gd` | 2 | 9 | PASSOU |
| Interação com NPC Tav | `tests/unit/test_npc.gd` | 1 | 4 | PASSOU |
| Movimentação do Jogador | `tests/unit/test_player.gd` | 3 | 11 | PASSOU |
| Save / Load | `tests/unit/test_save_load.gd` | 1 | 8 | PASSOU |
| Smoke Tests | `tests/unit/test_smoke.gd` | 2 | 12 | PASSOU |
| Integração Kakariko Overworld | `tests/integration/test_kakariko_world.gd` | 2 | 6 | PASSOU |

---

## 4. Conformidade de Código e Linter (`./lint.sh`)

- `gdlint`: Sucesso absoluto (0 problemas em todos os 45 arquivos do repositório).
- `gdformat`: 100% de conformidade com os padrões de formatação da comunidade Godot.

---

## 5. Como Executar

### No Windows (Nativo):
```powershell
powershell.exe -File run.ps1
```

### No Linux / WSL (Headless / Testes):
```bash
./test.sh
./lint.sh
```
