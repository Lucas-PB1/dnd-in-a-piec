extends SceneTree
## Marca a MÃO DA FRENTE do herói em cada quadro de cada animação do heroi_frames.tres e
## salva em features/jogador/sprites/pontos_mao.tres. Também recorta essa mão numa camada
## própria (folhas *_mao.png + maos_frente_frames.tres), desenhada por cima da arma: os dedos
## ficam sobre o cabo e a arma parece segurada. (O escudo, ao contrário, cobre a mão de trás.) Rodar depois de trocar a arte do herói:
##   godot --headless --path . --script res://tools/marcar_pontos_mao.gd -- [revisao.png]
## Com o argumento, salva também uma folha ampliada com os pontos marcados, para conferir.
##
## Como acha a mão: pixels cor de pele abaixo do queixo, agrupados em manchas; a mão da
## frente é a mancha mais à direita (o herói olha para a direita na arte). Se num quadro
## ela some atrás do corpo, usa a média dos quadros vizinhos.

const FRAMES := "res://features/jogador/sprites/heroi_frames.tres"
const DESTINO := "res://features/jogador/sprites/pontos_mao.tres"
## Camada só com a mão da frente: as folhas do herói com o resto apagado.
const DESTINO_FRAMES_MAO := "res://features/jogador/sprites/maos_frente_frames.tres"
const SUFIXO_MAO := "_mao"
## Em volta da mão entram também os pixels escuros (o contorno), para a mão ter borda.
const LUZ_CONTORNO := 0.35
const VIZINHOS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
	Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]
## Tamanho do quadro do herói e onde ficam os pés (centro de baixo).
const TAMANHO_QUADRO := 80
const PES := Vector2(40, 80)
## Abaixo desta linha (y no quadro) começam as mãos; acima é rosto/queixo.
const Y_MINIMO_MAO := 48
## Região do queixo, que tem a mesma cor de pele.
const QUEIXO := Rect2i(38, 46, 11, 5)
## A mão da frente fica à direita desta coluna.
const X_MINIMO_FRENTE := 45
## Mancha menor que isto é sujeira, não mão.
const PIXELS_MINIMOS := 3
## Ângulos de descanso da arma por animação (graus; + = ponta para baixo e para a frente).
## A mão fica ~18 px acima dos pés e a lâmina tem ~30 px: acima de ~35° a ponta entra no chão.
const ANGULOS := {
	&"idle": 35.0, &"walk": 35.0, &"correr": 25.0, &"pulo_subindo": 20.0,
	&"pulo_topo": 30.0, &"pulo_caindo": 40.0, &"aterrissar": 35.0, &"ataque": 35.0,
}
const ESCALA_REVISAO := 4


func _initialize() -> void:
	var frames: SpriteFrames = load(FRAMES)
	var resultado := PontosMao.new()
	for animacao in frames.get_animation_names():
		resultado.pontos[animacao] = _pontos_da_animacao(frames, animacao, true)
		resultado.pontos_de_tras[animacao] = _pontos_da_animacao(frames, animacao, false)
		resultado.angulos[animacao] = ANGULOS.get(animacao, PontosMao.ANGULO_PADRAO)
	ResourceSaver.save(resultado, DESTINO)
	print("Pontos da mão salvos em ", DESTINO)
	_salvar_camada_da_mao(frames)
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_salvar_revisao(frames, resultado, args[0])
	quit()


## Pontos da mão da frente (`da_frente`) ou de trás em cada quadro da animação.
func _pontos_da_animacao(frames: SpriteFrames, animacao: StringName, da_frente: bool) -> PackedVector2Array:
	var achados: Array = []  # Vector2 ou null (não achou)
	for i in frames.get_frame_count(animacao):
		achados.append(_achar_mao(_imagem_do_quadro(frames, animacao, i), da_frente))
	return _preencher_buracos(achados)


func _imagem_do_quadro(frames: SpriteFrames, animacao: StringName, i: int) -> Image:
	var atlas := frames.get_frame_texture(animacao, i) as AtlasTexture
	return atlas.atlas.get_image().get_region(Rect2i(atlas.region))


## Centro da mancha de pele da mão (relativo aos pés), ou null se ela não aparece.
func _achar_mao(img: Image, da_frente: bool) -> Variant:
	var mancha := _mancha_da_mao(img, da_frente)
	return null if mancha.is_empty() else (_centro(mancha) - PES).round()


## Pixels da mancha de pele da mão. Mão da frente = a mais à direita depois de
## X_MINIMO_FRENTE; mão de trás = a mais à esquerda antes dele. Vazio = não aparece.
func _mancha_da_mao(img: Image, da_frente: bool) -> Array[Vector2i]:
	var melhor: Array[Vector2i] = []
	var melhor_x := -INF if da_frente else INF
	for mancha in _manchas_de_pele(img):
		if mancha.size() < PIXELS_MINIMOS:
			continue
		var x := _centro(mancha).x
		var do_lado_certo := x > X_MINIMO_FRENTE if da_frente else x <= X_MINIMO_FRENTE
		var mais_na_ponta := x > melhor_x if da_frente else x < melhor_x
		if do_lado_certo and mais_na_ponta:
			melhor = mancha
			melhor_x = x
	return melhor


func _manchas_de_pele(img: Image) -> Array[Array]:
	var visitado := {}
	var manchas: Array[Array] = []
	for y in range(Y_MINIMO_MAO, TAMANHO_QUADRO):
		for x in TAMANHO_QUADRO:
			var p := Vector2i(x, y)
			if not visitado.has(p) and _e_pele(img, p):
				manchas.append(_inundar(img, p, visitado))
	return manchas


## Junta todos os pixels de pele encostados em `inicio` (busca em largura).
func _inundar(img: Image, inicio: Vector2i, visitado: Dictionary) -> Array[Vector2i]:
	var mancha: Array[Vector2i] = []
	var fila: Array[Vector2i] = [inicio]
	visitado[inicio] = true
	while not fila.is_empty():
		var p: Vector2i = fila.pop_back()
		mancha.append(p)
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var v: Vector2i = p + d
			if v.y >= Y_MINIMO_MAO and v.x >= 0 and v.x < TAMANHO_QUADRO and v.y < TAMANHO_QUADRO \
					and not visitado.has(v) and _e_pele(img, v):
				visitado[v] = true
				fila.append(v)
	return mancha


func _e_pele(img: Image, p: Vector2i) -> bool:
	if QUEIXO.has_point(p):
		return false
	var c := img.get_pixelv(p)
	var r := c.r8
	var g := c.g8
	var b := c.b8
	return c.a > 0.5 and r > 200 and g > 130 and g < 215 and b > 95 and b < 175 and r - b > 60


func _centro(mancha: Array) -> Vector2:
	var soma := Vector2.ZERO
	for p in mancha:
		soma += Vector2(p)
	return soma / mancha.size()


## Quadros sem mão achada recebem a média dos vizinhos (a animação dá a volta).
func _preencher_buracos(achados: Array) -> PackedVector2Array:
	var saida := PackedVector2Array()
	var n := achados.size()
	for i in n:
		if achados[i] != null:
			saida.append(achados[i])
			continue
		var antes: Variant = _vizinho_achado(achados, i, -1)
		var depois: Variant = _vizinho_achado(achados, i, 1)
		if antes == null:
			saida.append(Vector2.ZERO)
		else:
			saida.append(((antes + depois) / 2.0).round())
	return saida


func _vizinho_achado(achados: Array, i: int, passo: int) -> Variant:
	for k in range(1, achados.size()):
		var v: Variant = achados[posmod(i + passo * k, achados.size())]
		if v != null:
			return v
	return null


## Copia as folhas do herói deixando só a mão da frente (e o contorno dela) e escreve a
## SpriteFrames gêmea: o mesmo heroi_frames.tres apontando para as folhas *_mao.png.
func _salvar_camada_da_mao(frames: SpriteFrames) -> void:
	var folhas := {}  # caminho da folha do herói -> Image só com as mãos
	for animacao in frames.get_animation_names():
		for i in frames.get_frame_count(animacao):
			var atlas := frames.get_frame_texture(animacao, i) as AtlasTexture
			var caminho := atlas.atlas.resource_path
			if not folhas.has(caminho):
				folhas[caminho] = Image.create(atlas.atlas.get_width(), atlas.atlas.get_height(), false, Image.FORMAT_RGBA8)
			var quadro := _imagem_do_quadro(frames, animacao, i)
			for p in _pixels_da_mao(quadro):
				(folhas[caminho] as Image).set_pixelv(Vector2i(atlas.region.position) + p, quadro.get_pixelv(p))
	for caminho: String in folhas:
		(folhas[caminho] as Image).save_png(ProjectSettings.globalize_path(_caminho_da_mao(caminho)))
	var texto := FileAccess.get_file_as_string(FRAMES)
	# Sem os uid: senão o Godot acharia as folhas ORIGINAIS pelo uid (e o recurso duplicaria o uid).
	texto = RegEx.create_from_string(" uid=\"uid://[a-z0-9]+\"").sub(texto, "", true)
	for caminho: String in folhas:
		texto = texto.replace(caminho, _caminho_da_mao(caminho))
	var arquivo := FileAccess.open(DESTINO_FRAMES_MAO, FileAccess.WRITE)
	arquivo.store_string(texto)
	print("Camada da mão salva em ", DESTINO_FRAMES_MAO)


func _caminho_da_mao(caminho: String) -> String:
	return caminho.get_basename() + SUFIXO_MAO + ".png"


## A mancha da mão da frente mais o contorno escuro encostado nela.
func _pixels_da_mao(img: Image) -> Array[Vector2i]:
	var mao := _mancha_da_mao(img, true)
	var com_borda: Array[Vector2i] = mao.duplicate()
	for p in mao:
		for d in VIZINHOS:
			var v := p + d
			if Rect2i(Vector2i.ZERO, img.get_size()).has_point(v) and v not in com_borda:
				var cor := img.get_pixelv(v)
				if cor.a > 0.5 and cor.get_luminance() < LUZ_CONTORNO:
					com_borda.append(v)
	return com_borda

## Folha ampliada com cada quadro e um X vermelho na mão, para revisar.
func _salvar_revisao(frames: SpriteFrames, resultado: PontosMao, caminho: String) -> void:
	var nomes := frames.get_animation_names()
	var colunas := 0
	for animacao in nomes:
		colunas = maxi(colunas, frames.get_frame_count(animacao))
	var folha := Image.create(colunas * TAMANHO_QUADRO, nomes.size() * TAMANHO_QUADRO, false, Image.FORMAT_RGBA8)
	folha.fill(Color(0.42, 0.6, 0.84))
	for linha in nomes.size():
		var animacao: StringName = nomes[linha]
		for i in frames.get_frame_count(animacao):
			var origem := Vector2i(i * TAMANHO_QUADRO, linha * TAMANHO_QUADRO)
			folha.blend_rect(_imagem_do_quadro(frames, animacao, i), Rect2i(0, 0, TAMANHO_QUADRO, TAMANHO_QUADRO), origem)
			_marcar_x(folha, Vector2i(resultado.ponto(animacao, i) + PES) + origem, Color.RED)
			_marcar_x(folha, Vector2i(resultado.ponto_de_tras(animacao, i) + PES) + origem, Color.CYAN)
	folha.resize(folha.get_width() * ESCALA_REVISAO, folha.get_height() * ESCALA_REVISAO, Image.INTERPOLATE_NEAREST)
	folha.save_png(caminho)
	print("Revisão salva em ", caminho, " (linhas: ", ", ".join(nomes), "; vermelho = frente, ciano = trás)")


func _marcar_x(folha: Image, centro: Vector2i, cor: Color) -> void:
	for d in [-2, -1, 0, 1, 2]:
		folha.set_pixelv(centro + Vector2i(d, d), cor)
		folha.set_pixelv(centro + Vector2i(d, -d), cor)
