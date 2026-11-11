extends SceneTree
## Gera a arte provisória (pixel art): ladrilhos, ícones de condição, boneco e baú.
## Efeitos de golpe vêm do Kenney (`tools/montar_efeitos_golpe.gd`), não daqui.
## Rodar: godot --headless --path . --script res://tools/gerar_arte_provisoria.gd
## Depois rode "godot --headless --path . --import" (e gerar_fase_teste.gd se mudou ladrilhos).

const TAM := 32  # tamanho do ladrilho em pixels

# Ordem dos ladrilhos na imagem (coluna no atlas). gerar_fase_teste.gd usa os mesmos índices.
enum { GRAMA, TERRA, PLATAFORMA, PEDRA }

const CONTORNO := Color8(34, 28, 40)

const ARQ_LADRILHOS := "res://assets/tiles/ladrilhos.png"
const ARQ_CONDICOES := "res://assets/efeitos/condicoes.png"
const ARQ_BONECO := "res://features/boneco_treino/boneco_treino.png"


func _initialize() -> void:
	_gerar_ladrilhos()
	_gerar_condicoes()
	_gerar_boneco()
	print("Arte provisória gerada.")
	quit()


## Uma fileira do atlas por ambiente. A ordem das colunas é o enum do topo.
const PALETAS: Array[Dictionary] = [
	{
		"terra": Color8(122, 82, 54), "terra_escura": Color8(98, 64, 44), "terra_clara": Color8(146, 104, 70),
		"grama": Color8(84, 168, 64), "grama_topo": Color8(132, 206, 92), "grama_sombra": Color8(52, 116, 48),
		"madeira": Color8(168, 112, 62), "madeira_topo": Color8(206, 148, 88), "madeira_fundo": Color8(110, 70, 40),
		"madeira_emenda": Color8(130, 84, 48), "prego": Color8(60, 50, 50),
		"pedra": Color8(120, 124, 140), "pedra_topo": Color8(160, 164, 180), "pedra_lado": Color8(150, 154, 170),
		"pedra_fundo": Color8(80, 82, 98), "pedra_lado_escuro": Color8(88, 90, 106), "pedra_mancha": Color8(98, 100, 116),
	},
	{
		"terra": Color8(140, 96, 58), "terra_escura": Color8(110, 72, 40), "terra_clara": Color8(168, 124, 74),
		"grama": Color8(150, 140, 62), "grama_topo": Color8(190, 176, 90), "grama_sombra": Color8(100, 90, 40),
		"madeira": Color8(150, 96, 52), "madeira_topo": Color8(190, 130, 74), "madeira_fundo": Color8(96, 60, 32),
		"madeira_emenda": Color8(120, 74, 40), "prego": Color8(60, 50, 50),
		"pedra": Color8(150, 130, 100), "pedra_topo": Color8(186, 166, 130), "pedra_lado": Color8(170, 150, 116),
		"pedra_fundo": Color8(100, 84, 62), "pedra_lado_escuro": Color8(110, 92, 68), "pedra_mancha": Color8(120, 100, 74),
	},
	{
		"terra": Color8(70, 78, 48), "terra_escura": Color8(48, 56, 34), "terra_clara": Color8(96, 104, 64),
		"grama": Color8(48, 110, 58), "grama_topo": Color8(80, 146, 72), "grama_sombra": Color8(28, 70, 40),
		"madeira": Color8(90, 100, 58), "madeira_topo": Color8(120, 132, 74), "madeira_fundo": Color8(54, 62, 36),
		"madeira_emenda": Color8(70, 80, 44), "prego": Color8(40, 48, 36),
		"pedra": Color8(90, 104, 90), "pedra_topo": Color8(120, 136, 116), "pedra_lado": Color8(104, 120, 100),
		"pedra_fundo": Color8(52, 64, 52), "pedra_lado_escuro": Color8(60, 72, 58), "pedra_mancha": Color8(70, 84, 66),
	},
	{
		"terra": Color8(100, 96, 104), "terra_escura": Color8(72, 68, 78), "terra_clara": Color8(128, 124, 132),
		"grama": Color8(110, 112, 100), "grama_topo": Color8(150, 150, 136), "grama_sombra": Color8(72, 74, 66),
		"madeira": Color8(120, 110, 100), "madeira_topo": Color8(156, 144, 128), "madeira_fundo": Color8(78, 70, 64),
		"madeira_emenda": Color8(96, 88, 80), "prego": Color8(50, 48, 52),
		"pedra": Color8(132, 132, 140), "pedra_topo": Color8(170, 170, 178), "pedra_lado": Color8(154, 154, 162),
		"pedra_fundo": Color8(84, 84, 94), "pedra_lado_escuro": Color8(92, 92, 102), "pedra_mancha": Color8(104, 104, 114),
	},
	{
		"terra": Color8(78, 40, 38), "terra_escura": Color8(52, 26, 26), "terra_clara": Color8(110, 58, 50),
		"grama": Color8(90, 36, 36), "grama_topo": Color8(130, 56, 48), "grama_sombra": Color8(56, 22, 24),
		"madeira": Color8(96, 52, 44), "madeira_topo": Color8(130, 74, 58), "madeira_fundo": Color8(58, 30, 28),
		"madeira_emenda": Color8(74, 40, 36), "prego": Color8(40, 28, 28),
		"pedra": Color8(70, 64, 72), "pedra_topo": Color8(100, 92, 100), "pedra_lado": Color8(86, 78, 86),
		"pedra_fundo": Color8(40, 36, 44), "pedra_lado_escuro": Color8(48, 42, 50), "pedra_mancha": Color8(58, 50, 58),
	},
	# Caverna (provisório só se o pacote falhar; a linha 5 vem do Buch).
	{
		"terra": Color8(70, 68, 78), "terra_escura": Color8(48, 46, 56), "terra_clara": Color8(96, 94, 108),
		"grama": Color8(88, 92, 104), "grama_topo": Color8(120, 124, 140), "grama_sombra": Color8(54, 56, 66),
		"madeira": Color8(90, 78, 64), "madeira_topo": Color8(120, 104, 84), "madeira_fundo": Color8(56, 48, 40),
		"madeira_emenda": Color8(70, 60, 50), "prego": Color8(40, 36, 40),
		"pedra": Color8(96, 100, 112), "pedra_topo": Color8(130, 134, 148), "pedra_lado": Color8(110, 114, 126),
		"pedra_fundo": Color8(58, 60, 70), "pedra_lado_escuro": Color8(66, 68, 78), "pedra_mancha": Color8(78, 82, 94),
	},
]


func _gerar_ladrilhos() -> void:
	var img := Image.create(TAM * COLUNAS_ATLAS, TAM * PALETAS.size(), false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for linha in PALETAS.size():
		var paleta: Dictionary = PALETAS[linha]
		_terra(img, TERRA, linha, rng, paleta)
		_terra(img, GRAMA, linha, rng, paleta)
		_grama_no_topo(img, GRAMA, linha, rng, paleta)
		_plataforma(img, PLATAFORMA, linha, paleta)
		_pedra(img, PEDRA, linha, rng, paleta)
	_ladrilhos_do_pacote(img)
	img.save_png(ARQ_LADRILHOS)


## Uma linha do atlas = um `tema` de fase (0..). Pacotes CC0; tom multiplica a cor.
## Recortes na ordem GRAMA, TERRA, PLATAFORMA, PEDRA. `celula` = lado no PNG (16 sobe 2× para 32).
const ALTURA_PLATAFORMA := 16
const ARQ_CHAO_SPRITECOOK := "res://assets/tiles/spritecook/chao_floresta.png"
const CELULAS_GRAMA_SPRITECOOK: Array[Vector2i] = [Vector2i(2, 0), Vector2i(3, 0), Vector2i(1, 0)]
const CELULAS_TERRA_SPRITECOOK: Array[Vector2i] = [Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 1), Vector2i(3, 2)]
const COLUNAS_EXTRAS_GRAMA: Array[int] = [4, 5]
const COLUNAS_EXTRAS_TERRA: Array[int] = [6, 7, 8]
const COLUNAS_ATLAS := 9
## Linha do atlas → pacote. Índices = `tema` em gerar_fase_teste.gd (0 floresta … 5 caverna).
const LINHAS_LADRILHO: Array[Dictionary] = [
	{"pacote": &"floresta", "tom": Color(1, 1, 1), "spritecook": true},
	{"pacote": &"floresta", "tom": Color(1.0, 0.82, 0.68), "spritecook": true},
	{"pacote": &"pantano", "tom": Color(1, 1, 1), "spritecook": false},
	{"pacote": &"ruina", "tom": Color(1, 1, 1), "spritecook": false},
	{"pacote": &"fortaleza", "tom": Color(1, 1, 1), "spritecook": false},
	{"pacote": &"caverna", "tom": Color(1, 1, 1), "spritecook": false},
]
const PACOTES_LADRILHO := {
	&"floresta": {
		# Plataforma = ilha flutuante (grama+rocha), não a faixa verde fina que some no fundo.
		"arquivo": "res://assets/fundos/floresta/tiles.png", "celula": 32, "plataforma_cheia": true,
		"recortes": [Vector2i(16, 12), Vector2i(48, 36), Vector2i(32, 16), Vector2i(16, 40)],
	},
	&"fortaleza": {
		"arquivo": "res://assets/fundos/fortaleza/tileset.png", "celula": 32,
		"recortes": [Vector2i(48, 48), Vector2i(48, 80), Vector2i(0, 16), Vector2i(0, 48)],
	},
	# Gothicvania Swamp (16×16 → 32): musgo, terra, prancha, rocha.
	&"pantano": {
		"arquivo": "res://assets/fundos/pantano/tileset.png", "celula": 16,
		"recortes": [Vector2i(32, 80), Vector2i(32, 32), Vector2i(128, 80), Vector2i(32, 0)],
	},
	# Gothicvania Cemetery (16×16 → 32): relva com ossos, terra, prancha, pedra.
	&"ruina": {
		"arquivo": "res://assets/fundos/ruina/tileset.png", "celula": 16,
		"recortes": [Vector2i(16, 64), Vector2i(16, 80), Vector2i(192, 64), Vector2i(256, 80)],
	},
	# Buch DB32 Cave (CC0): superfície, preenchimento, prancha, parede.
	&"caverna": {
		"arquivo": "res://assets/tiles/caverna/chao/cave_tileset.png", "celula": 32,
		"recortes": [Vector2i(0, 32), Vector2i(0, 64), Vector2i(160, 32), Vector2i(0, 128)],
	},
}


func _ladrilhos_do_pacote(img: Image) -> void:
	for linha in mini(LINHAS_LADRILHO.size(), PALETAS.size()):
		var dados: Dictionary = LINHAS_LADRILHO[linha]
		var pacote: Dictionary = PACOTES_LADRILHO[dados.pacote]
		var fonte := Image.load_from_file(ProjectSettings.globalize_path(pacote.arquivo))
		fonte.convert(Image.FORMAT_RGBA8)
		var chao: Image = _chao_spritecook() if dados.spritecook else null
		var tom: Color = dados.tom
		var celula: int = int(pacote.get("celula", TAM))
		for tipo in [GRAMA, TERRA, PLATAFORMA, PEDRA]:
			var altura := TAM
			if tipo == PLATAFORMA and not bool(pacote.get("plataforma_cheia", false)):
				altura = ALTURA_PLATAFORMA
			var bloco := _recortar_ladrilho(fonte, pacote.recortes[tipo], celula, altura)
			if chao != null and (tipo == GRAMA or tipo == TERRA):
				var celulas := CELULAS_GRAMA_SPRITECOOK if tipo == GRAMA else CELULAS_TERRA_SPRITECOOK
				bloco = chao.get_region(Rect2i(celulas[0] * TAM, Vector2i(TAM, TAM)))
			_pintar(bloco, tom)
			var destino := Vector2i(tipo * TAM, linha * TAM)
			img.fill_rect(Rect2i(destino, Vector2i(TAM, TAM)), Color(0, 0, 0, 0))
			img.blit_rect(bloco, Rect2i(Vector2i.ZERO, bloco.get_size()), destino)
		_variantes_de_sorteio(img, linha, chao, tom)


## Recorte na folha; se a célula for 16, amplia 2× (nearest) para o atlas 32.
func _recortar_ladrilho(fonte: Image, origem: Vector2i, celula: int, altura_destino: int) -> Image:
	var altura_fonte := celula / 2 if altura_destino == ALTURA_PLATAFORMA else celula
	var bloco := fonte.get_region(Rect2i(origem, Vector2i(celula, altura_fonte)))
	if celula != TAM or altura_fonte != altura_destino:
		bloco.resize(TAM, altura_destino, Image.INTERPOLATE_NEAREST)
	return bloco


## Preenche as colunas extras da linha: com o ladrilho normal (sorteio sem efeito) ou, na floresta,
## com as outras peças do SpriteCook, pintadas com o tom do ambiente.
func _variantes_de_sorteio(img: Image, linha: int, chao: Image, tom: Color) -> void:
	_preencher_extras(img, linha, GRAMA, COLUNAS_EXTRAS_GRAMA, CELULAS_GRAMA_SPRITECOOK, chao, tom)
	_preencher_extras(img, linha, TERRA, COLUNAS_EXTRAS_TERRA, CELULAS_TERRA_SPRITECOOK, chao, tom)


func _preencher_extras(img: Image, linha: int, coluna_base: int, extras: Array[int], celulas: Array[Vector2i], chao: Image, tom: Color) -> void:
	for i in extras.size():
		var destino := Vector2i(extras[i] * TAM, linha * TAM)
		var bloco: Image
		if chao == null:
			bloco = img.get_region(Rect2i(coluna_base * TAM, linha * TAM, TAM, TAM))
		else:
			bloco = chao.get_region(Rect2i(celulas[i + 1] * TAM, Vector2i(TAM, TAM)))
			_pintar(bloco, tom)
		img.blit_rect(bloco, Rect2i(Vector2i.ZERO, bloco.get_size()), destino)


func _chao_spritecook() -> Image:
	var chao := Image.load_from_file(ProjectSettings.globalize_path(ARQ_CHAO_SPRITECOOK))
	chao.convert(Image.FORMAT_RGBA8)
	return chao


## Multiplica a cor de cada pixel pelo `tom` (a transparência não muda).
func _pintar(img: Image, tom: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var cor := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(cor.r * tom.r, cor.g * tom.g, cor.b * tom.b, cor.a))


# --- Condições, boneco e baú ----------------------------------------------------

## Ícones das condições (8x8, na ordem de CondicoesComponent.ORDEM): Caído (seta para
## baixo), Lento (ampulheta), Enfraquecido (espada quebrada), Atormentado (alvo).
## "#" = cor do ícone, "o" = contorno escuro.
const ICONES_CONDICAO := [
	[Color8(250, 210, 80), ["...oo...", "...##...", "...##...", "...##...", ".o####o.", "..o##o..", "...oo...", "oooooooo"]],
	[Color8(110, 190, 255), ["o######o", ".o####o.", "..o##o..", "...oo...", "..o##o..", ".o####o.", "o######o", "........"]],
	[Color8(190, 140, 230), ["......o#", ".....o#o", "....o#o.", "........", "..o#o...", ".o#o....", "o#o.....", "oo......"]],
	[Color8(255, 90, 90), ["..####..", ".#....#.", "#..##..#", "#.#..#.#", "#.#..#.#", "#..##..#", ".#....#.", "..####.."]],
]
const TAM_ICONE_CONDICAO := 8


func _gerar_condicoes() -> void:
	var img := Image.create(TAM_ICONE_CONDICAO * ICONES_CONDICAO.size(), TAM_ICONE_CONDICAO, false, Image.FORMAT_RGBA8)
	for i in ICONES_CONDICAO.size():
		var cor: Color = ICONES_CONDICAO[i][0]
		var linhas: Array = ICONES_CONDICAO[i][1]
		for y in TAM_ICONE_CONDICAO:
			for x in TAM_ICONE_CONDICAO:
				match (linhas[y] as String)[x]:
					"#": img.set_pixel(i * TAM_ICONE_CONDICAO + x, y, cor)
					"o": img.set_pixel(i * TAM_ICONE_CONDICAO + x, y, CONTORNO)
	_salvar(img, ARQ_CONDICOES)


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


func _terra(img: Image, coluna: int, linha: int, rng: RandomNumberGenerator, paleta: Dictionary) -> void:
	var origem := _origem(coluna, linha)
	img.fill_rect(Rect2i(origem.x, origem.y, TAM, TAM), paleta.terra)
	for i in 26:
		var cor: Color = paleta.terra_escura if rng.randf() < 0.7 else paleta.terra_clara
		var x := rng.randi_range(0, TAM - 2)
		var y := rng.randi_range(0, TAM - 2)
		img.fill_rect(Rect2i(origem.x + x, origem.y + y, 2, 1 + rng.randi_range(0, 1)), cor)


func _grama_no_topo(img: Image, coluna: int, linha: int, rng: RandomNumberGenerator, paleta: Dictionary) -> void:
	var origem := _origem(coluna, linha)
	img.fill_rect(Rect2i(origem.x, origem.y, TAM, 8), paleta.grama)
	img.fill_rect(Rect2i(origem.x, origem.y, TAM, 2), paleta.grama_topo)
	for x in TAM:
		var altura := 8 + rng.randi_range(0, 3)
		img.fill_rect(Rect2i(origem.x + x, origem.y + 8, 1, altura - 8), paleta.grama)
		img.set_pixel(origem.x + x, origem.y + altura, paleta.grama_sombra)


func _plataforma(img: Image, coluna: int, linha: int, paleta: Dictionary) -> void:
	# Prancha fina: só os 10 px de cima (o resto é transparente, para atravessar por baixo).
	var origem := _origem(coluna, linha)
	img.fill_rect(Rect2i(origem.x, origem.y, TAM, 10), paleta.madeira)
	img.fill_rect(Rect2i(origem.x, origem.y, TAM, 2), paleta.madeira_topo)
	img.fill_rect(Rect2i(origem.x, origem.y + 8, TAM, 2), paleta.madeira_fundo)
	for x in [7, 23]:
		img.set_pixel(origem.x + x, origem.y + 4, paleta.prego)
	img.fill_rect(Rect2i(origem.x + 15, origem.y + 2, 1, 6), paleta.madeira_emenda)


func _pedra(img: Image, coluna: int, linha: int, rng: RandomNumberGenerator, paleta: Dictionary) -> void:
	var origem := _origem(coluna, linha)
	img.fill_rect(Rect2i(origem.x, origem.y, TAM, TAM), paleta.pedra)
	img.fill_rect(Rect2i(origem.x, origem.y, TAM, 2), paleta.pedra_topo)
	img.fill_rect(Rect2i(origem.x, origem.y, 2, TAM), paleta.pedra_lado)
	img.fill_rect(Rect2i(origem.x, origem.y + TAM - 2, TAM, 2), paleta.pedra_fundo)
	img.fill_rect(Rect2i(origem.x + TAM - 2, origem.y, 2, TAM), paleta.pedra_lado_escuro)
	for i in 10:
		img.set_pixel(origem.x + rng.randi_range(3, TAM - 4), origem.y + rng.randi_range(3, TAM - 4), paleta.pedra_mancha)
	img.fill_rect(Rect2i(origem.x, origem.y, TAM, 1), CONTORNO)
	img.fill_rect(Rect2i(origem.x, origem.y + TAM - 1, TAM, 1), CONTORNO)
	img.fill_rect(Rect2i(origem.x, origem.y, 1, TAM), CONTORNO)
	img.fill_rect(Rect2i(origem.x + TAM - 1, origem.y, 1, TAM), CONTORNO)


func _origem(coluna: int, linha: int) -> Vector2i:
	return Vector2i(coluna * TAM, linha * TAM)
