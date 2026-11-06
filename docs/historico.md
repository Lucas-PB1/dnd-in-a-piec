# Histórico das fatias

O que já foi feito, em ordem. **Acrescente uma linha ao fechar cada fatia.** O que falta está em
`docs/pendencias.md`; as decisões, em `docs/decisoes/`.

- Fatias 1 e 2 (2.5D): boneco na relva e herói do SpriteCook. Substituídas pela fatia 3 (commits `60f2dda` e `0b1ca2b`).
- Fatia 3: herói andando e pulando numa fase de teste em 2D lateral.
- Fatia 4: skills de código limpo, corrida com dois toques (animação provisória), fase reta, herói refatorado em física + componente visual.
- Skills godot-* criadas e código migrado: novas pastas, máquina de estados do herói, `StatsJogador` em `data/`, sem `get_parent()`, fase com API própria.
- Fatia 5: golpe de espada (J) no chão e no ar, arma como dado e sprite separado, Hitbox/Hurtbox, boneco de treino. Tentativa de usar pacote pronto (Hero Knight) foi cancelada e limpa.
- Fatia 6a: ficha de D&D (compra de pontos, vida d10 + CON, dano 1d6 + FOR/DES), tela de criação, HUD de vida.
- Fatia 6b: inventário (Item, Inventario, tela com I), espada começa na mochila, soco desarmado.
- Fatia 6c: espada equipada sempre na mão (ponto da mão por quadro), golpe girando a partir da mão.
- Fatia 7: tela de título "DnD in a Piece", criação com nome e classe, nome no HUD e no inventário.
- Fatia 8: combate de D&D (d20 contra CA, crítico, salvaguardas na ficha), Gray Ooze com a ficha do livro, herói leva dano/recua/pisca/reaparece.
- Ajuste: movimento pelo deslocamento de D&D e ritmo de ataque pela iniciativa (tiques).
- Fatia 9: "Você caiu!" com Tentar de novo; tipos de dano (espada perfurante, soco contundente, Pseudópode ácido); resistências do Ooze; Corrosão da arma.
- Proficiências de armas (efeito no ataque) e de armaduras (só na ficha da classe por enquanto).
- Fatia 10: 21 armaduras + escudos com as regras do livro, escolha na criação, armadura visível no herói, corrosão de armadura.
- Fatia 11a: 29 armas do PHB (dados + sprites provisórios), Versátil/Duas Mãos/Pesada/Alcance, pilhas, pacotes A e B na criação, baú do arsenal (E).
- Fatia 11b: duas armas leves (J J; a 2ª na outra mão), arremesso com K (cai no chão, E pega), escudo na frente do corpo. Pacote B já equipa Cimitarra e Espada Curta.
- Golpes das armas: arte do pacote CC0 Idylwild, golpe próprio para cada uma das 29 armas, área de acerto seguindo a arma, alcance de 5/10 pés com passo de estocada.
- Menus com ícones 16x16; Mangual e Chicote com quadros desenhados.
- Efeitos de golpe por tipo: arco, rastro e impacto.
- Fatia 11c: maestrias de arma (3 na criação), condições com ícones, vantagem/desvantagem, um alvo por golpe + Trespassar, Raspão, Corte Duplo.
- Revisão: duas armas (2ª atrás do corpo, extra em X), escudo seguro pela mão de trás, camada da mão por cima da arma, arremesso com carga (normal/longo), voo por tipo e queda no alvo.
- Armadura visível só na túnica (ladrilho do material). Sem ombro, peitoral, saia nem elmo por cima do corpo.
- Second Wind do Guerreiro (F): cura 1d10+1, 2 usos por luta, ação bônus, HUD «Fôlego 2/2». «Tentar de novo» devolve os usos.
- Tela de comandos (C): ver e trocar teclas (salvo em `user://comandos.cfg`) e trazer ou tirar o Gray Ooze. O trazido não volta no «Tentar de novo».
- Armas à distância do livro base: 9 armas, munição, K com mira (W/S), pacote B com Arco Longo e 20 flechas. Atirador de Elite e Especialista em Besta no tiro (`docs/talentos.md`); a ficha começa sem talento.
- Disparo: quadros por arma; a munição escolhe a curva; a Destreza (referência 14) limita o teto da carga e o tempo para encher. Azagaia e dardo continuam no arremesso de Força.
- Disparo revisto: pose de mira no peito (montada das artes do herói), mão por cima da empunhadura e 8 quadros por arma (arcos, bestas, funda, zarabatana, pistola, mosquete).
- Armas à distância com a arte do Aerial Arsenal (CC0): arcos inclinados para a frente, bestas do pacote, pistola e mosquete de pederneira em pixel art e quadro de descanso.
- Força do tiro por arma: velocidade de saída pelo alcance longo do livro, impulso e peso por munição (antes todas as armas pareciam iguais na tela).
- Goblin Minion (ficha do livro): arremessa 3 adagas, golpeia de perto e Desengaja com a Fuga Ágil. Na tela de comandos (C -> Trazer).
- Goblin Warrior (ficha do livro): cimitarra de perto, arco curto de longe (flechas não acabam) e a mesma Fuga Ágil. Arte CC0 do Goblin Corps. Esconder e o +1d4 com vantagem ficam para a Furtividade.
- Goblins no mapa: Minion em x = 2176 e Warrior em x = 2752, cada um além dos 60 pés de visão de quem está antes, e fora dos tiros de teste. "Tentar de novo" recria os dois junto com o Ooze.
- Guias para IA: `docs/artes_prontas.md`, `docs/arquitetura.md`, `docs/receitas.md`; regras do Cursor geradas das skills (`tools/gerar_regras_cursor.ps1`).
- Celular (fatia 1): tela larga (aspect expand), celular deitado, controles de toque (analógico ou setas + botões), correr segurando (Shift / borda do analógico).
- Celular (fatia 2): ajustar os controles de toque (arrastar, tamanho, transparência, Padrão, salvo).
- Organização: decisões divididas por tema em `docs/decisoes/`, pendências em `docs/pendencias.md`, comandos e agentes para Claude e Cursor.
