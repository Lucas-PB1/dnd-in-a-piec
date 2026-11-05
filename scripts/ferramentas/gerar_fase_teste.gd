extends SceneTree
## Gera o TileSet (assets/tiles/ladrilhos.tres) e a fase de teste (scenes/fases/fase_teste.tscn)
## a partir do MAPA em texto abaixo. Mude o desenho e rode de novo:
##   godot --headless --path . --script res://scripts/ferramentas/gerar_fase_teste.gd
## Cada caractere = 1 ladrilho de 32x32 px. Linha terminada em "*" repete o último caractere.
##   #  chão (vira grama no topo e terra embaixo, automaticamente)
##   P  bloco de pedra
##   =  plataforma de madeira (dá para atravessar por baixo e subir nela)
##   S  onde o herói começa
##   .  vazio
## Paredes de pedra são colocadas automaticamente nas duas pontas.

const TAM := 32
const CAMINHO_TILESET := "res://assets/tiles/ladrilhos.tres"
const CAMINHO_FASE := "res://scenes/fases/fase_teste.tscn"
## Altura da parede das pontas acima do topo do mapa (ladrilhos).
const ALTURA_EXTRA_PAREDE := 6
## Altura da prancha da plataforma (px a partir do topo do ladrilho).
const ALTURA_PRANCHA := 10

enum { GRAMA, TERRA, PLATAFORMA, PEDRA }  # mesma ordem do gerar_arte_provisoria.gd

## Fase reta (sem plataformas por enquanto): só chão, comprida para testar a corrida.
## As linhas vazias de cima são o céu; o chão tem 3 ladrilhos de profundidade.
const LARGURA_FASE := 120
const MAPA := [
	".",
	".",
	".",
	".",
	".",
	".",
	".",
	".",
	"..S",
	"#*",
	"#*",
	"#*",
]


func _initialize() -> void:
	ResourceSaver.save(_criar_tileset(), CAMINHO_TILESET)

	var fase := Node2D.new()
	fase.name = "FaseTeste"
	var terreno := _criar_terreno(fase)
	_pintar_mapa(fase, terreno)
	_colocar_paredes(terreno)

	var cena := PackedScene.new()
	cena.pack(fase)
	ResourceSaver.save(cena, CAMINHO_FASE)
	print("Fase gerada: %dx%d ladrilhos -> %s" % [_largura(), MAPA.size(), CAMINHO_FASE])
	fase.free()
	quit()


func _criar_terreno(fase: Node2D) -> TileMapLayer:
	var terreno := TileMapLayer.new()
	terreno.name = "Terreno"
	terreno.tile_set = load(CAMINHO_TILESET)
	_adicionar(fase, terreno)
	return terreno


func _pintar_mapa(fase: Node2D, terreno: TileMapLayer) -> void:
	for y in MAPA.size():
		for x in _largura():
			var celula := Vector2i(x, y)
			match _char(x, y):
				"#":
					_pintar(terreno, celula, _tipo_do_chao(x, y))
				"P":
					_pintar(terreno, celula, PEDRA)
				"=":
					_pintar(terreno, celula, PLATAFORMA)
				"S":
					_colocar_inicio(fase, celula)


## Grama no topo; terra quando tem chão ou pedra em cima.
func _tipo_do_chao(x: int, y: int) -> int:
	var acima := _char(x, y - 1)
	return TERRA if acima == "#" or acima == "P" else GRAMA


func _colocar_inicio(fase: Node2D, celula: Vector2i) -> void:
	var inicio := Marker2D.new()
	inicio.name = "InicioJogador"
	# Pés do herói no chão: base do ladrilho "S".
	inicio.position = Vector2(celula.x * TAM + TAM / 2.0, (celula.y + 1) * TAM)
	_adicionar(fase, inicio)


## Paredes de pedra nas duas pontas, da altura toda (o herói não sai pelos lados).
func _colocar_paredes(terreno: TileMapLayer) -> void:
	for y in range(-ALTURA_EXTRA_PAREDE, MAPA.size()):
		_pintar(terreno, Vector2i(-1, y), PEDRA)
		_pintar(terreno, Vector2i(_largura(), y), PEDRA)


func _pintar(terreno: TileMapLayer, celula: Vector2i, tipo: int) -> void:
	terreno.set_cell(celula, 0, Vector2i(tipo, 0))


## Adiciona um nó à fase e marca o dono, senão ele não é salvo na cena.
func _adicionar(fase: Node2D, no: Node) -> void:
	fase.add_child(no)
	no.owner = fase


func _largura() -> int:
	var largura := LARGURA_FASE
	for linha in MAPA:
		largura = maxi(largura, (linha as String).trim_suffix("*").length())
	return largura


## Caractere do mapa em (x, y). Fora do desenho = vazio. "#*" repete "#" até o fim da linha.
func _char(x: int, y: int) -> String:
	if y < 0 or y >= MAPA.size():
		return "."
	var linha: String = MAPA[y]
	if linha.ends_with("*"):
		var base := linha.trim_suffix("*")
		return base[x] if x < base.length() else base[base.length() - 1]
	return linha[x] if x < linha.length() else "."


func _criar_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TAM, TAM)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)

	var fonte := TileSetAtlasSource.new()
	fonte.texture = load("res://assets/tiles/ladrilhos.png")
	fonte.texture_region_size = Vector2i(TAM, TAM)
	tileset.add_source(fonte, 0)

	for tipo in [GRAMA, TERRA, PLATAFORMA, PEDRA]:
		fonte.create_tile(Vector2i(tipo, 0))
		var dados := fonte.get_tile_data(Vector2i(tipo, 0), 0)
		dados.add_collision_polygon(0)
		var e_plataforma: bool = tipo == PLATAFORMA
		dados.set_collision_polygon_points(0, 0, _retangulo_colisao(ALTURA_PRANCHA if e_plataforma else TAM))
		dados.set_collision_polygon_one_way(0, 0, e_plataforma)
	return tileset


## Retângulo de colisão do topo do ladrilho até `altura` px para baixo.
func _retangulo_colisao(altura: float) -> PackedVector2Array:
	var meio := TAM / 2.0
	return PackedVector2Array([
		Vector2(-meio, -meio), Vector2(meio, -meio),
		Vector2(meio, -meio + altura), Vector2(-meio, -meio + altura)])
