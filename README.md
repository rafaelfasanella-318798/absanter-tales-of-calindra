# Absanter – Tales of Calindra

[![CI](https://github.com/rafaelfasanella-318798/absanter-tales-of-calindra/actions/workflows/ci.yml/badge.svg)](https://github.com/rafaelfasanella-318798/absanter-tales-of-calindra/actions/workflows/ci.yml)

**Absanter – Tales of Calindra** é um RPG clássico estilo JRPG 2D pixel art top-down construído em **Godot 4.x** com GDScript puro.

- **Protagonista**: **Ragg**
- **Companheira de Party**: **Calindra** (suporte, magias arcanas, habilidades combinadas)
- **Estética**: Pixel art 16x16 (estilo *Chrono Trigger* / *Stardew Valley*)
- **Combate**: Turnos clássico JRPG com cálculo dinâmico de iniciativa, fraquezas elementais, habilidades e itens

---

## 🎮 Funcionalidades Implementadas

- **Exploração e Mundo (Top-Down)**:
  - Movimento fluido em 4/8 direções com colisão pixel-perfect.
  - Sistema de seguidores de party (Calindra acompanha Ragg dinamicamente).
  - Câmera pixel-perfect suave com limites configurados por cena.
  - Interação com NPCs (diálogo letra a letra com retrato e escolhas), baús e pontos de salvamento.
  - Transições suaves de mapas com pontos de spawn nomeados (Vila Kakariko, Interiores, Caverna e Sala do Chefe).

- **Combate por Turnos**:
  - Máquina de estados completa: ordem por agilidade, animações de golpe, números de dano flutuantes, flashes e screen shake.
  - Habilidades arcanas, cura, suporte e habilidades combinadas Ragg + Calindra.
  - Inteligência artificial de inimigos por dados e fases de chefe (ex: Mini-chefe Mímico e Guardião de Pedra).
  - Telas de vitória, recompensas (XP, ouro, drops) e Game Over com retry.

- **Equipamentos e Estatísticas**:
  - Slots: Arma, Armadura e Acessório.
  - Bônus dinâmicos de atributos (HP, MP, ATK, DEF, MAG, SPD) e restrições por personagem.
  - Aba de **Equipamento** no menu de pausa com **pré-visualização comparativa de stats** em tempo real.

- **Economia, Loja e Inventário**:
  - `InventoryManager` com empilhamento de itens e gestão de ouro.
  - Interface de Loja (compra e venda de consumíveis e equipamentos).

- **Persistência e Configurações**:
  - Salvamento completo em JSON (posição, party, inventário, equipamentos, missões e flags) em `user://saves/`.
  - Menu de Pausa com abas de Status, Itens, Equipamentos, Missões, Opções e Salvar.
  - Suporte à Localização (PT-BR e EN).
  - Console de Debug in-game para testes rápidos.

---

## 🚀 Como Executar

### Linux / WSL (com WSLg ou servidor X11)
```bash
./run.sh
```

### Windows Nativo
```powershell
powershell.exe -File run.ps1
```

---

## 🧪 Testes Automatizados e Qualidade

O projeto conta com mais de **70 testes automatizados** (unitários e de integração) via **GUT**:

```bash
# Executar a suíte de testes GUT em modo headless
./test.sh

# Executar validação de dados (data validator)
./tools/godot/godot --headless --script scripts/tools/run_data_validator.gd

# Checagem de formatação e análise estática (gdlint + gdformat)
./lint.sh
```

---

## 📁 Estrutura do Repositório

```
├── assets/          # Sprites, tilesets, fontes e UI pixel art
├── data/            # Recursos de jogo (.tres): personagens, inimigos, magias, itens e missões
├── docs/            # Documentação técnica, GDD, relatórios de milestone e créditos
├── scenes/          # Cenas Godot (.tscn): mundo, combate, UI e sistema principal
├── scripts/         # Scripts GDScript (.gd): autoloads, mecânicas, combate e ferramentas
└── tests/           # Testes automatizados com GUT (unitários e integração)
```

---

## 📄 Licenças e Créditos

Todos os assets de terceiros utilizados no projeto possuem licenças livres e permissivas (CC0 / MIT). Detalhes completos podem ser consultados em [`docs/CREDITS.md`](docs/CREDITS.md).
