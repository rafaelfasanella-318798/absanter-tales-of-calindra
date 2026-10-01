# Roadmap de 100 Passos · Vila de Pedrassolo e a Caverna do Eco

> **Nota de escopo**: documento irmão de [`text-rpg-ia-concept.md`](text-rpg-ia-concept.md) e
> [`text-rpg-ia-agent-spec.md`](text-rpg-ia-agent-spec.md). Aqui a ideia sai do abstrato
> ("O Templo Caído", usado como exemplo didático) e vira um **cenário concreto e pequeno** —
> uma vila e uma caverna — modelado primeiro **em texto puro**, para depois formalizar em dados e
> iterar. Sem relação com *Absanter – Tales of Calindra*; não altera `docs/ARCHITECTURE.md`.

---

## 1. Por que modelar em texto antes de qualquer dado/código

A ordem de trabalho aqui é deliberada: **primeiro escrever o mundo como prosa**, do jeito que um
mestre de RPG de mesa escreveria suas anotações — lugares, gente, objetos, atmosfera — e só
**depois** extrair disso o grafo de fatos (JSON/Neo4j). Isso evita desenhar uma estrutura de dados
bonita para uma história que ainda não existe. A cada iteração, o texto manda; os dados seguem.

---

## 2. O mundo em texto puro

### 2.1 A Vila de Pedrassolo

> Pedrassolo é uma vila pequena encaixada entre dois morros de pedra cinza, com um rio raso
> cortando a praça central. As casas são de madeira escura e telhado de ardósia. Desde que os
> ecos começaram a sair da Caverna, ao norte, ninguém mais sobe sozinho até lá.

**Lugares da vila:**
- **Praça central**: poço, mercado fraco, ponto de encontro. É onde o jogador chega.
- **Ferraria de Bor**: Bor é desconfiado, fala pouco, mas sabe mais sobre a caverna do que admite
  — ele perdeu um irmão lá dentro, anos atrás.
- **Taverna do Corvo Manco**: o taverneiro Dom adora fofoca e exagera tudo; é a fonte cômica e
  também a fonte de pistas erradas (bom gatilho para "recheio" bizarro da IA).
- **Casa da anciã Mira**: Mira é a guardiã da memória da vila; ela conhece a lenda verdadeira da
  Caverna do Eco e só conta se o jogador for respeitoso ou muito insistente.
- **Portão norte**: saída da vila, estrada de pedras soltas até a entrada da caverna.

**NPCs da vila:**
- **Bor, o ferreiro**: pista prática (um mapa de minas rabiscado, ou um item útil forjado por ele).
- **Dom, o taverneiro**: fofocas, histórias exageradas, possíveis pistas falsas/engraçadas.
- **Mira, a anciã**: a lenda verdadeira — fala do "Eco" como algo que "lembra o que a pedra
  esqueceu", plantando a ambiguidade sobre se a criatura da caverna é inimiga ou não.

### 2.2 A Caverna do Eco

> A entrada é uma fenda estreita no morro norte, sempre fria, sempre com um zumbido baixo vindo de
> dentro — como se a própria pedra estivesse cantarolando. Quanto mais fundo, mais os sons do
> jogador (passos, respiração, palavras) voltam distorcidos, atrasados, às vezes dizendo coisas que
> ele não disse.

**Lugares da caverna:**
- **Entrada / Galeria dos Ecos**: primeira câmara, onde sons começam a repetir de forma estranha.
- **Poço Escuro**: uma descida vertical, perigosa, com uma corda velha (pode ou não aguentar).
- **Salão do Cristal**: câmara funda, iluminada por um cristal pulsante — fonte do "Eco".
- **Saída secreta**: uma fenda lateral que leva de volta à vila por outro caminho (atalho/bônus).

**O "Eco" (criatura/entidade da caverna):**
- Não é descrito como monstro clássico — é uma presença que **repete e distorce** o que o jogador
  diz e faz, lentamente assumindo uma "forma" baseada nas próprias ações do jogador. Isso dá à IA
  um gancho natural para gerar reações bizarras e personalizadas no recheio.
- O confronto final não precisa ser "matar"; pode ser **dominar, acalmar, fugir ou se aliar** —
  textualmente aberto, mas estruturalmente só duas saídas contam para o grafo (ver seção 3):
  `eco_dominado` (conflito) ou `eco_acalmado` (diplomacia/aceitação).

---

## 3. Formalização: o grafo de fatos deste cenário

Convertendo a prosa acima em dados, seguindo o schema de `text-rpg-ia-concept.md` (seções 4 e 4.4):

```json
{
  "historia": "a_caverna_do_eco",
  "fatos": [
    {"id": "chegada_vila", "titulo": "Chegada a Pedrassolo", "requer": [], "requer_qualquer": [], "bloqueia": [], "obrigatorio": true, "reversivel": false, "tags": ["ato_1", "vila"]},
    {"id": "conversa_mira", "titulo": "A lenda da anciã Mira", "requer": ["chegada_vila"], "requer_qualquer": [], "bloqueia": [], "obrigatorio": true, "reversivel": true, "tags": ["ato_1", "vila"]},
    {"id": "pista_bor", "titulo": "A pista prática do ferreiro Bor", "requer": ["chegada_vila"], "requer_qualquer": [], "bloqueia": [], "obrigatorio": true, "reversivel": true, "tags": ["ato_1", "vila"]},
    {"id": "entrada_liberada", "titulo": "Caminho até a caverna conhecido", "requer": [], "requer_qualquer": ["conversa_mira", "pista_bor"], "bloqueia": [], "obrigatorio": true, "reversivel": false, "tags": ["ato_1", "transicao"]},
    {"id": "galeria_dos_ecos", "titulo": "Atravessar a Galeria dos Ecos", "requer": ["entrada_liberada"], "requer_qualquer": [], "bloqueia": [], "obrigatorio": true, "reversivel": true, "tags": ["ato_2", "caverna"]},
    {"id": "poco_escuro", "titulo": "Descer o Poço Escuro", "requer": ["galeria_dos_ecos"], "requer_qualquer": [], "bloqueia": [], "obrigatorio": true, "reversivel": true, "tags": ["ato_2", "caverna"]},
    {"id": "encontro_eco", "titulo": "Encontro com o Eco", "requer": ["poco_escuro"], "requer_qualquer": [], "bloqueia": [], "obrigatorio": true, "reversivel": false, "tags": ["ato_2", "ponto_de_virada"]},
    {"id": "eco_dominado", "titulo": "O Eco é dominado/derrotado", "requer": ["encontro_eco"], "requer_qualquer": [], "bloqueia": ["eco_acalmado"], "obrigatorio": true, "reversivel": false, "tags": ["ato_3", "ramo_conflito"]},
    {"id": "eco_acalmado", "titulo": "O Eco é acalmado/aceito", "requer": ["encontro_eco"], "requer_qualquer": [], "bloqueia": ["eco_dominado"], "obrigatorio": true, "reversivel": false, "tags": ["ato_3", "ramo_diplomacia"]},
    {"id": "cristal_recuperado", "titulo": "O cristal do Salão é recuperado", "requer": [], "requer_qualquer": ["eco_dominado", "eco_acalmado"], "bloqueia": [], "obrigatorio": true, "reversivel": false, "tags": ["ato_3", "climax"]},
    {"id": "retorno_vila", "titulo": "Retorno a Pedrassolo com o cristal", "requer": ["cristal_recuperado"], "requer_qualquer": [], "bloqueia": [], "obrigatorio": true, "reversivel": false, "tags": ["ato_3", "final"]}
  ]
}
```

11 fatos: 2 pares de ordem livre (`conversa_mira`/`pista_bor`), 1 convergência OU
(`entrada_liberada`), 1 ramo de exclusão mútua (`eco_dominado`/`eco_acalmado`), 1 segunda
convergência OU (`cristal_recuperado`), fechando em `retorno_vila`. Pequeno o bastante para
implementar em poucos dias, grande o bastante para testar todas as regras já definidas.

---

## 4. Os próximos 100 passos

Organizados em 10 fases de ~10 passos. Cada passo é pequeno e verificável — a ideia é poder
marcar `[x]` e sempre saber exatamente o que fazer em seguida.

### Fase 1 — Aprofundar o texto (mundo e tom), passos 1-10
1. Escrever 1 parágrafo de "primeira impressão" para cada um dos 5 lugares da vila.
2. Escrever 1 parágrafo de "primeira impressão" para cada um dos 4 lugares da caverna.
3. Escrever 3 falas de exemplo para Bor (desconfiado, curto, nunca fala do irmão de primeira).
4. Escrever 3 falas de exemplo para Dom (exagerado, cômico, adora rumores absurdos).
5. Escrever 3 falas de exemplo para Mira (enigmática, fala da "pedra que lembra").
6. Decidir e anotar 2-3 "coisas bizarras" que podem acontecer na Galeria dos Ecos (recheio da IA).
7. Decidir como o Eco "fala" (ecoa o jogador com leve distorção — escrever 2 exemplos).
8. Escrever o texto de abertura do jogo (as 2-3 primeiras frases que o jogador vê).
9. Escrever o texto de cada um dos dois finais (`eco_dominado` e `eco_acalmado`).
10. Revisar tudo acima em voz alta/lendo — ajustar tom para "o que soa divertido de jogar".

### Fase 2 — Formalizar o grafo de fatos, passos 11-20
11. Validar o JSON da seção 3 contra o schema de `text-rpg-ia-concept.md` (seção 4.1/4.4).
12. Conferir manualmente as 2 jogadas possíveis (ordem Mira→Bor e Bor→Mira) chegam ao mesmo lugar.
13. Conferir que os dois ramos (`eco_dominado`/`eco_acalmado`) de fato se bloqueiam mutuamente.
14. Adicionar o campo `gatilho` (texto curto) em cada fato — que tipo de ação do jogador ativa.
15. Adicionar 1-2 `flags` de estado além dos fatos (ex.: `tem_mapa_bor`, `respeitou_mira`).
16. Decidir se `conversa_mira` exige "respeito" (flag) ou é sempre elegível — documentar a regra.
17. Escrever as tags de consequência (`⚠️`/`🎲`/`🔀`) esperadas para 2-3 ações-chave de cada fato.
18. Revisar o grafo com a pergunta: "dá pra pular um fato obrigatório sem querer?" (não deve dar).
19. Salvar o JSON final da história em `data/historias/a_caverna_do_eco.json` (quando o repo do
    protótipo existir — ver passo 31).
20. Marcar esta fase como concluída e revisar com o usuário antes de seguir ("OK" de aprovação).

### Fase 3 — Escolher e preparar o ambiente técnico, passos 21-30
21. Confirmar a stack do script MVP (Python, Node ou outra) — decisão já pendente desde o
    primeiro documento; resolver aqui antes de codar.
22. Instalar/validar Neo4j Community local (Desktop ou Docker).
23. Validar acesso ao Neo4j Browser em `http://localhost:7474`.
24. Instalar o driver oficial do Neo4j na linguagem escolhida.
25. Validar o Ollama local já configurado (`docs/local-ai.md`) respondendo a um prompt simples.
26. Escolher o modelo local para o MVP (ex.: Qwen2.5-Coder-7B para iteração rápida).
27. Criar a pasta do protótipo (ex.: `text-rpg-prototipo/`) fora da árvore de Godot do Absanter.
28. Inicializar o projeto (ex.: `requirements.txt`/`package.json`) com as dependências mínimas.
29. Criar um `README.md` curto no protótipo explicando como rodar (espelha os docs de conceito).
30. Decidir e anotar: este protótipo vive neste mesmo repositório ou em repositório separado?

### Fase 4 — Carregar o grafo no Neo4j, passos 31-40
31. Escrever o script de import que lê o JSON da seção 3 e cria os nós `:Fato` no Neo4j.
32. Criar as relações `REQUER` a partir do campo `requer` de cada fato.
33. Criar as relações `BLOQUEIA` a partir do campo `bloqueia` de cada fato.
34. Criar as relações `REQUER_QUALQUER` (nova, para o campo `requer_qualquer` — OU).
35. Adicionar a propriedade `ocorrido: false` em todos os fatos na criação.
36. Rodar a consulta de fatos elegíveis (seção 10.2 do doc de conceito) adaptada para considerar
    também `REQUER_QUALQUER` (ajustar o `WHERE NOT EXISTS` para aceitar "pelo menos um").
37. Testar a consulta manualmente no Neo4j Browser com `chegada_vila.ocorrido = true`.
38. Testar a consulta com `eco_dominado.ocorrido = true` e confirmar que `eco_acalmado` some da
    lista de elegíveis (bloqueio mútuo funcionando).
39. Visualizar o grafo completo no Neo4j Browser e tirar um print para registro.
40. Documentar a consulta final de "fatos elegíveis" no próprio `text-rpg-ia-concept.md` (seção 10).

### Fase 5 — Motor de jogo mínimo (sem IA ainda), passos 41-50
41. Escrever a função que lê o estado atual do Neo4j (fatos ocorridos + flags).
42. Escrever a função que consulta os fatos elegíveis a partir do estado.
43. Escrever o loop de leitura de comando do jogador (texto livre, `input()`/`readline`).
44. Implementar uma narração **hardcoded** (sem IA) para cada fato, só para validar o loop inteiro
    de ponta a ponta (ex.: imprimir o resumo do fato quando ele for "forçado" a ocorrer).
45. Implementar o comando de forçar um fato manualmente (modo debug) para testar o grafo todo.
46. Rodar o jogo do início ao fim no modo debug, caminho A (Mira→Bor→dominar o Eco).
47. Rodar o jogo do início ao fim no modo debug, caminho B (Bor→Mira→acalmar o Eco).
48. Confirmar que os dois caminhos terminam em `retorno_vila` e que o jogo encerra corretamente.
49. Adicionar uma tela de "fatos ocorridos até agora" (debug) para facilitar o desenvolvimento.
50. Commitar o motor mínimo funcional (sem IA) como marco ("funciona o esqueleto, falta a carne").

### Fase 6 — Integrar a IA (Ollama) ao loop, passos 51-65
51. Escrever o prompt de sistema do agente a partir de `text-rpg-ia-agent-spec.md` (seções 1-4).
52. Adaptar o prompt de sistema citando o mundo de Pedrassolo (nomes, tom, personagens).
53. Montar a função que serializa estado + fatos elegíveis no formato JSON da seção 2 do agent-spec.
54. Enviar o prompt + entrada ao Ollama e capturar a resposta bruta.
55. Escrever o parser que separa a narração em texto livre do bloco JSON final da resposta.
56. Validar o parser com as duas transcrições de exemplo do `text-rpg-ia-agent-spec.md` (seção 5).
57. Implementar a validação de saída: `fato_consumido` está em `fatos_elegiveis`? tags são válidas?
58. Implementar a lógica de "descarta e re-pede" quando a validação falhar.
59. Aplicar `mudancas_estado` e `fato_consumido` validado de volta no Neo4j.
60. Rodar o primeiro turno real (chegada à vila) com a IA e conferir a narração gerada.
61. Rodar a sequência completa de "conversa com Mira" com a IA, sem forçar fatos manualmente.
62. Rodar a sequência completa de "pista do Bor" com a IA.
63. Rodar o encontro com o Eco até um dos dois ramos, deixando a IA decidir o texto (não o fato).
64. Ajustar o prompt de sistema conforme os resultados (tom bizarro demais? sério demais?).
65. Commitar a primeira versão jogável de ponta a ponta com IA real.

### Fase 7 — Sugestão de ações e tags de consequência, passos 66-75
66. Implementar o envio de `fatos_bloqueaveis` junto da entrada da IA a cada turno.
67. Validar que a IA usa `⚠️` corretamente nas sugestões próximas ao ramo `eco_dominado`/`eco_acalmado`.
68. Validar que `🔀` aparece quando a sugestão pode levar a um fato elegível diferente (ex.:
    sugerir ir falar com Mira vs. com Bor logo na chegada).
69. Validar que `🎲` aparece em sugestões de puro recheio (sem fato estrutural ligado).
70. Exibir as sugestões formatadas no console, numeradas, como no exemplo da seção 6.2 do doc de
    conceito.
71. Implementar a opção de o jogador digitar o número da sugestão em vez do texto completo.
72. Testar o fluxo misto: ora escolher sugestão por número, ora digitar ação totalmente livre.
73. Revisar com o usuário se as tags estão claras/úteis na prática (ajuste de UX de texto).
74. Ajustar o prompt para limitar a 3-5 sugestões sempre (nunca 0, nunca mais que 5).
75. Commitar a feature de sugestão de ações como concluída.

### Fase 8 — Playtests de variação, passos 76-85
76. Jogar a história inteira 1 vez escolhendo sempre a primeira sugestão (teste de "piloto automático").
77. Jogar a história inteira 1 vez digitando só ações livres, ignorando as sugestões.
78. Jogar a história inteira 1 vez tentando quebrar o contrato (pedir à IA pra pular o Eco) e
    confirmar que o motor não deixa.
79. Jogar escolhendo o ramo `eco_dominado` e anotar o texto final gerado.
80. Jogar escolhendo o ramo `eco_acalmado` e anotar o texto final gerado.
81. Comparar os dois finais — checar se a narrativa reflete bem a escolha estrutural.
82. Testar a ordem Bor→Mira e Mira→Bor lado a lado — confirmar que ambas soam naturais.
83. Listar os bugs/estranhezas encontrados nos playtests (tabela simples de issues).
84. Corrigir os 3 problemas mais importantes encontrados.
85. Repetir 1 playtest completo após as correções para confirmar que não regrediu nada.

### Fase 9 — Visualização web do grafo, passos 86-95
86. Abrir o Neo4j Browser durante uma partida e observar os fatos mudando de cor/estado ao vivo.
87. Escrever a consulta Cypher de exportação do grafo completo para JSON.
88. Montar a página estática (`index.html` + vis-network.js ou Cytoscape.js) conforme a seção
    10.3 do `text-rpg-ia-concept.md`.
89. Aplicar as cores por status (🟢 ocorrido, 🟡 elegível, ⚪ pendente, 🔴 bloqueado) no grafo web.
90. Testar a página localmente abrindo o HTML direto no navegador (sem servidor).
91. Decidir se essa página vai acompanhar uma partida ao vivo (lendo do Neo4j) ou só mostrar a
    estrutura estática da história "A Caverna do Eco".
92. Publicar a versão estática em GitHub Pages (se decidido no passo 30 que o protótipo é público).
93. Adicionar um link para essa página no `text-rpg-ia-concept.md` (seção 9.3) como exemplo real.
94. Tirar capturas de tela da visualização para documentação.
95. Commitar a vitrine web como concluída.

### Fase 10 — Fechar o ciclo e planejar a próxima iteração, passos 96-100
96. Escrever um relatório curto (estilo `docs/RELATORIO-Gx.md`) resumindo o que foi aprendido com
    "A Caverna do Eco" como primeiro cenário completo.
97. Levantar 3-5 ideias de próximo cenário (maior, com mais ramos) para a segunda iteração.
98. Decidir, com base no que funcionou, se algum ajuste é necessário no schema de fatos (seção 4
    do `text-rpg-ia-concept.md`) antes de escalar.
99. Revisar com o usuário (decisor) se o rumo está bom e pedir aprovação (`OK`) para seguir.
100. Definir o escopo do próximo mundo/cenário e reiniciar o ciclo a partir da Fase 1.

---

## 5. Critério de "pronto" deste primeiro ciclo

O ciclo de 100 passos está completo quando: o jogador consegue jogar "A Caverna do Eco" do início
ao fim, em pelo menos duas ordens/ramos diferentes, 100% em texto, com a IA improvisando o recheio
e sugerindo ações com tags de consequência, e o grafo da história sendo visível em uma página web.
