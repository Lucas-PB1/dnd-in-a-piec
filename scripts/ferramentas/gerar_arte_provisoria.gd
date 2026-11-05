extends SceneTree
## Gera a arte provisória (pixel art) do projeto e salva em assets/sprites/.
## Rodar: godot --headless --path . --script res://scripts/ferramentas/gerar_arte_provisoria.gd
## Depois rode "godot --headless --path . --import" para o Godot importar os PNGs.

const PASTA := "res://assets/sprites/"

# Tamanho de cada quadro do boneco (16 px = 1 metro no jogo)
const LARGURA_QUADRO := 16
const ALTURA_QUADRO := 24

# Paleta
const CONTORNO := Color8(34, 28, 40)
const PELE := Color8(242, 194, 150)
const CABELO := Color8(110, 62, 34)
const CAMISA := Color8(52, 110, 196)
const CAMISA_ESCURA := Color8(36, 78, 150)
const CALCA := Color8(84, 64, 52)
const SAPATO := Color8(46, 36, 34)
const OLHO := Color8(30, 24, 36)


func _initialize() -> void:
	_gerar_jogador()
	_gerar_grama()
	_gerar_tufo()
	_gerar_sombra()
	print("Arte provisória gerada em ", PASTA)
	quit()


# --- Boneco -----------------------------------------------------------------

## Folha com 6 quadros lado a lado: 0-1 = idle, 2-5 = walk.
func _gerar_jogador() -> void:
	var img := Image.create(LARGURA_QUADRO * 6, ALTURA_QUADRO, false, Image.FORMAT_RGBA8)
	# idle: respiração (o corpo desce 1 px no segundo quadro)
	_desenhar_boneco(img, 0, 0, 0, 0)
	_desenhar_boneco(img, 1, 1, 0, 0)
	# walk: pernas alternando, com um leve sobe-e-desce
	_desenhar_boneco(img, 2, 0, -1, 1)
	_desenhar_boneco(img, 3, -1, 0, 0)
	_desenhar_boneco(img, 4, 0, 1, -1)
	_desenhar_boneco(img, 5, -1, 0, 0)
	for i in 6:
		_contornar(img, Rect2i(i * LARGURA_QUADRO, 0, LARGURA_QUADRO, ALTURA_QUADRO))
	img.save_png(PASTA + "jogador.png")


## Desenha um boneco de perfil virado para a DIREITA (o jogo espelha para a esquerda).
## bob = deslocamento vertical do corpo; perna_tras/perna_frente = deslocamento horizontal das pernas.
func _desenhar_boneco(img: Image, quadro: int, bob: int, perna_tras: int, perna_frente: int) -> void:
	var ox := quadro * LARGURA_QUADRO
	var y := 2 + bob  # topo da cabeça (deixa 1 px livre para o contorno)
	# Pernas (não sobem e descem junto com o corpo)
	img.fill_rect(Rect2i(ox + 5 + perna_tras, 17, 3, 5), CALCA)
	img.fill_rect(Rect2i(ox + 8 + perna_frente, 17, 3, 5), CALCA)
	img.fill_rect(Rect2i(ox + 5 + perna_tras, 22, 3, 1), SAPATO)
	img.fill_rect(Rect2i(ox + 8 + perna_frente, 22, 4, 1), SAPATO)
	# Corpo
	img.fill_rect(Rect2i(ox + 4, y + 9, 8, 7), CAMISA)
	img.fill_rect(Rect2i(ox + 7, y + 10, 2, 4), CAMISA_ESCURA)  # braço
	img.fill_rect(Rect2i(ox + 7, y + 14, 2, 1), PELE)  # mão
	# Cabeça
	img.fill_rect(Rect2i(ox + 4, y + 2, 8, 7), PELE)
	img.fill_rect(Rect2i(ox + 3, y + 1, 9, 3), CABELO)
	img.fill_rect(Rect2i(ox + 3, y + 4, 2, 3), CABELO)  # nuca
	img.set_pixel(ox + 10, y + 5, OLHO)


## Coloca um contorno escuro de 1 px em volta dos pixels opacos dentro do retângulo.
func _contornar(img: Image, area: Rect2i) -> void:
	var bordas: Array[Vector2i] = []
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var v: Vector2i = Vector2i(x, y) + d
				if area.has_point(v) and img.get_pixelv(v).a > 0.0 and img.get_pixelv(v) != CONTORNO:
					bordas.append(Vector2i(x, y))
					break
	for p in bordas:
		img.set_pixelv(p, CONTORNO)


# --- Cenário ----------------------------------------------------------------

## Ladrilho de grama 16x16 que se repete sem emenda.
func _gerar_grama() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color8(86, 160, 72))
	for i in 40:
		var cor := Color8(70, 140, 60) if rng.randf() < 0.6 else Color8(108, 184, 84)
		img.set_pixel(rng.randi_range(0, 15), rng.randi_range(0, 15), cor)
	# Folhinhas em forma de "v"
	for i in 5:
		var x := rng.randi_range(1, 14)
		var y := rng.randi_range(1, 14)
		img.set_pixel(x - 1, y - 1, Color8(124, 196, 96))
		img.set_pixel(x + 1, y - 1, Color8(124, 196, 96))
		img.set_pixel(x, y, Color8(62, 126, 54))
	img.save_png(PASTA + "grama.png")


## Tufo de grama alta, em pé no chão.
func _gerar_tufo() -> void:
	var img := Image.create(10, 8, false, Image.FORMAT_RGBA8)
	var claro := Color8(124, 196, 96)
	var escuro := Color8(62, 126, 54)
	# Cada folha: coluna x, altura
	for folha in [[1, 4], [3, 7], [4, 5], [6, 8], [8, 5]]:
		var x: int = folha[0]
		var altura: int = folha[1]
		for y in range(8 - altura, 8):
			img.set_pixel(x, y, claro if y < 8 - altura + 2 else escuro)
	img.save_png(PASTA + "tufo_grama.png")


## Sombra oval semitransparente para ficar deitada no chão.
func _gerar_sombra() -> void:
	var img := Image.create(14, 8, false, Image.FORMAT_RGBA8)
	var centro := Vector2(6.5, 3.5)
	for y in 8:
		for x in 14:
			var d := Vector2((x - centro.x) / 7.0, (y - centro.y) / 4.0)
			if d.length() <= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0.35))
	img.save_png(PASTA + "sombra.png")
