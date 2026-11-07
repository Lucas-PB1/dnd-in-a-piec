extends SceneTree
## Gera a arte provisória (pixel art): ladrilhos, efeitos de golpe (arco, rastro, impacto) e boneco de treino.
## Rodar: godot --headless --path . --script res://tools/gerar_arte_provisoria.gd
## Depois rode "godot --headless --path . --import" (e gerar_fase_teste.gd se mudou ladrilhos).

const TAM := 32  # tamanho do ladrilho em pixels

# Ordem dos ladrilhos na imagem (coluna no atlas). gerar_fase_teste.gd usa os mesmos índices.
enum { GRAMA, TERRA, PLATAFORMA, PEDRA }

const CONTORNO := Color8(34, 28, 40)

const ARQ_LADRILHOS := "res://assets/tiles/ladrilhos.png"
const ARQ_CORTE := "res://assets/efeitos/corte.png"
const ARQ_RASTRO := "res://assets/efeitos/rastro.png"
const ARQ_IMPACTO := "res://assets/efeitos/impacto.png"
const ARQ_CONDICOES := "res://assets/efeitos/condicoes.png"
const ARQ_BONECO := "res://features/boneco_treino/boneco_treino.png"
const ARQ_BAU := "res://features/bau/bau.png"

## Arco de corte: quadros quadrados lado a lado.
const TAM_CORTE := 48
const QUADROS_CORTE := 4
## Rastro da estocada: quadros compridos (da mão até a ponta).
const TAM_RASTRO := Vector2i(48, 12)
## Impacto dos contundentes: quadros quadrados.
const TAM_IMPACTO := 32
const QUADROS_EFEITO := 4


func _initialize() -> void:
	_gerar_ladrilhos()
	_gerar_corte()
	_gerar_rastro()
	_gerar_impacto()
	_gerar_condicoes()
	_gerar_boneco()
	_gerar_bau()
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
]


func _gerar_ladrilhos() -> void:
	var img := Image.create(TAM * 4, TAM * PALETAS.size(), false, Image.FORMAT_RGBA8)
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


## Ladrilhos recortados dos pacotes CC0 do ansimuz (assets/fundos/), uma linha por ambiente, na
## mesma ordem de FundoParalaxe.AMBIENTES e pintados com o mesmo tom. Os recortes são de 32x32
## (a plataforma, de 32x16) e ficam numa lista na ordem do enum: GRAMA, TERRA, PLATAFORMA, PEDRA.
const ALTURA_PLATAFORMA := 16
const PACOTES_LADRILHO := {
	&"floresta": {
		"arquivo": "res://assets/fundos/floresta/tiles.png",
		"recortes": [Vector2i(16, 12), Vector2i(48, 36), Vector2i(96, 12), Vector2i(16, 40)],
	},
	&"fortaleza": {
		"arquivo": "res://assets/fundos/fortaleza/tileset.png",
		"recortes": [Vector2i(48, 48), Vector2i(48, 80), Vector2i(0, 16), Vector2i(0, 48)],
	},
}


func _ladrilhos_do_pacote(img: Image) -> void:
	var ambientes := FundoParalaxe.AMBIENTES.keys()
	for linha in mini(ambientes.size(), PALETAS.size()):
		var dados: Array = FundoParalaxe.AMBIENTES[ambientes[linha]]
		var pacote: Dictionary = PACOTES_LADRILHO[dados[0]]
		var fonte := Image.load_from_file(ProjectSettings.globalize_path(pacote["arquivo"]))
		fonte.convert(Image.FORMAT_RGBA8)
		for tipo in [GRAMA, TERRA, PLATAFORMA, PEDRA]:
			var altura := ALTURA_PLATAFORMA if tipo == PLATAFORMA else TAM
			var origem: Vector2i = pacote["recortes"][tipo]
			var bloco := fonte.get_region(Rect2i(origem, Vector2i(TAM, altura)))
			_pintar(bloco, dados[1])
			var destino := Vector2i(tipo * TAM, linha * TAM)
			img.fill_rect(Rect2i(destino, Vector2i(TAM, TAM)), Color(0, 0, 0, 0))
			img.blit_rect(bloco, Rect2i(Vector2i.ZERO, bloco.get_size()), destino)


## Multiplica a cor de cada pixel pelo `tom` (a transparência não muda).
func _pintar(img: Image, tom: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var cor := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(cor.r * tom.r, cor.g * tom.g, cor.b * tom.b, cor.a))


# --- Corte e boneco ----------------------------------------------------

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


## Rastro da estocada (branco; a cor vem da Arma): linhas paralelas que correm da mão até
## a ponta, mais fortes perto da ponta, e somem.
func _gerar_rastro() -> void:
	var img := Image.create(TAM_RASTRO.x * QUADROS_EFEITO, TAM_RASTRO.y, false, Image.FORMAT_RGBA8)
	# [onde a linha começa (fração), alfa] por quadro: estica, fica cheia, recua para a ponta e some.
	var quadros := [[0.55, 1.0], [0.1, 1.0], [0.35, 0.65], [0.7, 0.3]]
	var linhas := [[3, 0.5], [6, 1.0], [9, 0.5], [5, 0.35], [7, 0.35]]  # [y, força]
	for q in QUADROS_EFEITO:
		var inicio := int(TAM_RASTRO.x * quadros[q][0])
		for linha: Array in linhas:
			for x in range(inicio, TAM_RASTRO.x):
				var perto_da_ponta := float(x - inicio) / maxf(TAM_RASTRO.x - inicio, 1.0)
				var alfa: float = quadros[q][1] * linha[1] * (0.35 + 0.65 * perto_da_ponta)
				img.set_pixel(q * TAM_RASTRO.x + x, linha[0], Color(1, 1, 1, alfa))
	_salvar(img, ARQ_RASTRO)


## Impacto dos contundentes (branco; a cor vem da Arma): clarão, anel que abre e faíscas.
func _gerar_impacto() -> void:
	var img := Image.create(TAM_IMPACTO * QUADROS_EFEITO, TAM_IMPACTO, false, Image.FORMAT_RGBA8)
	# [raio do anel, grossura, comprimento das faíscas, alfa] por quadro.
	var quadros := [[3.0, 3.0, 6.0, 1.0], [7.0, 2.0, 11.0, 1.0], [11.0, 1.5, 14.0, 0.7], [14.0, 1.0, 15.0, 0.35]]
	var centro := Vector2(TAM_IMPACTO, TAM_IMPACTO) / 2.0
	for q in QUADROS_EFEITO:
		var raio: float = quadros[q][0]
		var alfa: float = quadros[q][3]
		for y in TAM_IMPACTO:
			for x in TAM_IMPACTO:
				var d := Vector2(x + 0.5, y + 0.5).distance_to(centro)
				if absf(d - raio) <= quadros[q][1] * 0.5 or (q == 0 and d < raio):
					img.set_pixel(q * TAM_IMPACTO + x, y, Color(1, 1, 1, alfa))
		for k in 8:  # faíscas
			var direcao := Vector2.from_angle(k * TAU / 8.0 + 0.2)
			for s in range(int(raio) + 2, int(quadros[q][2])):
				if s % 2 == 0 or q < 2:
					var p := Vector2i(centro + direcao * s)
					if Rect2i(0, 0, TAM_IMPACTO, TAM_IMPACTO).has_point(p):
						img.set_pixel(q * TAM_IMPACTO + p.x, p.y, Color(1, 1, 1, alfa))
	_salvar(img, ARQ_IMPACTO)


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


## Baú de madeira com cintas e fechadura dourada, visto de lado (30x22).
func _gerar_bau() -> void:
	var img := Image.create(30, 22, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(1, 3, 28, 18), Color8(126, 82, 46))  # corpo
	img.fill_rect(Rect2i(1, 3, 28, 7), Color8(150, 100, 58))  # tampa
	img.fill_rect(Rect2i(1, 10, 28, 1), Color8(70, 44, 26))  # fresta da tampa
	for x in [5, 23]:  # cintas de metal
		img.fill_rect(Rect2i(x, 3, 2, 18), Color8(120, 124, 134))
	img.fill_rect(Rect2i(13, 8, 4, 5), Color8(214, 170, 60))  # fechadura
	img.fill_rect(Rect2i(14, 10, 2, 2), Color8(70, 44, 26))
	_contornar(img, Rect2i(0, 0, 30, 22))
	_salvar(img, ARQ_BAU)



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
