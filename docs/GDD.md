# Game Design Document (GDD) · Absanter – Tales of Calindra

## 1. Visão Geral do Mundo
<!-- [VOCÊ] Nome do continente/reino, geografia geral, nível de tecnologia e magia, era histórica -->

## 2. Lore e Mitologia
<!-- [VOCÊ] Mito de criação, conflito central milenar, facções em disputa, significado de "Absanter" -->

## 3. Sinopse da Narrativa (3 Atos)
<!-- [VOCÊ] Resumo da história do início ao fim, principais reviravoltas -->
### Ato I: O Despertar
### Ato II: A Ruptura
### Ato III: O Clímax e Consequências

## 4. Antagonistas
<!-- [VOCÊ] Vilão principal e suas motivações filosóficas/pessoais; vilões secundários -->
### Vilão Principal
### Vilões Secundários

## 5. Geografia e Locais
<!-- [VOCÊ] Lista de regiões, cidades e masmorras (clima, habitantes, eventos) -->

## 6. Temas e Mensagem
<!-- [VOCÊ] Temas centrais abordados pela narrativa e experiência do jogador -->

## 7. Tom e Estilo Narrativo
<!-- [VOCÊ] Tom dos diálogos e humor (sério, dramático, irônico, leve) -->

---

## 8. Direcionamento Visual e Mecânicas 3D (Grandia III Style)

> Atualizado em 29/09/2026 — decisão de redirecionar o projeto de 2D pixel art para **3D low-poly estilo Grandia III (PS2)**.

### 8.1 Câmera e Exploração
- **SpringArm3D** com braço ajustável (7u padrão) para evitar clipping em geometria
- Órbita por mouse (botão direito) ou analógico direito do gamepad
- Inclinação clampada entre -15° e +55° para leitura clara do espaço
- `CameraRig` segue o Player com lerp suavizado

### 8.2 Sistema de Encontro de Campo
- Inimigos erram pelo mapa como `EnemyWanderer3D` (Area3D com patrulha aleatória)
- **Surprise Attack**: player atinge inimigo pelas costas → party começa com IP alta
- **Ambush**: inimigo surpreende o player → inimigos começam com IP alta
- **Normal**: encontro frontal, sem bônus

### 8.3 Combate 3D — IP Timeline (Grandia III)
| Mechanic | Descrição |
|---|---|
| IP Timeline | Barra horizontal; personagens avançam ao longo do tempo. COM (75%) = escolha; ACT (100%) = executa |
| COMBO | 2 hits rápidos, empurra -20% IP do alvo, gera SP |
| CRITICAL | 1 hit forte; se alvo está em ACT → **CANCEL** (recua -55% IP) |
| Aerial Launch | Após CANCEL com alvo vivo → lança no ar; parceiro com SP ≥ 30 executa Aerial Combo |
| Evasão | Gasta 15% IP; teleporta o personagem para posição aleatória segura na arena |
| Habilidades | SP (barra secundária) acumula em COMBOs; gasto em Aerial e habilidades especiais |

### 8.4 Camp / Dinner System
- Pontos de acampamento disponíveis no mundo exploração
- Ragg e Calindra sentam ao redor de uma fogueira (OmniLight3D pulsante)
- **Diálogos rotativos** (3 acampamentos diferentes, cíclicos) aprofundam a relação
- Restauração: **100% HP** e **75% MP** ao descansar

### 8.5 Render
- Resolução base: **1280×720**
- Anti-aliasing: **MSAA 2×** + **FXAA** (screen-space AA)
- Sem stretch de viewport (renderização nativa 3D)
