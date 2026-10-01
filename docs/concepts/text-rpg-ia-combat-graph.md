# Combate como Grafo de Interações (inspirado em Baldur's Gate 3)

> **Nota de escopo**: documento irmão de [`text-rpg-ia-concept.md`](text-rpg-ia-concept.md),
> [`text-rpg-ia-agent-spec.md`](text-rpg-ia-agent-spec.md) e
> [`text-rpg-ia-roadmap-100-passos.md`](text-rpg-ia-roadmap-100-passos.md). Detalha como o
> **combate tático** (ataques, magias, empurrões, condições, superfícies) também pode ser
> modelado como um grafo — no mesmo banco (Neo4j) do grafo de história, mas com nós/relações
> próprios. Sem relação com *Absanter – Tales of Calindra*; não altera `docs/ARCHITECTURE.md`.

---

## 1. Por que combate também é um grafo

O grafo de fatos (história) responde "o que pode acontecer narrativamente agora". O combate
precisa responder uma pergunta parecida, só que em escala de segundos e turnos: **"o que esta
ação específica desencadeia, mecanicamente, agora?"** — um ataque causa dano, que pode causar uma
condição, que pode impedir outra ação, que pode interagir com uma superfície, que pode disparar
uma reação de outro personagem. Isso **é** um grafo de causa-e-efeito, só que de curtíssimo prazo.

Mantemos a mesma régua do resto do projeto (seção 5 de `text-rpg-ia-concept.md`): **a IA narra,
o grafo decide**. Números, testes de resistência, dano e condições são resolvidos
deterministicamente por consultas ao grafo/motor — a IA só veste isso de texto (ex.: "seu machado
abre um corte fundo no ombro da criatura, que cambaleia e cai sobre as pedras").

---

## 2. O que pesquisamos em Baldur's Gate 3 (resumo)

BG3 usa a base de regras de D&D 5e com extensões próprias da Larian. Os pontos centrais que
reaproveitamos no modelo:

1. **Economia de ação por turno**: cada personagem tem, por turno, 1 **Ação**, 1 **Ação Bônus**,
   **Movimento** (até um limite) e 1 **Reação** (gatilhada fora do próprio turno, ex.: ataque de
   oportunidade, Contramágica). Gastou, não volta até o próximo turno.
2. **Vantagem / Desvantagem**: em vez de modificadores numéricos complicados, testes rolam 2 dados
   e pegam o melhor (vantagem) ou o pior (desvantagem) — efeito de muitas condições e posições.
3. **Condições** (ex.: Caído, Queimando, Atordoado, Enredado, Cego, Amedrontado, Envenenado,
   Molhado): cada uma altera o que o personagem pode fazer e/ou como ele é atingido.
4. **Superfícies e combos ambientais**: fogo, óleo, água, gás venenoso, eletricidade podem
   cobrir o chão e **reagir entre si** (óleo + fogo = mais fogo; água + eletricidade = choque em
   área; água + frio = superfície escorregadia/gelo). Empurrar um inimigo para dentro de uma
   superfície ruim (ou de um precipício) é uma tática central.
5. **Empurrão (Shove)**: ação bônus, teste de Atletismo (quem empurra) vs. Atletismo/Acrobacia
   (quem resiste); se vencer, o alvo é deslocado — podendo cair de altura ou em uma superfície.
6. **Reações**: ataque de oportunidade (quando alguém sai do alcance sem usar Desengajar),
   Contramágica, Escudo (spell), entre outras — tudo é "SE eu fizer X, VOCÊ pode reagir com Y".

Isso tudo já é, na prática, um **grafo de regras declarativas** (parecido com o Osiris de BG3,
citado na seção 6.1 de `text-rpg-ia-concept.md`) — então o encaixe com nossa abordagem é direto.

---

## 3. Modelo de dados do combate (nós e relações)

### 3.1 Nós

```
(:Personagem {id, nome, pv, pv_max, ca, forca, destreza, ... , iniciativa})
(:Acao {id, nome, tipo})              // tipo: ataque | magia | empurrao | manobra | item
(:Recurso {id, nome})                 // "acao", "acao_bonus", "movimento", "reacao", "espaco_magia_N"
(:Condicao {id, nome, efeitos})       // Caído, Queimando, Atordoado, Enredado, Cego, Amedrontado...
(:Superficie {id, nome})              // Fogo, Óleo, Água, Gás Venenoso, Eletrificada, Gelo
(:Combo {id, nome, resultado})        // ex.: "Óleo + Fogo", resultado "Explosão / Fogo intenso"
```

### 3.2 Relações

```
(:Personagem)-[:CONHECE]->(:Acao)
(:Acao)-[:CONSOME]->(:Recurso)
(:Acao)-[:CAUSA {dano, tipo_dano, teste}]->(:Condicao)
(:Acao)-[:CRIA]->(:Superficie)
(:Superficie)-[:COMBINA_COM]->(:Combo)<-[:COMBINA_COM]-(:Superficie)
(:Condicao)-[:IMPEDE]->(:Acao)                      // ex.: Atordoado impede qualquer Ação
(:Condicao)-[:CONCEDE_VANTAGEM_CONTRA]->(:Personagem)
(:Acao)-[:PROVOCA_REACAO]->(:Acao)                  // ex.: Sair do alcance provoca Ataque de Oportunidade
(:Acao)-[:REQUER {tipo, valor}]->(:Condicao)         // pré-requisitos (alcance, linha de visão, etc.)
(:Personagem)-[:RESISTE_A|:IMUNE_A|:VULNERAVEL_A]->(:Condicao)
```

Esse modelo cobre literalmente os 6 pontos da seção 2: economia de ação (`CONSOME` um `:Recurso`),
dano e condições (`CAUSA`), superfícies e combos (`CRIA` + `COMBINA_COM`), empurrão (uma `:Acao`
do tipo `empurrao` que `CAUSA` a condição "Caído" ou desloca o personagem), e reações
(`PROVOCA_REACAO`).

### 3.3 Exemplo de dados: algumas ações concretas

```json
[
  {
    "acao": "ataque_machado",
    "tipo": "ataque",
    "consome": ["acao"],
    "causa": {"dano": "1d8+forca", "tipo_dano": "cortante"},
    "requer": [{"tipo": "alcance", "valor": "corpo_a_corpo"}]
  },
  {
    "acao": "maos_flamejantes",
    "tipo": "magia",
    "consome": ["acao", "espaco_magia_1"],
    "causa": {"dano": "3d6", "tipo_dano": "fogo", "teste": "destreza"},
    "cria": ["superficie_fogo"],
    "requer": [{"tipo": "alcance", "valor": "cone_curto"}]
  },
  {
    "acao": "empurrao",
    "tipo": "empurrao",
    "consome": ["acao_bonus"],
    "causa": {"teste": "atletismo_vs_atletismo_ou_acrobacia"},
    "requer": [{"tipo": "alcance", "valor": "adjacente"}]
  },
  {
    "acao": "ataque_de_oportunidade",
    "tipo": "ataque",
    "consome": ["reacao"],
    "causa": {"dano": "1d8+forca", "tipo_dano": "cortante"},
    "provocado_por": "sair_do_alcance_sem_desengajar"
  }
]
```

---

## 4. Consultas Cypher centrais

### 4.1 O personagem pode usar esta ação agora? (checagem de recursos + impedimentos)

```cypher
MATCH (p:Personagem {id: $personagem_id})-[:CONHECE]->(a:Acao {id: $acao_id})
MATCH (a)-[:CONSOME]->(r:Recurso)
WHERE NOT EXISTS {
  MATCH (p)-[:RECURSO_GASTO_NO_TURNO]->(r)
}
AND NOT EXISTS {
  MATCH (p)-[:TEM_CONDICAO]->(c:Condicao)-[:IMPEDE]->(a)
}
RETURN a, collect(r) AS recursos_necessarios
```

### 4.2 Resolver uma superfície combinando com outra (combo ambiental)

```cypher
MATCH (s1:Superficie {id: $superficie_existente})-[:COMBINA_COM]->(combo:Combo)<-[:COMBINA_COM]-(s2:Superficie {id: $superficie_nova})
RETURN combo.resultado
```

### 4.3 Checar o que uma condição impede/concede antes de validar uma ação

```cypher
MATCH (p:Personagem {id: $personagem_id})-[:TEM_CONDICAO]->(c:Condicao)
OPTIONAL MATCH (c)-[:IMPEDE]->(a:Acao)
OPTIONAL MATCH (c)-[:CONCEDE_VANTAGEM_CONTRA]->(p)
RETURN c.nome, collect(DISTINCT a.nome) AS acoes_impedidas
```

### 4.4 Fim de turno: liberar recursos

```cypher
MATCH (p:Personagem {id: $personagem_id})-[rg:RECURSO_GASTO_NO_TURNO]->(:Recurso)
DELETE rg
```

(a `:Reacao` é a exceção parcial: ela só reseta no **início** do próprio turno do personagem,
não no fim do turno de quem a provocou — isso vira uma flag/propriedade separada, não detalhada
aqui para não inflar o MVP.)

---

## 5. Exemplo de combate completo: o encontro com "o Eco"

Reaproveitando o cenário de `text-rpg-ia-roadmap-100-passos.md` (Caverna do Eco), um combate
simples no **Salão do Cristal**, mostrando a cadeia de causa-e-efeito como grafo:

**Turno do jogador:**
1. Jogador conjura `maos_flamejantes` no Eco → consome `acao` + `espaco_magia_1` → `CAUSA` dano de
   fogo (teste de Destreza) e `CRIA` a superfície `fogo` no chão sob o Eco.
2. O chão do Salão já tinha uma poça de `agua_parada` (ambientação da caverna) — o motor checa
   `COMBINA_COM` entre `fogo` e `agua_parada`: resultado é `vapor_denso` (combo: reduz visibilidade,
   não dano) em vez de uma explosão (isso é água, não óleo — combo diferente do exemplo da seção 2).
3. Jogador usa `empurrao` (ação bônus) contra o Eco, já enfraquecido — teste de Atletismo vence →
   o Eco é deslocado para a beira do Poço Escuro adjacente.

**Reação do Eco (fora do turno do jogador, mas disparada pela consulta 4.1 no próximo turno dele):**
4. O Eco, arrasado e à beira do poço, tenta uma `acao` de "recuar" — o motor checa `IMPEDE`: ele
   não tem nenhuma condição que o impeça, então a ação é permitida; a IA narra o Eco tentando se
   agarrar à borda.

**Resolução narrada pela IA (determinada pelo grafo, vestida em texto):**
> As chamas sobem pelas pedras cobertas de musgo, e o vapor espesso enche o Salão do Cristal.
> O Eco — ainda reverberando um grito que não é mais seu — perde o equilíbrio na borda do poço,
> os dedos de pedra raspando em busca de apoio. Por um instante, ele some na escuridão lá embaixo.

Note que **nenhum número apareceu na narração** — a IA recebeu do motor algo como
`{"alvo": "o_eco", "resultado": "deslocado_para_borda_poco_escuro", "condicao_risco": "pode_cair"}`
e transformou isso em prosa, exatamente como já fazem a narração e as sugestões de ação do resto
do sistema (seções 3 e 6 de `text-rpg-ia-agent-spec.md`).

---

## 6. Integração com o grafo de história

Um combate pode, ele mesmo, **ser** (ou desbloquear) um fato da história:

- `encontro_eco` (seção 3 de `text-rpg-ia-roadmap-100-passos.md`) é o fato que **inicia** o
  combate — o motor muda de "modo narrativo" para "modo combate" ao processar esse fato.
- O **resultado** do combate decide qual fato acontece a seguir: Eco empurrado no poço e não
  resgatado → tende a `eco_dominado`; Eco poupado/curado a meio do combate → tende a
  `eco_acalmado`. A ponte entre "resultado do combate" e "qual fato ocorre" é só mais uma
  condição no grafo de história (seção 4.2 de `text-rpg-ia-concept.md`), não um sistema novo.
- Combate **não precisa** sempre levar a um fato — encontros aleatórios/opcionais (recheio) usam
  o mesmo grafo de combate sem nunca tocar no grafo de história.

---

## 7. Escopo do MVP (não tentar o BG3 inteiro de uma vez)

BG3 tem centenas de magias, condições e interações. Para o primeiro ciclo (mesmo da
`text-rpg-ia-roadmap-100-passos.md`), o subconjunto mínimo recomendado é:

- **3 ações**: `ataque_corpo_a_corpo`, 1 `magia` simples com superfície, `empurrao`.
- **3 condições**: `caido`, `queimando`, `atordoado`.
- **2 superfícies** e **1 combo** entre elas (ex.: óleo + fogo).
- **Economia de ação completa** (ação, ação bônus, movimento, reação) desde o início — é a peça
  que mais estrutura o resto, vale implementar cedo mesmo que com poucas ações.
- **1 reação**: ataque de oportunidade.

Esse subconjunto já é suficiente para o combate do "Eco" na seção 5 e para validar o modelo de
dados inteiro (seção 3) antes de adicionar mais magias/condições — mesma filosofia de "esqueleto
primeiro, conteúdo depois" do resto do projeto.

---

## 8. Pendências em aberto

- [ ] Decidir se o combate roda turno a turno automaticamente (iniciativa calculada) ou se o
      jogador comanda cada passo em texto livre, com o motor resolvendo por trás.
- [ ] Definir o formato exato de teste (d20 + vantagem/desvantagem) e onde ele é calculado
      (motor, não a IA — reforçar isso no prompt de sistema do agente).
- [ ] Modelar a propriedade de "Reação disponível" separadamente do reset de fim de turno
      (seção 4.4), já que reação reseta no início do turno do dono, não no fim do turno alheio.
- [ ] Expandir a lista de condições e superfícies além do MVP da seção 7, iteração a iteração.
- [ ] Escrever o combate do "Eco" (seção 5) como dado real (JSON/Cypher) e testar no motor do
      roadmap de 100 passos.
