extends SceneTree
## Gera a arte provisória (pixel art): ladrilhos, espada, arco de corte e boneco de treino.
## Rodar: godot --headless --path . --script res://tools/gerar_arte_provisoria.gd
## Depois rode "godot --headless --path . --import" (e gerar_fase_teste.gd se mudou ladrilhos).

const TAM := 32  # tamanho do ladrilho em pixels

# Ordem dos ladrilhos na imagem (coluna no atlas). gerar_fase_teste.gd usa os mesmos índices.
enum { GRAMA, TERRA, PLATAFORMA, PEDRA }

const CONTORNO := Color8(34, 28, 40)

const ARQ_LADRILHOS := "res://assets/tiles/ladrilhos.png"
const ARQ_ESPADA := "res://assets/armas/espada_curta.png"
const ARQ_CORTE := "res://assets/efeitos/corte.png"
const ARQ_BONECO := "res://features/boneco_treino/boneco_treino.png"

## Arco de corte: quadros quadrados lado a lado.
const TAM_CORTE := 48
const QUADROS_CORTE := 4


func _initialize() -> void:
	_gerar_ladrilhos()
	_gerar_espada()
	_gerar_corte()
	_gerar_boneco()
	print("Arte provisória gerada.")
	quit()


func _gerar_ladrilhos() -> void:
	var img := Image.create(TAM * 4, TAM, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_terra(img, TERRA, rng)
	_terra(img, GRAMA, rng)
	_grama_no_topo(img, GRAMA, rng)
	_plataforma(img, PLATAFORMA)
	_pedra(img, PEDRA, rng)
	img.save_png(ARQ_LADRILHOS)


# --- Espada, corte e boneco ----------------------------------------------------

## Espada curta apontando para a direita; o cabo começa em x = 0.
func _gerar_espada() -> void:
	var img := Image.create(32, 7, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(0, 2, 6, 3), Color8(96, 60, 36))  # cabo de couro
	img.fill_rect(Rect2i(0, 3, 6, 1), Color8(130, 84, 48))
	img.fill_rect(Rect2i(6, 0, 2, 7), Color8(214, 170, 60))  # guarda dourada
	img.fill_rect(Rect2i(8, 2, 21, 3), Color8(196, 204, 216))  # lâmina
	img.fill_rect(Rect2i(8, 2, 21, 1), Color8(236, 242, 250))  # fio brilhante
	img.fill_rect(Rect2i(29, 3, 2, 1), Color8(196, 204, 216))  # ponta
	_contornar(img, Rect2i(0, 0, 32, 7))
	_salvar(img, ARQ_ESPADA)


## Arco de corte branco (a cor vem da Arma via modulate), em QUADROS_CORTE quadros:
## o arco cresce, fica cheio e some.
func _gerar_corte() -> void:
	var img := Image.create(TAM_CORTE * QUADROS_CORTE, TAM_CORTE, false, Image.FORMAT_RGBA8)
	var faixas := [[-1.2, -0.4, 1.0], [-1.3, 0.6, 1.0], [-1.3, 1.1, 0.75], [-0.2, 1.2, 0.35]]
	for q in QUADROS_CORTE:
		var faixa: Array = faixas[q]
		_desenhar_arco(img, q * TAM_CORTE, faixa[0], faixa[1], faixa[2])
	_salvar(img, ARQ_CORTE)


## Lua crescente entre os ângulos (radianos, 0 = frente) com a transparência dada.
func _desenhar_arco(img: Image, ox: int, ang_ini: float, ang_fim: float, alfa: float) -> void:
	var centro := Vector2(TAM_CORTE * 0.3, TAM_CORTE * 0.5)
	var raio_fora := TAM_CORTE * 0.46
	for y in TAM_CORTE:
		for x in TAM_CORTE:
			var v := Vector2(x, y) - centro
			var ang := v.angle()
			if ang < ang_ini or ang > ang_fim:
				continue
			# A espessura do arco é maior no meio do ângulo (formato de lua).
			var meio := (ang - ang_ini) / maxf(ang_fim - ang_ini, 0.01)
			var espessura := 2.0 + 6.0 * sin(meio * PI)
			if v.length() <= raio_fora and v.length() >= raio_fora - espessura:
				img.set_pixel(ox + x, y, Color(1, 1, 1, alfa))


## Boneco de treino: poste de madeira com um saco de palha e um alvo vermelho.
func _gerar_boneco() -> void:
	var img := Image.create(28, 56, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(12, 20, 4, 36), Color8(110, 74, 44))  # poste
	img.fill_rect(Rect2i(4, 26, 20, 4), Color8(110, 74, 44))  # braços
	img.fill_rect(Rect2i(7, 14, 14, 26), Color8(206, 176, 96))  # saco de palha
	img.fill_rect(Rect2i(7, 22, 14, 2), Color8(150, 110, 60))  # corda
	img.fill_rect(Rect2i(9, 2, 10, 12), Color8(220, 190, 110))  # cabeça
	img.fill_rect(Rect2i(11, 28, 6, 6), Color8(200, 50, 50))  # alvo
	img.fill_rect(Rect2i(13, 30, 2, 2), Color8(250, 240, 220))
	img.fill_rect(Rect2i(6, 52, 16, 4), Color8(80, 60, 40))  # base
	_contornar(img, Rect2i(0, 0, 28, 56))
	_salvar(img, ARQ_BONECO)


func _salvar(img: Image, caminho: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(caminho.get_base_dir()))
	img.save_png(caminho)


## Contorno escuro de 1 px em volta dos pixels opacos.
func _contornar(img: Image, area: Rect2i) -> void:
	var bordas: Array[Vector2i] = []
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if img.get_pixel(x, y).a == 0.0 and _tem_vizinho_opaco(img, area, Vector2i(x, y)):
				bordas.append(Vector2i(x, y))
	for p in bordas:
		img.set_pixelv(p, CONTORNO)


func _tem_vizinho_opaco(img: Image, area: Rect2i, p: Vector2i) -> bool:
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var v: Vector2i = p + d
		if area.has_point(v) and img.get_pixelv(v).a > 0.0:
			return true
	return false


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
