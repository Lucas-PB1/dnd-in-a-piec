# Pendências

Tudo o que falta, num lugar só, para escolher a próxima fatia **sem inventar**. Ao propor a
próxima fatia, escolha daqui (e ofereça 3 opções ao usuário, a recomendada primeiro). Ao fechar
uma fatia: **tire daqui o que ficou pronto** e acrescente o que apareceu de novo.

Legenda de tamanho: **P** (uma tarde), **M** (uma fatia), **G** (várias fatias).

## 1. Próximas fatias sugeridas

| # | Fatia | Tam. | Onde mexe | Observação |
|---|---|---|---|---|
| 1 | **Exportar o APK (Android)** | M | `export_presets.cfg`, guia em `docs/` | Precisa do JDK, Android SDK e modelos de exportação do Godot (o usuário instala; a IA guia). Testar os controles de toque com o dedo. |
| 2 | **Fase com plataformas e buracos** | M | `tools/gerar_fase_teste.gd` | Os tipos `=` (plataforma) e `P` já existem no gerador; a fase está reta por pedido antigo. |
| 3 | **Testes de Furtividade** | M | `core/regras/`, criaturas | Primeira perícia. Também libera o Esconder do Goblin Warrior e o +1d4 quando o ataque já tem vantagem. |

## 2. Regras do livro que ainda não existem

| O quê | Tam. | Situação hoje |
|---|---|---|
| Raças/espécies | G | Deslocamento padrão 30 pés para todos (`Ficha.DESLOCAMENTO_PADRAO_PES`). |
| Antecedentes | M | Escolha de talento só quando existir antecedente; `Ficha.talentos` começa vazia. |
| INT, SAB, CAR | — | Existem na ficha, não fazem nada. |
| Perícias (Furtividade primeiro) | M | Nenhum teste de perícia. |
| Magia | G | Abrir o bloco de talentos de magia em `docs/talentos.md` na fatia dela. |
| Descanso curto | P | Second Wind recarrega no "Tentar de novo" (regra da casa) em vez de descanso. |
| Limite de tamanho do Empurrar e do Derrubar | P | Hoje vale para qualquer tamanho (o livro: Grande ou menor). |
| Amorfo (Gray Ooze) | P | Sem efeito no jogo. |
| Níveis acima do 1 | G | Tudo é nível 1 (vida, Second Wind 1d10+1). |
| Salvar e carregar o jogo | M | Só as configurações são salvas (`user://comandos.cfg`, `user://toque.cfg`). Decisão grande: propor 2 opções. |

## 3. Arte provisória (trocar quando der)

| O quê | Como trocar |
|---|---|
| Animação de correr do herói (quadros do andar a 20 fps) | Animação `run` no SpriteCook (~32 créditos; a conta tem 2). Sem mexer no código. |
| Efeitos de golpe (arco, rastro, impacto) | Desenhados por script em `assets/efeitos/`. Pacote CC0 ou SpriteCook. |
| Ladrilhos e cenário | `tools/gerar_arte_provisoria.gd`. Pacote de tileset CC0 (`docs/artes_prontas.md`). |
| Armaduras no herói | O usuário achou "pouco épico"; ficou como pintura da túnica. Revisitar com arte nova. |
| Goblin com lança na arte, mas a ficha usa adaga | Achar ou gerar um goblin com adagas, se incomodar. |

## 4. Dívidas técnicas (pequenas)

| O quê | Quando resolver |
|---|---|
| Base comum das criaturas (perseguir, ritmo, condições, empurrão repetidos em Ooze e Goblin) | Antes de uma criatura que não reuse o Goblin (o Warrior usa a máquina dele). |
| `BotaoToque` e `AnalogicoToque` repetem "editando/destacado" | Ao criar o 3º tipo de controle de toque. |
| "Arma na mão ou desarmado" em 2 lugares (Jogador e TelaInventario) | Se aparecer um 3º lugar. |
| Sinais `pulou`/`reapareceu` do herói sem ouvinte | Quando houver som/efeito para eles, ou remover. |
| Projétil do herói pode nascer na altura da cabeça no 1º quadro do voo | Conferir em jogo; se for, nascer na ponta da arma. |

## 5. Mais para frente

- Controle (gamepad).
- iOS (precisa de Mac com Xcode).
- Trocar o nome do jogo antes de publicar ("D&D" é marca da Wizards of the Coast).
