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
| Fases | `tools/gerar_fase_teste.gd` gera a fase de teste reta e cinco fases de campanha (`levels/fase_1..5.tscn`) a partir de mapas em texto. Cada fase tem ambiente próprio, buracos, algumas plataformas *one-way*, pontos de armadilha, início e porta. `Fase` expõe as posições, limites, índice, cota e tipos permitidos. | Layouts ficam fáceis de ajustar e a fase não expõe seus nós internos. |
| Campanha | Clareira -> Trilha -> Pântano -> Ruína -> Fortaleza. A `main` sorteia inimigos nos pontos de armadilha, cobra a cota da fase na porta e mostra a vitória ao concluir a Fortaleza. `fase_teste.tscn` continua reta para abrir e testar sozinha. | Aumentar o percurso e variar terreno, cenário e encontros.  **Fundos em camadas** (`levels/fundo_paralaxe.gd`, `FundoParalaxe`, criado pela `Fase` a partir de `nome_ambiente`): arte CC0 do ansimuz (`assets/fundos/`); floresta nas três primeiras fases (tons claro, quente e verde-escuro) e fortaleza noturna nas duas últimas; 2 camadas que acompanham a câmera a 15/45% (floresta) ou 5/30% (fortaleza); o céu liso `Ceu` fica escondido. **Chão:** os ladrilhos (grama, terra, plataforma, pedra) são recortados dos mesmos pacotes e pintados com o tom de cada fase por `tools/gerar_arte_provisoria.gd` (`PACOTES_LADRILHO`). **Relevo** no gerador das fases (`degraus` = chão elevado, `altas` = plataformas a 2 ou 3 ladrilhos, `pontos` = armadilhas extras): subida de até 2 ladrilhos, buraco de até 3, plataforma só onde o pulo (104 px) alcança, conferido por `tests/teste_campanha.gd`. Ainda **não**: fundo próprio do Pântano e da Ruína (reusam floresta e fortaleza em outro tom). |
| Dificuldade por nível | A cota ganha um inimigo por nível (até os pontos marcados); o sorteio pode incluir Goblin Warrior mais cedo nos níveis 2 e 3. Criaturas e posições continuam aleatórias por entrada. Uma fase nova é descanso longo: PV, Fôlego e Surto de Ação são recuperados. | Ajustar os encontros ao nível escolhido e adquirido. |
| Câmera | `Camera2D` filha do herói, com suavização, olha à frente na direção em que ele corre; limites calculados pelo tamanho da fase. | Ver o que vem pela frente. |
| Movimento suave | Interpolação de física ligada. | Sem tremedeira em monitores de 144 Hz. |
| Componentes de combate | `core/componentes/`: `TremorComponent` (treme o sprite ao levar dano), `HitboxComponent` (entrega um `Golpe`, 1x por alvo por golpe), `HurtboxComponent` (só emite `golpe_recebido`), `DefesaComponent` (CA, resolve, tira vida, `invulneravel`), `HealthComponent`, `TextoFlutuanteComponent`, `CondicoesComponent`. Camadas de física: 1 `mundo`, 2 `jogador`, 3 `hurtbox_inimigo`, 4 `hurtbox_jogador`, 5 `inimigo`. | Reutilizável por herói, inimigos e boneco. |
| Nome do jogo | **"DnD in a Piece"**, em `project.godot` (`application/config/name`); a tela de título lê de lá. "D&D" é marca da Wizards of the Coast: trocar o nome se um dia for publicar. | Pedido do usuário. |

## Limites do mapa e porta
- Toda `Fase` cria o nó `Limites` (`StaticBody2D` no mundo, camada 1) com três `WorldBoundaryShape2D`: lateral esquerda e direita (a partir da área jogável, sem as paredes das pontas) e um teto 96 px acima do topo. Servem ao Atleta, que escala sem limite de altura, e a qualquer corpo que tente sair do mapa.
- A saída tem um desenho de porta (`Porta/Desenho`, 50x81 px, arte CC0 do rubberduck); a área da porta e a cota continuam como eram.
