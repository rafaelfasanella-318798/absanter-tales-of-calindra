# Relatório de Conclusão · Milestone M3 (Vertical Slice Jogável)

Documento oficial de entrega do Milestone M3 de *Absanter – Tales of Calindra*.

---

## 1. Visão Geral da Entrega

O Milestone M3 consolida a **Vertical Slice** completa do jogo: o Prólogo e o Capítulo 1 estão 100% jogáveis desde a chegada a Kakariko, passando pela descoberta e derrota do Mímico, exploração da Caverna dos Murmúrios, até a batalha épica contra o chefe Golem Antigo e a resolução da quest principal com Tav.

Além do ciclo narrativo e de gameplay principal, foram entregues todos os sistemas auxiliares essenciais:
- Sistema de Localização dinâmico (PT-BR / EN).
- Loja e Economia com NPC Mercador (compra e venda de consumíveis).
- Console de Debug in-game para testes rápidos de desenvolvimento.
- Validador de dados automatizado e exportador de balanceamento em CSV.
- Menu de pausa aprimorado com controle de áudio e abas completas.
- Suíte de smoke test cobrindo todas as 20 cenas do projeto.

---

## 2. Mapa do Conteúdo Jogável

| Localidade / Cena | Arquivo | Entidades e Funcionalidades |
|---|---|---|
| **Tela de Título** | `scenes/main/main.tscn` | Novo Jogo, Continuar, Sair, Alternar Idioma (PT-BR/EN) |
| **Vila Kakariko** | `scenes/world/kakariko.tscn` | Tav (NPC de quest), Barnaby (Mercador da Loja), Baú Mímico, Ponto de Save/Cura, Slimes errantes, portais para a Cabana e para a Caverna |
| **Cabana de Kakariko** | `scenes/world/kakariko_house.tscn` | Interior decorado, baú com Poção de Vida, transição de porta |
| **Caverna dos Murmúrios** | `scenes/world/kakariko_cave.tscn` | Dungeon com Morcegos errantes, Ponto de Save/Cura, Portão do Selo (requer Lâmina de Kakariko) |
| **Câmara do Guardião** | `scenes/world/kakariko_boss_room.tscn` | Arena do chefe com diálogo pré-batalha contra o Golem Antigo |
| **Arena de Combate** | `scenes/battle/battle_scene.tscn` | Batalha em turnos completa, comandos, magias, itens, VFX e tela de vitória |

---

## 3. Sistemas Implementados e Funcionalidades

### 3.1. Sistema de Localização (`LocalizationAutoload`)
- **Tabela de Strings**: `data/localization/strings.csv` com chaves traduzidas para Português (`pt_BR`) e Inglês (`en`).
- **Integração com Engine**: Registra dicionários com `TranslationServer` e oferece `Localization.translate_key(key)` e `tr()`.
- **Alternância Dinâmica**: Suporte a troca de idioma instantânea na tela de título e nas opções do menu de pausa.

### 3.2. Sistema de Loja e Comércio (`ShopMenu` + Barnaby)
- **Menu da Loja**: `scenes/ui/shop_menu.tscn` e `scripts/ui/shop_menu.gd`.
- **Modo Compra**: Adquire `pocao_vida`, `pocao_mana`, `antidoto`, `pena_fenix` deduzindo ouro do `InventoryManager`.
- **Modo Venda**: Permite vender itens do inventário recebendo 50% do valor em ouro.
- **NPC Mercador**: Barnaby posicionado na vila com diálogo comercial e abertura do menu de compras.

### 3.3. Console de Debug In-Game (`DebugConsoleUI`)
- **Atalho de Acesso**: Tecla `~` (aspas/til) ou `F12`.
- **Comandos Suportados**:
  - `help`: Lista os comandos disponíveis.
  - `teleport <kakariko|house|cave|boss>`: Teleporta a party para qualquer mapa.
  - `gold <qtd>`: Adiciona ouro instantaneamente.
  - `item <item_id> [qtd]`: Adiciona itens ao inventário.
  - `quest <quest_id> <estagio>`: Modifica o estágio de qualquer missão.
  - `heal`: Restaura vida e mana de todos os membros.
  - `god`: Alterna modo invulnerável.
  - `level [qtd]`: Concede níveis e amplia atributos da party.
  - `battle <inimigo>`: Inicia combate imediatamente com qualquer monstro.
  - `flag <nome> <valor>`: Altera flags no `GameState`.
  - `clear` e `exit`: Limpeza e fechamento do console.

### 3.4. Validação de Dados e Exportação de Balanceamento
- **Validador Automático**: `scripts/tools/data_validator.gd` e runner CLI `run_data_validator.gd`.
  - Verifica integridade de todos os `.tres` em `data/` (personagens, inimigos, magias, itens, missões).
  - Garante ausência de IDs duplicados, atributos negativos e referências nulas.
- **Exportador de Balanceamento**: `scripts/tools/export_balance_csv.gd` gera `data/balance_summary.csv` contendo resumo tabular dos atributos de personagens e inimigos.

### 3.5. Menu de Pausa com Opções de Áudio
- Abas disponíveis:
  - **Status**: Visualização dos atributos de Ragg e Calindra e ouro acumulado.
  - **Itens**: Inventário com opção de uso fora de batalha.
  - **Missões**: Lista de missões ativas e histórico de objetivos concluídos.
  - **Opções**: Sliders para Volume Master, Música, Efeitos Sonoros e seletor de Idioma.
  - **Salvar**: Gravação direta no Slot 1 com feedback visual.
  - **Sair**: Retorno à tela de título.

---

## 4. Métricas de Testes e Qualidade

### Testes Automatizados (`./test.sh`)
- **Total de Scripts de Teste**: 21
- **Total de Testes Executados**: 64
- **Testes Aprovados**: **64 (100%)**
- **Falhas / Avisos**: **0**
- **Total de Asserções**: **286**
- **Tempo de Execução**: ~13s

### Cobertura dos Testes:
1. `test_all_scenes_smoke.gd`: Instanciação sem falhas de todas as 20 cenas do projeto.
2. `test_vertical_slice_progression.gd`: Fluxo narrativo completo da quest de Kakariko do início ao fim.
3. `test_shop_system.gd`: Compra, venda, saldo insuficiente e interface de loja.
4. `test_debug_console.gd`: Parsing e execução de todos os comandos do console.
5. `test_localization.gd`: Tradução e troca de locale entre PT-BR e EN.
6. `test_data_tools.gd`: Validação do banco de dados e exportação de CSV.
7. `test_inventory_party.gd`: Operações de stack de itens, gestão de ouro e formação de party.
8. `test_balance_simulation.gd`: 150 simulações automatizadas de combate com taxas de vitória consistentes.
9. `test_battle_formulas.gd`, `test_battle_manager.gd`, `test_battler.gd`: Mecânica de combate em turnos.
10. `test_save_load.gd`, `test_save_point.gd`: Persistência de dados em JSON e pontos de cura.
11. `test_npc.gd`, `test_mimic.gd`, `test_player.gd`, `test_follower.gd`, `test_kakariko_world.gd`.

### Análise Estática (`./lint.sh`)
- **`gdlint`**: 0 problemas encontrados.
- **`gdformat`**: 66 arquivos verificados e formatados em total conformidade.

---

## 5. Como Jogar e Testar

1. **Executar no Linux (WSL com WSLg ou X11)**:
   ```bash
   ./run.sh
   ```
2. **Executar no Windows nativo**:
   ```powershell
   powershell.exe -File run.ps1
   ```
3. **Rodar a suíte completa de testes**:
   ```bash
   ./test.sh
   ```
4. **Validar integridade de dados e linting**:
   ```bash
   ./tools/godot/godot --headless --script scripts/tools/run_data_validator.gd
   ./lint.sh
   ```
