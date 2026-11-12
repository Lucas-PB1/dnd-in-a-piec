extends SceneTree
## Monta o ícone do jogo (128×128): escudo + espada Idylwild (CC0), fundo escuro, escala Nearest.
##   godot --headless --path . --script res://tools/montar_icone.gd

const TAM := 128
const ARQ_SAIDA := "res://icon.png"
const ARQ_ESCUDO := "res://assets/armaduras/fonte_idylwild/wooden_buckler.png"
const ARQ_ESPADA := "res://assets/armas/espada_grande.png"
const COR_FUNDO := Color(0.10, 0.14, 0.12, 1.0)
const TOLERANCIA_FUNDO := 0.08
## Escudo ampliado (px) e canto superior-esquerdo no canvas.
const ESCUDO_LADO := 88
const ESCUDO_XY := Vector2i(20, 22)
## Espada ampliada (px) e canto; fica por cima do escudo.
const ESPADA_LADO := 108
const ESPADA_XY := Vector2i(10, 6)


func _initialize() -> void:
	var saida := Image.create(TAM, TAM, false, Image.FORMAT_RGBA8)
	saida.fill(COR_FUNDO)
	_colar(saida, _preparar(ARQ_ESCUDO, ESCUDO_LADO), ESCUDO_XY)
	_colar(saida, _preparar(ARQ_ESPADA, ESPADA_LADO), ESPADA_XY)
	var caminho := ProjectSettings.globalize_path(ARQ_SAIDA)
	saida.save_png(caminho)
	print("Ícone gerado: %s (%dx%d)" % [ARQ_SAIDA, TAM, TAM])
	quit()


func _preparar(caminho: String, lado: int) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(caminho))
	FerramentasPixel.tirar_fundo(img, TOLERANCIA_FUNDO)
	FerramentasPixel.endurecer_alfa(img)
	img.resize(lado, lado, Image.INTERPOLATE_NEAREST)
	return img


func _colar(destino: Image, pedaco: Image, canto: Vector2i) -> void:
	for y in pedaco.get_height():
		for x in pedaco.get_width():
			var cor := pedaco.get_pixel(x, y)
			if cor.a < 0.5:
				continue
			var dx := canto.x + x
			var dy := canto.y + y
			if dx < 0 or dy < 0 or dx >= destino.get_width() or dy >= destino.get_height():
				continue
			destino.set_pixel(dx, dy, cor)
