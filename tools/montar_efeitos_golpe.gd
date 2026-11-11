extends SceneTree
## Monta as tiras de efeito de golpe a partir do Particle Pack do Kenney (CC0).
## Fundo preto → branco com alfa = max(R,G,B)^0,55 (glow legível em 64 px).
##   godot --headless --path . --script res://tools/montar_efeitos_golpe.gd
## Depois: godot --headless --path . --import

const FONTE := "res://assets/efeitos/fonte_kenney_particle/"
const ARQ_CORTE := "res://assets/efeitos/corte.png"
const ARQ_RASTRO := "res://assets/efeitos/rastro.png"
const ARQ_IMPACTO := "res://assets/efeitos/impacto.png"
const ARQ_FRAMES := "res://assets/efeitos/efeitos_golpe.tres"

const QUADROS := 4
const TAM_CORTE := 64
const TAM_RASTRO := Vector2i(64, 20)
const TAM_IMPACTO := 48
const LIMIAR_CONTEUDO := 12.0 / 255.0
const EXPOENTE_ALFA := 0.55


func _initialize() -> void:
	_montar_corte()
	_montar_rastro()
	_montar_impacto()
	_gravar_frames()
	print("Efeitos de golpe montados (Kenney Particle Pack).")
	quit()


func _montar_corte() -> void:
	var tira := Image.create(TAM_CORTE * QUADROS, TAM_CORTE, false, Image.FORMAT_RGBA8)
	for q in QUADROS:
		var fonte := _carregar_branco_alfa("slash_%02d.png" % (q + 1))
		_encaixar(tira, fonte, q * TAM_CORTE, 0, TAM_CORTE, TAM_CORTE)
	tira.save_png(ProjectSettings.globalize_path(ARQ_CORTE))


func _montar_rastro() -> void:
	var tira := Image.create(TAM_RASTRO.x * QUADROS, TAM_RASTRO.y, false, Image.FORMAT_RGBA8)
	for q in QUADROS:
		var fonte := _carregar_branco_alfa("trace_%02d.png" % (q + 1))
		fonte.rotate_90(CLOCKWISE)
		_encaixar(tira, fonte, q * TAM_RASTRO.x, 0, TAM_RASTRO.x, TAM_RASTRO.y)
	tira.save_png(ProjectSettings.globalize_path(ARQ_RASTRO))


func _montar_impacto() -> void:
	var tira := Image.create(TAM_IMPACTO * QUADROS, TAM_IMPACTO, false, Image.FORMAT_RGBA8)
	for q in QUADROS:
		var fonte := _carregar_branco_alfa("circle_%02d.png" % (q + 1))
		_encaixar(tira, fonte, q * TAM_IMPACTO, 0, TAM_IMPACTO, TAM_IMPACTO)
	tira.save_png(ProjectSettings.globalize_path(ARQ_IMPACTO))


func _carregar_branco_alfa(nome: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(FONTE + nome))
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var luma: float = maxf(c.r, maxf(c.g, c.b))
			img.set_pixel(x, y, Color(1, 1, 1, pow(luma, EXPOENTE_ALFA)))
	return img


func _encaixar(destino: Image, fonte: Image, ox: int, oy: int, largura: int, altura: int) -> void:
	var caixa := _caixa_do_conteudo(fonte)
	if caixa.size.x < 1 or caixa.size.y < 1:
		push_warning("Sem conteúdo em enfeite na célula %d" % ox)
		return
	var recorte := fonte.get_region(caixa)
	var escala := minf(float(largura) * 0.92 / float(recorte.get_width()), float(altura) * 0.92 / float(recorte.get_height()))
	var nw := maxi(1, int(round(recorte.get_width() * escala)))
	var nh := maxi(1, int(round(recorte.get_height() * escala)))
	recorte.resize(nw, nh, Image.INTERPOLATE_TRILINEAR)
	var dx := ox + (largura - nw) / 2
	var dy := oy + (altura - nh) / 2
	destino.blit_rect(recorte, Rect2i(Vector2i.ZERO, Vector2i(nw, nh)), Vector2i(dx, dy))


func _caixa_do_conteudo(img: Image) -> Rect2i:
	var min_x := img.get_width()
	var min_y := img.get_height()
	var max_x := -1
	var max_y := -1
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a >= LIMIAR_CONTEUDO:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _gravar_frames() -> void:
	var frames := SpriteFrames.new()
	_add_anim(frames, &"corte", ARQ_CORTE, TAM_CORTE, TAM_CORTE, 28.0)
	_add_anim(frames, &"rastro", ARQ_RASTRO, TAM_RASTRO.x, TAM_RASTRO.y, 20.0)
	_add_anim(frames, &"impacto", ARQ_IMPACTO, TAM_IMPACTO, TAM_IMPACTO, 24.0)
	ResourceSaver.save(frames, ARQ_FRAMES)


func _add_anim(frames: SpriteFrames, nome: StringName, caminho: String, lar: int, alt: int, velocidade: float) -> void:
	if frames.has_animation(nome):
		frames.remove_animation(nome)
	frames.add_animation(nome)
	frames.set_animation_loop(nome, false)
	frames.set_animation_speed(nome, velocidade)
	var atlas: Texture2D = load(caminho)
	for q in QUADROS:
		var pedaco := AtlasTexture.new()
		pedaco.atlas = atlas
		pedaco.region = Rect2(q * lar, 0, lar, alt)
		frames.add_frame(nome, pedaco)
