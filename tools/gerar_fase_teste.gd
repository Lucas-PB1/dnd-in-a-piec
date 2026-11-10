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
const ALTURA_EXTRA_PAREDE := 6
const ALTURA_PRANCHA := 10
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

## Enfeites das Ruínas: recortes da folha CC0 do castelo (rubberduck, ver assets/CREDITOS.md). Sem colisão, atrás do terreno.
const FOLHA_CASTELO := "res://assets/tiles/castelo/castle_tileset_part3.png"
const ENFEITE_Z := -5
const CHAMA_QUADROS: Array[Rect2] = [Rect2(45, 5, 7, 8), Rect2(77, 4, 6, 9), Rect2(109, 5, 6, 8), Rect2(141, 3, 7, 10)]
const CHAMA_ESCALA := 2.0
const CHAMA_VELOCIDADE := 8.0
const TOCHA_ALTURA_SUPORTE := 18.0
const ENFEITES_PRONTOS := {
	"janela": Rect2(3, 6, 26, 56),
	"estandarte_vermelho": Rect2(19, 198, 90, 41),
	"estandarte_amarelo": Rect2(147, 198, 90, 41),
	"estandarte_verde": Rect2(19, 262, 90, 41),
	"estandarte_azul": Rect2(19, 326, 90, 41),
	"estandarte_laranja": Rect2(147, 326, 90, 41),
}

const CEU := [
	Color(0.53, 0.78, 0.95),
	Color(0.64, 0.78, 0.9),
	Color(0.40, 0.50, 0.36),
	Color(0.30, 0.24, 0.40),
	Color(0.26, 0.09, 0.11),
]


## Sem argumento regera tudo (APAGA o que foi posto à mão nas cenas 1 a 5: marcador do chefe, loja etc.). Com um número
## (`-- 6`), grava só essa fase.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var so_a_fase: int = int(args[0]) if args.size() > 0 else 0
	ResourceSaver.save(_criar_tileset(), CAMINHO_TILESET)
	if so_a_fase == 0:
		_gravar(_fase_reta(), _mapa_reto(), 0)
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


## Clareira 1, Trilha 2, Pântano 3, Ruína 3, Fortaleza 4. Há mais pontos do que a quantidade.
func _fases() -> Array[Dictionary]:
	var fases: Array[Dictionary] = [
		{
			"nome": "Clareira", "arquivo": "res://levels/fase_1.tscn", "no": "Fase",
			"tema": 0, "indice": 1, "ultima": false, "quantidade": 1, "tipos": TIPOS_SEM_ARCO,
			"largura": 40, "inicio": 2,
			"buracos": [Vector2i(31, 2)], "plataformas": [],
			"chao": [33, 34], "plataforma": [], "porta": 35,
			"degraus": [[12, 3, 1]], "altas": [[18, 4, 2], [25, 3, 2]], "pontos": [[19, 6]],
		},
		{
			"nome": "Trilha", "arquivo": "res://levels/fase_2.tscn", "no": "Fase",
			"tema": 1, "indice": 2, "ultima": false, "quantidade": 2, "tipos": TIPOS_SEM_ARCO,
			"largura": 46, "inicio": 2,
			"buracos": [Vector2i(8, 2), Vector2i(21, 2), Vector2i(34, 2)], "plataformas": [],
			"chao": [10, 23, 36], "plataforma": [], "porta": 39,
			"degraus": [[13, 2, 1], [15, 2, 2], [17, 2, 1]], "altas": [[27, 4, 2]], "pontos": [[15, 6], [28, 6]],
		},
		{
			"nome": "Pântano", "arquivo": "res://levels/fase_3.tscn", "no": "Fase",
			"tema": 2, "indice": 3, "ultima": false, "quantidade": 3, "tipos": TIPOS_SEM_ARCO,
			"largura": 48, "inicio": 2,
			"buracos": [Vector2i(8, 2), Vector2i(30, 2)], "plataformas": [Vector2i(16, 3)],
			"chao": [10, 33, 40], "plataforma": [17], "porta": 43,
			"degraus": [[22, 3, 2]], "altas": [[34, 3, 2], [38, 3, 3]], "pontos": [[23, 6], [35, 6], [39, 5]],
		},
		{
			"nome": "Ruína", "arquivo": "res://levels/fase_4.tscn", "no": "Fase",
			"tema": 3, "indice": 4, "ultima": false, "quantidade": 3, "tipos": TIPOS_RUINA,
			"largura": 48, "inicio": 2,
			"buracos": [Vector2i(6, 2), Vector2i(18, 2)], "plataformas": [Vector2i(30, 3)],
			"chao": [8, 38], "plataforma": [31], "arco": [25], "porta": 42,
			"degraus": [[10, 2, 1], [12, 3, 2], [15, 2, 1]], "altas": [[34, 3, 2]], "pontos": [[13, 6], [35, 6]],
		},
		{
			"nome": "Fortaleza", "arquivo": "res://levels/fase_5.tscn", "no": "Fase",
			"tema": 4, "indice": 5, "ultima": false, "quantidade": 4, "tipos": TIPOS_FORTALEZA,
			"largura": 50, "inicio": 2,
			"buracos": [Vector2i(8, 2), Vector2i(26, 2)], "plataformas": [Vector2i(19, 3)],
			"chao": [10, 12, 40], "plataforma": [21], "arco": [33], "porta": 44,
			"degraus": [[14, 2, 1], [16, 2, 2], [36, 2, 1], [38, 1, 2]], "altas": [[25, 5, 2]], "pontos": [[16, 6], [27, 6], [38, 6]],
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
			"tema": 4, "indice": 7, "ultima": false, "quantidade": 4, "tipos": TIPOS_MINA, "missao": "Atravesse a mina",
			"largura": 60, "inicio": 2, "loja": Vector2(150, 0),
			"buracos": [Vector2i(9, 2), Vector2i(26, 3), Vector2i(41, 2)], "plataformas": [],
			"chao": [13, 30, 39, 44], "plataforma": [], "porta": 56,
			"degraus": [[16, 3, 1], [19, 2, 2], [33, 3, 1], [36, 2, 2], [47, 3, 1]], "altas": [[22, 4, 2]], "pontos": [[20, 6], [23, 6], [37, 6]],
			"enfeites": [["tocha", 6, 64], ["tocha", 14, 64], ["tocha", 31, 64], ["tocha", 45, 64], ["tocha", 52, 64]],
		},
		{
			"nome": "Caverna Úmida", "arquivo": "res://levels/fase_8.tscn", "no": "Fase",
			"tema": 3, "indice": 8, "ultima": false, "quantidade": 5, "tipos": TIPOS_CAVERNA, "missao": "Atravesse a caverna",
			"largura": 64, "inicio": 2, "loja": Vector2(150, 0),
			"buracos": [Vector2i(8, 3), Vector2i(22, 2), Vector2i(37, 3), Vector2i(50, 2)], "plataformas": [],
			"chao": [11, 19, 30, 44, 53], "plataforma": [], "porta": 60,
			"degraus": [[13, 3, 1], [15, 2, 2], [26, 3, 1], [28, 2, 2], [40, 3, 1], [42, 2, 2]], "altas": [[33, 4, 2]], "pontos": [[16, 6], [29, 6], [43, 6], [34, 6]],
			"enfeites": [["tocha", 5, 64], ["tocha", 17, 64], ["tocha", 33, 64], ["tocha", 47, 64], ["tocha", 57, 64]],
		},
		{
			# A cripta do Wight, a fase 9 do plano.
			"nome": "Cripta", "arquivo": "res://levels/fase_9.tscn", "no": "Fase",
			"tema": 3, "indice": 9, "ultima": false, "quantidade": 2, "tipos": TIPOS_CRIPTA, "missao": "Desça à cripta",
			"largura": 54, "inicio": 2,
			"buracos": [Vector2i(12, 2)], "plataformas": [],
			"chao": [15, 30], "plataforma": [], "porta": 50,
			# Arena do Wight (colunas 32 a 53, chão reto): ele espera na coluna 44; os acompanhantes (1 Skeleton e 1 Zombie;
			# o Zombie vem do sorteio da cripta também) surgem perto dele quando ele percebe o herói.
			"chefe": [&"wight", 44], "acompanhantes": [&"skeleton", &"zombie"],
			"degraus": [[18, 3, 1], [21, 2, 2]], "altas": [[24, 4, 2]], "pontos": [[22, 6], [36, 6]],
			"enfeites": [["tocha", 6, 64], ["tocha", 15, 64], ["janela", 20, 100], ["tocha", 29, 64], ["estandarte_azul", 36, 150], ["tocha", 40, 64], ["tocha", 48, 64]],
		},
		{
			# O covil da Quimera, a fase 10 (final). Arena larga e reta (colunas 30 a 63): ela espera na coluna 46. A lava (dano de
			# fogo no chão) ainda não existe: o fundo avermelhado é só clima (ver docs/backlog/).
			"nome": "Covil", "arquivo": "res://levels/fase_10.tscn", "no": "Fase",
			"tema": 4, "indice": 10, "ultima": true, "quantidade": 3, "tipos": TIPOS_COVIL, "missao": "Enfrente a Quimera",
			"largura": 64, "inicio": 2, "loja": Vector2(150, 0),
			"buracos": [Vector2i(9, 3)], "plataformas": [],
			"chao": [13, 22], "plataforma": [], "porta": 60,
			"chefe": [&"quimera", 46],
			"degraus": [[16, 3, 1], [19, 2, 2]], "altas": [[25, 4, 2]], "pontos": [[18, 6], [27, 6]],
			"enfeites": [["tocha", 6, 64], ["tocha", 14, 64], ["tocha", 24, 64], ["tocha", 34, 64], ["tocha", 44, 64], ["tocha", 54, 64]],
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
	fase.acompanhantes_do_chefe = _tipos(definicao.get("acompanhantes", []))
	fase.deslocamento_loja = definicao.get("loja", fase.deslocamento_loja)
	var terreno := _criar_terreno(fase)
	_pintar_mapa(fase, terreno, mapa, tema)
	_colocar_paredes(terreno, mapa, tema)
	_colocar_enfeites(fase, definicao.get("enfeites", []))
	_colocar_chefe(fase, definicao.get("chefe", []))
	_colocar_quebraveis(fase, definicao.get("quebraveis", []))
	_colocar_ceu(fase, mapa, CEU[tema])
	var cena := PackedScene.new()
	cena.pack(fase)
	ResourceSaver.save(cena, definicao.arquivo)
	print("Fase gerada: %s (%s)" % [definicao.nome, definicao.arquivo])
	fase.free()


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


## Enfeites sem colisão (tochas com chama animada, janelas, estandartes): [nome, coluna, altura dos pés do enfeite acima do chão (px)].
func _colocar_enfeites(fase: Node2D, enfeites: Array) -> void:
	if enfeites.is_empty():
		return
	var grupo := Node2D.new()
	grupo.name = "Enfeites"
	grupo.z_index = ENFEITE_Z
	_adicionar(fase, grupo)
	for enfeite: Array in enfeites:
		var centro := Vector2(int(enfeite[1]) * TAM + TAM / 2.0, (LINHA_ACAO + 1) * TAM - float(enfeite[2]))
		if enfeite[0] == "tocha":
			_colocar_tocha(grupo, centro, fase)
		else:
			_colocar_enfeite_pronto(grupo, centro, enfeite[0], fase)


func _colocar_enfeite_pronto(grupo: Node2D, pes: Vector2, nome: String, fase: Node2D) -> void:
	var regiao: Rect2 = ENFEITES_PRONTOS[nome]
	var textura := AtlasTexture.new()
	textura.atlas = load(FOLHA_CASTELO)
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
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	var fonte := TileSetAtlasSource.new()
	fonte.texture = load("res://assets/tiles/ladrilhos.png")
	fonte.texture_region_size = Vector2i(TAM, TAM)
	tileset.add_source(fonte, 0)
	for tema in CEU.size():
		for tipo in [GRAMA, TERRA, PLATAFORMA, PEDRA] + VARIANTES_GRAMA.slice(1) + VARIANTES_TERRA.slice(1):
			var coord := Vector2i(tipo, tema)
			fonte.create_tile(coord)
			var dados := fonte.get_tile_data(coord, 0)
			dados.add_collision_polygon(0)
			var e_plataforma: bool = tipo == PLATAFORMA
			dados.set_collision_polygon_points(0, 0, _retangulo_colisao(ALTURA_PRANCHA if e_plataforma else TAM))
			dados.set_collision_polygon_one_way(0, 0, e_plataforma)
	return tileset


func _retangulo_colisao(altura: float) -> PackedVector2Array:
	var meio := TAM / 2.0
	return PackedVector2Array([
		Vector2(-meio, -meio), Vector2(meio, -meio),
		Vector2(meio, -meio + altura), Vector2(-meio, -meio + altura)])
