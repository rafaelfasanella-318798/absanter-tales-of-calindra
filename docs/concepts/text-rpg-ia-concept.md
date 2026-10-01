# RPG de Texto com IA · Conceito e Planejamento

> **Nota de escopo**: este documento descreve uma **ideia independente**, sem relação com
> *Absanter – Tales of Calindra* (o JRPG 3D principal deste repositório). É um conceito separado,
> guardado aqui por conveniência. Nenhuma decisão aqui altera `docs/ARCHITECTURE.md`.

---

## 1. Ideia central

Um RPG **puro texto de console** (estilo MUD / interactive fiction dos anos 80–90), onde uma IA
generativa cria conteúdo emergente e imprevisível — descrições, diálogos, reações de NPCs,
consequências de ações — **dentro de uma estrutura de história limitada e controlada**.

A graça está no contraste:
- A **história principal é fixa**: um conjunto pequeno e bem definido de fatos/eventos que
  precisam acontecer (ex.: "o reino cai", "o herói encontra o traidor", "o templo é destruído").
- **A ordem e a forma como esses fatos acontecem variam** de acordo com as ações do jogador e com
  o que a IA improvisa no caminho.
- O "recheio" entre os grandes fatos é gerado livremente pela IA — podendo (e devendo) ser bizarro,
  cômico, surreal — sem quebrar a estrutura da história.

Meta de design: **"roteiro fixo, improviso livre"**. Como uma peça de teatro com atores de
improvisação: os atores sabem os 5 ou 6 marcos que a cena precisa atingir, mas tudo o que
acontece entre esses marcos é inventado na hora.

---

## 2. Por que começar só com planejamento

Antes de codar qualquer coisa, este documento serve para:
1. Definir o **formato mínimo viável** (o "jogo" mais simples possível que já é divertido).
2. Definir como a **história limitada** é representada (dados, não código).
3. Definir o **contrato entre o motor do jogo e a IA** (o que a IA pode e não pode inventar).
4. Só depois disso, evoluir para um protótipo jogável.

---

## 3. Pilares do design

| Pilar | Descrição |
|---|---|
| **Texto puro** | Sem gráficos. Tudo é lido e digitado. Estilo terminal/console clássico. |
| **História com trilhos, não corredor** | Grandes fatos são obrigatórios; a ordem entre eles e o caminho até eles é livre. |
| **IA como "mestre de RPG"** | A IA improvisa narração, NPCs e consequências, mas não pode inventar ou pular fatos estruturais. |
| **Loucura controlada** | Quanto mais bizarro o improviso dentro dos limites, melhor — isso é uma feature, não um bug. |
| **Dados fora do código** | Fatos, gatilhos e estado do mundo vivem em arquivos de dados (JSON/YAML), nunca hardcoded. |

---

## 4. Estrutura da história (o "esqueleto fixo")

A história é modelada como um **grafo de fatos com pré-requisitos**, não como uma linha reta.

### 4.1 Fato de história (`story_fact`)
Cada fato é um marco obrigatório da narrativa. Exemplo de estrutura (conceitual, em JSON):

```json
{
  "id": "queda_do_reino",
  "titulo": "A queda do reino",
  "resumo": "O reino central é destruído ou conquistado.",
  "requer": ["traidor_revelado"],
  "bloqueia": [],
  "obrigatorio": true,
  "tags": ["climax", "ato_2"]
}
```

- `requer`: outros fatos que precisam ter acontecido antes (define ordens parciais, não uma
  ordem total — vários fatos podem ficar "disponíveis" ao mesmo tempo).
- `bloqueia`: fatos que passam a ficar indisponíveis/cancelados se este acontecer (permite
  ramificações mutuamente exclusivas, ex.: "aliança com os anões" bloqueia "guerra contra os anões").
- `obrigatorio`: se `true`, o jogo não pode terminar sem que esse fato tenha ocorrido.

### 4.2 Como um fato "acontece"
Cada fato tem um ou mais **gatilhos** possíveis — condições simples de estado do jogo (local
visitado, item obtido, NPC morto, flag setada) que, quando satisfeitas, tornam aquele fato elegível
para ser narrado pela IA. A IA recebe a lista de fatos elegíveis no momento e escolhe/narra **qual
deles** acontece e **como**, dentro do que fizer sentido para as ações recentes do jogador.

### 4.3 Final do jogo
O jogo termina quando todos os fatos `obrigatorio: true` ainda não bloqueados tiverem ocorrido
(ou um conjunto mínimo definido como "final"). Isso garante que, por mais doida que a jornada seja,
a história sempre converge para um encerramento coerente.

### 4.4 `requer` (E) vs. `requer_qualquer` (OU) — caminhos que se cruzam e se fecham
Para representar ramificações que **se excluem mas convergem depois**, o grafo precisa de dois
tipos de pré-requisito, não só um:

- `requer` (lista, lógica **E**): todos precisam ter ocorrido. Usado para pré-requisitos normais.
- `requer_qualquer` (lista, lógica **OU**): basta **um** deles ter ocorrido. Usado quando dois
  (ou mais) fatos mutuamente exclusivos (ligados por `bloqueia` entre si) levam igualmente ao
  próximo marco da história — ex.: tanto "aliança com os anões" quanto "guerra contra os anões"
  habilitam "queda do reino", mesmo sendo caminhos opostos.
- **Regra de satisfação de `obrigatorio`**: se um fato `obrigatorio: true` foi `bloqueado` por
  outro fato que de fato ocorreu (par mutuamente exclusivo), ele conta como **resolvido** para
  fins do final do jogo (seção 4.3) — não é necessário que ambos os lados de uma exclusão mútua
  aconteçam, só que **um** deles aconteça.

A seção 11 mostra um exemplo completo usando esses dois tipos de pré-requisito.

---

## 5. O que a IA pode e não pode fazer (contrato)

Para a "loucura" não virar bagunça incoerente, a IA opera sob restrições claras:

**Pode:**
- Inventar descrições de cenas, NPCs, diálogos, itens cômicos/bizarros, eventos aleatórios.
- Decidir *como* um fato elegível se manifesta na narrativa (o "flavor").
- Reagir de forma imprevisível a ações do jogador, desde que não contradiga o estado salvo.
- Criar NPCs e sub-tramas descartáveis que não afetam o grafo de fatos.

**Não pode:**
- Pular um fato obrigatório ou inventar que ele já aconteceu sem o gatilho real ter ocorrido.
- Contradizer fatos já ocorridos (precisa de memória do estado/histórico).
- Alterar o grafo de fatos em si (isso é dado, não vem da IA).
- Encerrar o jogo antes de cumprir os fatos obrigatórios pendentes.

Mecanicamente, isso é implementado passando para a IA, a cada turno:
1. O **prompt de sistema** com o tom/estilo desejado (ex.: "narrador doido, PT-BR, até 3 parágrafos").
2. O **estado atual** (fatos ocorridos, flags, inventário, local).
3. Os **fatos elegíveis agora** (com um resumo curto de cada).
4. A **última ação do jogador**.

E a IA retorna: texto narrado + (opcional) qual fato elegível ela decidiu "consumir" nesta resposta,
em um formato estruturado simples que o motor consegue parsear (ex.: um bloco JSON ao final da
resposta, ou tool calling, dependendo da API usada).

---

## 6. Sugestão de ações e consequências (inspirado em Baldur's Gate 3)

Além de narrar o que acontece, a IA também deve atuar como um **"mestre que sussurra opções"**:
logo após narrar a cena, ela sugere ao jogador **o que ele pode fazer a seguir**, mostrando pistas
do que cada ação pode causar — sem tirar a liberdade de o jogador digitar qualquer coisa em texto
livre (as sugestões são um apoio, não um menu travado).

### 6.1 Inspiração: como BG3 resolve isso

Pesquisa feita sobre o sistema narrativo de *Baldur's Gate 3* (motor **Osiris**, da Larian):

- BG3 modela toda a narrativa como **fatos em um banco de dados de regras** (`DB_Characters`,
  flags de quest, etc.) e **regras declarativas** no formato
  `SE <evento/condição> ENTÃO <ação>` — exatamente o espírito do nosso grafo de fatos (seção 4) e
  das consultas Cypher (seção 10).
- Cada **opção de diálogo** na UI de BG3 já vem com **tags visíveis de risco/tipo** antes de o
  jogador escolher: ícone de dado para teste de atributo (Persuasão, Intimidação, Enganação),
  indicação de "isso pode ser permanente", e reações de aprovação/desaprovação dos companheiros.
  O jogador nunca vê o resultado exato, mas vê **o tipo de consequência** antes de agir.
- As regras são **determinísticas**: uma vez satisfeitas as condições, a consequência sempre
  ocorre — não há "a IA inventando se aquilo conta ou não". Isso reforça o contrato da seção 5:
  quem decide se uma ação é elegível é o grafo de fatos, não o improviso da IA.

**O que aproveitamos para este projeto**: não copiar a interface de BG3 (ele é gráfico, o nosso é
texto), mas copiar a ideia de **"mostrar o tipo de consequência antes da escolha, sem revelar o
resultado exato"**, apoiada nos mesmos dados estruturados (fatos/flags) que já usamos para a
narrativa, em vez de a IA simplesmente alucinar uma lista de opções soltas.

### 6.2 Como funciona no nosso motor

A cada turno, depois de narrar a cena, a IA recebe (além do que já é passado pela seção 5):
- A lista de **fatos elegíveis agora** (vinda da consulta Cypher da seção 10.2).
- As **arestas `BLOQUEIA`** desses fatos (para sinalizar ramificações que se fecham).
- Flags simples de "risco" por fato (`obrigatorio`, `reversivel: true/false`, se definido nos
  dados — campo novo opcional no `story_fact`).

E devolve, junto da narração, uma lista curta (3–5) de **ações sugeridas em texto livre**, cada
uma com uma **tag de consequência** curta, sem spoiler do resultado exato. Exemplo de saída para o
jogador:

```
Você está diante do portão do templo em chamas. O guarda sussurra seu nome.

O que você faz?
  1. Entrar correndo no templo.         [⚠️ pode ser irreversível]
  2. Tentar acalmar o guarda.           [🎲 incerto — depende de como você agir]
  3. Fugir para a floresta.             [🔀 muda o rumo da história]
  4. (ou digite sua própria ação livremente)
```

- `⚠️` = a ação provavelmente consome um fato `obrigatorio` ou aciona uma relação `BLOQUEIA`
  (ramificação que fecha outros caminhos).
- `🎲` = a ação é ambígua o bastante para a IA improvisar o resultado (sem fato estrutural
  amarrado, puro "recheio").
- `🔀` = a ação provavelmente leva a um fato elegível diferente do caminho atual (mostra que a
  *ordem* dos grandes fatos pode mudar a partir daqui).
- O jogador **nunca é obrigado** a escolher da lista — ela é só uma ajuda; digitar uma ação livre
  (como já era o padrão da seção 6/7) continua sempre válido.

### 6.3 Regra de implementação

As tags de consequência **não podem ser inventadas livremente pela IA** (mesma lógica do contrato
da seção 5): o motor calcula, a partir do grafo (Neo4j), quais fatos cada ação hipotética
aproximaria, e só então pede à IA para **redigir** a sugestão de ação em linguagem natural e
escolher a tag certa entre as pré-definidas (`⚠️`, `🎲`, `🔀`). Isso evita que a IA prometa uma
consequência que o grafo não vai de fato cumprir depois.

---

## 7. Loop de jogo (MVP em texto puro)

```
1. Motor mostra o estado atual (texto) e pede um comando livre do jogador.
2. Jogador digita uma ação em linguagem natural (ex.: "eu abro a porta e grito").
3. Motor calcula fatos elegíveis a partir do estado.
4. Motor monta o prompt e chama a IA.
5. IA responde com narração + (opcional) fato consumido + mudanças de estado sugeridas.
6. Motor valida a resposta (o fato era elegível? a mudança de estado é permitida?) e aplica.
7. Motor recalcula os fatos elegíveis no novo estado e pede à IA uma lista curta de ações
   sugeridas com tags de consequência (seção 6).
8. Motor mostra a narração + sugestões e volta ao passo 1 (o jogador pode escolher uma sugestão
   ou digitar algo totalmente livre).
9. Quando todos os fatos obrigatórios ocorreram, o jogo chega ao final.
```

Esse loop não depende de Godot, nem de UI gráfica — pode ser um script simples (Python, Node, ou
até GDScript rodando em modo console) conversando com uma API de LLM (local via Ollama, já usado
no projeto principal — ver `docs/local-ai.md` — ou remota).

---

## 8. Formato mínimo viável (MVP)

O menor experimento jogável que já valida a ideia:

1. **1 banco Neo4j Community local** com uma história de 5-8 fatos (grafo simples, 1-2
   ramificações) — ver seção 10 para o modelo de dados e a consulta de fatos elegíveis.
2. **1 script de console** que faz o loop acima (incluindo a sugestão de ações da seção 6),
   lendo/escrevendo no Neo4j e chamando um modelo local (Ollama).
3. **Visualização**: abrir o Neo4j Browser (`http://localhost:7474`) junto da partida para ver o
   grafo da história sendo "preenchido" em tempo real (fatos passam de pendente → ocorrido).
4. **Sem save/load real além do próprio grafo** — o estado de "ocorrido/não ocorrido" vive nas
   propriedades dos nós do Neo4j.
5. **Sem validação robusta** — se a IA alucinar fora do contrato, o motor só ignora e re-pede.
6. **Critério de sucesso do MVP**: conseguir jogar do início ao fim, com pelo menos uma jogada em
   que a ordem dos fatos muda em relação a outra jogada, com momentos de narrativa "doida" que
   não quebram a lógica da história, e acompanhando visualmente o grafo pelo navegador.

---

## 9. Caminho de evolução (depois do MVP de planejamento/texto)

1. **MVP console + Neo4j** (Python/Node + Ollama) → validar o conceito de "trilhos + improviso"
   com o grafo já visível no Neo4j Browser.
2. **Robustecer o contrato IA/motor**: validação de respostas, retry, memória de longo prazo
   (resumo do que já aconteceu, para não estourar contexto).
3. **Ferramentas de autoria**: editor simples do grafo de fatos (ainda via Cypher/Neo4j Browser,
   sem GUI própria).
4. **Vitrine web pública do grafo**: exportar o grafo para JSON e publicar uma página estática
   (vis-network.js ou Cytoscape.js, ex.: GitHub Pages) para mostrar a estrutura da história sem
   depender de ter Neo4j instalado — ver seção 10.3.
5. **Camada de apresentação do jogo**: sair do console puro para uma UI minimalista (ainda
   majoritariamente texto), possivelmente dentro do próprio Godot como uma tela/modo separado, ou
   como app à parte.
6. **Decisão futura**: se evoluir para "jogo" completo, decidir se vira:
   - um modo/minigame dentro de Absanter (improvável, universos diferentes), ou
   - um projeto novo e independente (Godot ou outra stack), reaproveitando apenas o
     conhecimento de IA local (`docs/local-ai.md`).

Essa decisão de arquitetura (dentro ou fora deste repositório) fica em aberto e deve ser revisitada
quando o MVP de console provar o conceito.

---

## 10. Banco de dados de grafos para a história

O grafo de fatos (seção 4) é, por natureza, um **grafo** — nós (fatos) ligados por arestas
(`requer`, `bloqueia`). Em vez de manter isso só em JSON solto, o plano passa a usar um **banco de
dados de grafos de verdade**, o que já dá de graça: consultas de caminho/ordem topológica,
detecção de ciclos, e (o pedido principal) **uma visualização web nativa** do grafo.

### 10.1 Escolha da ferramenta (critério: mais fácil primeiro)

| Opção | Prós | Contras | Quando usar |
|---|---|---|---|
| **Neo4j Community (Desktop/Docker)** | Banco de grafos real; vem com **Neo4j Browser**, um site web local (`http://localhost:7474`) que já desenha o grafo automaticamente, sem escrever nenhum código de visualização; linguagem de consulta (Cypher) simples e legível | Precisa instalar/rodar um serviço (Java por baixo) | **Recomendado para o MVP** — visualização "de graça" |
| **Kuzu / SQLite com tabelas de nós e arestas** | Embarcado, sem serviço rodando, arquivo único | Não tem visualizador web pronto; precisa construir a tela | Se quiser zero dependências externas |
| **JSON + biblioteca JS de grafo (vis-network / Cytoscape.js)** | Site estático, fácil de publicar/compartilhar (ex.: GitHub Pages) | Não é um "banco de dados" de verdade, é só dados + render | Boa para a **vitrine pública** do grafo, depois do MVP |

**Decisão para o MVP**: usar **Neo4j Community** para autoria e consulta do grafo (já resolve o
"banco de dados de grafos" e o "visível em um site" com o mínimo de esforço — o Browser do Neo4j
*é* o site). O motor de jogo (script do loop da seção 7) lê o grafo do Neo4j via driver oficial
(Python/Node) em vez de um JSON estático.

Depois do MVP, se a ideia for **publicar** o grafo para outras pessoas verem sem precisar instalar
Neo4j, exporta-se o grafo para JSON e renderiza-se com **vis-network.js** ou **Cytoscape.js** em
uma página HTML estática simples (sem backend) — ótimo para hospedar em GitHub Pages.

### 10.2 Modelo de dados (nós e relações)

```
(:Fato {id, titulo, resumo, obrigatorio, tags})
(:Fato)-[:REQUER]->(:Fato)
(:Fato)-[:BLOQUEIA]->(:Fato)
(:Fato)-[:GATILHO {tipo, condicao}]->(:Fato)   // opcional: gatilho como nó/relação própria
```

- `REQUER`: pré-requisito (equivalente ao campo `requer` da seção 4.1).
- `BLOQUEIA`: exclusão mútua (equivalente ao campo `bloqueia`).
- Fatos "elegíveis agora" = fatos sem relação `REQUER` pendente e não alcançados por `BLOQUEIA`
  de um fato já ocorrido — isso vira uma **consulta Cypher direta**, não lógica manual no motor.

Exemplo de consulta Cypher para achar fatos elegíveis (todos os `REQUER` já satisfeitos e nenhum
`BLOQUEIA` ativo):

```cypher
MATCH (f:Fato)
WHERE f.ocorrido = false
  AND NOT EXISTS {
    MATCH (f)-[:REQUER]->(pre:Fato) WHERE pre.ocorrido = false
  }
  AND NOT EXISTS {
    MATCH (b:Fato)-[:BLOQUEIA]->(f) WHERE b.ocorrido = true
  }
RETURN f
```

### 10.3 Visualização web (o pedido do usuário)

- **Fase MVP**: Neo4j Browser (vem junto, zero código) — já mostra o grafo completo, permite
  clicar em nós, filtrar por tag/status (`ocorrido`/`obrigatorio`), e rodar a consulta acima
  visualmente colorida (fatos elegíveis em destaque).
- **Fase de vitrine pública**: página estática (`index.html` + `vis-network.js` ou
  `Cytoscape.js`) que lê um JSON exportado do Neo4j (`CALL apoc.export.json...` ou export manual)
  e desenha o grafo no navegador, com cores por status:
  - 🟢 fato já ocorrido
  - 🟡 fato elegível agora
  - ⚪ fato bloqueado/pendente
  - 🔴 fato cancelado (via `BLOQUEIA`)
- Esse site pode, inclusive, **acompanhar uma partida em andamento** (ligado ao mesmo banco), ou
  ser só um diagrama estático para mostrar a estrutura da história a quem for ler o projeto.

---

## 11. Exemplo completo: um cenário com variações (para a IA entender de forma fácil)

Este exemplo existe para servir de **referência concreta e legível por uma IA**: uma história
pequena, completa, já no formato de dados que o motor/agente vai consumir, mostrando na prática o
"roteiro fixo, improviso livre" (E/OU, ramificações, convergência).

### 11.1 A história: "O Templo Caído"

6 fatos, 1 ramificação mutuamente exclusiva, 1 ponto de convergência:

```json
{
  "historia": "o_templo_caido",
  "fatos": [
    {
      "id": "inicio_jornada",
      "titulo": "A jornada começa",
      "resumo": "O jogador deixa a vila natal após o templo começar a tremer.",
      "requer": [],
      "requer_qualquer": [],
      "bloqueia": [],
      "obrigatorio": true,
      "reversivel": false,
      "tags": ["ato_1"]
    },
    {
      "id": "encontro_guia",
      "titulo": "Encontro com o guia",
      "resumo": "Um guia excêntrico se oferece para acompanhar o jogador.",
      "requer": ["inicio_jornada"],
      "requer_qualquer": [],
      "bloqueia": [],
      "obrigatorio": true,
      "reversivel": true,
      "tags": ["ato_1"]
    },
    {
      "id": "descoberta_mapa",
      "titulo": "Descoberta do mapa antigo",
      "resumo": "O jogador encontra um mapa que indica a entrada secreta do templo.",
      "requer": ["inicio_jornada"],
      "requer_qualquer": [],
      "bloqueia": [],
      "obrigatorio": true,
      "reversivel": true,
      "tags": ["ato_1"]
    },
    {
      "id": "traidor_revelado",
      "titulo": "O traidor é revelado",
      "resumo": "Fica claro que o guia (ou outro NPC próximo) serve a um interesse oculto.",
      "requer": ["encontro_guia", "descoberta_mapa"],
      "requer_qualquer": [],
      "bloqueia": [],
      "obrigatorio": true,
      "reversivel": false,
      "tags": ["ato_2", "ponto_de_virada"]
    },
    {
      "id": "alianca_anoes",
      "titulo": "Aliança com os anões",
      "resumo": "O jogador escolhe negociar e formar aliança contra o traidor.",
      "requer": ["traidor_revelado"],
      "requer_qualquer": [],
      "bloqueia": ["guerra_anoes"],
      "obrigatorio": true,
      "reversivel": false,
      "tags": ["ato_2", "ramo_diplomacia"]
    },
    {
      "id": "guerra_anoes",
      "titulo": "Guerra contra os anões",
      "resumo": "O jogador escolhe o confronto direto em vez da negociação.",
      "requer": ["traidor_revelado"],
      "requer_qualquer": [],
      "bloqueia": ["alianca_anoes"],
      "obrigatorio": true,
      "reversivel": false,
      "tags": ["ato_2", "ramo_conflito"]
    },
    {
      "id": "queda_do_templo",
      "titulo": "A queda do templo",
      "resumo": "O templo desaba, encerrando o ato final — a causa muda conforme o caminho.",
      "requer": [],
      "requer_qualquer": ["alianca_anoes", "guerra_anoes"],
      "bloqueia": [],
      "obrigatorio": true,
      "reversivel": false,
      "tags": ["ato_3", "climax"]
    }
  ]
}
```

### 11.2 Duas jogadas diferentes, mesmo esqueleto

**Jogada A** (ordem: guia antes do mapa, caminho diplomático):

```
inicio_jornada → encontro_guia → descoberta_mapa → traidor_revelado → alianca_anoes → queda_do_templo
```

**Jogada B** (ordem: mapa antes do guia, caminho de conflito):

```
inicio_jornada → descoberta_mapa → encontro_guia → traidor_revelado → guerra_anoes → queda_do_templo
```

O que muda entre A e B:
- A **ordem** de `encontro_guia`/`descoberta_mapa` é livre (nenhum dos dois depende do outro).
- O **ramo** `alianca_anoes` × `guerra_anoes` é mutuamente exclusivo (`bloqueia` recíproco):
  escolher um cancela o outro, mas ambos satisfazem `requer_qualquer` de `queda_do_templo`.
- `queda_do_templo` sempre acontece por último em ambas as jogadas — é o ponto de convergência
  obrigatório, mas **o motivo narrado muda** conforme o ramo escolhido.
- Tudo o que acontece **entre** os fatos (diálogos, descrições, eventos bizarros) é 100%
  improviso da IA — não está no grafo e pode ser completamente diferente a cada jogada.

### 11.3 Fatos elegíveis em cada momento (o que a IA recebe a cada turno)

| Estado atual (fatos já ocorridos) | Fatos elegíveis agora |
|---|---|
| `{}` | `inicio_jornada` |
| `{inicio_jornada}` | `encontro_guia`, `descoberta_mapa` (qualquer ordem) |
| `{inicio_jornada, encontro_guia}` | `descoberta_mapa` |
| `{inicio_jornada, encontro_guia, descoberta_mapa}` | `traidor_revelado` |
| `{..., traidor_revelado}` | `alianca_anoes`, `guerra_anoes` (escolher um bloqueia o outro) |
| `{..., alianca_anoes}` **ou** `{..., guerra_anoes}` | `queda_do_templo` |
| `{..., queda_do_templo}` | — fim de jogo |

Essa tabela é exatamente o que a consulta Cypher da seção 10.2 devolve em cada turno — é por isso
que o formato de dados acima (JSON com `requer`/`requer_qualquer`/`bloqueia`) é fácil de uma IA
(ou de um script) entender e processar sem ambiguidade.

> Este mesmo exemplo é reaproveitado, em formato de instruções diretas para um agente de IA,
> no novo documento [`text-rpg-ia-agent-spec.md`](text-rpg-ia-agent-spec.md) — que pode ser usado
> como base/prompt para montar o agente mencionado na seção seguinte de pendências.

> Para um cenário concreto (vila + caverna) modelado primeiro em texto puro e depois formalizado
> no mesmo schema, e um plano de execução granular ("próximos 100 passos") a partir dele, ver
> [`text-rpg-ia-roadmap-100-passos.md`](text-rpg-ia-roadmap-100-passos.md).

---

## 12. Combate como grafo de interações

O mesmo princípio de modelar com grafos vale para o **combate tático** (ataques, magias,
empurrões, condições, superfícies interagindo entre si) — inspirado nas mecânicas de
*Baldur's Gate 3* (economia de ação, vantagem/desvantagem, superfícies e combos ambientais,
reações como ataque de oportunidade). A regra de ouro continua a mesma do resto do documento:
**o grafo decide o resultado mecânico, a IA só narra**.

O detalhamento completo — schema de nós/relações (`Personagem`, `Acao`, `Recurso`, `Condicao`,
`Superficie`, `Combo`), consultas Cypher para resolver ações e combos, um combate de exemplo
completo (o encontro com "o Eco" da Caverna do Eco) e o escopo de MVP recomendado — está em
[`text-rpg-ia-combat-graph.md`](text-rpg-ia-combat-graph.md).

---

## 13. Pendências em aberto

- [ ] Escolher a stack do script MVP (Python vs. Node vs. GDScript headless).
- [ ] Escolher o modelo de IA local para o MVP (reaproveitar Qwen de `docs/local-ai.md`?).
- [ ] Definir o formato exato da resposta estruturada da IA (JSON ao final vs. tool calling).
- [ ] Escrever a primeira história de exemplo (5-8 fatos) para testar o grafo.
- [ ] Decidir, após o MVP, se este conceito vira parte do repositório Absanter ou um projeto novo.
- [ ] Instalar/validar Neo4j Community local e importar a primeira história de exemplo.
- [ ] Escolher a biblioteca de visualização para a fase de vitrine pública (vis-network vs. Cytoscape.js).
- [ ] Definir o campo opcional `reversivel` no `story_fact` e como ele vira a tag `⚠️` na seção 6.
- [ ] Prototipar o prompt que gera as 3-5 sugestões de ação com tags de consequência (seção 6.2).
- [ ] Montar o agente de IA a partir de `text-rpg-ia-agent-spec.md` e testar com a história
      "O Templo Caído" (seção 11).
- [ ] Prototipar o MVP de combate (seção 7 de `text-rpg-ia-combat-graph.md`) usando o encontro
      com "o Eco" como primeiro caso de teste.
