extends SceneTree
## Gera o TileSet e as fases a partir dos mapas abaixo.
##   godot --headless --path . --script res://tools/gerar_fase_teste.gd
## Cada caractere = 1 ladrilho de 32 px. O gerador monta o texto a partir dos números
## de cada fase (buraco, plataforma, armadilha, porta, muro), para não errar a conta.
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
const ALTURA_EXTRA_PAREDE := 6
const ALTURA_PRANCHA := 10
## Fileira do "S": os pés ficam na base dela, em y = 288.
const LINHA_ACAO := 8
const PROFUNDIDADE_CHAO := 3
const LINHAS := LINHA_ACAO + 1 + PROFUNDIDADE_CHAO
## O pulo (~104 px) não passa de um muro desta altura acima do chão.
const ALTURA_MURO := 4
const LARGURA_TESTE := 120
## A porta detecta o corpo do herói (camada 2).
const MASCARA_JOGADOR := 2
const LARGURA_PORTA := 28.0
const ALTURA_PORTA := 72.0

enum { GRAMA, TERRA, PLATAFORMA, PEDRA }

const OOZE := &"ooze"
const MINION := &"minion"
const WARRIOR := &"warrior"
const TIPOS_SEM_ARCO: Array[StringName] = [OOZE, MINION]
const TIPOS_TODOS: Array[StringName] = [OOZE, MINION, WARRIOR]

const CEU := [
	Color(0.53, 0.78, 0.95),
	Color(0.64, 0.78, 0.9),
	Color(0.40, 0.50, 0.36),
	Color(0.30, 0.24, 0.40),
	Color(0.26, 0.09, 0.11),
]


func _initialize() -> void:
	ResourceSaver.save(_criar_tileset(), CAMINHO_TILESET)
	_gravar(_fase_reta(), _mapa_reto(), 0, -1)
	for definicao in _fases():
		_gravar(definicao, _mapa_de(definicao), definicao.tema, definicao.muro)
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
			"chao": [33, 34], "plataforma": [], "porta": 35, "muro": 36,
			"degraus": [[12, 3, 1]], "altas": [[18, 4, 2], [25, 3, 2]], "pontos": [[19, 6]],
		},
		{
			"nome": "Trilha", "arquivo": "res://levels/fase_2.tscn", "no": "Fase",
			"tema": 1, "indice": 2, "ultima": false, "quantidade": 2, "tipos": TIPOS_SEM_ARCO,
			"largura": 46, "inicio": 2,
			"buracos": [Vector2i(8, 2), Vector2i(21, 2), Vector2i(34, 2)], "plataformas": [],
			"chao": [10, 23, 36], "plataforma": [], "porta": 39, "muro": 40,
			"degraus": [[13, 2, 1], [15, 2, 2], [17, 2, 1]], "altas": [[27, 4, 2]], "pontos": [[15, 6], [28, 6]],
		},
		{
			"nome": "Pântano", "arquivo": "res://levels/fase_3.tscn", "no": "Fase",
			"tema": 2, "indice": 3, "ultima": false, "quantidade": 3, "tipos": TIPOS_SEM_ARCO,
			"largura": 48, "inicio": 2,
			"buracos": [Vector2i(8, 2), Vector2i(30, 2)], "plataformas": [Vector2i(16, 3)],
			"chao": [10, 33, 40], "plataforma": [17], "porta": 43, "muro": 44,
			"degraus": [[22, 3, 2]], "altas": [[34, 3, 2], [38, 3, 3]], "pontos": [[23, 6], [35, 6], [39, 5]],
		},
		{
			"nome": "Ruína", "arquivo": "res://levels/fase_4.tscn", "no": "Fase",
			"tema": 3, "indice": 4, "ultima": false, "quantidade": 3, "tipos": TIPOS_TODOS,
			"largura": 48, "inicio": 2,
			"buracos": [Vector2i(6, 2), Vector2i(18, 2)], "plataformas": [Vector2i(30, 3)],
			"chao": [8, 38], "plataforma": [31], "arco": [25], "porta": 42, "muro": 43,
			"degraus": [[10, 2, 1], [12, 3, 2], [15, 2, 1]], "altas": [[34, 3, 2]], "pontos": [[13, 6], [35, 6]],
		},
		{
			"nome": "Fortaleza", "arquivo": "res://levels/fase_5.tscn", "no": "Fase",
			"tema": 4, "indice": 5, "ultima": true, "quantidade": 4, "tipos": TIPOS_TODOS,
			"largura": 50, "inicio": 2,
			"buracos": [Vector2i(8, 2), Vector2i(26, 2)], "plataformas": [Vector2i(19, 3)],
			"chao": [10, 12, 40], "plataforma": [21], "arco": [33], "porta": 44, "muro": 45,
			"degraus": [[14, 2, 1], [16, 2, 2], [36, 2, 1], [38, 1, 2]], "altas": [[25, 5, 2]], "pontos": [[16, 6], [27, 6], [38, 6]],
		},
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


func _gravar(definicao: Dictionary, mapa: Array[String], tema: int, muro: int) -> void:
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
	var terreno := _criar_terreno(fase)
	_pintar_mapa(fase, terreno, mapa, tema)
	_colocar_paredes(terreno, mapa, tema)
	if muro >= 0:
		_colocar_muro(terreno, muro, mapa, tema)
	_colocar_ceu(fase, mapa, CEU[tema])
	var cena := PackedScene.new()
	cena.pack(fase)
	ResourceSaver.save(cena, definicao.arquivo)
	print("Fase gerada: %s (%s)" % [definicao.nome, definicao.arquivo])
	fase.free()


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


func _colocar_muro(terreno: TileMapLayer, x: int, mapa: Array[String], tema: int) -> void:
	for y in range(LINHA_ACAO - ALTURA_MURO, mapa.size()):
		_pintar(terreno, Vector2i(x, y), PEDRA, tema)


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


func _pintar(terreno: TileMapLayer, celula: Vector2i, tipo: int, tema: int) -> void:
	terreno.set_cell(celula, 0, Vector2i(tipo, tema))


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
		for tipo in [GRAMA, TERRA, PLATAFORMA, PEDRA]:
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
