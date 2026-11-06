# Decisões: telas, HUD, entrada e celular

Parte da tabela de decisões do projeto (índice no `CLAUDE.md`). **Atualize aqui quando uma
decisão deste tema mudar.** Telas em `ui/`; regra geral: a tela não conhece o herói (emite um
"pedido" e a `main` chama `abrir(...)`).

| Decisão | Escolha | Por quê |
|---|---|---|
| Início do jogo | `main`: **tela de título** (`ui/titulo/`: Novo Jogo, Sair) -> **criação** -> jogo. Título, criação e derrota pausam o jogo e escondem o HUD e os controles de toque. `mostrar_inicio = false` pula tudo (testes). | Pedido do usuário. |
| Criação | `ui/criacao_personagem/`: três passos. **Quem**: nome (até 16 letras), classe e pacote. **Atributos**: compra de pontos, sugestão da classe e uma linha de vida/CA/dano. **Maestrias**: clique marca e desmarca, até as 3 armas que domina (efeito de cada uma explicado). INT, SAB e CAR ainda não fazem nada. | Pedido do usuário. |
| HUD | `ui/hud/`: "Nome (Classe)", "PV atual/máximo" e «Fôlego X/2». | |
| Tela de inventário | `ui/inventario/`, tecla **I** (Esc fecha), **pausa o jogo**. Lista à esquerda; à direita a aba **Item** (resumo e Equipar/Jogar fora) ou **Ficha** compacta. Emite `abrir_pedido`; a `main` chama `abrir(...)`. Não abre durante a criação nem na edição do toque. | |
| Comandos | Tecla **C** abre `ui/comandos/` (pausa): o que cada ação faz e a tecla atual. Clicar numa ação e apertar uma tecla troca o atalho; essa tecla sai da ação que já a usava. `Comandos` (`core/utilitarios/`) grava em `user://comandos.cfg`; a `main` carrega no começo. Não é autoload. Na mesma tela: lista **Combate** (Trazer/Tirar) e **Toque (celular)** (analógico/setas, quando aparecer, Ajustar botões). | Pedido do usuário. |
| Ações de input | `mover_esquerda` (A, ←), `mover_direita` (D, →), `mover_baixo` (S, ↓), `pular` (Espaço, W, ↑), `atacar` (J), `arremessar` (K), `folego` (F), `inventario` (I), `interagir` (E), `comandos` (C), `correr` (Shift, segurar; também a borda do analógico), `mirar_cima` (sem tecla: o analógico ou a seta ↑ do toque). O código de jogo só lê ações. | |
| Plataforma | PC (Windows) e **Android** (celular deitado). Teclado no PC; toque no celular; controle depois. Ainda **não**: exportar o APK. | Pedido do usuário. |
| Controles de toque | `ui/controles_toque/` (`ControlesToque`, CanvasLayer 5): **analógico OU setas** à esquerda (o jogador escolhe; `OpcoesToque`, `user://toque.cfg`) e botões à direita (Atacar, Pular, Lançar, Fôlego, E) + Bolsa e Menu no alto. Apertam as **mesmas ações do InputMap** (`Input.action_press`), vários dedos ao mesmo tempo. Analógico: lado anda, **borda corre** (`correr`), cima = `mirar_cima` (não pula), baixo = `mover_baixo`. Setas: toque duplo corre. Aparecem **só com tela de toque** (ou Sempre/Nunca); somem nas telas de pausa; com o jogo pausado não apertam. No PC dá para testar com o mouse (`emulate_touch_from_mouse`). | Pedido do usuário. |
| Ajustar os controles | **Ajustar botões** (tela de comandos): modo de edição com o jogo pausado. Arrastar muda o lugar (o controle se prende ao **canto mais perto**, para valer em qualquer largura de tela); − / + muda o tamanho do selecionado (raio 12 a 64); a barra muda a transparência; **Padrão** desfaz; **Pronto** salva (`OpcoesToque.posicoes`, `opacidade`). | Pedido do usuário. |
| Tema dos menus | `ui/tema_menu.tres` (visual compartilhado); `ui/resumo_item.gd` (texto curto de arma/armadura nas telas). Telas com âncora de tela inteira (a largura muda no celular). | |
