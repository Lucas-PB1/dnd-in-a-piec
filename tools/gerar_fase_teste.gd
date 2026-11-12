extends SceneTree
## Gera o TileSet e as fases a partir dos mapas abaixo.
##   godot --headless --path . --script res://tools/gerar_fase_teste.gd
## Cada caractere = 1 ladrilho de 32 px. O gerador monta o texto a partir dos números
## de cada fase (buraco, plataforma, armadilha, porta), para não errar a conta.
##   #  chão (grama no topo, terra embaixo)
##   P  pedra
##   =  plataforma (atravessa por baixo)
##  Relevo de cada fase (opcional): "degraus" [x, largura, altura] = chão elevado; "altas"
##  [x, largura, fileiras acima do chão] = plataforma que se atravessa por baixo; "pontos"
##  [x, fileira] = ponto de armadilha extra (em cima de um degrau ou de uma plataforma).
##   S  início do herói
##   A  ponto de armadilha (no chão, ou na fileira de cima quando está numa plataforma)
##   D  porta
##   .  vazio
## Paredes de pedra fecham as duas pontas. A fase reta de teste não tem buraco nem porta.

const TAM := 32
const CAMINHO_TILESET := "res://assets/tiles/ladrilhos.tres"
const SCRIPT_FASE := "res://levels/fase.gd"
const CENA_BLOCO := "res://features/bloco_quebravel/bloco_quebravel.tscn"
const CENA_LAVA := "res://features/lava/lava.tscn"
const CENA_DESAFIO_PERICIA := "res://features/desafio_pericia/desafio_pericia.tscn"
const ALTURA_EXTRA_PAREDE := 6
const ALTURA_PRANCHA := 10
## Tem de bater com `Fase.RECUO_PES_NA_GRAMA_PX`: pés dentro da relva, não em cima dela.
const RECUO_COLISAO_GRAMA := 10
## Fileira do "S": os pés ficam na base dela, em y = 288.
const LINHA_ACAO := 8
const PROFUNDIDADE_CHAO := 3
const LINHAS := LINHA_ACAO + 1 + PROFUNDIDADE_CHAO
const LARGURA_TESTE := 120
## A porta detecta o corpo do herói (camada 2).
const MASCARA_JOGADOR := 2
const LARGURA_PORTA := 28.0
const ALTURA_PORTA := 72.0

enum { GRAMA, TERRA, PLATAFORMA, PEDRA }

## Colunas extras do atlas com variantes de GRAMA e de TERRA, sorteadas por ladrilho (ver gerar_arte_provisoria.gd).
const VARIANTES_GRAMA: Array[int] = [GRAMA, 4, 5]
const VARIANTES_TERRA: Array[int] = [TERRA, 6, 7, 8]

const OOZE := &"ooze"
const MINION := &"minion"
const WARRIOR := &"warrior"
const KOBOLD := &"kobold"
const TIPOS_SEM_ARCO: Array[StringName] = [OOZE, MINION, KOBOLD]
const HOBGOBLIN := &"hobgoblin"
const BUGBEAR := &"bugbear"
const SKELETON := &"skeleton"
const ZOMBIE := &"zombie"
const TIPOS_RUINA: Array[StringName] = [OOZE, MINION, WARRIOR, HOBGOBLIN]
const TIPOS_FORTALEZA: Array[StringName] = [OOZE, MINION, WARRIOR, HOBGOBLIN, BUGBEAR]
const TIPOS_PEDRA: Array[StringName] = [WARRIOR, HOBGOBLIN, BUGBEAR]
const TIPOS_MINA: Array[StringName] = [OOZE, WARRIOR, BUGBEAR, SKELETON]
const TIPOS_CAVERNA: Array[StringName] = [OOZE, WARRIOR, BUGBEAR, SKELETON, ZOMBIE]
const TIPOS_CRIPTA: Array[StringName] = [SKELETON, ZOMBIE, WARRIOR, HOBGOBLIN]
const TIPOS_COVIL: Array[StringName] = [WARRIOR, HOBGOBLIN, BUGBEAR, SKELETON, ZOMBIE]

## Enfeites sem colisão, atrás do terreno. Castelo = rubberduck; caverna = OPP2017 (ver assets/CREDITOS.md).
## Floresta/pântano: polígonos provisórios (arbusto, junco, água) até haver folha própria.
const FOLHA_CASTELO := "res://assets/tiles/castelo/castle_tileset_part3.png"
const FOLHA_CAVERNA_OBJ := "res://assets/tiles/caverna/enfeites/tile_cave_bg_objects.png"
const FOLHA_CAVERNA_CRISTAL := "res://assets/tiles/caverna/enfeites/tile_cave_bg_crystal.png"
const FOLHA_CAVERNA_FLUO := "res://assets/tiles/caverna/enfeites/tile_cave_bg_fluo.png"
const ENFEITE_Z := -5
const CHAMA_QUADROS: Array[Rect2] = [Rect2(45, 5, 7, 8), Rect2(77, 4, 6, 9), Rect2(109, 5, 6, 8), Rect2(141, 3, 7, 10)]
const CHAMA_ESCALA := 2.0
const CHAMA_VELOCIDADE := 8.0
const TOCHA_ALTURA_SUPORTE := 18.0
## nome -> {folha, regiao}. Procedurais (arbusto/junco/agua) não entram aqui.
const ENFEITES_PRONTOS := {
	"janela": {"folha": FOLHA_CASTELO, "regiao": Rect2(3, 6, 26, 56)},
	"estandarte_vermelho": {"folha": FOLHA_CASTELO, "regiao": Rect2(19, 198, 90, 41)},
	"estandarte_amarelo": {"folha": FOLHA_CASTELO, "regiao": Rect2(147, 198, 90, 41)},
	"estandarte_verde": {"folha": FOLHA_CASTELO, "regiao": Rect2(19, 262, 90, 41)},
	"estandarte_azul": {"folha": FOLHA_CASTELO, "regiao": Rect2(19, 326, 90, 41)},
	"estandarte_laranja": {"folha": FOLHA_CASTELO, "regiao": Rect2(147, 326, 90, 41)},
	"rocha_baixa": {"folha": FOLHA_CAVERNA_OBJ, "regiao": Rect2(0, 10, 64, 22)},
	"cranio": {"folha": FOLHA_CAVERNA_OBJ, "regiao": Rect2(0, 33, 61, 31)},
	"cranio_b": {"folha": FOLHA_CAVERNA_OBJ, "regiao": Rect2(64, 33, 61, 31)},
	"picareta": {"folha": FOLHA_CAVERNA_OBJ, "regiao": Rect2(10, 71, 86, 25)},
	"carrinho": {"folha": FOLHA_CAVERNA_OBJ, "regiao": Rect2(0, 112, 64, 48)},
	"rocha_grande": {"folha": FOLHA_CAVERNA_OBJ, "regiao": Rect2(0, 185, 96, 39)},
	"cristal_largo": {"folha": FOLHA_CAVERNA_CRISTAL, "regiao": Rect2(0, 2, 96, 62)},
	"cristal_fino": {"folha": FOLHA_CAVERNA_CRISTAL, "regiao": Rect2(106, 0, 45, 64)},
	"cristal_medio": {"folha": FOLHA_CAVERNA_CRISTAL, "regiao": Rect2(167, 0, 57, 64)},
	"cristal_alto": {"folha": FOLHA_CAVERNA_CRISTAL, "regiao": Rect2(231, 0, 57, 64)},
	"cogumelo": {"folha": FOLHA_CAVERNA_FLUO, "regiao": Rect2(8, 77, 50, 51)},
	"cogumelo_b": {"folha": FOLHA_CAVERNA_FLUO, "regiao": Rect2(71, 78, 48, 50)},
}

const CEU := [
	Color(0.53, 0.78, 0.95),
	Color(0.64, 0.78, 0.9),
	Color(0.40, 0.50, 0.36),
	Color(0.30, 0.24, 0.40),
	Color(0.26, 0.09, 0.11),
	Color(0.12, 0.14, 0.18),  # caverna
]


## Sem argumento regera tudo (APAGA o que foi posto à mão nas cenas 1 a 5: marcador do chefe, loja etc.). Com um número
## (`-- 6`), grava só essa fase.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var so_a_fase: int = int(args[0]) if args.size() > 0 else 0
	ResourceSaver.save(_criar_tileset(), CAMINHO_TILESET)
	if so_a_fase == 0:
		_gravar(_fase_reta(), _mapa_reto(), 0)
		var tutorial := _fase_tutorial()
		_gravar(tutorial, _mapa_de(tutorial), 0)
	for definicao in _fases():
		if so_a_fase == 0 or definicao.indice == so_a_fase:
			_gravar(definicao, _mapa_de(definicao), definicao.tema)
	quit()


## Fase reta de 120 ladrilhos, para abrir sozinha. O jogo usa as cinco da campanha.
func _fase_reta() -> Dictionary:
	var sem_tipos: Array[StringName] = []
	return {
		"nome": "Teste", "arquivo": "res://levels/fase_teste.tscn", "no": "FaseTeste",
		"tema": 0, "indice": 0, "ultima": false, "quantidade": 0,
		"tipos": sem_tipos, "largura": LARGURA_TESTE, "inicio": 2,
	}


## Antes da Clareira: sem inimigos (porta sempre abre), placas ensinam o básico.
## Layout: início → baú → loja → boneco → pedra → porta (offsets do baú/boneco na main).
func _fase_tutorial() -> Dictionary:
	var sem_tipos: Array[StringName] = []
	return {
		"nome": "Treino", "arquivo": "res://levels/fase_tutorial.tscn", "no": "Fase",
		"tema": 0, "indice": 0, "ultima": false, "quantidade": 0,
		"tipos": sem_tipos, "luz_do_sol": true,
		"missao": "", "largura": 42, "inicio": 2,
		"buracos": [], "plataformas": [],
		"chao": [], "plataforma": [], "porta": 39,
		"degraus": [], "altas": [], "pontos": [],
		"loja": Vector2(220, 0),
		# Boneco em ~480; folga E ≥96 → pedra em 600.
		"desafios": [{
			"x": 600, "rotulo": "Empurrar a pedra",
			"aviso_sucesso": "A pedra rolou!", "aviso_falha": "A pedra não se moveu",
		}],
		"enfeites": [["arbusto", 6, 0], ["arbusto", 14, 0], ["arbusto", 24, 0], ["arbusto", 32, 0]],
		"placas": [
			["A/D andar · Espaço pular", 5],
			["E: baú · I: mochila", 7],
			["F: Fôlego (cura)", 9],
			["E: loja (50 po)", 12],
			["J: golpe · K: azagaia", 16],
			["Baú → arco · segure J", 20],
			["R: Surto (nível 2+)", 23],
			["E: empurrar a pedra", 28],
			["Porta → Clareira", 35],
		],
	}


## Clareira 1, Trilha 2, Pântano 3, Ruína 3, Fortaleza 4. Há mais pontos do que a quantidade.
func _fases() -> Array[Dictionary]:
	var fases: Array[Dictionary] = [
		{
			"nome": "Clareira", "arquivo": "res://levels/fase_1.tscn", "no": "Fase",
			"tema": 0, "indice": 1, "ultima": false, "quantidade": 1, "tipos": TIPOS_SEM_ARCO,
			"missao": "Limpe a clareira", "luz_do_sol": true,
			"largura": 40, "inicio": 2,
			"buracos": [Vector2i(31, 2)], "plataformas": [],
			"chao": [33, 34], "plataforma": [], "porta": 35,
			"degraus": [[12, 3, 1]], "altas": [[18, 4, 2], [25, 3, 2]], "pontos": [[19, 6]],
			"desafios": [{
				# Longe da loja (≥ Fase.FOLGA_INTERACAO_E): loja ~330 → pedra em 480.
				"x": 480, "rotulo": "Empurrar a pedra",
				"aviso_sucesso": "A pedra rolou!", "aviso_falha": "A pedra não se moveu",
			}],
			"enfeites": [["arbusto", 5, 0], ["arbusto", 10, 0], ["arbusto", 16, 0], ["arbusto", 22, 0], ["arbusto", 28, 0]],
		},
		{
			"nome": "Trilha", "arquivo": "res://levels/fase_2.tscn", "no": "Fase",
			"tema": 1, "indice": 2, "ultima": false, "quantidade": 2, "tipos": TIPOS_SEM_ARCO,
			"missao": "Abra a trilha", "luz_do_sol": true,
			"largura": 46, "inicio": 2, "loja": Vector2(150, 0),
			"buracos": [Vector2i(8, 2), Vector2i(21, 2), Vector2i(34, 2)], "plataformas": [],
			"chao": [10, 23, 36], "plataforma": [], "porta": 39,
			"degraus": [[13, 2, 1], [15, 2, 2], [17, 2, 1]], "altas": [[27, 4, 2]], "pontos": [[15, 6], [28, 6]],
			"enfeites": [["arbusto", 4, 0], ["arbusto", 12, 0], ["arbusto", 19, 0], ["arbusto", 30, 0], ["arbusto", 37, 0]],
		},
		{
			"nome": "Pântano", "arquivo": "res://levels/fase_3.tscn", "no": "Fase",
			"tema": 2, "indice": 3, "ultima": false, "quantidade": 3, "tipos": TIPOS_SEM_ARCO,
			"missao": "Limpe o pântano",
			"largura": 48, "inicio": 2, "loja": Vector2(150, 0),
			"buracos": [Vector2i(8, 2), Vector2i(30, 2)], "plataformas": [Vector2i(16, 3)],
			"chao": [10, 33, 40], "plataforma": [17], "porta": 43,
			"chefe": [&"ankheg", 37],
			"degraus": [[22, 3, 2]], "altas": [[34, 3, 2], [38, 3, 3]], "pontos": [[23, 6], [35, 6], [39, 5]],
			"enfeites": [
				["agua", 5, 0], ["junco", 6, 0], ["junco", 11, 0], ["agua", 13, 0],
				["junco", 20, 0], ["agua", 25, 0], ["junco", 27, 0], ["junco", 36, 0], ["agua", 41, 0],
			],
		},
		{
			"nome": "Ruína", "arquivo": "res://levels/fase_4.tscn", "no": "Fase",
			"tema": 3, "indice": 4, "ultima": false, "quantidade": 3, "tipos": TIPOS_RUINA,
			"largura": 48, "inicio": 2, "loja": Vector2(190, 0),
			"buracos": [Vector2i(6, 2), Vector2i(18, 2)], "plataformas": [Vector2i(30, 3)],
			"chao": [8, 38], "plataforma": [31], "arco": [25], "porta": 42,
			"degraus": [[10, 2, 1], [12, 3, 2], [15, 2, 1]], "altas": [[34, 3, 2]], "pontos": [[13, 6], [35, 6]],
			"enfeites": [
				["tocha", 5, 64], ["janela", 9, 100], ["tocha", 14, 64], ["estandarte_vermelho", 22, 150],
				["tocha", 28, 64], ["janela", 33, 100], ["tocha", 37, 64], ["estandarte_azul", 40, 150],
			],
		},
		{
			"nome": "Fortaleza", "arquivo": "res://levels/fase_5.tscn", "no": "Fase",
			"tema": 4, "indice": 5, "ultima": false, "quantidade": 4, "tipos": TIPOS_FORTALEZA,
			"largura": 50, "inicio": 2, "loja": Vector2(150, 0),
			"buracos": [Vector2i(8, 2), Vector2i(26, 2)], "plataformas": [Vector2i(19, 3)],
			"chao": [10, 12, 40], "plataforma": [21], "arco": [33], "porta": 44,
			"degraus": [[14, 2, 1], [16, 2, 2], [36, 2, 1], [38, 1, 2]], "altas": [[25, 5, 2]], "pontos": [[16, 6], [27, 6], [38, 6]],
			"enfeites": [
				["tocha", 5, 64], ["estandarte_vermelho", 11, 150], ["tocha", 18, 64], ["janela", 23, 100],
				["tocha", 30, 64], ["estandarte_amarelo", 35, 150], ["tocha", 41, 64], ["estandarte_azul", 46, 150],
			],
		},
		{
			"nome": "Labirinto", "arquivo": "res://levels/fase_6.tscn", "no": "Fase",
			"tema": 3, "indice": 6, "ultima": false, "quantidade": 4, "tipos": TIPOS_PEDRA, "missao": "Atravesse o labirinto",
			"largura": 62, "inicio": 2, "loja": Vector2(150, 0),
			"buracos": [Vector2i(10, 2), Vector2i(24, 3)], "plataformas": [],
			"chao": [14, 31, 39, 43], "plataforma": [], "porta": 58,
			# Arena do Minotauro (colunas 44 a 61, chão reto): o chefe espera na coluna 56; dois pilares de blocos rachados
			# [coluna, altura em blocos] que ele quebra na investida.
			"chefe": [&"minotauro", 56], "quebraveis": [[49, 2], [52, 2]],
			"degraus": [[16, 3, 1], [19, 2, 2], [33, 3, 1], [36, 3, 2]], "altas": [[22, 4, 2], [40, 3, 2]], "pontos": [[20, 6], [41, 6]],
			"enfeites": [
				["tocha", 6, 64], ["estandarte_vermelho", 8, 150], ["janela", 12, 100], ["tocha", 15, 64],
				["estandarte_amarelo", 20, 150], ["janela", 26, 100], ["tocha", 29, 64], ["estandarte_azul", 34, 150],
				["tocha", 38, 64], ["janela", 40, 100], ["estandarte_vermelho", 44, 150], ["tocha", 46, 64],
				["estandarte_verde", 48, 150], ["janela", 51, 100], ["tocha", 53, 64], ["estandarte_azul", 55, 150],
				["tocha", 59, 64],
			],
		},
		{
			"nome": "Mina", "arquivo": "res://levels/fase_7.tscn", "no": "Fase",
			"tema": 5, "indice": 7, "ultima": false, "quantidade": 4, "tipos": TIPOS_MINA, "missao": "Atravesse a mina",
			"largura": 60, "inicio": 2, "loja": Vector2(150, 0),
			"buracos": [Vector2i(9, 2), Vector2i(26, 3), Vector2i(41, 2)], "plataformas": [],
			"chao": [13, 30, 39, 44], "plataforma": [], "porta": 56,
			"degraus": [[16, 3, 1], [19, 2, 2], [33, 3, 1], [36, 2, 2], [47, 3, 1]], "altas": [[22, 4, 2]], "pontos": [[20, 6], [23, 6], [37, 6]],
			"enfeites": [
				["tocha", 6, 64], ["rocha_baixa", 11, 0], ["picareta", 18, 0], ["tocha", 14, 64],
				["carrinho", 28, 0], ["tocha", 31, 64], ["cristal_fino", 38, 0], ["tocha", 45, 64],
				["rocha_grande", 49, 0], ["tocha", 52, 64],
			],
		},
		{
			"nome": "Caverna Úmida", "arquivo": "res://levels/fase_8.tscn", "no": "Fase",
			"tema": 5, "indice": 8, "ultima": false, "quantidade": 5, "tipos": TIPOS_CAVERNA, "missao": "Atravesse a caverna",
			"largura": 64, "inicio": 2, "loja": Vector2(150, 0),
			"buracos": [Vector2i(8, 3), Vector2i(22, 2), Vector2i(37, 3), Vector2i(50, 2)], "plataformas": [],
			"chao": [11, 19, 30, 44, 53], "plataforma": [], "porta": 60,
			"degraus": [[13, 3, 1], [15, 2, 2], [26, 3, 1], [28, 2, 2], [40, 3, 1], [42, 2, 2]], "altas": [[33, 4, 2]], "pontos": [[16, 6], [29, 6], [43, 6], [34, 6]],
			"enfeites": [
				["tocha", 5, 64], ["cogumelo", 10, 0], ["cristal_medio", 14, 0], ["tocha", 17, 64],
				["cogumelo_b", 24, 0], ["cristal_largo", 31, 0], ["tocha", 33, 64], ["cristal_alto", 45, 0],
				["tocha", 47, 64], ["cogumelo", 54, 0], ["tocha", 57, 64],
			],
		},
		{
			# A cripta do Wight, a fase 9 do plano.
			"nome": "Cripta", "arquivo": "res://levels/fase_9.tscn", "no": "Fase",
			"tema": 5, "indice": 9, "ultima": false, "quantidade": 2, "tipos": TIPOS_CRIPTA, "missao": "Desça à cripta",
			"largura": 54, "inicio": 2,
			"buracos": [Vector2i(12, 2)], "plataformas": [],
			"chao": [15, 30], "plataforma": [], "porta": 50,
			# Arena do Wight (colunas 32 a 53, chão reto): ele espera na coluna 44; os acompanhantes (1 Skeleton e 1 Zombie;
			# o Zombie vem do sorteio da cripta também) surgem perto dele quando ele percebe o herói.
			"chefe": [&"wight", 44], "acompanhantes": [&"skeleton", &"zombie"],
			"degraus": [[18, 3, 1], [21, 2, 2]], "altas": [[24, 4, 2]], "pontos": [[22, 6], [36, 6]],
			"enfeites": [
				["tocha", 6, 64], ["cranio", 10, 0], ["tocha", 15, 64], ["janela", 20, 100],
				["cranio_b", 25, 0], ["tocha", 29, 64], ["estandarte_azul", 36, 150],
				["tocha", 40, 64], ["cranio", 45, 0], ["tocha", 48, 64],
			],
		},
		{
			# O covil da Quimera, a fase 10 (final). Arena larga e reta (colunas 30 a 63): ela espera na coluna 46.
			# Duas poças de lava no chão (zona de 1d6 de fogo / rodada); dá para contornar pelos degraus/plataformas.
			"nome": "Covil", "arquivo": "res://levels/fase_10.tscn", "no": "Fase",
			"tema": 5, "indice": 10, "ultima": true, "quantidade": 3, "tipos": TIPOS_COVIL, "missao": "Enfrente a Quimera",
			"largura": 64, "inicio": 2, "loja": Vector2(150, 0),
			"buracos": [], "plataformas": [],
			"lavas": [Vector2i(9, 3), Vector2i(35, 2)],
			"chao": [13, 22], "plataforma": [], "porta": 60,
			"chefe": [&"quimera", 46],
			"degraus": [[16, 3, 1], [19, 2, 2]], "altas": [[25, 4, 2]], "pontos": [[18, 6], [27, 6]],
			"enfeites": [
				["tocha", 6, 64], ["rocha_grande", 12, 0], ["tocha", 14, 64], ["cristal_largo", 22, 0],
				["tocha", 24, 64], ["cranio", 30, 0], ["tocha", 34, 64], ["cristal_alto", 40, 0],
				["tocha", 44, 64], ["cogumelo", 50, 0], ["tocha", 54, 64], ["rocha_baixa", 58, 0],
			],
		}
	]
	return fases


func _mapa_reto() -> Array[String]:
	var linhas: Array[String] = []
	for y in LINHAS:
		if y < LINHA_ACAO:
			linhas.append(".".repeat(LARGURA_TESTE))
		elif y == LINHA_ACAO:
			linhas.append(_trocar(".".repeat(LARGURA_TESTE), 2, "S"))
		else:
			linhas.append("#".repeat(LARGURA_TESTE))
	return linhas


func _mapa_de(definicao: Dictionary) -> Array[String]:
	var largura: int = definicao.largura
	var linhas: Array[String] = []
	for y in LINHAS:
		var linha := ".".repeat(largura)
		if y > LINHA_ACAO:
			linha = "#".repeat(largura)
			for buraco: Vector2i in definicao.buracos:
				for x in buraco.y:
					linha = _trocar(linha, buraco.x + x, ".")
		elif y == LINHA_ACAO:
			linha = _trocar(linha, definicao.inicio, "S")
			linha = _trocar(linha, definicao.porta, "D")
			for x: int in definicao.chao:
				linha = _trocar(linha, x, "A")
			for plataforma: Vector2i in definicao.plataformas:
				for x in plataforma.y:
					linha = _trocar(linha, plataforma.x + x, "=")
			for x: int in definicao.get("arco", []):
				linha = _trocar(linha, x, "A")
		elif y == LINHA_ACAO - 1:
			for x: int in definicao.plataforma:
				linha = _trocar(linha, x, "A")
		linhas.append(linha)
	_aplicar_relevo(linhas, definicao)
	return linhas


## Degraus (chão elevado), plataformas altas e pontos extras. O jogador sobe com o pulo de ~104 px:
## degraus de até 2 ladrilhos e plataformas a 2 ladrilhos do chão (a 3 só a partir de outra).
func _aplicar_relevo(linhas: Array[String], definicao: Dictionary) -> void:
	for degrau: Array in definicao.get("degraus", []):
		for altura in int(degrau[2]):
			var fileira := LINHA_ACAO - altura
			for x in int(degrau[1]):
				linhas[fileira] = _trocar(linhas[fileira], int(degrau[0]) + x, "#")
	for alta: Array in definicao.get("altas", []):
		var fileira := LINHA_ACAO + 1 - int(alta[2])
		for x in int(alta[1]):
			linhas[fileira] = _trocar(linhas[fileira], int(alta[0]) + x, "=")
	for ponto: Array in definicao.get("pontos", []):
		linhas[int(ponto[1])] = _trocar(linhas[int(ponto[1])], int(ponto[0]), "A")


func _gravar(definicao: Dictionary, mapa: Array[String], tema: int) -> void:
	var fase := Node2D.new()
	# Dentro da árvore o grupo da armadilha é gravado na cena.
	root.add_child(fase)
	fase.name = definicao.no
	fase.set_script(load(SCRIPT_FASE))
	fase.indice = definicao.indice
	fase.ultima = definicao.ultima
	fase.nome_ambiente = definicao.nome
	fase.quantidade = definicao.quantidade
	fase.tipos_permitidos = definicao.tipos
	fase.missao = definicao.get("missao", "")
	fase.luz_do_sol = definicao.get("luz_do_sol", false)
	fase.acompanhantes_do_chefe = _tipos(definicao.get("acompanhantes", []))
	fase.deslocamento_loja = definicao.get("loja", fase.deslocamento_loja)
	var terreno := _criar_terreno(fase)
	_pintar_mapa(fase, terreno, mapa, tema)
	_colocar_paredes(terreno, mapa, tema)
	_colocar_enfeites(fase, definicao.get("enfeites", []))
	_colocar_chefe(fase, definicao.get("chefe", []))
	_colocar_quebraveis(fase, definicao.get("quebraveis", []))
	_colocar_lavas(fase, definicao.get("lavas", []))
	_colocar_desafios(fase, definicao.get("desafios", []))
	_colocar_placas(fase, definicao.get("placas", []))
	_colocar_ceu(fase, mapa, CEU[tema])
	var cena := PackedScene.new()
	cena.pack(fase)
	ResourceSaver.save(cena, definicao.arquivo)
	print("Fase gerada: %s (%s)" % [definicao.nome, definicao.arquivo])
	fase.free()


## Placas de tutorial: [texto, coluna]. Ficam acima do chão, legíveis em pixel.
func _colocar_placas(fase: Node2D, placas: Array) -> void:
	if placas.is_empty():
		return
	var grupo := Node2D.new()
	grupo.name = "Placas"
	_adicionar(fase, grupo)
	var i := 0
	for entrada: Array in placas:
		i += 1
		var placa := Label.new()
		placa.name = "Placa%d" % i
		placa.text = String(entrada[0])
		placa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placa.position = Vector2(int(entrada[1]) * TAM + TAM / 2.0 - 40.0, LINHA_ACAO * TAM - 48.0)
		placa.add_theme_font_size_override(&"font_size", 10)
		placa.add_theme_color_override(&"font_color", Color(0.95, 0.92, 0.75))
		placa.add_theme_color_override(&"font_outline_color", Color.BLACK)
		placa.add_theme_constant_override(&"outline_size", 3)
		grupo.add_child(placa)
		placa.owner = fase


func _tipos(lista: Array) -> Array[StringName]:
	var tipos: Array[StringName] = []
	tipos.assign(lista)
	return tipos


## Chefe da fase: [tipo, coluna]. Grava o tipo e o marcador "Chefe" onde ele nasce.
func _colocar_chefe(fase: Node2D, chefe: Array) -> void:
	if chefe.is_empty():
		return
	fase.chefe = chefe[0]
	var marca := Marker2D.new()
	marca.name = "Chefe"
	marca.position = _pes(Vector2i(int(chefe[1]), LINHA_ACAO))
	_adicionar(fase, marca)


## Pilares de blocos rachados [coluna, altura em blocos] em cima do chão. Só a raiz de cada bloco é gravada na cena.
func _colocar_quebraveis(fase: Node2D, pilares: Array) -> void:
	var cena: PackedScene = load(CENA_BLOCO)
	for pilar: Array in pilares:
		for andar in int(pilar[1]):
			var bloco: Node2D = cena.instantiate()
			bloco.name = "Bloco%d_%d" % [int(pilar[0]), andar]
			bloco.position = _pes(Vector2i(int(pilar[0]), LINHA_ACAO)) - Vector2(0.0, andar * TAM)
			fase.add_child(bloco)
			bloco.owner = fase


## Poças de lava no chão [coluna, largura em ladrilhos]. Zona de dano; o chão embaixo continua sólido.
func _colocar_lavas(fase: Node2D, lavas: Array) -> void:
	if lavas.is_empty():
		return
	var cena: PackedScene = load(CENA_LAVA)
	for i in lavas.size():
		var def: Vector2i = lavas[i]
		var lava: Lava = cena.instantiate()
		lava.name = "Lava%d" % (i + 1)
		lava.configurar(def.y)
		lava.position = Vector2(def.x * TAM, (LINHA_ACAO + 1) * TAM)
		_adicionar(fase, lava)


## Desafios de perícia (pedra etc.): dicionário com x (px), rotulo e avisos.
func _colocar_desafios(fase: Node2D, desafios: Array) -> void:
	if desafios.is_empty():
		return
	var cena: PackedScene = load(CENA_DESAFIO_PERICIA)
	for i in desafios.size():
		var def: Dictionary = desafios[i]
		var desafio: Node2D = cena.instantiate()
		desafio.name = "DesafioPericia" if desafios.size() == 1 else "DesafioPericia%d" % (i + 1)
		desafio.add_to_group(&"desafio_pericia", true)
		desafio.position = Vector2(float(def.x), (LINHA_ACAO + 1) * TAM)
		if def.has("rotulo"):
			desafio.set("rotulo", def.rotulo)
		if def.has("aviso_sucesso"):
			desafio.set("aviso_sucesso", def.aviso_sucesso)
		if def.has("aviso_falha"):
			desafio.set("aviso_falha", def.aviso_falha)
		_adicionar(fase, desafio)


## Enfeites sem colisão: [nome, coluna, altura dos pés acima do chão (px)]. 0 = assentado no chão.
func _colocar_enfeites(fase: Node2D, enfeites: Array) -> void:
	if enfeites.is_empty():
		return
	var grupo := Node2D.new()
	grupo.name = "Enfeites"
	grupo.z_index = ENFEITE_Z
	_adicionar(fase, grupo)
	for enfeite: Array in enfeites:
		var centro := Vector2(int(enfeite[1]) * TAM + TAM / 2.0, (LINHA_ACAO + 1) * TAM - float(enfeite[2]))
		match String(enfeite[0]):
			"tocha":
				_colocar_tocha(grupo, centro, fase)
			"arbusto":
				_colocar_arbusto(grupo, centro, fase)
			"junco":
				_colocar_junco(grupo, centro, fase)
			"agua":
				_colocar_agua(grupo, centro, fase)
			_:
				_colocar_enfeite_pronto(grupo, centro, enfeite[0], fase)


func _colocar_enfeite_pronto(grupo: Node2D, pes: Vector2, nome: String, fase: Node2D) -> void:
	var def: Dictionary = ENFEITES_PRONTOS[nome]
	var regiao: Rect2 = def.regiao
	var textura := AtlasTexture.new()
	textura.atlas = load(def.folha)
	textura.region = regiao
	var sprite := Sprite2D.new()
	sprite.name = nome.capitalize().replace(" ", "")
	sprite.texture = textura
	sprite.centered = false
	sprite.position = pes - Vector2(regiao.size.x / 2.0, regiao.size.y)
	grupo.add_child(sprite)
	sprite.owner = fase


## Tocha: suporte escuro e chama de 4 quadros que tremula.
func _colocar_tocha(grupo: Node2D, pes: Vector2, fase: Node2D) -> void:
	var suporte := Polygon2D.new()
	suporte.name = "SuporteTocha"
	suporte.color = Color(0.2, 0.13, 0.09)
	suporte.polygon = PackedVector2Array([Vector2(-2, 0), Vector2(2, 0), Vector2(2, -TOCHA_ALTURA_SUPORTE), Vector2(-2, -TOCHA_ALTURA_SUPORTE)])
	suporte.position = pes
	grupo.add_child(suporte)
	suporte.owner = fase
	var quadros := SpriteFrames.new()
	quadros.set_animation_speed("default", CHAMA_VELOCIDADE)
	for regiao in CHAMA_QUADROS:
		var textura := AtlasTexture.new()
		textura.atlas = load(FOLHA_CASTELO)
		textura.region = regiao
		quadros.add_frame("default", textura)
	var chama := AnimatedSprite2D.new()
	chama.name = "ChamaTocha"
	chama.sprite_frames = quadros
	chama.autoplay = "default"
	chama.scale = Vector2(CHAMA_ESCALA, CHAMA_ESCALA)
	chama.position = pes + Vector2(0, -TOCHA_ALTURA_SUPORTE - 8.0)
	grupo.add_child(chama)
	chama.owner = fase


## Arbusto provisório da floresta (polígono verde).
func _colocar_arbusto(grupo: Node2D, pes: Vector2, fase: Node2D) -> void:
	var arbusto := Polygon2D.new()
	arbusto.name = "Arbusto"
	arbusto.color = Color(0.22, 0.48, 0.20)
	arbusto.polygon = PackedVector2Array([
		Vector2(-14, 0), Vector2(-10, -10), Vector2(-16, -18), Vector2(-6, -26),
		Vector2(0, -30), Vector2(8, -24), Vector2(16, -16), Vector2(12, -8), Vector2(14, 0),
	])
	arbusto.position = pes
	grupo.add_child(arbusto)
	arbusto.owner = fase


## Junco do pântano: hastes finas.
func _colocar_junco(grupo: Node2D, pes: Vector2, fase: Node2D) -> void:
	var junco := Polygon2D.new()
	junco.name = "Junco"
	junco.color = Color(0.28, 0.42, 0.18)
	junco.polygon = PackedVector2Array([
		Vector2(-8, 0), Vector2(-10, -22), Vector2(-6, -36), Vector2(-2, -20),
		Vector2(0, -40), Vector2(2, -18), Vector2(6, -34), Vector2(10, -16), Vector2(8, 0),
	])
	junco.position = pes
	grupo.add_child(junco)
	junco.owner = fase


## Poça de água turva do pântano + bolhas estáticas (polish barato até haver sprite).
func _colocar_agua(grupo: Node2D, pes: Vector2, fase: Node2D) -> void:
	var agua := Polygon2D.new()
	agua.name = "Agua"
	agua.color = Color(0.18, 0.36, 0.28, 0.72)
	agua.polygon = PackedVector2Array([
		Vector2(-22, -2), Vector2(-18, -8), Vector2(-4, -10), Vector2(12, -8),
		Vector2(22, -3), Vector2(18, 2), Vector2(-16, 2),
	])
	agua.position = pes
	grupo.add_child(agua)
	agua.owner = fase
	for i in 3:
		var bolha := Polygon2D.new()
		bolha.name = "Bolha%d" % (i + 1)
		bolha.color = Color(0.55, 0.75, 0.65, 0.55)
		var r := 2.0 + float(i)
		bolha.polygon = PackedVector2Array([
			Vector2(-r, 0), Vector2(0, -r), Vector2(r, 0), Vector2(0, r * 0.6),
		])
		bolha.position = pes + Vector2(-10.0 + i * 10.0, -6.0 - i * 3.0)
		grupo.add_child(bolha)
		bolha.owner = fase


func _criar_terreno(fase: Node2D) -> TileMapLayer:
	var terreno := TileMapLayer.new()
	terreno.name = "Terreno"
	terreno.tile_set = load(CAMINHO_TILESET)
	_adicionar(fase, terreno)
	return terreno


func _pintar_mapa(fase: Node2D, terreno: TileMapLayer, mapa: Array[String], tema: int) -> void:
	for y in mapa.size():
		for x in _largura(mapa):
			var celula := Vector2i(x, y)
			match _char(mapa, x, y):
				"#":
					_pintar(terreno, celula, _tipo_do_chao(mapa, x, y), tema)
				"P":
					_pintar(terreno, celula, PEDRA, tema)
				"=":
					_pintar(terreno, celula, PLATAFORMA, tema)
				"S":
					_colocar_inicio(fase, celula)
				"A":
					_colocar_armadilha(fase, celula)
				"D":
					_colocar_porta(fase, celula)


func _tipo_do_chao(mapa: Array[String], x: int, y: int) -> int:
	var acima := _char(mapa, x, y - 1)
	return TERRA if acima == "#" or acima == "P" else GRAMA


func _colocar_inicio(fase: Node2D, celula: Vector2i) -> void:
	var inicio := Marker2D.new()
	inicio.name = "InicioJogador"
	inicio.position = _pes(celula)
	_adicionar(fase, inicio)


func _colocar_armadilha(fase: Node2D, celula: Vector2i) -> void:
	var marca := Marker2D.new()
	marca.name = "Armadilha%d" % (fase.get_child_count() + 1)
	marca.position = _pes(celula)
	marca.add_to_group(&"armadilha", true)
	_adicionar(fase, marca)


func _colocar_porta(fase: Node2D, celula: Vector2i) -> void:
	var porta := Area2D.new()
	porta.name = "Porta"
	porta.position = _pes(celula)
	porta.collision_layer = 0
	porta.collision_mask = MASCARA_JOGADOR
	porta.monitorable = false
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(LARGURA_PORTA, ALTURA_PORTA)
	forma.shape = retangulo
	forma.position = Vector2(0.0, -ALTURA_PORTA / 2.0)
	porta.add_child(forma)
	_adicionar(fase, porta)


## Pés no chão: base do ladrilho. Numa plataforma, a letra fica na fileira de cima.
func _pes(celula: Vector2i) -> Vector2:
	return Vector2(celula.x * TAM + TAM / 2.0, (celula.y + 1) * TAM)


func _colocar_paredes(terreno: TileMapLayer, mapa: Array[String], tema: int) -> void:
	var largura := _largura(mapa)
	for y in range(-ALTURA_EXTRA_PAREDE, mapa.size()):
		_pintar(terreno, Vector2i(-1, y), PEDRA, tema)
		_pintar(terreno, Vector2i(largura, y), PEDRA, tema)


func _colocar_ceu(fase: Node2D, mapa: Array[String], cor: Color) -> void:
	var ceu := Polygon2D.new()
	ceu.name = "Ceu"
	ceu.color = cor
	ceu.z_index = -10
	var largura := float(_largura(mapa) * TAM)
	var fundo := float(mapa.size() * TAM)
	ceu.polygon = PackedVector2Array([
		Vector2(-TAM, -ALTURA_EXTRA_PAREDE * TAM), Vector2(largura + TAM, -ALTURA_EXTRA_PAREDE * TAM),
		Vector2(largura + TAM, fundo), Vector2(-TAM, fundo),
	])
	_adicionar(fase, ceu)


## Sorteia a variante do ladrilho pela posição (sempre a mesma para a mesma célula, sem depender de semente).
func _sortear_variante(celula: Vector2i, tipo: int) -> int:
	var variantes: Array[int] = [tipo]
	if tipo == GRAMA:
		variantes = VARIANTES_GRAMA
	elif tipo == TERRA:
		variantes = VARIANTES_TERRA
	return variantes[absi(hash(celula)) % variantes.size()]


func _pintar(terreno: TileMapLayer, celula: Vector2i, tipo: int, tema: int) -> void:
	terreno.set_cell(celula, 0, Vector2i(_sortear_variante(celula, tipo), tema))


func _adicionar(fase: Node2D, no: Node) -> void:
	fase.add_child(no)
	no.owner = fase
	# Instância de PackedScene: os filhos já pertencem à cena empacotada. Se ganharem
	# owner da fase, o pack grava nós duplicados (aviso no editor: name conflicts).
	if not no.scene_file_path.is_empty():
		return
	for filho in no.find_children("*", "", true, false):
		filho.owner = fase


func _largura(mapa: Array[String]) -> int:
	var largura := 0
	for linha in mapa:
		largura = maxi(largura, (linha as String).length())
	return largura


func _char(mapa: Array[String], x: int, y: int) -> String:
	if y < 0 or y >= mapa.size():
		return "."
	var linha: String = mapa[y]
	return linha[x] if x < linha.length() else "."


func _trocar(linha: String, x: int, caractere: String) -> String:
	return linha.substr(0, x) + caractere + linha.substr(x + 1)


func _criar_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TAM, TAM)
	# Camada 0 = chão sólido (physics layer "mundo"); camada 1 = prancha one-way ("plataforma").
	# O Gray Ooze (Amorfo) só mascara o mundo e atravessa as pranchas.
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(1, 1 << 5)  # bit da layer 6
	var fonte := TileSetAtlasSource.new()
	fonte.texture = load("res://assets/tiles/ladrilhos.png")
	fonte.texture_region_size = Vector2i(TAM, TAM)
	tileset.add_source(fonte, 0)
	for tema in CEU.size():
		for tipo in [GRAMA, TERRA, PLATAFORMA, PEDRA] + VARIANTES_GRAMA.slice(1) + VARIANTES_TERRA.slice(1):
			var coord := Vector2i(tipo, tema)
			fonte.create_tile(coord)
			var dados := fonte.get_tile_data(coord, 0)
			var e_plataforma: bool = tipo == PLATAFORMA
			var e_grama: bool = tipo == GRAMA or VARIANTES_GRAMA.has(tipo)
			var camada_fisica := 1 if e_plataforma else 0
			var altura := ALTURA_PRANCHA if e_plataforma else TAM
			var recuo := float(RECUO_COLISAO_GRAMA) if e_grama else 0.0
			dados.add_collision_polygon(camada_fisica)
			dados.set_collision_polygon_points(camada_fisica, 0, _retangulo_colisao(altura, recuo))
			dados.set_collision_polygon_one_way(camada_fisica, 0, e_plataforma)
	return tileset


func _retangulo_colisao(altura: float, recuo_topo: float = 0.0) -> PackedVector2Array:
	var meio := TAM / 2.0
	return PackedVector2Array([
		Vector2(-meio, -meio + recuo_topo), Vector2(meio, -meio + recuo_topo),
		Vector2(meio, -meio + altura), Vector2(-meio, -meio + altura)])
