extends SceneTree
## Monta a pose de MIRA do herói (armas de disparo) juntando duas artes que já existem:
## o tronco com o braço esticado na altura do peito (um quadro do pulo) e as pernas de pé
## (o 1º quadro do parado), alinhados pela linha do cinto. Salva heroi_mirar.png (80x80).
##   godot --headless --path . --script res://tools/montar_pose_mira.gd
## Depois: --import e tools/marcar_pontos_mao.gd (pontos e camada da mão da nova pose).
## Rode de novo se a arte do herói mudar.

const PULO := "res://features/jogador/sprites/heroi_jump.png"
const PARADO := "res://features/jogador/sprites/heroi_idle.png"
const DESTINO := "res://features/jogador/sprites/heroi_mirar.png"
const TAMANHO := 80
## Quadro do pulo com o braço esticado à frente e quadro do parado com as pernas firmes.
const QUADRO_TRONCO := 5
const QUADRO_PERNAS := 0
## Onde procurar o cinto (linhas do quadro): abaixo do peito, acima das botas.
const FAIXA_CINTO := Vector2i(48, 66)
## Linhas do cinto que ficam com o tronco (o resto para baixo vem das pernas).
const SOBRA_DO_CINTO := 2


func _initialize() -> void:
	var tronco := _quadro(PULO, QUADRO_TRONCO)
	var pernas := _quadro(PARADO, QUADRO_PERNAS)
	var cinto_tronco := _cinto(tronco)
	var cinto_pernas := _cinto(pernas)
	var corte := cinto_pernas + SOBRA_DO_CINTO
	var pose := Image.create(TAMANHO, TAMANHO, false, Image.FORMAT_RGBA8)
	pose.blit_rect(pernas, Rect2i(0, corte, TAMANHO, TAMANHO - corte), Vector2i(0, corte))
	_apagar_pele(pose, corte)  # a mão do parado (na altura da coxa) não pode sobrar
	pose.blend_rect(tronco, Rect2i(0, 0, TAMANHO, cinto_tronco + SOBRA_DO_CINTO), Vector2i(0, cinto_pernas - cinto_tronco))
	pose.save_png(ProjectSettings.globalize_path(DESTINO))
	print("Pose de mira salva em ", DESTINO)
	quit()


func _quadro(caminho: String, indice: int) -> Image:
	var folha := Image.load_from_file(ProjectSettings.globalize_path(caminho))
	folha.convert(Image.FORMAT_RGBA8)
	return folha.get_region(Rect2i(indice * TAMANHO, 0, TAMANHO, TAMANHO))


## Linha com mais pixels de couro escuro (o cinto) dentro da faixa.
func _cinto(img: Image) -> int:
	var melhor := FAIXA_CINTO.x
	var total_max := 0
	for y in range(FAIXA_CINTO.x, FAIXA_CINTO.y):
		var total := 0
		for x in TAMANHO:
			if _e_couro(img.get_pixel(x, y)):
				total += 1
		if total > total_max:
			total_max = total
			melhor = y
	return melhor


func _e_couro(c: Color) -> bool:
	return c.a > 0.5 and c.r > c.g and c.g > c.b and c.r - c.b > 0.12 and c.get_luminance() < 0.35


## Apaga os pixels cor de pele abaixo da linha `de` (e o contorno escuro colado neles).
func _apagar_pele(img: Image, de: int) -> void:
	var pele: Array[Vector2i] = []
	for y in range(de, TAMANHO):
		for x in TAMANHO:
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and c.r8 > 200 and c.g8 > 130 and c.g8 < 215 and c.b8 > 95 and c.b8 < 175:
				pele.append(Vector2i(x, y))
	for p in pele:
		for d in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var v: Vector2i = p + d
			if Rect2i(0, de, TAMANHO, TAMANHO - de).has_point(v) and (d == Vector2i.ZERO or img.get_pixelv(v).get_luminance() < 0.25):
				img.set_pixelv(v, Color(0, 0, 0, 0))
