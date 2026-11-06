extends SceneTree
## Gera as armas do Player's Handbook (2024): corpo a corpo, arremesso e à distância.
## Sprite provisório em assets/armas/<id>.png e .tres em data/armas/<id>.tres.
## Munição em data/municoes/ (a flecha do pacote Idylwild vira o projétil).
##   godot --headless --path . --script res://tools/gerar_armas.gd
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/gerar_armas.gd   (2ª vez: cria os .tres)
## Para mudar uma arma, edite a TABELA e rode de novo (não edite os .tres à mão).
## À distância: a coluna de alcance vai para o disparo (propriedade D), não para o arremesso.

const PASTA_DADOS := "res://data/armas/"
const PASTA_MUNICOES := "res://data/municoes/"
const PASTA_ARTE := "res://assets/armas/"
const PASTA_MUNICAO_ARTE := "res://assets/armas/municoes/"
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
const PONTA_NORMAL := EscalaDnd.PONTA_5_PES
const PONTA_ALCANCE := PONTA_NORMAL + EscalaDnd.PIXELS_POR_LADRILHO
const ARQ_DESARMADO := "res://data/ataque_desarmado.tres"

## Propriedades: F acuidade, L leve, H pesada, T duas mãos, R alcance, E empilhável,
## D disparo, G recarga, X besta.
## id: [nome, nome original, categoria, dano, tipo, propriedades, versátil, alcance "n/l"
##      (arremesso, ou disparo se tiver D), maestria, peso, preço, ícone de origem
##      (assets/armas/fonte_idylwild/; vazio = desenhado por script), comprimento da pegada
##      até a ponta (px; 0 = o do ícone), munição (só no disparo)]
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
	"besta_leve": ["Besta Leve", "Light Crossbow", S, "1d8", P, "TXGD", "", "80/320", Proficiencias.LENTIDAO, "5 lb.", "25 GP", "", 44, "Virote"],
	"arco_curto": ["Arco Curto", "Shortbow", S, "1d6", P, "TD", "", "80/320", Proficiencias.ATORMENTAR, "2 lb.", "25 GP", "", 40, "Flecha"],
	"funda": ["Funda", "Sling", S, "1d4", B, "D", "", "30/120", Proficiencias.LENTIDAO, "—", "1 SP", "", 22, "Pedra de Funda"],
	"zarabatana": ["Zarabatana", "Blowgun", M, "1d1", P, "GD", "", "25/100", Proficiencias.ATORMENTAR, "1 lb.", "10 GP", "", 36, "Agulha"],
	"besta_mao": ["Besta de Mão", "Hand Crossbow", M, "1d6", P, "LXGD", "", "30/120", Proficiencias.ATORMENTAR, "3 lb.", "75 GP", "", 28, "Virote"],
	"besta_pesada": ["Besta Pesada", "Heavy Crossbow", M, "1d10", P, "HTXGD", "", "100/400", Proficiencias.EMPURRAR, "18 lb.", "50 GP", "", 52, "Virote"],
	"arco_longo": ["Arco Longo", "Longbow", M, "1d8", P, "HTD", "", "150/600", Proficiencias.LENTIDAO, "2 lb.", "50 GP", "", 56, "Flecha"],
	"mosquete": ["Mosquete", "Musket", M, "1d12", P, "HTGD", "", "40/120", Proficiencias.LENTIDAO, "10 lb.", "500 GP", "", 56, "Bala"],
	"pistola": ["Pistola", "Pistol", M, "1d10", P, "GD", "", "30/90", Proficiencias.ATORMENTAR, "3 lb.", "250 GP", "", 28, "Bala"],
}

## Munição: id do arquivo -> [nome, nome original, impulso (x velocidade da arma), peso (x
## gravidade: menor = mais reto)]. A arte vem do pacote (MUNICAO_AEREO).
const MUNICOES := {
	"flecha": ["Flecha", "Arrow", 1.0, 0.6],
	"virote": ["Virote", "Bolt", 1.1, 0.5],
	"pedra_funda": ["Pedra de Funda", "Sling Bullet", 1.0, 1.0],
	"agulha": ["Agulha", "Needle", 0.9, 0.8],
	"bala": ["Bala", "Firearm Bullet", 2.2, 0.25],
}

## Armas de arremesso que voam de ponta (as outras giram no ar).
const DE_PONTA := ["azagaia", "lanca", "tridente", "dardo"]

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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_MUNICOES))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_ARTE))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_MUNICAO_ARTE))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_ICONES))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_QUADROS))
	for id in TABELA:
		_desenhar(id, TABELA[id]).save_png(PASTA_ARTE + id + ".png")
		_icone(id, TABELA[id]).save_png(PASTA_ICONES + id + ".png")
		if QUADROS.has(id) or _e_disparo(id):
			(_folha_de_quadros(id) if QUADROS.has(id) else _folha_disparo(id)).save_png(PASTA_QUADROS + id + ".png")
	for id in MUNICOES:
		_desenhar_municao(id).save_png(PASTA_MUNICAO_ARTE + id + ".png")
		_icone_municao(id).save_png(PASTA_ICONES + id + ".png")
	var faltando := TABELA.keys().filter(func(id: String) -> bool: return _falta_arte(id))
	if not faltando.is_empty():
		print("Sprites gerados. Rode --import e depois este script de novo para criar os .tres.")
		quit()
		return
	for id in TABELA:
		ResourceSaver.save(_criar(id, TABELA[id]), PASTA_DADOS + id + ".tres")
	for id in MUNICOES:
		ResourceSaver.save(_criar_municao(id), PASTA_MUNICOES + id + ".tres")
	_atualizar_soco()
	print("%d armas e %d munições geradas." % [TABELA.size(), MUNICOES.size()])
	quit()


## Alguma imagem da arma ainda não foi importada (sprite, ícone ou quadros)?
func _falta_arte(id: String) -> bool:
	var falta_quadros := (QUADROS.has(id) or _e_disparo(id)) and not ResourceLoader.exists(PASTA_QUADROS + id + ".png")
	var falta_municao := false
	for mid in MUNICOES:
		if not ResourceLoader.exists(PASTA_MUNICAO_ARTE + mid + ".png") or not ResourceLoader.exists(PASTA_ICONES + mid + ".png"):
			falta_municao = true
	return falta_municao or not ResourceLoader.exists(PASTA_ARTE + id + ".png") or not ResourceLoader.exists(PASTA_ICONES + id + ".png") or falta_quadros


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
	a.arremesso_de_ponta = id in DE_PONTA
	if d[7] != "":
		var partes: PackedStringArray = (d[7] as String).split("/")
		if "D" in props:
			a.disparo_normal_pes = float(partes[0])
			a.disparo_longo_pes = float(partes[1])
			a.municao = d[13]
			a.recarga = "G" in props
			a.besta = "X" in props
		else:
			a.arremesso_normal_pes = float(partes[0])
			a.arremesso_longo_pes = float(partes[1])
	a.maestria = d[8]
	a.peso = d[9]
	a.preco = d[10]
	a.livro = LIVRO
	a.textura = load(PASTA_ARTE + id + ".png")
	a.icone = load(PASTA_ICONES + id + ".png")
	a.angulo_arte = _angulo_aereo(id) if _e_do_pacote(id) else _angulo_da_arte(d[11])
	var medidas := geometria(a.textura.get_image(), a.angulo_arte)
	a.pegada = _pegada_aerea(id, a.textura.get_image()) if _e_do_pacote(id) else medidas[0]
	a.comprimento = snappedf(medidas[1], 0.1)
	if a.disparavel():
		a.poses = []
		a.passo = 0.0
		a.efeito = &""
		_aplicar_disparo(a, id)
	elif QUADROS.has(id):
		_aplicar_quadros(a, id)
		a.passo = _passo(a, PONTA_ALCANCE if a.alcance_estendido else PONTA_NORMAL)
		a.efeito = _efeito(a, id)
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
	if _e_do_pacote(id):
		return _icone_aereo(PACOTE_AEREO[id])
	if _e_fogo(id):
		return _arte_fogo(id)
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


## Munição empilhável. A flecha reusa a arte do pacote; o resto é desenhado apontando para a direita.
func _criar_municao(id: String) -> Municao:
	var d: Array = MUNICOES[id]
	var m := Municao.new()
	m.nome = d[0]
	m.descricao = "Munição. Empilha na mochila. (%s)" % d[1]
	m.empilhavel = true
	m.textura = load(PASTA_MUNICAO_ARTE + id + ".png")
	m.icone = load(PASTA_ICONES + id + ".png")
	m.angulo_arte = MUNICAO_AEREO[id][1]
	m.impulso = d[2]
	m.peso = d[3]
	return m


func _desenhar_municao(id: String) -> Image:
	return _municao_aerea(id)


func _icone_municao(id: String) -> Image:
	return FerramentasPixel.reduzir(_icone_aereo(MUNICAO_AEREO[id][0]), TAMANHO_ICONE)


# --- Cores dos quadros desenhados (funda e zarabatana) -------------------------

const COR_MADEIRA := Color8(120, 72, 40)
const COR_MADEIRA_CLARA := Color8(176, 122, 70)
const COR_PEDRA := Color8(110, 108, 100)


# --- Ícones dos menus (16x16) ---------------------------------------------------

## Ícone do menu: o ícone original do pacote (com a cor da variação), reduzido pela metade.
## O chicote, desenhado por script, ganha um ícone enrolado.
func _icone(id: String, d: Array) -> Image:
	var fonte: String = d[11]
	if _e_do_pacote(id):
		return FerramentasPixel.reduzir(_icone_aereo(PACOTE_AEREO[id]), TAMANHO_ICONE)
	if _e_fogo(id):
		return _icone_fogo(id)
	if fonte == "":
		return _icone_chicote()
	var img := Image.load_from_file(ProjectSettings.globalize_path(PASTA_FONTE + fonte + ".png"))
	img.convert(Image.FORMAT_RGBA8)
	_variar(img, VARIACOES.get(id, ""), Vector2.from_angle(deg_to_rad(_angulo_da_arte(fonte))))
	return FerramentasPixel.reduzir(img, TAMANHO_ICONE)



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
## Disparo: 8 quadros (preparo, sobe, mira, puxa, puxa, cheio, soltura, volta). A mão (a
## empunhadura) fica no mesmo ponto em todos.
const QUADROS_DO_DISPARO := 9
const TAMANHO_DISPARO := Vector2i(112, 96)
const MAO_DISPARO := Vector2(46, 50)

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


func _e_disparo(id: String) -> bool:
	return "D" in str(TABELA[id][5])


## Folha dos 8 quadros do disparo.
func _folha_disparo(id: String) -> Image:
	var folha := Image.create(TAMANHO_DISPARO.x * QUADROS_DO_DISPARO, TAMANHO_DISPARO.y, false, Image.FORMAT_RGBA8)
	for i in QUADROS_DO_DISPARO:
		var quadro := Image.create(TAMANHO_DISPARO.x, TAMANHO_DISPARO.y, false, Image.FORMAT_RGBA8)
		if i == DESCANSO:
			quadro = _quadro_descanso(id)
		else:
			_quadro_disparo(quadro, id, i)
		if not (_e_do_pacote(id) or _e_fogo(id)) or id in ["funda", "zarabatana"]:
			_contornar(quadro)  # a arte do pacote e a das armas de fogo já têm contorno
		folha.blit_rect(quadro, Rect2i(Vector2i.ZERO, TAMANHO_DISPARO), Vector2i(i * TAMANHO_DISPARO.x, 0))
	return folha


func _aplicar_disparo(a: Arma, id: String) -> void:
	var folha: Texture2D = load(PASTA_QUADROS + id + ".png")
	a.pegada_quadros = MAO_DISPARO
	a.quadros_disparo = []
	for i in QUADROS_DO_DISPARO:
		var quadro := AtlasTexture.new()
		quadro.atlas = folha
		quadro.region = Rect2(i * TAMANHO_DISPARO.x, 0, TAMANHO_DISPARO.x, TAMANHO_DISPARO.y)
		a.quadros_disparo.append(quadro)


func _quadro_disparo(img: Image, id: String, passo: int) -> void:
	if _e_do_pacote(id) and (_e_arco(id) or id.begins_with("besta")):
		_quadro_pacote(img, id, passo)
		return
	match id:
		"funda":
			_quadro_funda(img, passo)
		"zarabatana":
			_quadro_sopro(img, passo)
		"mosquete", "pistola":
			_quadro_fogo(img, passo, id)


# --- Quadros do disparo ---------------------------------------------------------
# 8 quadros com o herói na pose de mira (braço esticado na altura do peito). A empunhadura
# fica sempre na mão (MAO_DISPARO), e a camada da mão do herói é desenhada por cima dela.
# 0 preparo (arma baixa), 1 sobe, 2 mira, 3 e 4 puxa/arma, 5 cheio, 6 soltura, 7 volta,
# 8 descanso (fora do tiro: arma baixa e relaxada na mão, sem munição, sem fumaça).

## Inclinação da arma (graus; + = ponta para baixo) em cada quadro, comum a todas.
const INCLINACAO_DISPARO: Array[float] = [32.0, 16.0, 2.0, 0.0, 0.0, 0.0, -8.0, 10.0, 40.0]
## Quadro de descanso e quanto abaixo da mão (px) a arma pode ir parada: a mão do herói
## parado fica 18 px acima dos pés, então a ponta para 2 px acima do chão.
const DESCANSO := 8
const ABAIXO_DA_MAO_PARADO := 16
## No descanso, a inclinação desce em passos até a arma não passar do chão.
const PASSO_INCLINACAO := 4.0
## Armas compridas descansam em riste (ponta para cima, graus negativos): não encostam no
## chão nem cruzam o corpo. As outras começam apontando para baixo (INCLINACAO_DISPARO).
const DESCANSO_EM_RISTE := {"besta_leve": -55.0, "besta_pesada": -60.0, "mosquete": -62.0}
## Coice (px para trás) na soltura e na volta.
const COICE: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 1.0, 0.0]
const COR_PELE := Color8(236, 180, 140)
const COR_FUMACA := Color(0.78, 0.8, 0.84, 0.85)
const COR_CLARAO := Color8(255, 214, 110)

## Inclinação usada no quadro de descanso (ajustada por arma em _quadro_descanso).
var _inclinacao_descanso := 40.0



## Descanso: começa inclinada (ponta para baixo e à frente) e endireita até nada passar
## de ABAIXO_DA_MAO_PARADO px abaixo da mão (as compridas não entram no chão).
func _quadro_descanso(id: String) -> Image:
	_inclinacao_descanso = DESCANSO_EM_RISTE.get(id, INCLINACAO_DISPARO[DESCANSO])
	while true:
		var img := Image.create(TAMANHO_DISPARO.x, TAMANHO_DISPARO.y, false, Image.FORMAT_RGBA8)
		_quadro_disparo(img, id, DESCANSO)
		var usado := img.get_used_rect()
		if usado.end.y <= MAO_DISPARO.y + ABAIXO_DA_MAO_PARADO or _inclinacao_descanso <= DESCANSO_EM_RISTE.get(id, 0.0):
			return img
		_inclinacao_descanso -= PASSO_INCLINACAO
	return null

## Dedos da mão de trás (a que puxa a corda ou segura o cano), quando aparece.
func _dedos(img: Image, p: Vector2) -> void:
	_disco(img, p, 1.6, COR_PELE)


## Funda: o bolso gira em volta da mão, cada vez mais rápido, e abre para a frente.
func _quadro_funda(img: Image, passo: int) -> void:
	var angulos: Array[float] = [80.0, 150.0, 220.0, 290.0, 360.0, 430.0, -25.0, 95.0, 92.0]
	var raios: Array[float] = [10.0, 12.0, 14.0, 15.0, 16.0, 16.0, 18.0, 11.0, 9.0]
	var bolso := MAO_DISPARO + Vector2.from_angle(deg_to_rad(angulos[passo])) * raios[passo]
	_linha(img, MAO_DISPARO, bolso, COR_COURO, 1)
	_linha(img, MAO_DISPARO + Vector2(0, 1), bolso + Vector2(0, 1), COR_COURO_CLARO, 1)
	if passo == 6:
		_disco(img, bolso, 1.6, COR_COURO)  # o bolso aberto, vazio
		return
	_disco(img, bolso, 2.6, COR_COURO)
	if passo < 7:
		_disco(img, bolso, 1.6, COR_PEDRA)
	if passo >= 3 and passo <= 5:  # rastro do giro
		var antes := MAO_DISPARO + Vector2.from_angle(deg_to_rad(angulos[passo] - 40.0)) * raios[passo]
		_linha(img, antes, bolso, Color(1, 1, 1, 0.35), 1)


## Zarabatana: o tubo sobe até a boca (acima e atrás da mão); na soltura, sopro de ar.
func _quadro_sopro(img: Image, passo: int) -> void:
	if passo == DESCANSO:  # em pé na mão, a ponta para cima
		_linha(img, MAO_DISPARO + Vector2(-5, 8), MAO_DISPARO + Vector2(9, -28), COR_MADEIRA, 3)
		_linha(img, MAO_DISPARO + Vector2(-6, 7), MAO_DISPARO + Vector2(8, -29), COR_MADEIRA_CLARA, 1)
		return
	var boca := Vector2(-9.0, -19.0)
	var subidas: Array[float] = [0.0, 0.45, 0.85, 1.0, 1.0, 1.0, 1.0, 0.6, 0.0]
	var tras := Vector2(-2.0, 2.0).lerp(boca, subidas[passo])
	var frente := tras + Vector2(38.0, 6.0 * (1.0 - subidas[passo]) + 1.0)
	_linha(img, MAO_DISPARO + tras, MAO_DISPARO + frente, COR_MADEIRA, 3)
	_linha(img, MAO_DISPARO + tras + Vector2(0, -1), MAO_DISPARO + frente + Vector2(0, -1), COR_MADEIRA_CLARA, 1)
	if passo >= 3 and passo <= 5:  # bochecha cheia de ar
		_disco(img, MAO_DISPARO + boca + Vector2(-2.0, 0.0), 2.0 + (passo - 3) * 0.5, Color(1, 1, 1, 0.5))
	if passo == 6:
		_disco(img, MAO_DISPARO + frente + Vector2(3, 0), 2.5, Color(0.9, 0.95, 1.0, 0.85))
		_disco(img, MAO_DISPARO + frente + Vector2(7, -1), 1.5, Color(0.9, 0.95, 1.0, 0.6))


## Armas de fogo (pederneira) em pixel art no estilo do pacote: contorno escuro, madeira,
## aço e latão. Uma letra por pixel (PALETA_FOGO); "." = vazio. O cano aponta para a direita.
const PALETA_FOGO := {
	"o": Color8(43, 34, 32), "W": Color8(124, 74, 42), "w": Color8(168, 108, 60), "d": Color8(86, 50, 30),
	"S": Color8(112, 116, 128), "s": Color8(178, 184, 196), "K": Color8(64, 66, 76),
	"B": Color8(196, 150, 60), "b": Color8(236, 200, 110),
}
const ARTE_PISTOLA: Array[String] = [
	"......oo",
	".....oKKo",
	"......oKooooooooooooooooooo",
	".....oosssssssssssssssssssbo",
	"....oWwoSSSSSSSSSSSSSSSSSSBo",
	"...oWwWWoKKKKKKKKKKKKKKKKKoo",
	"..oWwWWdwwwwwwwwwwwwwBwdoo",
	"..oWWWdoooKooooooooooooo",
	".oWwWdo..oKKo",
	".oWWdo....ooo",
	"oBbBo",
	".ooo",
]
const ARTE_MOSQUETE: Array[String] = [
	"............oo",
	"...........oKKo",
	"............oKoooooooooooooooooooooooooooooooooooooooooo",
	"...........oosssssssssssssssssssssssssssssssssssssssssbo",
	"ooo.......oWwoSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSBo",
	"obwooooooooWwWoKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKoo",
	"oBwwwwwwwwwwWWWwwwwwwwwwBwwwwwwwwwwwwwwBwwwwwwwwwwdoo",
	"oBWWWWWWWWWWWdooKooWWWWWBWWWWWWWWWWWWWWBWWWWWWWWdoo",
	"oBWWWWWWWWWdoo.oKKooddddBddddddddddddddBddddddoo",
	"oBdddddddoo.....ooo.oooooooooooooooooooooooooo",
	"oooooooo",
]
## Pontos na arte: a mão (empunhadura), a boca do cano, a pederneira e a mão de baixo.
const PONTOS_FOGO := {
	"pistola": {"mao": Vector2(5.5, 7.5), "boca": Vector2(27.5, 3.5), "pederneira": Vector2(7.5, 2.5)},
	"mosquete": {"mao": Vector2(14.5, 7.5), "boca": Vector2(55.5, 3.5), "pederneira": Vector2(13.5, 2.5), "apoio": Vector2(31.5, 8.5)},
}


func _e_fogo(id: String) -> bool:
	return PONTOS_FOGO.has(id)


func _arte_fogo(id: String) -> Image:
	var linhas: Array[String] = ARTE_PISTOLA if id == "pistola" else ARTE_MOSQUETE
	var largura := 0
	for linha in linhas:
		largura = maxi(largura, linha.length())
	var img := Image.create(largura, linhas.size(), false, Image.FORMAT_RGBA8)
	for y in linhas.size():
		for x in linhas[y].length():
			var letra := linhas[y][x]
			if PALETA_FOGO.has(letra):
				img.set_pixel(x, y, PALETA_FOGO[letra])
	return img


## Ícone da arma de fogo: a arte na diagonal (como os ícones do pacote) num quadrado de
## 2x (pistola) ou 4x (mosquete) o ícone, reduzido para 16x16.
func _icone_fogo(id: String) -> Image:
	var arte := _arte_fogo(id)
	var lado := TAMANHO_ICONE * (2 if id == "pistola" else 4)
	var quadrado := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
	var centro_arte := Vector2(arte.get_size()) / 2.0
	var volta := deg_to_rad(ANGULO_PONTA_PACOTE)
	for y in lado:
		for x in lado:
			var rel := Vector2(x, y) + Vector2(0.5, 0.5) - Vector2(lado, lado) / 2.0
			var src := Vector2i((rel.rotated(-volta) + centro_arte).floor())
			if Rect2i(Vector2i.ZERO, arte.get_size()).has_point(src):
				quadrado.set_pixel(x, y, arte.get_pixelv(src))
	return FerramentasPixel.reduzir(quadrado, TAMANHO_ICONE)


## Armas de fogo: sobe e mira firme; na soltura faísca na pederneira, clarão, coice para
## cima e fumaça que sobe e se espalha na volta. O mosquete tem a outra mão sob o cano.
func _quadro_fogo(img: Image, passo: int, id: String) -> void:
	var arte := _arte_fogo(id)
	var pontos: Dictionary = PONTOS_FOGO[id]
	var margem := Vector2(MARGEM_ICONE, MARGEM_ICONE)
	var tela := _tela_do_icone(arte)
	tela.blit_rect(arte, Rect2i(Vector2i.ZERO, arte.get_size()), Vector2i(margem))
	var inclinacao := _inclinacao_descanso if passo == DESCANSO else INCLINACAO_DISPARO[passo]
	var coice := Vector2(-COICE[passo], 0.0)
	var pivo: Vector2 = pontos["mao"] + margem
	_girar_para(img, tela, pivo, inclinacao, coice)
	var na_tela := func(p: Vector2) -> Vector2:
		return MAO_DISPARO + coice + (p + margem - pivo).rotated(deg_to_rad(inclinacao))
	if pontos.has("apoio") and passo >= 1 and passo < DESCANSO:
		_dedos(img, na_tela.call(pontos["apoio"]))
	var ponta: Vector2 = na_tela.call(pontos["boca"])
	if passo == 6:
		_disco(img, na_tela.call(pontos["pederneira"]), 1.5, COR_CLARAO)
		_disco(img, ponta + Vector2(4, 0), 4.0 if id == "pistola" else 5.0, COR_CLARAO)
		_disco(img, ponta + Vector2(4, 0), 2.5, COR_ESTALO)
		_disco(img, ponta + Vector2(10, -2), 3.0, COR_FUMACA)
	elif passo == 7:
		for i in 3:
			_disco(img, ponta + Vector2(6 + i * 4, -3 - i * 3), 3.0 + i, Color(COR_FUMACA, 0.7 - i * 0.18))


# --- Armas à distância do pacote CC0 Idylwild's Aerial Arsenal -------------------
# Arcos, bestas, funda e zarabatana usam a arte do pacote (32x32, na diagonal). Os quadros
# do disparo dos arcos e bestas são montados em cima dela, no espaço do ÍCONE (tira-se a
# corda original e desenha-se a puxada; a flecha do pacote vai encaixada) e depois girados
# para o espaço do herói, com a empunhadura na mão (MAO_DISPARO).

const PASTA_AEREO := "res://assets/armas/fonte_aereo/"
## id da arma -> ícone do pacote.
const PACOTE_AEREO := {
	"arco_curto": "bow1", "arco_longo": "bow2", "besta_mao": "crossbow3", "besta_leve": "crossbow2",
	"besta_pesada": "crossbow4", "funda": "sling", "zarabatana": "blowgun",
}
## Para onde a arma aponta NO ÍCONE (graus). Arco: a barriga (para baixo e à direita);
## besta, funda e zarabatana: a ponta (para cima e à direita).
const ANGULO_ARCO_PACOTE := 45.0
const ANGULO_PONTA_PACOTE := -45.0
## Munição: id -> [ícone do pacote, ângulo da ponta no ícone, tamanho do projétil (0 = 32)].
const MUNICAO_AEREO := {
	"flecha": ["arrow1", -45.0, 0], "virote": ["bolt1", -45.0, 0], "agulha": ["blowgundart", -45.0, 0],
	"pedra_funda": ["stone", 0.0, 8], "bala": ["metalball", 0.0, 8],
}
## Corda puxada: cor e quanto recua (px no ícone) em cada quadro (0 = parada).
const COR_CORDA_PACOTE := Color8(43, 34, 32)
const PUXAO_ARCO: Array[float] = [1.0, 1.0, 2.0, 4.0, 6.0, 8.0, 0.0, 0.0, 0.0]
## Margem em volta do ícone para a corda puxada caber (px).
const MARGEM_ICONE := 20
## Arco inclinado para a frente no disparo (graus): o braço de cima não cobre o rosto.
const CANTO_ARCO := 30.0
## O pacote tem os dois arcos do mesmo tamanho: o longo é desenhado maior (na mesma passada do giro).
const ESCALA_ARCO := {"arco_longo": 1.3}
## Besta: a mão fica nesta fração do comprimento, a partir da coronha (no gatilho).
const GATILHO := 0.35
const COR_ESTALO_BESTA := Color(1.0, 0.97, 0.85, 0.9)


func _e_do_pacote(id: String) -> bool:
	return PACOTE_AEREO.has(id)


func _e_arco(id: String) -> bool:
	return id in ["arco_curto", "arco_longo"]


func _icone_aereo(nome: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(PASTA_AEREO + nome + ".png"))
	img.convert(Image.FORMAT_RGBA8)
	return img


func _angulo_aereo(id: String) -> float:
	return ANGULO_ARCO_PACOTE if _e_arco(id) else ANGULO_PONTA_PACOTE


## Pixels da corda do arco: pretos, com os dois vizinhos na direção da barriga vazios
## (o contorno dos braços tem madeira de um dos lados).
func _corda_do_arco(img: Image) -> Array[Vector2i]:
	var corda: Array[Vector2i] = []
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5 or c.get_luminance() > 0.08:
				continue
			if _vazio(img, Vector2i(x + 1, y + 1)) and _vazio(img, Vector2i(x - 1, y - 1)):
				corda.append(Vector2i(x, y))
	return corda


func _vazio(img: Image, p: Vector2i) -> bool:
	return not Rect2i(Vector2i.ZERO, img.get_size()).has_point(p) or img.get_pixelv(p).a < 0.5


## Pegada do arco: o ponto da barriga mais longe da corda, no meio (a empunhadura de couro).
func _pegada_do_arco(img: Image) -> Vector2:
	var corda := _corda_do_arco(img)
	var meio := Vector2.ZERO
	for p in corda:
		meio += Vector2(p)
	meio /= maxf(corda.size(), 1.0)
	var barriga := Vector2.from_angle(deg_to_rad(ANGULO_ARCO_PACOTE))
	var melhor := meio
	for y in img.get_height():
		for x in img.get_width():
			var p := Vector2(x, y) + Vector2(0.5, 0.5)
			if img.get_pixel(x, y).a > 0.5 and absf((p - meio).dot(barriga.orthogonal())) < 1.5 \
					and (p - meio).dot(barriga) > (melhor - meio).dot(barriga):
				melhor = p
	return melhor - barriga * 1.5


## Pegada da besta: no gatilho, um pouco à frente da coronha.
func _pegada_da_besta(img: Image) -> Vector2:
	var medidas := geometria(img, ANGULO_PONTA_PACOTE)
	var frente := Vector2.from_angle(deg_to_rad(ANGULO_PONTA_PACOTE))
	return medidas[0] - frente * PEGADA_ARTE + frente * (medidas[1] + PEGADA_ARTE) * GATILHO


func _pegada_aerea(id: String, img: Image) -> Vector2:
	if _e_arco(id):
		return _pegada_do_arco(img)
	if id.begins_with("besta"):
		return _pegada_da_besta(img)
	return geometria(img, ANGULO_PONTA_PACOTE)[0]


## Quadro do disparo de arco ou besta: monta no ícone e gira para a mão do herói.
func _quadro_pacote(img: Image, id: String, passo: int) -> void:
	var icone := _icone_aereo(PACOTE_AEREO[id])
	var pegada := _pegada_aerea(id, icone)
	var inclinacao := _inclinacao_descanso if passo == DESCANSO else INCLINACAO_DISPARO[passo]
	var giro := inclinacao - _angulo_aereo(id)
	var coice := Vector2(-COICE[passo], 0.0)
	var deslocar := Vector2i(MARGEM_ICONE, MARGEM_ICONE)
	if _e_arco(id):
		if passo == 6 or passo == 7:  # o arco fica firme; só a corda vibra
			inclinacao = 0.0
			giro = -_angulo_aereo(id)
		_quadro_arco_pacote(img, icone, pegada + Vector2(deslocar), passo, inclinacao, giro, coice, ESCALA_ARCO.get(id, 1.0))
		return
	var tela := _tela_do_icone(icone)
	tela.blit_rect(icone, Rect2i(Vector2i.ZERO, icone.get_size()), deslocar)
	if passo == 6:  # soltura: estalo na frente do arco da besta
		var frente := Vector2.from_angle(deg_to_rad(ANGULO_PONTA_PACOTE))
		var alcance: float = geometria(icone, ANGULO_PONTA_PACOTE)[1]
		_disco(tela, pegada + frente * alcance + Vector2(deslocar), 2.5, COR_ESTALO_BESTA)
	_girar_para(img, tela, pegada + Vector2(deslocar), giro, coice)


## Tela com margem em volta do ícone (para girar sem cortar).
func _tela_do_icone(icone: Image) -> Image:
	return Image.create(icone.get_width() + MARGEM_ICONE * 2, icone.get_height() + MARGEM_ICONE * 2, false, Image.FORMAT_RGBA8)


## Arco: o arco (sem a corda) vai inclinado para a frente (CANTO_ARCO), longe do rosto; a
## corda e a flecha são desenhadas já na tela do herói, com a flecha reta na linha da mão.
func _quadro_arco_pacote(img: Image, icone: Image, pivo: Vector2, passo: int, inclinacao: float, giro: float, coice: Vector2, escala: float) -> void:
	var corda := _corda_do_arco(icone)
	var limpo := _tela_do_icone(icone)
	limpo.blit_rect(icone, Rect2i(Vector2i.ZERO, icone.get_size()), Vector2i(MARGEM_ICONE, MARGEM_ICONE))
	var meio := Vector2.ZERO
	for p in corda:
		limpo.set_pixelv(p + Vector2i(MARGEM_ICONE, MARGEM_ICONE), Color(0, 0, 0, 0))
		meio += Vector2(p) + Vector2(MARGEM_ICONE, MARGEM_ICONE) + Vector2(0.5, 0.5)
	meio /= maxf(corda.size(), 1.0)
	var giro_arco := giro + (0.0 if passo == DESCANSO else CANTO_ARCO)
	_girar_para(img, limpo, pivo, giro_arco, coice, escala)
	var ao_longo := Vector2(1, -1).normalized()
	var pontas: Array[Vector2i] = corda.duplicate()
	pontas.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return Vector2(a).dot(ao_longo) < Vector2(b).dot(ao_longo))
	var na_tela := func(p: Vector2i) -> Vector2:
		var no_icone := Vector2(p) + Vector2(MARGEM_ICONE, MARGEM_ICONE) + Vector2(0.5, 0.5)
		return MAO_DISPARO + coice + (no_icone - pivo).rotated(deg_to_rad(giro_arco)) * escala
	var baixo: Vector2 = na_tela.call(pontas.front())
	var cima: Vector2 = na_tela.call(pontas.back())
	if passo == 6:  # soltura: a corda vibra
		var lado := Vector2(1.2, 0.0)
		for i in 4:
			var sinal := 1.0 if i % 2 == 0 else -1.0
			_linha(img, baixo.lerp(cima, i / 4.0) + lado * sinal, baixo.lerp(cima, (i + 1) / 4.0) - lado * sinal, COR_CORDA_PACOTE, 1)
		return
	if passo >= 7:
		_linha(img, baixo, cima, COR_CORDA_PACOTE, 1)
		return
	var recuo := (meio - pivo).length() * escala + PUXAO_ARCO[passo]
	var encaixe := MAO_DISPARO + coice + Vector2(-recuo, 0.0).rotated(deg_to_rad(inclinacao))
	_linha(img, baixo, encaixe, COR_CORDA_PACOTE, 1)
	_linha(img, cima, encaixe, COR_CORDA_PACOTE, 1)
	var tela_flecha := _tela_do_icone(icone)
	_por_flecha(tela_flecha, pivo + (encaixe - MAO_DISPARO - coice).rotated(-deg_to_rad(giro)))
	_girar_para(img, tela_flecha, pivo, giro, coice)
	if passo >= 2:
		_disco(img, encaixe, 1.4, COR_PELE)


## A flecha do pacote, girada 90° (lossless) para apontar para a barriga, com a cauda no encaixe.
func _por_flecha(tela: Image, encaixe: Vector2) -> void:
	var flecha := _icone_aereo("arrow1")
	flecha.rotate_90(CLOCKWISE)
	var direcao := Vector2.from_angle(deg_to_rad(ANGULO_ARCO_PACOTE))
	var cauda := Vector2.ZERO
	var menor := INF
	for p in _opacos(flecha):
		var proj := (Vector2(p) + Vector2(0.5, 0.5)).dot(direcao)
		if proj < menor:
			menor = proj
			cauda = Vector2(p)
	tela.blend_rect(flecha, Rect2i(Vector2i.ZERO, flecha.get_size()), Vector2i(encaixe - cauda))


## Copia `fonte` girada `graus` em volta de `pivo` para `destino`, com o pivô em MAO_DISPARO
## (mais `deslocar`). Vizinho mais próximo, como o Godot gira um sprite em pixel art.
func _girar_para(destino: Image, fonte: Image, pivo: Vector2, graus: float, deslocar: Vector2, escala: float = 1.0) -> void:
	var volta := -deg_to_rad(graus)
	for y in destino.get_height():
		for x in destino.get_width():
			var rel := Vector2(x, y) + Vector2(0.5, 0.5) - MAO_DISPARO - deslocar
			var src := (rel.rotated(volta) / escala + pivo).floor()
			if Rect2i(Vector2i.ZERO, fonte.get_size()).has_point(Vector2i(src)):
				var cor := fonte.get_pixelv(Vector2i(src))
				if cor.a > 0.0:
					destino.set_pixel(x, y, cor)


# Munição -------------------------------------------------------------------------

func _municao_aerea(id: String) -> Image:
	var d: Array = MUNICAO_AEREO[id]
	var img := _icone_aereo(d[0])
	return FerramentasPixel.reduzir(img, d[2]) if d[2] > 0 else img
