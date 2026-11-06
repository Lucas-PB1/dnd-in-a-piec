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
## Ícones de 16x16 para os menus (o ícone do pacote reduzido pela metade).
const PASTA_ICONES := "res://assets/armas/icones/"
const TAMANHO_ICONE := 16
const LIVRO := "Player’s Handbook"

const S := Proficiencias.ARMA_SIMPLES
const M := Proficiencias.ARMA_MARCIAL
const C := TiposDano.CORTANTE
const P := TiposDano.PERFURANTE
const B := TiposDano.CONTUNDENTE

## Até onde a ponta tem de chegar (px à frente da mão) no golpe: 5 pés; com Alcance (Reach),
## 10 pés (+1 ladrilho). Se a arma não chega lá com as poses, o herói dá um passo à frente.
const PONTA_NORMAL := 44.0
const PONTA_ALCANCE := PONTA_NORMAL + EscalaDnd.PIXELS_POR_LADRILHO
const ARQ_DESARMADO := "res://data/ataque_desarmado.tres"

## Propriedades: F acuidade, L leve, H pesada, T duas mãos, R alcance, E empilhável.
## id: [nome, nome original, categoria, dano, tipo, propriedades, versátil, arremesso "n/l",
##      maestria, peso, preço, ícone de origem (assets/armas/fonte_idylwild/; vazio = desenhado
##      por script), comprimento da pegada até a ponta (px, escala de jogo; 0 = o do ícone)]
const TABELA := {
	"clava": ["Clava", "Club", S, "1d4", B, "L", "", "", Proficiencias.LENTIDAO, "2 lb.", "1 SP", "club1", 30],
	"adaga": ["Adaga", "Dagger", S, "1d4", P, "FL", "", "20/60", Proficiencias.CORTE_DUPLO, "1 lb.", "2 GP", "dagger1", 24],
	"clava_grande": ["Clava Grande", "Greatclub", S, "1d8", B, "T", "", "", Proficiencias.EMPURRAR, "10 lb.", "2 SP", "club1", 46],
	"machadinha": ["Machadinha", "Handaxe", S, "1d6", C, "L", "", "20/60", Proficiencias.ATORMENTAR, "2 lb.", "5 GP", "throwing_axe1", 26],
	"azagaia": ["Azagaia", "Javelin", S, "1d6", P, "E", "", "30/120", Proficiencias.LENTIDAO, "2 lb.", "5 SP", "javelin", 46],
	"martelo_leve": ["Martelo Leve", "Light Hammer", S, "1d4", B, "L", "", "20/60", Proficiencias.CORTE_DUPLO, "2 lb.", "2 GP", "hammer1", 26],
	"maca": ["Maça", "Mace", S, "1d6", B, "", "", "", Proficiencias.ENFRAQUECER, "4 lb.", "5 GP", "mace1", 36],
	"bordao": ["Bordão", "Quarterstaff", S, "1d6", B, "", "1d8", "", Proficiencias.DERRUBAR, "4 lb.", "2 SP", "staff1", 50],
	"foice": ["Foice", "Sickle", S, "1d4", C, "L", "", "", Proficiencias.CORTE_DUPLO, "2 lb.", "1 GP", "scythe2", 30],
	"lanca": ["Lança", "Spear", S, "1d6", P, "", "1d8", "20/60", Proficiencias.ENFRAQUECER, "3 lb.", "1 GP", "spear1", 50],
	"dardo": ["Dardo", "Dart", S, "1d4", P, "FE", "", "20/60", Proficiencias.ATORMENTAR, "1/4 lb.", "5 CP", "arrow1", 20],
	"machado_batalha": ["Machado de Batalha", "Battleaxe", M, "1d8", C, "", "1d10", "", Proficiencias.DERRUBAR, "4 lb.", "10 GP", "axe2", 40],
	"mangual": ["Mangual", "Flail", M, "1d8", B, "", "", "", Proficiencias.ENFRAQUECER, "2 lb.", "10 GP", "flail", 0],
	"glaive": ["Glaive", "Glaive", M, "1d10", C, "HTR", "", "", Proficiencias.RASPAO, "6 lb.", "20 GP", "polearm2", 76],
	"machado_grande": ["Machado Grande", "Greataxe", M, "1d12", C, "HT", "", "", Proficiencias.TRESPASSAR, "7 lb.", "30 GP", "axe3", 52],
	"espada_grande": ["Espada Grande", "Greatsword", M, "2d6", C, "HT", "", "", Proficiencias.RASPAO, "6 lb.", "50 GP", "sword2", 56],
	"alabarda": ["Alabarda", "Halberd", M, "1d10", C, "HTR", "", "", Proficiencias.TRESPASSAR, "6 lb.", "20 GP", "polearm3", 76],
	"lanca_montaria": ["Lança de Montaria", "Lance", M, "1d10", P, "HTR", "", "", Proficiencias.DERRUBAR, "6 lb.", "10 GP", "spear1", 78],
	"espada_longa": ["Espada Longa", "Longsword", M, "1d8", C, "", "1d10", "", Proficiencias.ENFRAQUECER, "3 lb.", "15 GP", "sword1", 44],
	"malho": ["Malho", "Maul", M, "2d6", B, "HT", "", "", Proficiencias.DERRUBAR, "10 lb.", "10 GP", "hammer2", 52],
	"maca_estrela": ["Maça Estrela", "Morningstar", M, "1d8", P, "", "", "", Proficiencias.ENFRAQUECER, "4 lb.", "15 GP", "morningstar", 40],
	"pique": ["Pique", "Pike", M, "1d10", P, "HTR", "", "", Proficiencias.EMPURRAR, "18 lb.", "5 GP", "spear2", 80],
	"rapieira": ["Rapieira", "Rapier", M, "1d8", P, "F", "", "", Proficiencias.ATORMENTAR, "2 lb.", "25 GP", "sword4", 44],
	"cimitarra": ["Cimitarra", "Scimitar", M, "1d6", C, "FL", "", "", Proficiencias.CORTE_DUPLO, "3 lb.", "25 GP", "knife", 32],
	"espada_curta": ["Espada Curta", "Shortsword", M, "1d6", P, "FL", "", "", Proficiencias.ATORMENTAR, "2 lb.", "10 GP", "dagger3", 32],
	"tridente": ["Tridente", "Trident", M, "1d8", P, "", "1d10", "20/60", Proficiencias.DERRUBAR, "4 lb.", "5 GP", "triden", 48],
	"picareta_guerra": ["Picareta de Guerra", "War Pick", M, "1d8", P, "", "1d10", "", Proficiencias.ENFRAQUECER, "2 lb.", "5 GP", "axe4", 38],
	"martelo_guerra": ["Martelo de Guerra", "Warhammer", M, "1d8", B, "", "1d10", "", Proficiencias.EMPURRAR, "5 lb.", "15 GP", "hammer1", 40],
	"chicote": ["Chicote", "Whip", M, "1d4", C, "FR", "", "", Proficiencias.LENTIDAO, "3 lb.", "2 GP", "", 70],
}

## Movimento de cada arma: poses-chave [tempo (s), ângulo (graus), mão x, mão y, acerta, escala].
## Ângulo com o herói olhando para a direita: 0 = à frente, -90 = para cima, positivo = para
## baixo. "acerta" vale para o trecho que começa na pose. A última pose fecha o golpe.
## Ideia geral: preparação (vai para trás devagar) -> trecho que acerta (rápido) -> recuperação.
const GOLPES := {
	# Lâminas leves: estocadas rápidas e cortes curtos.
	"adaga": [[0.0, 20, -2, 0, false], [0.05, 10, -6, 1, true], [0.11, 0, 8, 0, false], [0.22, 30, 0, 0, false]],
	"espada_curta": [[0.0, 10, -3, 0, false], [0.07, 0, -8, 0, true], [0.14, -3, 10, -1, false], [0.28, 30, 0, 0, false]],
	"rapieira": [[0.0, -8, -4, -2, false], [0.09, -2, -11, -1, true], [0.17, 0, 14, -1, false], [0.34, 28, 2, 0, false]],
	"cimitarra": [[0.0, -70, -2, -3, false], [0.06, -125, -4, -5, true], [0.14, 55, 4, 2, false], [0.27, 35, 0, 0, false]],
	"foice": [[0.0, -40, 0, -2, false], [0.07, -95, -2, -4, true], [0.13, 25, 7, 0, false], [0.19, 50, -3, 1, false], [0.28, 35, 0, 0, false]],
	"dardo": [[0.0, 15, -2, 0, false], [0.05, 0, -5, 0, true], [0.1, 0, 7, 0, false], [0.2, 30, 0, 0, false]],
	# Espadas e machados de uma mão: cortes de cima para baixo.
	"espada_longa": [[0.0, -80, -3, -3, false], [0.09, -125, -6, -6, true], [0.18, 45, 4, 2, false], [0.34, 35, 0, 0, false]],
	"machadinha": [[0.0, -70, -2, -3, false], [0.07, -105, -4, -5, true], [0.14, 45, 3, 1, false], [0.27, 35, 0, 0, false]],
	"machado_batalha": [[0.0, -75, -3, -4, false], [0.11, -130, -6, -8, true], [0.21, 60, 4, 3, false], [0.37, 40, 0, 0, false]],
	"picareta_guerra": [[0.0, -80, -3, -4, false], [0.1, -135, -5, -8, true], [0.19, 70, 4, 4, false], [0.35, 40, 0, 0, false]],
	# Contundentes de uma mão: pancadas com peso no fim.
	"clava": [[0.0, -70, -2, -2, false], [0.08, -115, -4, -5, true], [0.17, 45, 3, 1, false], [0.29, 35, 0, 0, false]],
	"maca": [[0.0, -80, -3, -3, false], [0.1, -120, -5, -6, true], [0.19, 55, 3, 2, false], [0.33, 35, 0, 0, false]],
	"maca_estrela": [[0.0, -85, -3, -3, false], [0.11, -130, -6, -7, true], [0.2, 60, 4, 2, false], [0.35, 35, 0, 0, false]],
	"martelo_leve": [[0.0, -60, -2, -2, false], [0.06, -100, -3, -4, true], [0.13, 40, 3, 0, false], [0.24, 35, 0, 0, false]],
	"martelo_guerra": [[0.0, -85, -4, -4, false], [0.12, -135, -6, -9, true], [0.22, 65, 4, 3, false], [0.37, 40, 0, 0, false]],
	# Pesadas de duas mãos: preparação longa, golpe largo, recuperação pesada.
	"espada_grande": [[0.0, -50, -4, -2, false], [0.15, -150, -8, -8, true], [0.28, 60, 6, 2, false], [0.47, 40, 2, 0, false]],
	"machado_grande": [[0.0, -55, -4, 0, false], [0.17, -160, -8, -10, true], [0.31, 70, 6, 4, false], [0.5, 45, 2, 0, false]],
	"clava_grande": [[0.0, -60, -4, -2, false], [0.16, -150, -8, -8, true], [0.29, 75, 4, 4, false], [0.48, 50, 0, 0, false]],
	"malho": [[0.0, -40, -4, 0, false], [0.19, -170, -8, -12, true], [0.33, 80, 6, 6, false], [0.55, 55, 2, 0, false]],
	# Haste: o bordão gira por cima; a glaive varre; a alabarda corta de cima.
	"bordao": [[0.0, 30, 0, 0, false], [0.07, -30, -4, -2, false], [0.13, -165, -6, -4, true], [0.23, 35, 5, 0, false], [0.37, 30, 0, 0, false]],
	"glaive": [[0.0, -25, -4, -2, false], [0.15, -150, -6, -6, true], [0.29, 25, 6, 0, false], [0.47, 20, 0, 0, false]],
	"alabarda": [[0.0, -40, -4, -2, false], [0.17, -140, -6, -8, true], [0.31, 40, 6, 2, false], [0.49, 25, 0, 0, false]],
	# Lanças: estocadas retas; quanto mais comprida, mais lenta.
	"lanca": [[0.0, 5, -4, -2, false], [0.08, 0, -10, -2, true], [0.16, -2, 12, -2, false], [0.31, 20, 0, 0, false]],
	"azagaia": [[0.0, 5, -4, -2, false], [0.07, 0, -9, -2, true], [0.14, -2, 11, -2, false], [0.28, 20, 0, 0, false]],
	"tridente": [[0.0, 12, -5, -2, false], [0.09, 6, -10, -2, true], [0.17, 4, 12, 0, false], [0.33, 25, 0, 0, false]],
	"pique": [[0.0, 2, -6, -2, false], [0.13, 0, -12, -2, true], [0.23, 0, 14, -2, false], [0.43, 15, 0, 0, false]],
	"lanca_montaria": [[0.0, 0, -5, -1, false], [0.13, -2, -11, -1, true], [0.25, 0, 14, -1, false], [0.45, 15, 0, 0, false]],
}
## Soco (ataque desarmado): um direto curto.
const GOLPE_SOCO := [[0.0, 0, -3, 0, false], [0.05, 0, -6, 0, true], [0.11, 0, 10, 0, false], [0.22, 0, 0, 0, false]]
## Comprimento do soco (px da mão até onde o punho "chega").
const COMPRIMENTO_SOCO := 8.0



func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_DADOS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_ARTE))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_ICONES))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_QUADROS))
	for id in TABELA:
		_desenhar(id, TABELA[id]).save_png(PASTA_ARTE + id + ".png")
		_icone(id, TABELA[id]).save_png(PASTA_ICONES + id + ".png")
		if QUADROS.has(id):
			_folha_de_quadros(id).save_png(PASTA_QUADROS + id + ".png")
	var faltando := TABELA.keys().filter(func(id: String) -> bool: return _falta_arte(id))
	if not faltando.is_empty():
		print("Sprites gerados. Rode --import e depois este script de novo para criar os .tres.")
		quit()
		return
	for id in TABELA:
		ResourceSaver.save(_criar(id, TABELA[id]), PASTA_DADOS + id + ".tres")
	_atualizar_soco()
	print("%d armas geradas em %s" % [TABELA.size(), PASTA_DADOS])
	quit()


## Alguma imagem da arma ainda não foi importada (sprite, ícone ou quadros)?
func _falta_arte(id: String) -> bool:
	var falta_quadros := QUADROS.has(id) and not ResourceLoader.exists(PASTA_QUADROS + id + ".png")
	return not ResourceLoader.exists(PASTA_ARTE + id + ".png") or not ResourceLoader.exists(PASTA_ICONES + id + ".png") or falta_quadros


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
	a.icone = load(PASTA_ICONES + id + ".png")
	a.angulo_arte = _angulo_da_arte(d[11])
	var medidas := geometria(a.textura.get_image(), a.angulo_arte)
	a.pegada = medidas[0]
	a.comprimento = snappedf(medidas[1], 0.1)
	if QUADROS.has(id):
		_aplicar_quadros(a, id)
	else:
		a.poses = _poses(GOLPES[id])
	a.passo = _passo(a, PONTA_ALCANCE if a.alcance_estendido else PONTA_NORMAL)
	a.efeito = _efeito(a, id)
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


## O soco (ataque desarmado) também ganha poses, comprimento e passo.
func _atualizar_soco() -> void:
	var soco: Arma = load(ARQ_DESARMADO)
	soco.poses = _poses(GOLPE_SOCO)
	soco.comprimento = COMPRIMENTO_SOCO
	soco.passo = _passo(soco, PONTA_NORMAL)
	soco.efeito = _efeito(soco, "")
	ResourceSaver.save(soco, ARQ_DESARMADO)


## Lista da tabela GOLPES -> poses: [tempo, ângulo, mão x, mão y, acerta, escala (opcional)].
func _poses(lista: Array) -> Array[PoseGolpe]:
	var poses: Array[PoseGolpe] = []
	for p: Array in lista:
		poses.append(PoseGolpe.criar(p[0], p[1], Vector2(p[2], p[3]), p[5] if p.size() > 5 else 1.0, p[4]))
	return poses


## Armas perfurantes que batem como contundentes (cabeça pesada): mostram impacto.
const EFEITO_POR_ARMA := {"maca_estrela": Arma.EFEITO_IMPACTO, "picareta_guerra": Arma.EFEITO_IMPACTO, "chicote": &""}
## Abaixo deste giro (graus) no trecho que acerta, o golpe é estocada (rastro).
const GIRO_ESTOCADA := 60.0


## Efeito do golpe: impacto nos contundentes, rastro nas estocadas (quase sem giro), arco
## nos cortes. EFEITO_POR_ARMA manda nas exceções.
func _efeito(a: Arma, id: String) -> StringName:
	if EFEITO_POR_ARMA.has(id):
		return EFEITO_POR_ARMA[id]
	if a.tipo_dano == B:
		return Arma.EFEITO_IMPACTO
	return Arma.EFEITO_RASTRO if _giro_no_acerto(a) < GIRO_ESTOCADA else Arma.EFEITO_CORTE


## Quanto a lâmina gira (graus) nos trechos que acertam.
static func _giro_no_acerto(a: Arma) -> float:
	var giro := 0.0
	for i in a.poses.size() - 1:
		if a.poses[i].acerta:
			giro += absf(a.poses[i + 1].angulo - a.poses[i].angulo)
	return giro

## Passo à frente (px) para a ponta chegar a `ponta` px da mão nos trechos que acertam.
static func _passo(a: Arma, ponta: float) -> float:
	return snappedf(maxf(ponta - a.alcance_da_ponta(), 0.0), 0.5)


# --- Sprites --------------------------------------------------------------------
# Os ícones do pacote (CC0, Idylwild) vêm na diagonal: cabo embaixo à esquerda, ponta em
# cima à direita (ANGULO_PACOTE). A imagem NÃO é girada (estragaria o pixel art): a Arma
# guarda o ângulo da arte e a pegada, e o AtaqueJogador compensa ao girar.
# Para chegar ao comprimento da TABELA, a haste é esticada (ou encurtada) na diagonal,
# repetindo a fatia de pixels no ponto de corte: o desenho continua nítido.

const PASTA_FONTE := "res://assets/armas/fonte_idylwild/"
## Direção da lâmina nos ícones do pacote (graus; y para baixo: -45 = para cima e à direita).
const ANGULO_PACOTE := -45.0
## Onde a haste é cortada para esticar: fração do comprimento a partir do cabo.
const FRACAO_CORTE := 0.45
## Armas em que o corte padrão cai num lugar ruim (ex.: a guarda larga da adaga).
const CORTE_POR_ICONE := {"dagger1": 0.75, "dagger3": 0.75}
## Ícones desenhados em outra direção (as adagas apontam para cima e à esquerda).
const ANGULO_POR_ICONE := {"dagger1": -135.0, "dagger3": -135.0}
## Distância (px) do fim do cabo até onde a mão segura.
const PEGADA_ARTE := 4.0
## Folga em volta da imagem enquanto estica (depois recorta).
const MARGEM := 64
## Raiz de 2: um passo na diagonal (1, -1) anda isto ao longo da lâmina.
const RAIZ2 := sqrt(2.0)

## Chicote (desenhado por script, na horizontal, nas cores do pacote).
const COR_COURO := Color8(92, 56, 38)
const COR_COURO_CLARO := Color8(140, 92, 58)
const COR_CONTORNO := Color8(30, 24, 30)
const ALTURA_CHICOTE := 7
const CABO_CHICOTE := 9

## Armas que usam o mesmo ícone de outra ganham um ajuste de cor para não parecerem iguais.
const VARIACOES := {"clava_grande": "madeira_escura", "lanca_montaria": "listras", "martelo_guerra": "aco_azul"}
## Listras da lança de torneio: largura (px ao longo da haste) e as cores escura e clara.
const LARGURA_LISTRA := 6.0
const COR_LISTRA_ESCURA := Color8(120, 28, 30)
const COR_LISTRA_CLARA := Color8(214, 74, 60)
## Na haste escura da lança, só o preto puro é contorno.
const LUZ_CONTORNO_HASTE := 0.06
const TINTA_MADEIRA_ESCURA := Color(0.62, 0.58, 0.6)
const TINTA_ACO_AZUL := Color(0.72, 0.86, 1.12)
## Pixels mais escuros que isto são contorno e não mudam de cor.
const LUZ_CONTORNO := 0.18


func _desenhar(id: String, d: Array) -> Image:
	var fonte: String = d[11]
	var alvo: float = d[12]
	if fonte == "":
		return _chicote(roundi(alvo + PEGADA_ARTE))
	var img := Image.load_from_file(ProjectSettings.globalize_path(PASTA_FONTE + fonte + ".png"))
	img.convert(Image.FORMAT_RGBA8)
	var direcao := Vector2.from_angle(deg_to_rad(_angulo_da_arte(fonte)))
	if alvo > 0.0:  # 0 = comprimento original (ex.: a corrente do mangual não estica)
		img = _ajustar_comprimento(img, alvo + PEGADA_ARTE, direcao, CORTE_POR_ICONE.get(fonte, FRACAO_CORTE))
	_variar(img, VARIACOES.get(id, ""), direcao)
	return img


## Ajuste de cor para diferenciar armas com o mesmo ícone (ver VARIACOES).
func _variar(img: Image, variacao: String, direcao: Vector2) -> void:
	var faixa := _faixa(_opacos(img), direcao)
	for p in _opacos(img):
		var cor := img.get_pixelv(p)
		var limite := LUZ_CONTORNO_HASTE if variacao == "listras" else LUZ_CONTORNO
		if cor.get_luminance() < limite:
			continue
		var madeira := cor.r > cor.b * 1.2
		match variacao:
			"madeira_escura":
				if madeira:
					img.set_pixelv(p, cor * TINTA_MADEIRA_ESCURA)
			"aco_azul":
				if not madeira:
					img.set_pixelv(p, (cor * TINTA_ACO_AZUL).clamp())
			"listras":
				var ao_longo := _proj(p, direcao) - faixa.x
				var na_haste := ao_longo > PEGADA_ARTE * 2.0 and ao_longo < (faixa.y - faixa.x) * 0.8
				if na_haste and int(ao_longo / LARGURA_LISTRA) % 2 == 1:
					img.set_pixelv(p, COR_LISTRA_ESCURA.lerp(COR_LISTRA_CLARA, clampf(cor.get_luminance() * 2.5, 0.0, 1.0)))


## Direção da lâmina no ícone (graus). Vazio = desenhado por script, na horizontal.
func _angulo_da_arte(fonte: String) -> float:
	if fonte == "":
		return 0.0
	return ANGULO_POR_ICONE.get(fonte, ANGULO_PACOTE)


## Estica ou encurta a imagem ao longo de `direcao` (diagonal) até `alvo` px de comprimento,
## cortando em `fracao_corte` do comprimento (a partir do cabo).
func _ajustar_comprimento(img: Image, alvo: float, direcao: Vector2, fracao_corte: float) -> Image:
	var pixels := _opacos(img)
	var faixa := _faixa(pixels, direcao)
	var passo := Vector2i(roundi(direcao.x * RAIZ2), roundi(direcao.y * RAIZ2))  # ex.: (1, -1)
	var k := roundi((alvo - (faixa.y - faixa.x)) / RAIZ2)
	var corte := faixa.x + (faixa.y - faixa.x) * fracao_corte
	var largura_fatia := direcao.dot(Vector2(passo))
	var saida := Image.create(img.get_width() + MARGEM * 2, img.get_height() + MARGEM * 2, false, Image.FORMAT_RGBA8)
	for p in pixels:
		var proj := _proj(p, direcao)
		if k < 0 and proj >= corte + k * largura_fatia and proj < corte:
			continue  # encurtando: some uma faixa da haste
		var destino := p + (passo * k if proj >= corte else Vector2i.ZERO)
		saida.set_pixelv(destino + Vector2i(MARGEM, MARGEM), img.get_pixelv(p))
	for p in pixels:  # esticando: repete a fatia do corte
		var proj := _proj(p, direcao)
		if k > 0 and proj >= corte - largura_fatia and proj < corte:
			for i in range(1, k + 1):
				saida.set_pixelv(p + passo * i + Vector2i(MARGEM, MARGEM), img.get_pixelv(p))
	return saida.get_region(saida.get_used_rect())


## Pegada (px na imagem) e comprimento da pegada até a ponta, para a arte apontando em `angulo`.
static func geometria(img: Image, angulo: float) -> Array:
	var direcao := Vector2.from_angle(deg_to_rad(angulo))
	var pixels := _opacos(img)
	var faixa := _faixa(pixels, direcao)
	var soma := Vector2.ZERO
	var quantos := 0
	for p in pixels:
		if _proj(p, direcao) < faixa.x + 1.5:
			soma += Vector2(p) + Vector2(0.5, 0.5)
			quantos += 1
	var pegada := soma / quantos + direcao * PEGADA_ARTE
	return [pegada, faixa.y - pegada.dot(direcao)]


static func _opacos(img: Image) -> Array[Vector2i]:
	var lista: Array[Vector2i] = []
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				lista.append(Vector2i(x, y))
	return lista


## Menor e maior projeção dos pixels em `direcao` (o cabo e a ponta).
static func _faixa(pixels: Array[Vector2i], direcao: Vector2) -> Vector2:
	var faixa := Vector2(INF, -INF)
	for p in pixels:
		var proj := _proj(p, direcao)
		faixa = Vector2(minf(faixa.x, proj), maxf(faixa.y, proj))
	return faixa


static func _proj(p: Vector2i, direcao: Vector2) -> float:
	return (Vector2(p) + Vector2(0.5, 0.5)).dot(direcao)


## Chicote na horizontal: cabo de couro trançado e a correia afinando até a ponta.
func _chicote(comprimento: int) -> Image:
	var img := Image.create(comprimento, ALTURA_CHICOTE, false, Image.FORMAT_RGBA8)
	var meio := ALTURA_CHICOTE / 2
	img.fill_rect(Rect2i(0, meio - 1, CABO_CHICOTE, 3), COR_COURO)
	for x in range(0, CABO_CHICOTE, 2):  # trança do cabo
		img.set_pixel(x, meio - 1, COR_COURO_CLARO)
	for x in range(CABO_CHICOTE, comprimento):
		var queda := int(round(sin(PI * float(x - CABO_CHICOTE) / (comprimento - CABO_CHICOTE)) * 2.0))
		img.set_pixel(x, meio + queda, COR_COURO_CLARO if x % 3 else COR_COURO)
		if x < comprimento * 0.6:
			img.set_pixel(x, meio + queda - 1, COR_COURO)
	_contornar(img)
	return img


func _contornar(img: Image) -> void:
	var bordas: Array[Vector2i] = []
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var v: Vector2i = Vector2i(x, y) + d
				if Rect2i(Vector2i.ZERO, img.get_size()).has_point(v) and img.get_pixelv(v).a > 0.0:
					bordas.append(Vector2i(x, y))
					break
	for p in bordas:
		img.set_pixelv(p, COR_CONTORNO)


# --- Ícones dos menus (16x16) ---------------------------------------------------

## Ícone do menu: o ícone original do pacote (com a cor da variação), reduzido pela metade.
## O chicote, desenhado por script, ganha um ícone enrolado.
func _icone(id: String, d: Array) -> Image:
	var fonte: String = d[11]
	if fonte == "":
		return _icone_chicote()
	var img := Image.load_from_file(ProjectSettings.globalize_path(PASTA_FONTE + fonte + ".png"))
	img.convert(Image.FORMAT_RGBA8)
	_variar(img, VARIACOES.get(id, ""), Vector2.from_angle(deg_to_rad(_angulo_da_arte(fonte))))
	return _reduzir(img, TAMANHO_ICONE)


## Reduz para `tamanho` escolhendo, em cada bloco, o pixel opaco de luz mediana: as linhas
## finas (hastes diagonais de 1 px) não somem, como sumiriam pegando um pixel fixo.
static func _reduzir(img: Image, tamanho: int) -> Image:
	var bloco := img.get_width() / tamanho
	var saida := Image.create(tamanho, tamanho, false, Image.FORMAT_RGBA8)
	for y in tamanho:
		for x in tamanho:
			var opacos: Array[Color] = []
			for dy in bloco:
				for dx in bloco:
					var cor := img.get_pixel(x * bloco + dx, y * bloco + dy)
					if cor.a > 0.0:
						opacos.append(cor)
			if opacos.is_empty():
				continue
			opacos.sort_custom(func(a: Color, b: Color) -> bool: return a.get_luminance() < b.get_luminance())
			saida.set_pixel(x, y, opacos[opacos.size() / 2])
	return saida


## Chicote enrolado em espiral, com o cabo para baixo.
func _icone_chicote() -> Image:
	var img := Image.create(TAMANHO_ICONE, TAMANHO_ICONE, false, Image.FORMAT_RGBA8)
	var centro := Vector2(9.0, 7.0)
	for i in 60:
		var t := float(i) / 60.0
		var ponto := centro + Vector2.from_angle(t * TAU * 1.6) * (1.5 + t * 4.5)
		img.set_pixelv(Vector2i(ponto), COR_COURO_CLARO if i % 3 else COR_COURO)
	img.fill_rect(Rect2i(2, 11, 2, 4), COR_COURO)  # cabo
	img.set_pixel(3, 11, COR_COURO_CLARO)
	_contornar(img)
	return img


# --- Quadros desenhados (armas flexíveis) -------------------------------------------
# O mangual e o chicote não são rígidos: em vez de girar uma imagem, cada pose do golpe
# mostra um quadro desenhado (herói olhando para a direita, mão no centro do quadro).
# A ponta de cada quadro (a bola, a ponta da correia) vira a pose: a área de acerto vai
# da mão até ela.

const PASTA_QUADROS := "res://assets/armas/quadros/"
## Tamanho de cada quadro e onde fica a mão nele.
const TAMANHO_QUADRO := Vector2i(176, 144)
const MAO_QUADRO := Vector2(88, 72)

## Mangual: [tempo, ângulo do cabo, ângulo da corrente, acerta]. A bola fica para trás no
## giro (a corrente atrasa em relação ao cabo), passa por cima e desce à frente.
const QUADROS_MANGUAL := [
	[0.0, -20, 100, false], [0.05, -70, 145, false], [0.1, -120, 190, false],
	[0.15, -150, 250, false], [0.19, -70, -75, true], [0.23, 5, 0, true],
	[0.27, 40, 55, false], [0.33, 35, 115, false], [0.4, 30, 85, false],
]
const CABO_MANGUAL := 14.0
const CORRENTE_MANGUAL := 18.0
const RAIO_BOLA := 4.0
const ELO := 3.0
const COR_CABO_MANGUAL := Color8(168, 116, 66)
const COR_PUNHO_MANGUAL := Color8(150, 40, 40)
const COR_ELO := Color8(150, 154, 168)
const COR_BOLA := Color8(70, 72, 82)
const COR_ESPINHO := Color8(200, 204, 214)

## Chicote: [tempo, ângulo do cabo, curva no começo e no fim da correia (graus somados ao
## cabo), extensão (1 = esticado), acerta, estalo]. Sobe, a correia fica para trás e faz
## um laço, desenrola para a frente e estala esticado.
const QUADROS_CHICOTE := [
	[0.0, 30, 20, 60, 0.5, false, false], [0.06, -60, 40, 120, 0.6, false, false],
	[0.11, -130, 30, 90, 0.8, false, false], [0.15, -160, -20, 40, 0.9, false, false],
	[0.18, -40, -120, -200, 0.9, true, false], [0.21, -10, -60, -10, 1.0, true, false],
	[0.24, 0, 4, 0, 1.0, true, true], [0.27, 10, 10, 40, 1.0, false, false],
	[0.34, 25, 20, 70, 0.7, false, false], [0.4, 30, 20, 60, 0.5, false, false],
]
const CABO_CHICOTE_PX := 9.0
const SEGMENTOS_CHICOTE := 14
const CORREIA_CHICOTE := 62.0
const COR_ESTALO := Color8(255, 250, 220)

const QUADROS := {"mangual": QUADROS_MANGUAL, "chicote": QUADROS_CHICOTE}


## Folha com todos os quadros do golpe, lado a lado.
func _folha_de_quadros(id: String) -> Image:
	var lista: Array = QUADROS[id]
	var folha := Image.create(TAMANHO_QUADRO.x * lista.size(), TAMANHO_QUADRO.y, false, Image.FORMAT_RGBA8)
	for i in lista.size():
		var quadro := Image.create(TAMANHO_QUADRO.x, TAMANHO_QUADRO.y, false, Image.FORMAT_RGBA8)
		if id == "mangual":
			_quadro_mangual(quadro, lista[i])
		else:
			_quadro_chicote(quadro, lista[i])
		_contornar(quadro)
		folha.blit_rect(quadro, Rect2i(Vector2i.ZERO, TAMANHO_QUADRO), Vector2i(i * TAMANHO_QUADRO.x, 0))
	return folha


## Quadros da folha + poses tiradas da ponta de cada quadro.
func _aplicar_quadros(a: Arma, id: String) -> void:
	var folha: Texture2D = load(PASTA_QUADROS + id + ".png")
	var lista: Array = QUADROS[id]
	a.pegada_quadros = MAO_QUADRO
	a.quadros = []
	a.poses = []
	var angulo_anterior := 0.0
	for i in lista.size():
		var quadro := AtlasTexture.new()
		quadro.atlas = folha
		quadro.region = Rect2(i * TAMANHO_QUADRO.x, 0, TAMANHO_QUADRO.x, TAMANHO_QUADRO.y)
		a.quadros.append(quadro)
		var ponta: Vector2 = _ponta_mangual(lista[i]) if id == "mangual" else _pontos_chicote(lista[i]).back() - MAO_QUADRO
		# Ângulo sem "pulo" de 360 entre quadros, para a interpolação ir pelo caminho curto.
		var angulo := rad_to_deg(ponta.angle())
		angulo += 360.0 * round((angulo_anterior - angulo) / 360.0) if i > 0 else 0.0
		angulo_anterior = angulo
		var acerta: bool = lista[i][3] if id == "mangual" else lista[i][5]
		a.poses.append(PoseGolpe.criar(lista[i][0], angulo, Vector2.ZERO, ponta.length() / a.comprimento, acerta))


# Mangual -------------------------------------------------------------------------

func _quadro_mangual(img: Image, q: Array) -> void:
	var fim_cabo := MAO_QUADRO + Vector2.from_angle(deg_to_rad(q[1])) * CABO_MANGUAL
	var bola := MAO_QUADRO + _ponta_mangual(q)
	var atras := MAO_QUADRO - Vector2.from_angle(deg_to_rad(q[1])) * 3.0  # pomo atrás da mão
	_linha(img, atras, fim_cabo, COR_CABO_MANGUAL, 2)
	_linha(img, atras, MAO_QUADRO + Vector2.from_angle(deg_to_rad(q[1])) * 4.0, COR_PUNHO_MANGUAL, 2)
	var elos := int(CORRENTE_MANGUAL / ELO)
	for k in elos:
		img.set_pixelv(Vector2i(fim_cabo.lerp(bola, float(k) / elos)), COR_ELO)
	_disco(img, bola, RAIO_BOLA, COR_BOLA)
	for k in 6:  # espinhos
		img.set_pixelv(Vector2i(bola + Vector2.from_angle(k * TAU / 6.0 + 0.3) * (RAIO_BOLA + 1.0)), COR_ESPINHO)
	img.set_pixelv(Vector2i(bola + Vector2(-1, -1)), COR_ESPINHO)  # brilho


## Centro da bola em relação à mão.
func _ponta_mangual(q: Array) -> Vector2:
	return Vector2.from_angle(deg_to_rad(q[1])) * CABO_MANGUAL + Vector2.from_angle(deg_to_rad(q[2])) * CORRENTE_MANGUAL


# Chicote -------------------------------------------------------------------------

func _quadro_chicote(img: Image, q: Array) -> void:
	var pontos := _pontos_chicote(q)
	_linha(img, MAO_QUADRO - Vector2.from_angle(deg_to_rad(q[1])) * 2.0, pontos[0], COR_COURO, 2)
	for k in range(1, pontos.size()):
		var grosso := 2 if k < pontos.size() * 0.5 else 1  # a correia afina até a ponta
		_linha(img, pontos[k - 1], pontos[k], COR_COURO_CLARO if k % 2 else COR_COURO, grosso)
	if q[6]:  # estalo na ponta
		var ponta: Vector2 = pontos.back()
		for d in [Vector2(2, 0), Vector2(0, 2), Vector2(0, -2), Vector2(2, -2), Vector2(2, 2)]:
			img.set_pixelv(Vector2i(ponta + d), COR_ESTALO)


## Pontos da correia: começa no fim do cabo; cada segmento vira um pouco mais (curva).
func _pontos_chicote(q: Array) -> Array[Vector2]:
	var cabo: float = q[1]
	var pontos: Array[Vector2] = [MAO_QUADRO + Vector2.from_angle(deg_to_rad(cabo)) * CABO_CHICOTE_PX]
	var passo_correia: float = CORREIA_CHICOTE / SEGMENTOS_CHICOTE * q[4]
	for k in SEGMENTOS_CHICOTE:
		var curva := lerpf(q[2], q[3], float(k) / (SEGMENTOS_CHICOTE - 1))
		pontos.append(pontos.back() + Vector2.from_angle(deg_to_rad(cabo + curva)) * passo_correia)
	return pontos


# Desenho -------------------------------------------------------------------------

func _linha(img: Image, a: Vector2, b: Vector2, cor: Color, grossura: int) -> void:
	var passos := maxi(int(a.distance_to(b) * 2.0), 1)
	for s in passos + 1:
		var p := a.lerp(b, float(s) / passos)
		for dy in grossura:
			var v := Vector2i(p) + Vector2i(0, dy)
			if Rect2i(Vector2i.ZERO, img.get_size()).has_point(v):
				img.set_pixelv(v, cor)


func _disco(img: Image, centro: Vector2, raio: float, cor: Color) -> void:
	for y in range(int(centro.y - raio) - 1, int(centro.y + raio) + 2):
		for x in range(int(centro.x - raio) - 1, int(centro.x + raio) + 2):
			if Vector2(x + 0.5, y + 0.5).distance_to(centro) <= raio and Rect2i(Vector2i.ZERO, img.get_size()).has_point(Vector2i(x, y)):
				img.set_pixel(x, y, cor)
