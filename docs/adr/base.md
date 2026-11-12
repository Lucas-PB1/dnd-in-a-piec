# Decisões: base técnica, tela e fase

Parte da tabela de decisões do projeto (índice no `CLAUDE.md`). **Atualize aqui quando uma
decisão deste tema mudar.**

| Decisão | Escolha | Por quê |
|---|---|---|
| Motor | Godot 4.7.2, GDScript | Já instalado; sem C#. |
| Renderizador | GL Compatibility (também no celular) | Leve e ótimo para pixel art 2D. |
| Resolução interna | **640x360**, `stretch/mode = viewport`, `scale_mode = integer`, **`aspect = expand`**: celular mais largo que 16:9 mostra mais fase em vez de faixas pretas (a altura fica 360). Celular sempre deitado (`handheld/orientation` = sensor paisagem). No PC: Opções → Som → **Tela** (Janela 1280×720 ou tela cheia borderless). | Pixel art ampliada sem borrar (2x = 1280x720, 3x = 1920x1080). |
| Filtro de textura | Nearest (padrão do projeto) | Pixel art nítida. |
| Unidade | Pixels. Ladrilhos de **32x32**. Herói com ~73 px de altura (~2,3 ladrilhos). | Proporção boa para ação lateral. |
| Ícone do app | `icon.png` 128×128 (escudo madeira + espada grande Idylwild, `tools/montar_icone.gd`); `project.godot` + preset Windows. O SVG padrão do Godot ficou em `assets/icone_godot_padrao.svg`. | Pedido do usuário. |
| Importação de PNG | Lossless, sem mipmaps. | Não estragar a pixel art. |
| Fases | `tools/gerar_fase_teste.gd` gera a fase de teste reta, o **Treino** (`levels/fase_tutorial.tscn`, índice 0) e **dez** fases de campanha (`levels/fase_1..10.tscn`) a partir de mapas em texto. Cada fase tem ambiente próprio, buracos, algumas plataformas *one-way*, pontos de armadilha, início, porta e (nas de chefe) marcador do chefe. `Fase` expõe as posições, limites, índice, cota, tipos permitidos e `ultima`. | Layouts ficam fáceis de ajustar e a fase não expõe seus nós internos. |
| Enfeites de mapa | Nó `Enfeites` (z atrás do terreno, sem colisão) gerado pela lista `"enfeites"` de cada fase: tochas/estandartes/janelas (folha castelo CC0), props de mina/caverna (OPP2017), e polígonos provisórios na floresta/pântano (`arbusto`, `junco`, `agua`+bolhas). | Um enfeite por tema sem SpriteCook; floresta/pântano trocam o provisório quando houver folha. |
| Ladrilhos de cenário | Atlas `assets/tiles/ladrilhos.png` (6 temas) montado por `gerar_arte_provisoria.gd`: floresta (SpriteCook + Sunnyland), pântano/ruína (tilesets Gothicvania ansimuz), fortaleza (Fort of Illusion), caverna (Buch DB32). Sem fileira só de polígono provisório. Colisão da **grama** desce `Fase.RECUO_PES_NA_GRAMA_PX` (10 px) para os pés entrarem na relva; terra/pedra/prancha intactas. **Prancha da floresta:** ilha flutuante Sunnyland 32×32 (grama+rocha, `plataforma_cheia`), não a faixa verde fina. | Pacotes CC0; regenerar atlas + fases pelo gerador. |
| Campanha | **Tutorial + 10 fases / 4 temas:** Novo Jogo → intro → **Treino** (placas; baú → loja → boneco → pedra; **50 po**; **−4 PV**); porta → Clareira. Interações com E respeitam `Fase.FOLGA_INTERACAO_E` (96 px). Depois: Floresta (1–3), Ruínas (4–6), Subterrâneo (7–9), Covil (10). Treino fora de `CENAS_FASE`. | Percurso longo com chefes a cada 3 fases + super chefe. **Fundos em camadas**. **Lava no Covil:** `features/lava/`. |
| Dificuldade por nível | Cotas base: **1 / 2 / 2 / 3 / 4 / 4 / 4 / 5 / 3 / 4**. Extra: +1 a cada 2 níveis. Loja: teto dobra a cada 2 fases. Ouro de saque: lixo cedo um pouco menor, chefes/finais um pouco maior. XP: livro nos mobs + marcos casa 5–8 (ritmo ~nv 7–8 no Covil). | Recalibragem 2026-11-12 (fatias 1–2). PV/dano das fichas ainda no backlog. |
| Câmera | `Camera2D` filha do herói, com suavização, olha à frente na direção em que ele corre; limites calculados pelo tamanho da fase. | Ver o que vem pela frente. |
| Movimento suave | Interpolação de física ligada. | Sem tremedeira em monitores de 144 Hz. |
| Componentes de combate | `core/componentes/`: `TremorComponent` (treme o sprite ao levar dano), `HitboxComponent` (entrega um `Golpe`, 1x por alvo por golpe), `HurtboxComponent` (só emite `golpe_recebido`), `DefesaComponent` (CA, resolve, tira vida, `invulneravel`), `HealthComponent`, `TextoFlutuanteComponent`, `CondicoesComponent`. Camadas de física: 1 `mundo`, 2 `jogador`, 3 `hurtbox_inimigo`, 4 `hurtbox_jogador`, 5 `inimigo`, 6 `plataforma` (pranchas *one-way*; Amorfo do Ooze não mascara). | Reutilizável por herói, inimigos e boneco. |
| Nome do jogo | **"DnD in a Piece"**, em `project.godot` (`application/config/name`); a tela de título lê de lá. "D&D" é marca da Wizards of the Coast: trocar o nome se um dia for publicar. | Pedido do usuário. |

## Limites do mapa e porta
- Toda `Fase` cria o nó `Limites` (`StaticBody2D` no mundo, camada 1) com três `WorldBoundaryShape2D`: lateral esquerda e direita (a partir da área jogável, sem as paredes das pontas) e um teto 96 px acima do topo. Servem ao Atleta, que escala sem limite de altura, e a qualquer corpo que tente sair do mapa.
- A saída tem um desenho de porta (`Porta/Desenho`, 50x81 px, arte CC0 do rubberduck); a área da porta e a cota continuam como eram.
