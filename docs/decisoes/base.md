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
| Fase | `TileMapLayer` gerado por script a partir de um mapa em texto (`tools/gerar_fase_teste.gd`); plataformas finas são *one-way* (atravessa por baixo). Script raiz `levels/fase.gd` (`Fase`) expõe `posicao_inicio()`, `area_jogavel()` e `limite_queda()`. | Fácil de mudar o layout; quem usa a fase não mexe nos nós internos. |
| Fase atual | **Reta**, 120 ladrilhos, sem plataformas nem buracos (pedido do usuário). Os tipos `=` e `P` continuam disponíveis no gerador para depois. | Focar em andar, correr e pular. |
| Câmera | `Camera2D` filha do herói, com suavização, olha à frente na direção em que ele corre; limites calculados pelo tamanho da fase. | Ver o que vem pela frente. |
| Movimento suave | Interpolação de física ligada. | Sem tremedeira em monitores de 144 Hz. |
| Componentes de combate | `core/componentes/`: `HitboxComponent` (entrega um `Golpe`, 1x por alvo por golpe), `HurtboxComponent` (só emite `golpe_recebido`), `DefesaComponent` (CA, resolve, tira vida, `invulneravel`), `HealthComponent`, `TextoFlutuanteComponent`, `CondicoesComponent`. Camadas de física: 1 `mundo`, 2 `jogador`, 3 `hurtbox_inimigo`, 4 `hurtbox_jogador`, 5 `inimigo`. | Reutilizável por herói, inimigos e boneco. |
| Nome do jogo | **"DnD in a Piece"**, em `project.godot` (`application/config/name`); a tela de título lê de lá. "D&D" é marca da Wizards of the Coast: trocar o nome se um dia for publicar. | Pedido do usuário. |
