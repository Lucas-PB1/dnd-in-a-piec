extends SceneTree
## Gera o TileSet (assets/tiles/ladrilhos.tres) e a fase de teste (scenes/fases/fase_teste.tscn)
## a partir do MAPA em texto abaixo. Mude o desenho e rode de novo:
##   godot --headless --path . --script res://scripts/ferramentas/gerar_fase_teste.gd
## Cada caractere = 1 ladrilho de 32x32 px.
##   #  chão (vira grama no topo e terra embaixo, automaticamente)
##   P  bloco de pedra
##   =  plataforma de madeira (dá para atravessar por baixo e subir nela)
##   S  onde o herói começa
##   .  vazio
## Paredes de pedra são colocadas automaticamente nas duas pontas.

const TAM := 32
enum { GRAMA, TERRA, PLATAFORMA, PEDRA }  # mesma ordem do gerar_arte_provisoria.gd

const MAPA := [
	"............................................................",
	"............................................................",
	"............................................................",
	"...................................====.....................",
	"............................................................",
	"......................====...........................PP.....",
	"..............................................====...PP.....",
	".............===...........PPP.......................PP.....",
	"..S...................PP...PPP......................PPPP....",
	"######################PP...PPP.....#####.......#############",
	"######################PP..........######......##############",
	"######################PP.........#######.....###############",
]


func _initialize() -> void:
	var tileset := _criar_tileset()
	ResourceSaver.save(tileset, "res://assets/tiles/ladrilhos.tres")
	tileset = load("res://assets/tiles/ladrilhos.tres")

	var fase := Node2D.new()
	fase.name = "FaseTeste"
	var terreno := TileMapLayer.new()
	terreno.name = "Terreno"
	terreno.tile_set = tileset
	fase.add_child(terreno)
	terreno.owner = fase

	var largura := 0
	for linha in MAPA:
		largura = maxi(largura, linha.length())
	var altura := MAPA.size()

	for y in altura:
		var linha: String = MAPA[y]
		for x in largura:
			var c := linha[x] if x < linha.length() else "."
			match c:
				"#":
					var acima := _char(x, y - 1)
					var tipo := TERRA if acima == "#" or acima == "P" else GRAMA
					terreno.set_cell(Vector2i(x, y), 0, Vector2i(tipo, 0))
				"P":
					terreno.set_cell(Vector2i(x, y), 0, Vector2i(PEDRA, 0))
				"=":
					terreno.set_cell(Vector2i(x, y), 0, Vector2i(PLATAFORMA, 0))
				"S":
					var inicio := Marker2D.new()
					inicio.name = "InicioJogador"
					# Pés do herói no chão: base do ladrilho "S"
					inicio.position = Vector2(x * TAM + TAM / 2.0, (y + 1) * TAM)
					fase.add_child(inicio)
					inicio.owner = fase

	# Paredes de pedra nas duas pontas, da altura toda (o herói não cai pelos lados)
	for y in range(-6, altura):
		terreno.set_cell(Vector2i(-1, y), 0, Vector2i(PEDRA, 0))
		terreno.set_cell(Vector2i(largura, y), 0, Vector2i(PEDRA, 0))

	var cena := PackedScene.new()
	cena.pack(fase)
	ResourceSaver.save(cena, "res://scenes/fases/fase_teste.tscn")
	print("Fase gerada: %dx%d ladrilhos -> res://scenes/fases/fase_teste.tscn" % [largura, altura])
	fase.free()
	quit()


func _char(x: int, y: int) -> String:
	if y < 0 or y >= MAPA.size():
		return "."
	var linha: String = MAPA[y]
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

	var meio := TAM / 2.0
	var quadrado := PackedVector2Array([
		Vector2(-meio, -meio), Vector2(meio, -meio), Vector2(meio, meio), Vector2(-meio, meio)])
	# A prancha só tem 10 px de altura no topo do ladrilho
	var prancha := PackedVector2Array([
		Vector2(-meio, -meio), Vector2(meio, -meio), Vector2(meio, -meio + 10), Vector2(-meio, -meio + 10)])

	for tipo in [GRAMA, TERRA, PLATAFORMA, PEDRA]:
		fonte.create_tile(Vector2i(tipo, 0))
		var dados := fonte.get_tile_data(Vector2i(tipo, 0), 0)
		dados.add_collision_polygon(0)
		if tipo == PLATAFORMA:
			dados.set_collision_polygon_points(0, 0, prancha)
			dados.set_collision_polygon_one_way(0, 0, true)
		else:
			dados.set_collision_polygon_points(0, 0, quadrado)
	return tileset
