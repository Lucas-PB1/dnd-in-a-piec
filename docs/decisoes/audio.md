# Decisões: som e música

Parte da tabela de decisões do projeto (índice no `CLAUDE.md`). **Atualize aqui quando uma decisão
deste tema mudar.**

| Decisão | Escolha | Por quê |
|---|---|---|
| Barramentos | **Musica**, **Efeitos** e **Interface**, todos saindo no Master. `OpcoesSom` (`core/utilitarios/`) cria os que faltam e guarda o volume de cada um em `user://som.cfg`. A `main` os prepara em `_enter_tree`, antes de qualquer som nascer. Opções, aba **Som**: três barras. | Pedido do usuário. |
| Efeitos | `levels/sons.gd` (`Sons`, filho da `main`, sem autoload). Escuta os eventos: golpe resolvido (acerto, crítico, apanhar), golpe no ar (leve ou pesado), pulo, pouso, passos, arremesso, tiro, estouro dos monstros, Surto, Fôlego, subir de nível, morte do herói, abrir baú, salvar, cliques de todo botão e abrir e fechar telas. Cada som tem variações e leve sorteio de tom; 8 vozes por barramento. Monstros novos ganham os sons sem mudar nada neles. | Mesmo padrão do `Impacto`. |
| Fontes dos efeitos | Pacotes CC0 da Kenney (`assets/audio/kenney_rpg/`, `kenney_interface/`) e sons feitos por script (`tools/gerar_sons.gd` -> `assets/audio/sintetizados/`), para o que os pacotes não têm (impactos pesados, apanhar, morte, magia, cura). Créditos em `assets/CREDITOS.md`. | O pacote de RPG não tem impactos pesados nem magia. |
| Música | `levels/musica.gd` (`Musica`, filho da `main`): duas vozes com **transição suave** (1,4 s). Título e Clareira: Shakkar; Trilha e Pântano: The Old Tower Inn; Ruína e Fortaleza: Medieval Battle; vitória: The Old Tower Inn. A mesma faixa não recomeça. A faixa recomeça pelo sinal `finished` (marcar `loop` no arquivo deixava recursos de áudio abertos ao sair). | Pedido do usuário; faixas CC0 conferidas no OpenGameArt. |
| Ainda não | Sons próprios de cada monstro (aviso do golpe, voz), música de derrota, ambiente de cada fase (vento, água), sons de equipar e pegar item, e mixagem por distância. | Ver `docs/pendencias.md`. |
