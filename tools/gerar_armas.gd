extends SceneTree
## Gera as armas de corpo a corpo e de arremesso do Player's Handbook (2024): o sprite
## provisório de cada uma (assets/armas/<id>.png) e o .tres (data/armas/<id>.tres).
##   godot --headless --path . --script res://tools/gerar_armas.gd
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/gerar_armas.gd   (2ª vez: cria os .tres)
## Para mudar uma arma, edite a TABELA e rode de novo (não edite os .tres à mão).
## Armas à distância (arcos, bestas, funda, zarabatana, armas de fogo) entram numa fatia própria.

const PASTA_DADOS := "res://data/armas/"
const PASTA_ARTE := "res://assets/armas/"
const LIVRO := "Player’s Handbook"

const S := Proficiencias.ARMA_SIMPLES
const M := Proficiencias.ARMA_MARCIAL
const C := TiposDano.CORTANTE
const P := TiposDano.PERFURANTE
const B := TiposDano.CONTUNDENTE

## Área do golpe: normal 5 pés; com Alcance (Reach) +5 pés (1 ladrilho a mais).
const ALCANCE_NORMAL := 44.0
const ALCANCE_ESTENDIDO := ALCANCE_NORMAL + 32.0
## Tempos do golpe: leve é mais rápido, pesada mais lenta (só visual; o ritmo vem da iniciativa).
const DURACAO := {"leve": 0.26, "normal": 0.32, "pesada": 0.42}
## O corte acerta entre estas frações da duração.
const FRACAO_INICIO_ACERTO := 0.2
const FRACAO_FIM_ACERTO := 0.5

## Propriedades: F acuidade, L leve, H pesada, T duas mãos, R alcance, E empilhável.
## id: [nome, nome original, categoria, dano, tipo, propriedades, versátil, arremesso "n/l",
##      maestria, peso, preço, formato, comprimento do sprite (px)]
const TABELA := {
	"clava": ["Clava", "Club", S, "1d4", B, "L", "", "", Proficiencias.LENTIDAO, "2 lb.", "1 SP", "porrete", 22],
	"adaga": ["Adaga", "Dagger", S, "1d4", P, "FL", "", "20/60", Proficiencias.CORTE_DUPLO, "1 lb.", "2 GP", "espada", 16],
	"clava_grande": ["Clava Grande", "Greatclub", S, "1d8", B, "T", "", "", Proficiencias.EMPURRAR, "10 lb.", "2 SP", "porrete", 34],
	"machadinha": ["Machadinha", "Handaxe", S, "1d6", C, "L", "", "20/60", Proficiencias.ATORMENTAR, "2 lb.", "5 GP", "machado", 20],
	"azagaia": ["Azagaia", "Javelin", S, "1d6", P, "E", "", "30/120", Proficiencias.LENTIDAO, "2 lb.", "5 SP", "lanca", 34],
	"martelo_leve": ["Martelo Leve", "Light Hammer", S, "1d4", B, "L", "", "20/60", Proficiencias.CORTE_DUPLO, "2 lb.", "2 GP", "martelo", 18],
	"maca": ["Maça", "Mace", S, "1d6", B, "", "", "", Proficiencias.ENFRAQUECER, "4 lb.", "5 GP", "maca", 24],
	"bordao": ["Bordão", "Quarterstaff", S, "1d6", B, "", "1d8", "", Proficiencias.DERRUBAR, "4 lb.", "2 SP", "cajado", 44],
	"foice": ["Foice", "Sickle", S, "1d4", C, "L", "", "", Proficiencias.CORTE_DUPLO, "2 lb.", "1 GP", "foice", 18],
	"lanca": ["Lança", "Spear", S, "1d6", P, "", "1d8", "20/60", Proficiencias.ENFRAQUECER, "3 lb.", "1 GP", "lanca", 40],
	"dardo": ["Dardo", "Dart", S, "1d4", P, "FE", "", "20/60", Proficiencias.ATORMENTAR, "1/4 lb.", "5 CP", "dardo", 12],
	"machado_batalha": ["Machado de Batalha", "Battleaxe", M, "1d8", C, "", "1d10", "", Proficiencias.DERRUBAR, "4 lb.", "10 GP", "machado", 28],
	"mangual": ["Mangual", "Flail", M, "1d8", B, "", "", "", Proficiencias.ENFRAQUECER, "2 lb.", "10 GP", "mangual", 26],
	"glaive": ["Glaive", "Glaive", M, "1d10", C, "HTR", "", "", Proficiencias.RASPAO, "6 lb.", "20 GP", "glaive", 50],
	"machado_grande": ["Machado Grande", "Greataxe", M, "1d12", C, "HT", "", "", Proficiencias.TRESPASSAR, "7 lb.", "30 GP", "machado_grande", 38],
	"espada_grande": ["Espada Grande", "Greatsword", M, "2d6", C, "HT", "", "", Proficiencias.RASPAO, "6 lb.", "50 GP", "espada", 44],
	"alabarda": ["Alabarda", "Halberd", M, "1d10", C, "HTR", "", "", Proficiencias.TRESPASSAR, "6 lb.", "20 GP", "alabarda", 52],
	"lanca_montaria": ["Lança de Montaria", "Lance", M, "1d10", P, "HTR", "", "", Proficiencias.DERRUBAR, "6 lb.", "10 GP", "lanca_montaria", 54],
	"espada_longa": ["Espada Longa", "Longsword", M, "1d8", C, "", "1d10", "", Proficiencias.ENFRAQUECER, "3 lb.", "15 GP", "espada", 36],
	"malho": ["Malho", "Maul", M, "2d6", B, "HT", "", "", Proficiencias.DERRUBAR, "10 lb.", "10 GP", "malho", 40],
	"maca_estrela": ["Maça Estrela", "Morningstar", M, "1d8", P, "", "", "", Proficiencias.ENFRAQUECER, "4 lb.", "15 GP", "maca_estrela", 28],
	"pique": ["Pique", "Pike", M, "1d10", P, "HTR", "", "", Proficiencias.EMPURRAR, "18 lb.", "5 GP", "lanca", 58],
	"rapieira": ["Rapieira", "Rapier", M, "1d8", P, "F", "", "", Proficiencias.ATORMENTAR, "2 lb.", "25 GP", "rapieira", 36],
	"cimitarra": ["Cimitarra", "Scimitar", M, "1d6", C, "FL", "", "", Proficiencias.CORTE_DUPLO, "3 lb.", "25 GP", "cimitarra", 30],
	"espada_curta": ["Espada Curta", "Shortsword", M, "1d6", P, "FL", "", "", Proficiencias.ATORMENTAR, "2 lb.", "10 GP", "espada", 30],
	"tridente": ["Tridente", "Trident", M, "1d8", P, "", "1d10", "20/60", Proficiencias.DERRUBAR, "4 lb.", "5 GP", "tridente", 40],
	"picareta_guerra": ["Picareta de Guerra", "War Pick", M, "1d8", P, "", "1d10", "", Proficiencias.ENFRAQUECER, "2 lb.", "5 GP", "picareta", 26],
	"martelo_guerra": ["Martelo de Guerra", "Warhammer", M, "1d8", B, "", "1d10", "", Proficiencias.EMPURRAR, "5 lb.", "15 GP", "martelo", 28],
	"chicote": ["Chicote", "Whip", M, "1d4", C, "FR", "", "", Proficiencias.LENTIDAO, "3 lb.", "2 GP", "chicote", 40],
}

const ALTURA_SPRITE := 13
const COR_METAL := Color8(196, 204, 216)
const COR_METAL_BRILHO := Color8(236, 242, 250)
const COR_METAL_ESCURO := Color8(120, 126, 140)
const COR_MADEIRA := Color8(126, 82, 46)
const COR_MADEIRA_ESCURA := Color8(92, 58, 34)
const COR_COURO := Color8(96, 60, 36)
const COR_OURO := Color8(214, 170, 60)
const CONTORNO := Color8(34, 28, 40)
## Comprimento do cabo seguro pela mão (px a partir da origem).
const PUNHO := 6


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_DADOS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_ARTE))
	for id in TABELA:
		_desenhar(id, TABELA[id]).save_png(PASTA_ARTE + id + ".png")
	var faltando := TABELA.keys().filter(func(id: String) -> bool: return not ResourceLoader.exists(PASTA_ARTE + id + ".png"))
	if not faltando.is_empty():
		print("Sprites gerados. Rode --import e depois este script de novo para criar os .tres.")
		quit()
		return
	for id in TABELA:
		ResourceSaver.save(_criar(id, TABELA[id]), PASTA_DADOS + id + ".tres")
	print("%d armas geradas em %s" % [TABELA.size(), PASTA_DADOS])
	quit()


# --- Dados ------------------------------------------------------------------------

func _criar(id: String, d: Array) -> Arma:
	var a := Arma.new()
	var props: String = d[5]
	a.nome = d[0]
	a.nome_original = d[1]
	a.categoria = d[2]
	a.dados_dano = d[3]
	a.tipo_dano = d[4]
	a.acuidade = "F" in props
	a.leve = "L" in props
	a.pesada = "H" in props
	a.duas_maos = "T" in props
	a.alcance_estendido = "R" in props
	a.empilhavel = "E" in props
	a.dados_versatil = d[6]
	if d[7] != "":
		var partes: PackedStringArray = (d[7] as String).split("/")
		a.arremesso_normal_pes = float(partes[0])
		a.arremesso_longo_pes = float(partes[1])
	a.maestria = d[8]
	a.peso = d[9]
	a.preco = d[10]
	a.livro = LIVRO
	a.textura = load(PASTA_ARTE + id + ".png")
	a.icone = a.textura
	a.alcance = ALCANCE_ESTENDIDO if a.alcance_estendido else ALCANCE_NORMAL
	_definir_tempos(a)
	a.cor_corte = Color(1.0, 0.92, 0.7, 0.85) if a.tipo_dano == B else Color(0.85, 0.95, 1.0, 0.9)
	a.descricao = _descricao(a)
	return a


## "Arma marcial. Acuidade, Leve. Maestria: Atormentar. (Shortsword, Player’s Handbook)"
func _descricao(a: Arma) -> String:
	var partes: PackedStringArray = ["Arma %s" % Proficiencias.NOMES_CATEGORIA_ARMA[a.categoria]]
	if a.texto_propriedades() != "":
		partes.append(a.texto_propriedades())
	partes.append("Maestria: %s" % Proficiencias.NOMES_MAESTRIAS[a.maestria])
	return "%s. (%s, %s)" % [". ".join(partes), a.nome_original, a.livro]


func _definir_tempos(a: Arma) -> void:
	var tipo := "leve" if a.leve else ("pesada" if a.pesada else "normal")
	a.duracao = DURACAO[tipo]
	a.inicio_acerto = snappedf(a.duracao * FRACAO_INICIO_ACERTO, 0.01)
	a.fim_acerto = snappedf(a.duracao * FRACAO_FIM_ACERTO, 0.01)


# --- Sprites --------------------------------------------------------------------
# Todas apontam para a direita, com o cabo começando em x = 0 e o centro em y = ALTURA_SPRITE/2.

func _desenhar(_id: String, d: Array) -> Image:
	var comprimento: int = d[12]
	var img := Image.create(comprimento + 2, ALTURA_SPRITE, false, Image.FORMAT_RGBA8)
	var meio := ALTURA_SPRITE / 2
	match d[11]:
		"espada": _espada(img, comprimento, meio, false)
		"cimitarra": _espada(img, comprimento, meio, true)
		"rapieira": _rapieira(img, comprimento, meio)
		"machado": _machado(img, comprimento, meio, false)
		"machado_grande": _machado(img, comprimento, meio, true)
		"martelo": _martelo(img, comprimento, meio, 5)
		"malho": _martelo(img, comprimento, meio, 8)
		"maca": _maca(img, comprimento, meio, false)
		"maca_estrela": _maca(img, comprimento, meio, true)
		"mangual": _mangual(img, comprimento, meio)
		"porrete": _porrete(img, comprimento, meio)
		"cajado": _cajado(img, comprimento, meio)
		"lanca": _lanca(img, comprimento, meio)
		"lanca_montaria": _lanca_montaria(img, comprimento, meio)
		"glaive": _haste_com_lamina(img, comprimento, meio, false)
		"alabarda": _haste_com_lamina(img, comprimento, meio, true)
		"tridente": _tridente(img, comprimento, meio)
		"foice": _foice(img, comprimento, meio)
		"picareta": _picareta(img, comprimento, meio)
		"chicote": _chicote(img, comprimento, meio)
		"dardo": _dardo(img, comprimento, meio)
	_contornar(img)
	return img


func _cabo(img: Image, x0: int, x1: int, y: int, cor: Color = COR_MADEIRA) -> void:
	img.fill_rect(Rect2i(x0, y - 1, x1 - x0, 2), cor)
	img.fill_rect(Rect2i(x0, y, x1 - x0, 1), cor.darkened(0.2))


func _espada(img: Image, comprimento: int, y: int, curva: bool) -> void:
	_cabo(img, 0, PUNHO, y, COR_COURO)
	img.fill_rect(Rect2i(PUNHO, y - 3, 2, 7), COR_OURO)  # guarda
	var inicio := PUNHO + 2
	var largura := 3 if comprimento >= 36 else 2
	for x in range(inicio, comprimento):
		var subida := int(round(pow(float(x - inicio) / (comprimento - inicio), 2.0) * 3.0)) if curva else 0
		var topo := y - largura / 2 - subida
		img.fill_rect(Rect2i(x, topo, 1, largura + (1 if x < comprimento - 2 else 0)), COR_METAL)
		img.set_pixel(x, topo, COR_METAL_BRILHO)


func _rapieira(img: Image, comprimento: int, y: int) -> void:
	_cabo(img, 0, PUNHO, y, COR_COURO)
	img.fill_rect(Rect2i(PUNHO - 1, y - 3, 3, 7), COR_OURO)  # copo da guarda
	img.fill_rect(Rect2i(PUNHO + 2, y, comprimento - PUNHO - 2, 1), COR_METAL_BRILHO)


func _machado(img: Image, comprimento: int, y: int, grande: bool) -> void:
	_cabo(img, 0, comprimento, y)
	var largura := 7 if grande else 5
	var x0 := comprimento - largura - 1
	for dx in largura:
		var altura := 3 + int(dx * (4 if grande else 2) / float(largura))
		img.fill_rect(Rect2i(x0 + dx, y - 1 - altura, 1, altura), COR_METAL)
		if grande:
			img.fill_rect(Rect2i(x0 + dx, y + 1, 1, altura - 1), COR_METAL)
	img.fill_rect(Rect2i(x0 + largura - 1, y - 6 if grande else y - 4, 1, 4), COR_METAL_BRILHO)


func _martelo(img: Image, comprimento: int, y: int, tamanho: int) -> void:
	_cabo(img, 0, comprimento - 2, y)
	img.fill_rect(Rect2i(comprimento - tamanho, y - tamanho / 2 - 1, tamanho, tamanho + 1), COR_METAL_ESCURO)
	img.fill_rect(Rect2i(comprimento - tamanho, y - tamanho / 2 - 1, tamanho, 1), COR_METAL)


func _maca(img: Image, comprimento: int, y: int, espinhos: bool) -> void:
	_cabo(img, 0, comprimento - 4, y)
	_disco(img, Vector2(comprimento - 3, y), 3.2, COR_METAL_ESCURO)
	if espinhos:
		for p in [Vector2i(comprimento - 3, y - 5), Vector2i(comprimento - 3, y + 4), Vector2i(comprimento + 1, y), Vector2i(comprimento - 7, y - 3)]:
			img.set_pixelv(p, COR_METAL_BRILHO)
	else:
		img.fill_rect(Rect2i(comprimento - 5, y - 4, 1, 8), COR_METAL)


func _mangual(img: Image, comprimento: int, y: int) -> void:
	_cabo(img, 0, comprimento - 12, y)
	for i in 4:  # corrente
		img.set_pixel(comprimento - 12 + i * 2, y - 1 - i / 2, COR_METAL_ESCURO)
	_disco(img, Vector2(comprimento - 3, y - 3), 3.0, COR_METAL_ESCURO)


func _porrete(img: Image, comprimento: int, y: int) -> void:
	for x in comprimento:
		var grossura := 1 + int(3.0 * x / comprimento)
		img.fill_rect(Rect2i(x, y - grossura / 2 - 1, 1, grossura + 1), COR_MADEIRA if x % 7 else COR_MADEIRA_ESCURA)


func _cajado(img: Image, comprimento: int, y: int) -> void:
	_cabo(img, 0, comprimento, y)
	img.fill_rect(Rect2i(0, y - 2, 2, 4), COR_METAL_ESCURO)
	img.fill_rect(Rect2i(comprimento - 2, y - 2, 2, 4), COR_METAL_ESCURO)


func _lanca(img: Image, comprimento: int, y: int) -> void:
	_cabo(img, 0, comprimento - 6, y)
	for dx in 6:
		var meia: int = 2 - absi(dx - 2) / 2
		img.fill_rect(Rect2i(comprimento - 6 + dx, y - meia - 1, 1, meia * 2 + 1), COR_METAL)


func _lanca_montaria(img: Image, comprimento: int, y: int) -> void:
	img.fill_rect(Rect2i(PUNHO, y - 4, 2, 8), COR_METAL_ESCURO)  # proteção da mão
	for x in range(0, comprimento):
		var meia: int = (3 - int(3.0 * x / comprimento)) if x > PUNHO else 1
		img.fill_rect(Rect2i(x, y - meia - 1, 1, meia * 2 + 1), COR_MADEIRA if x < comprimento - 6 else COR_METAL)


func _haste_com_lamina(img: Image, comprimento: int, y: int, com_machado: bool) -> void:
	_cabo(img, 0, comprimento - 10, y)
	for dx in 10:  # lâmina longa
		img.fill_rect(Rect2i(comprimento - 10 + dx, y - 3 + dx / 4, 1, 3), COR_METAL)
	if com_machado:
		img.fill_rect(Rect2i(comprimento - 14, y - 6, 4, 5), COR_METAL_ESCURO)
		img.fill_rect(Rect2i(comprimento - 14, y + 1, 2, 3), COR_METAL_ESCURO)  # esporão


func _tridente(img: Image, comprimento: int, y: int) -> void:
	_cabo(img, 0, comprimento - 7, y)
	img.fill_rect(Rect2i(comprimento - 8, y - 4, 2, 8), COR_METAL)
	for dy in [-4, 0, 3]:
		img.fill_rect(Rect2i(comprimento - 7, y + dy, 7, 1), COR_METAL_BRILHO)


func _foice(img: Image, comprimento: int, y: int) -> void:
	_cabo(img, 0, comprimento - 6, y)
	for i in 6:  # lâmina em gancho
		img.set_pixel(comprimento - 6 + i / 2, y - 1 - i, COR_METAL)
		img.set_pixel(comprimento - 5 + i / 2, y - 1 - i, COR_METAL_BRILHO)


func _picareta(img: Image, comprimento: int, y: int) -> void:
	_cabo(img, 0, comprimento - 2, y)
	img.fill_rect(Rect2i(comprimento - 4, y - 5, 3, 3), COR_METAL_ESCURO)
	for i in 5:  # bico para baixo e para a frente
		img.fill_rect(Rect2i(comprimento - 3 + i / 2, y - 2 + i, 2, 1), COR_METAL)


func _chicote(img: Image, comprimento: int, y: int) -> void:
	_cabo(img, 0, PUNHO + 2, y, COR_COURO)
	for x in range(PUNHO + 2, comprimento):
		var onda := int(round(sin(float(x) / 5.0) * 2.0))
		img.set_pixel(x, clampi(y + onda, 0, ALTURA_SPRITE - 1), COR_COURO.lightened(0.15))


func _dardo(img: Image, comprimento: int, y: int) -> void:
	img.fill_rect(Rect2i(0, y - 2, 2, 5), Color8(200, 60, 60))  # penas
	img.fill_rect(Rect2i(2, y, comprimento - 5, 1), COR_MADEIRA)
	img.fill_rect(Rect2i(comprimento - 3, y - 1, 3, 3), COR_METAL)


func _disco(img: Image, centro: Vector2, raio: float, cor: Color) -> void:
	for yy in img.get_height():
		for xx in img.get_width():
			if (Vector2(xx, yy) + Vector2(0.5, 0.5)).distance_to(centro) <= raio:
				img.set_pixel(xx, yy, cor)


func _contornar(img: Image) -> void:
	var bordas: Array[Vector2i] = []
	for yy in img.get_height():
		for xx in img.get_width():
			if img.get_pixel(xx, yy).a > 0.0:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var v: Vector2i = Vector2i(xx, yy) + d
				if v.x >= 0 and v.y >= 0 and v.x < img.get_width() and v.y < img.get_height() and img.get_pixelv(v).a > 0.0:
					bordas.append(Vector2i(xx, yy))
					break
	for p in bordas:
		img.set_pixelv(p, CONTORNO)
