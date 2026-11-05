extends SceneTree
## Gera a arte provisória do cenário (pixel art) em assets/tiles/.
## Rodar: godot --headless --path . --script res://scripts/ferramentas/gerar_arte_provisoria.gd
## Depois rode "godot --headless --path . --import" e então gerar_fase_teste.gd.

const TAM := 32  # tamanho do ladrilho em pixels

# Ordem dos ladrilhos na imagem (coluna no atlas). gerar_fase_teste.gd usa os mesmos índices.
enum { GRAMA, TERRA, PLATAFORMA, PEDRA }

const CONTORNO := Color8(34, 28, 40)


func _initialize() -> void:
	var img := Image.create(TAM * 4, TAM, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_terra(img, TERRA, rng)
	_terra(img, GRAMA, rng)
	_grama_no_topo(img, GRAMA, rng)
	_plataforma(img, PLATAFORMA)
	_pedra(img, PEDRA, rng)
	img.save_png("res://assets/tiles/ladrilhos.png")
	print("Ladrilhos gerados em res://assets/tiles/ladrilhos.png")
	quit()


func _terra(img: Image, coluna: int, rng: RandomNumberGenerator) -> void:
	var ox := coluna * TAM
	img.fill_rect(Rect2i(ox, 0, TAM, TAM), Color8(122, 82, 54))
	# Pedrinhas e manchas
	for i in 26:
		var cor := Color8(98, 64, 44) if rng.randf() < 0.7 else Color8(146, 104, 70)
		var x := rng.randi_range(0, TAM - 2)
		var y := rng.randi_range(0, TAM - 2)
		img.fill_rect(Rect2i(ox + x, y, 2, 1 + rng.randi_range(0, 1)), cor)


func _grama_no_topo(img: Image, coluna: int, rng: RandomNumberGenerator) -> void:
	var ox := coluna * TAM
	img.fill_rect(Rect2i(ox, 0, TAM, 8), Color8(84, 168, 64))
	img.fill_rect(Rect2i(ox, 0, TAM, 2), Color8(132, 206, 92))  # brilho no topo
	# Franja irregular de grama caindo sobre a terra
	for x in TAM:
		var altura := 8 + rng.randi_range(0, 3)
		img.fill_rect(Rect2i(ox + x, 8, 1, altura - 8), Color8(84, 168, 64))
		img.set_pixel(ox + x, altura, Color8(52, 116, 48))


func _plataforma(img: Image, coluna: int) -> void:
	# Prancha de madeira fina: só os 10 px de cima (o resto é transparente)
	var ox := coluna * TAM
	img.fill_rect(Rect2i(ox, 0, TAM, 10), Color8(168, 112, 62))
	img.fill_rect(Rect2i(ox, 0, TAM, 2), Color8(206, 148, 88))
	img.fill_rect(Rect2i(ox, 8, TAM, 2), Color8(110, 70, 40))
	for x in [7, 23]:  # pregos
		img.set_pixel(ox + x, 4, Color8(60, 50, 50))
	img.fill_rect(Rect2i(ox + 15, 2, 1, 6), Color8(130, 84, 48))  # emenda da tábua


func _pedra(img: Image, coluna: int, rng: RandomNumberGenerator) -> void:
	var ox := coluna * TAM
	img.fill_rect(Rect2i(ox, 0, TAM, TAM), Color8(120, 124, 140))
	img.fill_rect(Rect2i(ox, 0, TAM, 2), Color8(160, 164, 180))
	img.fill_rect(Rect2i(ox, 0, 2, TAM), Color8(150, 154, 170))
	img.fill_rect(Rect2i(ox, TAM - 2, TAM, 2), Color8(80, 82, 98))
	img.fill_rect(Rect2i(ox + TAM - 2, 0, 2, TAM), Color8(88, 90, 106))
	for i in 10:
		img.set_pixel(ox + rng.randi_range(3, TAM - 4), rng.randi_range(3, TAM - 4), Color8(98, 100, 116))
	img.fill_rect(Rect2i(ox, 0, TAM, 1), CONTORNO)
	img.fill_rect(Rect2i(ox, TAM - 1, TAM, 1), CONTORNO)
	img.fill_rect(Rect2i(ox, 0, 1, TAM), CONTORNO)
	img.fill_rect(Rect2i(ox + TAM - 1, 0, 1, TAM), CONTORNO)
