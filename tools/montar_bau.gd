extends SceneTree
## Monta o SpriteFrames do baú a partir da folha CC0 do r0ar (8 quadros 35×35).
##   godot --headless --path . --script res://tools/montar_bau.gd
## Depois: godot --headless --path . --import

const FOLHA := "res://features/bau/sprites/bau_abrindo.png"
const ARQ_FRAMES := "res://features/bau/sprites/bau_frames.tres"
const LADO := 35
const COLUNAS := 4
const QUADROS := 8
## Último quadro "cheio" (antes do vazio): tampa aberta com ouro.
const QUADRO_ABERTO := 6


func _initialize() -> void:
	var atlas: Texture2D = load(FOLHA)
	var frames := SpriteFrames.new()
	_add(frames, &"fechado", atlas, [0], true, 1.0)
	_add(frames, &"abrir", atlas, range(QUADRO_ABERTO + 1), false, 12.0)
	_add(frames, &"aberto", atlas, [QUADRO_ABERTO], true, 1.0)
	_add(frames, &"fechar", atlas, _reverso(range(QUADRO_ABERTO + 1)), false, 14.0)
	ResourceSaver.save(frames, ARQ_FRAMES)
	print("Baú: frames montados em %s" % ARQ_FRAMES)
	quit()


func _add(frames: SpriteFrames, nome: StringName, atlas: Texture2D, indices: Array, loop: bool, velocidade: float) -> void:
	if frames.has_animation(nome):
		frames.remove_animation(nome)
	frames.add_animation(nome)
	frames.set_animation_loop(nome, loop)
	frames.set_animation_speed(nome, velocidade)
	for i in indices:
		var pedaco := AtlasTexture.new()
		pedaco.atlas = atlas
		pedaco.region = _regiao(int(i))
		frames.add_frame(nome, pedaco)


func _regiao(indice: int) -> Rect2:
	var col := indice % COLUNAS
	var lin := indice / COLUNAS
	return Rect2(col * LADO, lin * LADO, LADO, LADO)


func _reverso(indices: Array) -> Array:
	var copia: Array = indices.duplicate()
	copia.reverse()
	return copia
