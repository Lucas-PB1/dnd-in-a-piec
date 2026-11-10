# Arquitetura: como as peças se ligam

Mapa do sistema para quem vai mexer no código (pessoa ou IA). As **decisões** (o quê e por quê)
estão em `docs/adr/` (índice no `CLAUDE.md`); as **regras de código**, nas skills `.claude/skills/godot-*`. Aqui está o
**como**: quem chama quem, por onde passa um golpe, onde mora cada número.

---

## 1. Camadas

```
data/ (.tres)        números e itens: armas, armaduras, munição, classe, criaturas, pacotes
   ▲ lidos por
core/dados/          Resources: Arma, Armadura, Municao, Item, ClasseRPG, CriaturaRPG, PacoteInicial, PoseGolpe
core/regras/         regras puras (RefCounted, testáveis sem cena): Dado, Atributos, Ficha, Combate,
                     Golpe, Inventario, Equipamento, Proficiencias, TiposDano, EscalaDnd,
                     CompraDePontos, Armadilha
core/componentes/    nós reutilizáveis: Hitbox, Hurtbox, Defesa, Health, Condicoes, TextoFlutuante
core/estados/        Estado, MaquinaEstados (genéricos)
core/utilitarios/    ToqueDuplo, DesenhoArma, Recursos, Comandos, OpcoesToque
   ▲ usados por
features/<nome>/     entidades: jogador, gray_ooze, goblin (+ variantes), ankheg, minotauro,
                     wight, quimera, bloco_quebravel, loja (NPC), boneco_treino, bau, arremesso
core/projeteis/      Flecha compartilhada (2+ features)
core/regras/loja.gd  e saque.gd: ouro, comprar/vender (regra pura; a tela é `ui/loja/`)
ui/<tela>/           telas e apresentação: titulo, criacao_personagem, hud, inventario, bau,
                     loja, comandos, derrota, vitoria, controles_toque, bestiario, habilidades,
                     pausa, compendio (páginas e montagem do conteúdo), talento
   ▲ montados por
levels/main.gd       a ÚNICA peça que conhece todas as outras: liga sinais e chama APIs públicas
```

Regras de dependência (skill `godot-estrutura-pastas`):
- `core/` não conhece `features/`, `ui/` nem `levels/`.
- Uma feature **nunca** importa outra (o goblin não conhece o herói; recebe um `Node2D` em `definir_alvo`).
- `ui/` não conhece o herói: emite um sinal "pedido" e a `main` chama `abrir(...)` com os dados.
- `levels/main.gd` pode carregar cenas de `features/` e `ui/`.

## 2. A cena principal (`levels/main.tscn`)

```
Main (main.gd)
├── Fase               (Fase atual; início, limites, pontos de armadilha, loja e porta)
├── Lojista            (NPC no início da fase; abre TelaLoja)
├── Bau                (abrir_pedido(itens) -> main abre TelaBau)
├── BonecoTreino       (CA 10, só mostra o resultado)
├── Jogador            (sinais: vida_mudou, folego_mudou, progressao_mudou, surto_acao_pedido...)
├── Hud
├── ControlesToque     (CanvasLayer 5: analógico/setas/botões; edição do layout)
└── Interface          (CanvasLayer 10)
    ├── TelaInventario (I)
    ├── TelaBau
    ├── TelaLoja
    ├── TelaComandos   (C: teclas, trazer criatura, opções e ajuste do toque)
    ├── TelaPausa      (Esc / Menu no celular)
    ├── TelaBestiario
    ├── TelaHabilidades
    ├── TelaCompendio   (abre pela pausa ou pelo título)
    ├── TelaTalento     (escolha de talento geral ao subir de nível)
    └── Telas de título, derrota e vitória (abertas conforme o fluxo)
```

Fluxo do jogo: `Main._ready` -> título -> criação -> **dez fases** -> vitória (`fase.ultima`).
Título, criação, derrota e vitória usam `_pausar(true)`, que pausa a árvore, esconde o HUD e os
controles de toque. Inventário, baú, loja e comandos pausam por conta própria (`get_tree().paused`).

**Loja em três camadas (intencional):** regra pura em `core/regras/loja.gd` (+ `saque.gd` para
ouro/drops), NPC em `features/loja/`, tela em `ui/loja/`. A `main` liga os três.

## 3. Campanha e encontros

`levels/fase_1..10.tscn` compartilham `Fase`: cada uma expõe o início, a área jogável, o limite de
queda, os pontos do grupo `armadilha`, o índice, a cota, os tipos permitidos e, nas fases de chefe,
`chefe` / `acompanhantes_do_chefe`. A porta emite `porta_tocada` e `porta_liberada`; a `main`
avança quando todos os inimigos da cota (e o chefe, se houver) morreram.
`core/regras/armadilha.gd` escolhe pontos sem repetição e tipos com uma semente controlável. O
nível soma inimigos à cota e libera tipos mais fortes; derrotas concedem XP e ouro. Uma fase nova
repõe PV e recursos como descanso longo. "Tentar de novo" repõe a vida e sorteia a fase atual
outra vez; a porta da fase 10 abre a vitória.
O botão de vitória recomeça na Clareira. Baú e boneco de treino só funcionam na primeira fase.

Todo inimigo pertence ao grupo `monstros` e precisa expor `definir_alvo(alvo: Node2D)`. A `main`
define também a Percepção passiva para quem se esconde. Criaturas trazidas pela tela de comandos
ficam fora da cota; "Tirar da arena" apaga todas e deixa a porta livre.

## 4. O caminho de um golpe

```
Atacante                         Alvo
────────                         ────
Ficha / CriaturaRPG
  └─ monta Golpe (nome, bônus, dado, tipo, maestria, vantagem...)
HitboxComponent.ligar(golpe)
  └─ a cada quadro: o MAIS PERTO
     entre as Hurtboxes tocando ──► HurtboxComponent.receber_golpe(golpe, origem)
                                      └─ sinal golpe_recebido
                                   DefesaComponent
                                      ├─ CondicoesComponent.preparar_golpe_recebido (Caído/Atormentado = vantagem)
                                      ├─ Combate.resolver_ataque(golpe, CA, rng, resistências)
                                      │    d20 (+vantagem/desvantagem) + bônus >= CA; 20 crítico; 1 erra;
                                      │    dano dos dados (+mod.), mínimo 1; resistência = metade; Raspão
                                      ├─ HealthComponent.receber_dano -> vida_mudou / morreu
                                      ├─ CondicoesComponent.aplicar_maestria (Empurrar, Derrubar...)
                                      └─ sinal golpe_resolvido(resultado) -> o dono reage
                                         (TextoFlutuante, estado LevandoDano, corrosão...)
```

- **Um golpe acerta um alvo** (o mais perto). Trespassar entrega `golpe.trespassar` a um 2º alvo perto.
- Projéteis (`ArmaArremessada` do herói, `ProjetilArremesso` das criaturas) carregam uma Hitbox com o mesmo `Golpe`;
  além do alcance normal marcam `golpe.desvantagem = true`; no longo desligam a Hitbox e caem.
- Camadas de física: 1 `mundo`, 2 `jogador`, 3 `hurtbox_inimigo` (valor 4), 4 `hurtbox_jogador`
  (valor 8), 5 `inimigo` (valor 16). Hitbox de inimigo: máscara 8. Hitbox do herói: máscara 4.

## 5. O herói (`features/jogador/`)

- `jogador.gd` (`Jogador`): **ferramentas de física e API pública**. Não decide comportamento.
- `estados/` (máquina de estados): `Parado`, `Andando`, `Correndo`, `NoAr`, `Atacando`,
  `Arremessando`, `LevandoDano`, `Escalando` (Atleta), `Caido` (derrubado). Cada estado chama
  ferramentas do `Jogador` e emite `trocar_para`.
- Componentes visuais **sem conhecer o Jogador** (call down): `AnimacaoJogador`, `CameraJogador`,
  `AtaqueJogador` (arma na mão, golpe por poses, quadros do disparo), `ArmaTras`, `EscudoJogador`.
- Números de movimento em `data/jogador_padrao.tres` (`StatsJogador`). **Velocidade e ritmo de
  ataque vêm da ficha** (deslocamento e iniciativa, via `EscalaDnd`).
- Ficha (`Ficha`) + inventário (`Inventario`) -> `Equipamento` calcula arma na mão, CA,
  deslocamento e o `Golpe` (o inventário da tela usa a mesma conta).
- `Ficha` acompanha XP e nível **1–6** (`NIVEL_MAXIMO`); talentos gerais nos níveis 4 e 6;
  Ataque Extra no 5. `Jogador` resolve testes de perícia e aplica Mente Tática quando ativada.
  A `main` entrega XP de inimigos, escala as cotas e aplica o Surto de Ação.

## 6. Criaturas

Features: `gray_ooze/`, `goblin/` (Minion, Warrior e variantes Kobold/Hobgoblin/Bugbear/Skeleton/Zombie
por herança), `ankheg/`, `minotauro/`, `wight/`, `quimera/`, `bloco_quebravel/`.

Três camadas (ADR `criaturas.md`): **kit sempre** (`MontagemDeCriatura` — ficha nos componentes,
empurrão, Lentidão, saltador), **capacidades da ficha** (arremesso/disparo/sol/…; em migração
para `core/`), **específico** (encenação do chefe). Molde simples: Ooze. Com capacidades: Goblin.

- Script raiz: chama `MontagemDeCriatura` no `_ready`, expõe ferramentas dos estados
  (`alvo_percebido`, `andar_para_alvo`, `ligar_golpe`…) e reage a `golpe_resolvido`.
- `estados/`: base tipada + um script por estado. Nós: `Sprite`, `Vida`, `Hurtbox`, `Defesa`,
  `Texto`, `Condicoes`, Hitbox, `MaquinaEstados`.
- Ritmo: `EscalaDnd.intervalo_ataque(iniciativa)`. Andar: `MontagemDeCriatura.velocidade_andar`.
- Chefes usam o mesmo kit; a máquina extra é o específico (cavar, investir, voar…).

## 7. Itens e equipamento

- `Item` (base): nome, descrição, ícone, `espaco` (`mao`, `mao_secundaria`, `corpo`), `empilhavel`.
- `Arma` e `Armadura` são `Item`; `Municao` também (empilhável, não equipa).
- **Os .tres de armas, armaduras e munição são GERADOS**: edite a TABELA em
  `tools/gerar_armas.gd` / `tools/gerar_armaduras.gd` e rode o gerador (ver `docs/how-to/receitas.md`).
- `Inventario` guarda **cópias** e o desgaste (corrosão) por item; o `.tres` nunca muda no jogo.

## 8. Entrada (teclado e toque)

- Ações do InputMap (`project.godot`): `mover_esquerda`, `mover_direita`, `mover_baixo`, `pular`,
  `atacar`, `arremessar`, `folego`, `inventario`, `interagir`, `comandos`, `correr`, `mirar_cima`.
- O código de jogo **só lê ações** (`Input.is_action_*`). Teclado e toque apertam as mesmas ações:
  `BotaoToque` mantém a ação pressionada e propaga `InputEventAction` para telas que tratam
  interações em `_unhandled_input`; `AnalogicoToque` mantém as ações direcionais.
- `Comandos` (`core/utilitarios/`): troca de tecla e `user://comandos.cfg`.
  `OpcoesToque`: modo, quando aparecer, layout e transparência em `user://toque.cfg`.

## 9. Escala D&D (`EscalaDnd`)

| Livro | Jogo |
|---|---|
| 5 pés | 1 ladrilho = 32 px |
| 1 rodada | 1,5 s |
| Deslocamento 30 pés | ~128 px/s (Disparada: dobro) |
| Iniciativa | intervalo entre ataques = (10 − iniciativa) × 0,1 s, mínimo 0,3 s |
| Alcance longo de tiro/arremesso | velocidade de saída = raiz(g × alcance) (`velocidade_para_alcance`) |

## 10. Persistência

- **Save do jogo:** `core/regras/salvamento.gd` grava `user://save.json` (ficha, mochila com
  desgaste/pilhas/equipados, fase e bestiário). Continuar no título volta ao começo da fase
  salva. Salva pelo menu de pausa e sozinho ao entrar numa fase nova (só no jogo de verdade).
  Testes usam outro caminho para não apagar o save do jogador (`tests/teste_salvamento.gd`).
- **Configurações:** `user://comandos.cfg` (teclas) e `user://toque.cfg` (toque). Testes que
  mexem nelas guardam e devolvem o arquivo do jogador (`tests/teste_toque.gd`).
