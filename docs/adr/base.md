# Decisões: base técnica, tela e fase

Parte da tabela de decisões do projeto (índice no `CLAUDE.md`). **Atualize aqui quando uma
decisão deste tema mudar.**

| Decisão | Escolha | Por quê |
|---|---|---|
| Motor | Godot 4.7.2, GDScript | Já instalado; sem C#. |
| Renderizador | GL Compatibility (também no celular) | Leve e ótimo para pixel art 2D. |
| Resolução interna | **640x360**, `stretch/mode = viewport`, `scale_mode = integer`, **`aspect = expand`**: celular mais largo que 16:9 mostra mais fase em vez de faixas pretas (a altura fica 360). Celular sempre deitado (`handheld/orientation` = sensor paisagem). | Pixel art ampliada sem borrar (2x = 1280x720, 3x = 1920x1080). |
| Filtro de textura | Nearest (padrão do projeto) | Pixel art nítida. |
| Unidade | Pixels. Ladrilhos de **32x32**. Herói com ~73 px de altura (~2,3 ladrilhos). | Proporção boa para ação lateral. |
| Importação de PNG | Lossless, sem mipmaps. | Não estragar a pixel art. |
| Fases | `tools/gerar_fase_teste.gd` gera a fase de teste reta e **dez** fases de campanha (`levels/fase_1..10.tscn`) a partir de mapas em texto. Cada fase tem ambiente próprio, buracos, algumas plataformas *one-way*, pontos de armadilha, início, porta e (nas de chefe) marcador do chefe. `Fase` expõe as posições, limites, índice, cota, tipos permitidos e `ultima`. | Layouts ficam fáceis de ajustar e a fase não expõe seus nós internos. |
| Campanha | **10 fases / 4 temas:** Floresta (1–3 Clareira, Trilha, Pântano; chefe Ankheg), Ruínas (4–6 Ruína, Fortaleza, Labirinto; chefe Minotauro), Subterrâneo (7–9 Mina, Caverna úmida, Cripta; chefe Wight), Covil (10; chefe Quimera). A `main` sorteia inimigos, cobra a cota na porta e mostra a vitória ao concluir a fase 10. `fase_teste.tscn` continua reta para abrir sozinha. | Percurso longo com chefes a cada 3 fases + super chefe. **Fundos em camadas** (`levels/fundo_paralaxe.gd`): floresta (1–3), fortaleza/ruínas (4–6), caverna (7–10, Covil avermelhado). **Lava no Covil:** `features/lava/` — zona de 1d6 de fogo a cada rodada (1,5 s) enquanto o herói está em cima; `Combate.resolver_ambiente` / `Defesa.receber_ambiente`. Ainda **não**: fundo próprio do Pântano e da Ruína (reusam floresta e fortaleza em outro tom). |
| Dificuldade por nível | A cota ganha inimigos extras por nível (`Main.INIMIGOS_EXTRA_POR_NIVEL`); tipos mais fortes liberam conforme o nível. Criaturas e posições continuam aleatórias por entrada. Uma fase nova é descanso longo: PV, Fôlego e Surto de Ação são recuperados. | Ajustar os encontros ao nível escolhido e adquirido (herói até o nível 6). |
| Câmera | `Camera2D` filha do herói, com suavização, olha à frente na direção em que ele corre; limites calculados pelo tamanho da fase. | Ver o que vem pela frente. |
| Movimento suave | Interpolação de física ligada. | Sem tremedeira em monitores de 144 Hz. |
| Componentes de combate | `core/componentes/`: `TremorComponent` (treme o sprite ao levar dano), `HitboxComponent` (entrega um `Golpe`, 1x por alvo por golpe), `HurtboxComponent` (só emite `golpe_recebido`), `DefesaComponent` (CA, resolve, tira vida, `invulneravel`), `HealthComponent`, `TextoFlutuanteComponent`, `CondicoesComponent`. Camadas de física: 1 `mundo`, 2 `jogador`, 3 `hurtbox_inimigo`, 4 `hurtbox_jogador`, 5 `inimigo`. | Reutilizável por herói, inimigos e boneco. |
| Nome do jogo | **"DnD in a Piece"**, em `project.godot` (`application/config/name`); a tela de título lê de lá. "D&D" é marca da Wizards of the Coast: trocar o nome se um dia for publicar. | Pedido do usuário. |

## Limites do mapa e porta
- Toda `Fase` cria o nó `Limites` (`StaticBody2D` no mundo, camada 1) com três `WorldBoundaryShape2D`: lateral esquerda e direita (a partir da área jogável, sem as paredes das pontas) e um teto 96 px acima do topo. Servem ao Atleta, que escala sem limite de altura, e a qualquer corpo que tente sair do mapa.
- A saída tem um desenho de porta (`Porta/Desenho`, 50x81 px, arte CC0 do rubberduck); a área da porta e a cota continuam como eram.
