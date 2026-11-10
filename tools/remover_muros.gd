extends SceneTree
## Tira o muro de pedra logo depois da porta de cada fase (sobravam 3-4 ladrilhos atrás dele, onde dava para entrar
## pulando e travar). Só as paredes das pontas ficam. Edita as cenas existentes sem regerar (o gerador apagaria o que foi
## posto à mão: marcador do chefe, loja etc.). Rode sem --headless não é preciso: godot --headless --path . --script res://tools/remover_muros.gd
## Cada fase: [arquivo, x do muro]. Os mesmos valores de "muro" em gerar_fase_teste.gd.

const MUROS := [
	["res://levels/fase_1.tscn", 36],
	["res://levels/fase_2.tscn", 40],
	["res://levels/fase_3.tscn", 44],
	["res://levels/fase_4.tscn", 43],
	["res://levels/fase_5.tscn", 45],
]
## Linhas do muro acima do chão (as do ar) e as do chão, que voltam a ser iguais às do vizinho.
const PRIMEIRA_LINHA_MURO := 4
const LINHA_ACAO := 8
const ULTIMA_LINHA := 11


func _initialize() -> void:
	for item in MUROS:
		_remover(item[0], item[1])
	quit()


func _remover(caminho: String, x: int) -> void:
	var fase: Node = (load(caminho) as PackedScene).instantiate()
	var terrenos := fase.find_children("*", "TileMapLayer", true, false)
	if terrenos.is_empty():
		push_error("sem TileMapLayer em " + caminho)
		return
	var terreno := terrenos[0] as TileMapLayer
	for y in range(PRIMEIRA_LINHA_MURO, LINHA_ACAO + 1):
		terreno.erase_cell(Vector2i(x, y))
	for y in range(LINHA_ACAO + 1, ULTIMA_LINHA + 1):
		var vizinha := Vector2i(x + 1, y)
		terreno.set_cell(Vector2i(x, y), terreno.get_cell_source_id(vizinha), terreno.get_cell_atlas_coords(vizinha),
			terreno.get_cell_alternative_tile(vizinha))
	var cena := PackedScene.new()
	cena.pack(fase)
	ResourceSaver.save(cena, caminho)
	print("Muro removido: ", caminho)
	fase.free()
