extends SceneTree
## Gera um .tres por armadura em data/armaduras/ a partir da TABELA abaixo (as 21 armaduras
## do Empório: Player's Handbook, Obojima e Northlands Worldbook) e os ícones dos menus
## (16x16, do pacote CC0 Idylwild's Armory). Duas passadas, como o gerar_armas:
##   godot --headless --path . --script res://tools/gerar_armaduras.gd   (ícones)
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/gerar_armaduras.gd   (.tres)
## Para mudar uma armadura, edite a tabela e rode de novo (não edite os .tres à mão).

const PASTA := "res://data/armaduras/"
const PASTA_FONTE := "res://assets/armaduras/fonte_idylwild/"
const PASTA_ICONES := "res://assets/armaduras/icones/"
## Ladrilhos de textura das roupas (8x8), repetidos pelo shader no corpo do herói.
const PASTA_TEXTURAS := "res://assets/armaduras/texturas/"
const TAMANHO_LADRILHO := 8
const COR_TACHA := Color(0.86, 0.8, 0.58)
const TAMANHO_ICONE := 16
## Escudos: a mesma arte serve de ícone e de escudo na mão do herói.
const ESCUDOS := ["escudo", "tampa_panela"]
## Pixels mais escuros que isto são contorno e não recebem a tinta.
const LUZ_CONTORNO := 0.15

## Ícone de cada armadura: [ícone do pacote, tinta]. A tinta (multiplica a cor) diferencia
## armaduras do livro que usam o mesmo ícone; branco = como no pacote.
const ICONES := {
	"acolchoada": ["quilted_armor", Color.WHITE],
	"scumweed": ["quilted_armor", Color(0.62, 0.95, 0.6)],
	"couro": ["leather_jacket", Color.WHITE],
	"couro_morsa": ["leather_jacket", Color(0.85, 0.85, 0.9)],
	"couro_batido": ["studded_jacket", Color.WHITE],
	"gibao_peles": ["leather_jacket_alt", Color.WHITE],
	"casca": ["leather_jacket_alt", Color(0.8, 0.95, 0.65)],
	"brunea": ["studded_jacket_alt", Color(1.1, 1.0, 0.75)],
	"camisao_malha": ["chainmail_alt", Color.WHITE],
	"camisao_malha_endurecido": ["chainmail_alt", Color(0.78, 0.8, 0.88)],
	"cota_aneis": ["chainmail_alt", Color(1.05, 0.95, 0.8)],
	"cota_malha": ["chainmail_jacket", Color.WHITE],
	"malha_dupla": ["chainmail_jacket", Color(0.8, 0.82, 0.92)],
	"peitoral": ["breastplate", Color.WHITE],
	"meia_armadura": ["platemail", Color(0.92, 0.92, 0.97)],
	"talas": ["platemail", Color(0.78, 0.78, 0.84)],
	"placas": ["platemail", Color.WHITE],
	"beinagrind": ["platemail", Color(1.05, 0.98, 0.82)],
	"mergulhador": ["close_helmet", Color(1.0, 0.78, 0.48)],
	"escudo": ["wooden_buckler", Color.WHITE],
	"tampa_panela": ["iron_buckler", Color.WHITE],
}

const L := Proficiencias.ARMADURA_LEVE
const M := Proficiencias.ARMADURA_MEDIA
const P := Proficiencias.ARMADURA_PESADA
const E := Proficiencias.ESCUDO
const PHB := "Player’s Handbook"
const OBO := "Obojima"
const NOR := "Northlands Worldbook"

## arquivo: [nome, nome original, categoria, CA, soma DES, máx DES (-1 = sem), Força mín.,
##           desv. Furtividade, peso, preço, livro, cor, padrão visual]
const TABELA := {
	"acolchoada": ["Armadura Acolchoada", "Padded Armor", L, 11, true, -1, 0, true, "8 lb.", "5 GP", PHB, Color(0.85, 0.8, 0.62), Armadura.Padrao.ACOLCHOADO],
	"couro": ["Armadura de Couro", "Leather Armor", L, 11, true, -1, 0, false, "10 lb.", "10 GP", PHB, Color(0.58, 0.37, 0.2), Armadura.Padrao.LISO],
	"couro_batido": ["Couro Batido", "Studded Leather Armor", L, 12, true, -1, 0, false, "13 lb.", "45 GP", PHB, Color(0.46, 0.28, 0.16), Armadura.Padrao.TACHAS],
	"casca": ["Armadura de Casca", "Bark Armor", L, 11, true, -1, 0, false, "14 lb.", "8 GP", OBO, Color(0.45, 0.33, 0.21), Armadura.Padrao.ESCAMAS],
	"gibao_peles": ["Gibão de Peles", "Hide Armor", M, 12, true, 2, 0, false, "12 lb.", "10 GP", PHB, Color(0.62, 0.47, 0.3), Armadura.Padrao.LISO],
	"camisao_malha": ["Camisão de Malha", "Chain Shirt", M, 13, true, 2, 0, false, "20 lb.", "50 GP", PHB, Color(0.7, 0.72, 0.76), Armadura.Padrao.MALHA],
	"brunea": ["Brunea", "Scale Mail", M, 14, true, 2, 0, true, "45 lb.", "50 GP", PHB, Color(0.66, 0.6, 0.48), Armadura.Padrao.ESCAMAS],
	"peitoral": ["Peitoral", "Breastplate", M, 14, true, 2, 0, false, "20 lb.", "400 GP", PHB, Color(0.76, 0.78, 0.82), Armadura.Padrao.PLACAS],
	"meia_armadura": ["Meia-Armadura", "Half Plate Armor", M, 15, true, 2, 0, true, "40 lb.", "750 GP", PHB, Color(0.72, 0.74, 0.79), Armadura.Padrao.PLACAS],
	"camisao_malha_endurecido": ["Camisão de Malha Endurecido", "Hardened Mail Shirt", M, 15, true, 2, 13, true, "40 lb.", "500 GP", NOR, Color(0.55, 0.57, 0.62), Armadura.Padrao.MALHA],
	"scumweed": ["Armadura de Scumweed", "Scumweed Armor", M, 15, true, 1, 0, false, "22 lb.", "60 GP", OBO, Color(0.32, 0.46, 0.3), Armadura.Padrao.ACOLCHOADO],
	"couro_morsa": ["Couro de Morsa", "Walrus Hide", M, 13, true, 2, 0, false, "20 lb.", "75 GP", NOR, Color(0.52, 0.43, 0.35), Armadura.Padrao.LISO],
	"cota_aneis": ["Cota de Anéis", "Ring Mail", P, 14, false, -1, 0, true, "40 lb.", "30 GP", PHB, Color(0.6, 0.6, 0.63), Armadura.Padrao.MALHA],
	"cota_malha": ["Cota de Malha", "Chain Mail", P, 16, false, -1, 13, true, "55 lb.", "75 GP", PHB, Color(0.68, 0.7, 0.75), Armadura.Padrao.MALHA],
	"talas": ["Armadura de Talas", "Splint Armor", P, 17, false, -1, 15, true, "60 lb.", "200 GP", PHB, Color(0.62, 0.62, 0.67), Armadura.Padrao.PLACAS],
	"placas": ["Armadura de Placas", "Plate Armor", P, 18, false, -1, 15, true, "65 lb.", "1,500 GP", PHB, Color(0.83, 0.85, 0.9), Armadura.Padrao.PLACAS],
	"beinagrind": ["Beinagrind", "Beinagrind", P, 15, false, -1, 13, true, "40 lb.", "50 GP", NOR, Color(0.88, 0.85, 0.76), Armadura.Padrao.PLACAS],
	"malha_dupla": ["Malha Dupla", "Double Mail", P, 17, false, -1, 16, true, "65 lb.", "350 GP", NOR, Color(0.58, 0.6, 0.65), Armadura.Padrao.MALHA],
	"mergulhador": ["Armadura de Mergulhador", "Divers Armor", P, 17, false, -1, 16, true, "100 lb.", "2,000 GP", OBO, Color(0.68, 0.55, 0.32), Armadura.Padrao.PLACAS],
	"escudo": ["Escudo", "Shield", E, 2, false, -1, 0, false, "6 lb.", "10 GP", PHB, Color(0.6, 0.37, 0.19), Armadura.Padrao.LISO],
	"tampa_panela": ["Tampa de Panela", "Pot Lid", E, 1, false, -1, 0, false, "2 lb.", "1 GP", OBO, Color(0.5, 0.52, 0.56), Armadura.Padrao.LISO],
}

## Peles grossas: o ladrilho ganha tufo, em vez do couro liso.
const PELES := ["gibao_peles", "couro_morsa"]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_ICONES))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_TEXTURAS))
	for arquivo in TABELA:
		_icone(arquivo).save_png(ProjectSettings.globalize_path(PASTA_ICONES + arquivo + ".png"))
		if TABELA[arquivo][2] != E:
			_textura_corpo(arquivo, TABELA[arquivo]).save_png(ProjectSettings.globalize_path(PASTA_TEXTURAS + arquivo + ".png"))
	if TABELA.keys().any(_falta_arte):
		print("Ícones gerados. Rode --import e depois este script de novo para criar os .tres.")
		quit()
		return
	for arquivo in TABELA:
		ResourceSaver.save(_criar(arquivo, TABELA[arquivo]), PASTA + arquivo + ".tres")
	print("%d armaduras geradas em %s" % [TABELA.size(), PASTA])
	quit()


## Alguma imagem da armadura (ícone ou ladrilho) ainda não foi importada?
func _falta_arte(arquivo: String) -> bool:
	var caminhos: Array[String] = [PASTA_ICONES + arquivo + ".png"]
	if TABELA[arquivo][2] != E:
		caminhos.append(PASTA_TEXTURAS + arquivo + ".png")
	return caminhos.any(func(caminho: String) -> bool: return not ResourceLoader.exists(caminho))


func _criar(arquivo: String, d: Array) -> Armadura:
	var a := Armadura.new()
	a.nome = d[0]
	a.nome_original = d[1]
	a.categoria = d[2]
	a.espaco = Item.ESPACO_MAO_SECUNDARIA if d[2] == E else Item.ESPACO_CORPO
	a.ca_base = d[3]
	a.soma_destreza = d[4]
	a.max_destreza = d[5]
	a.forca_minima = d[6]
	a.desvantagem_furtividade = d[7]
	a.peso = d[8]
	a.preco = d[9]
	a.livro = d[10]
	a.cor = d[11]
	a.padrao = d[12]
	a.icone = load(PASTA_ICONES + arquivo + ".png")
	if arquivo in ESCUDOS:
		a.textura = a.icone  # o broquel do pacote também é o escudo na mão do herói
	else:
		a.detalhe = load(PASTA_TEXTURAS + arquivo + ".png")
	a.descricao = _descricao(a)
	return a


## "Armadura pesada. CA 16. Força 13. Desvantagem em Furtividade. (Chain Mail, Player's Handbook)"
func _descricao(a: Armadura) -> String:
	var partes: PackedStringArray = [_nome_categoria(a.categoria), a.texto_ca()]
	if a.forca_minima > 0:
		partes.append("Força %d" % a.forca_minima)
	if a.desvantagem_furtividade:
		partes.append("Desvantagem em Furtividade")
	return "%s. (%s, %s)" % [". ".join(partes), a.nome_original, a.livro]


func _nome_categoria(categoria: StringName) -> String:
	match categoria:
		L: return "Armadura leve"
		M: return "Armadura média"
		P: return "Armadura pesada"
	return "Escudo"


## Ícone 16x16: o do pacote (com a tinta, se tiver) reduzido pela metade.
func _icone(arquivo: String) -> Image:
	var fonte: String = ICONES[arquivo][0]
	var tinta: Color = ICONES[arquivo][1]
	var img := Image.load_from_file(ProjectSettings.globalize_path(PASTA_FONTE + fonte + ".png"))
	img.convert(Image.FORMAT_RGBA8)
	if tinta != Color.WHITE:
		for y in img.get_height():
			for x in img.get_width():
				var cor := img.get_pixel(x, y)
				if cor.a > 0.0 and cor.get_luminance() >= LUZ_CONTORNO:
					img.set_pixel(x, y, Color(cor.r * tinta.r, cor.g * tinta.g, cor.b * tinta.b, cor.a).clamp())
	return FerramentasPixel.reduzir(img, TAMANHO_ICONE)


# --- Ladrilhos da roupa ------------------------------------------------------------
# 8x8, nas cores da armadura. O shader repete o ladrilho na túnica e guarda a luz da arte.
# Não há peça por cima do corpo: a armadura é só essa pintura.

func _textura_corpo(arquivo: String, d: Array) -> Image:
	var cor: Color = d[11]
	if arquivo in PELES:
		return _pelo(cor)
	if arquivo == "cota_aneis":
		return _ladrilho_aneis(cor)
	return _ladrilho(d[12], cor)


## Peles: tufos claros e escuros, não um couro liso.
func _pelo(cor: Color) -> Image:
	var img := _ladrilho(Armadura.Padrao.LISO, cor)
	var claro := cor.lightened(0.22)
	var escuro := cor.darkened(0.38)
	for p in [Vector2i(1, 2), Vector2i(1, 3), Vector2i(4, 5), Vector2i(4, 6), Vector2i(6, 1), Vector2i(6, 2)]:
		img.set_pixelv(p, escuro)
	for p in [Vector2i(1, 1), Vector2i(4, 4), Vector2i(6, 0)]:
		img.set_pixelv(p, claro)
	return img


## Cota de anéis: couro com anéis separados, costurados, não entrelaçados.
func _ladrilho_aneis(cor: Color) -> Image:
	var couro := Color(0.46, 0.32, 0.22).lerp(cor, 0.2)
	var img := _ladrilho(Armadura.Padrao.LISO, couro)
	_anel_solto(img, Vector2i(2, 2), cor)
	_anel_solto(img, Vector2i(6, 5), cor)
	return img


func _ladrilho(padrao: Armadura.Padrao, cor: Color) -> Image:
	var img := Image.create(TAMANHO_LADRILHO, TAMANHO_LADRILHO, false, Image.FORMAT_RGBA8)
	var claro := cor.lightened(0.25)
	var escuro := cor.darkened(0.35)
	img.fill(cor)
	match padrao:
		Armadura.Padrao.MALHA: _malha(img, cor, claro, escuro)
		Armadura.Padrao.TACHAS: _couro(img, claro, escuro); _tachas(img)
		Armadura.Padrao.PLACAS: _placas(img, cor, claro, escuro)
		Armadura.Padrao.ACOLCHOADO: _acolchoado(img, claro, escuro)
		Armadura.Padrao.ESCAMAS: _escamas(img, cor, claro, escuro)
		_: _couro(img, claro, escuro)
	return img


## Couro: grão escuro salpicado e uma costura clara pontilhada.
func _couro(img: Image, claro: Color, escuro: Color) -> void:
	for p in [Vector2i(2, 5), Vector2i(5, 2), Vector2i(1, 1)]:
		img.set_pixelv(p, escuro)
	for y in range(0, TAMANHO_LADRILHO, 2):
		img.set_pixel(7, y, claro)


## Tachas: dois rebites dourados com brilho em cima.
func _tachas(img: Image) -> void:
	for canto in [Vector2i(1, 2), Vector2i(5, 6)]:
		img.fill_rect(Rect2i(canto, Vector2i(2, 2)), COR_TACHA.darkened(0.2))
		img.set_pixelv(canto, COR_TACHA.lightened(0.3))


## Placas: faixa com borda brilhante em cima, sombra e emenda embaixo, dois rebites.
func _placas(img: Image, cor: Color, claro: Color, escuro: Color) -> void:
	var faixas := [claro, cor.lightened(0.1), cor, cor, cor.darkened(0.1), cor.darkened(0.2), escuro, escuro.darkened(0.3)]
	for y in TAMANHO_LADRILHO:
		img.fill_rect(Rect2i(0, y, TAMANHO_LADRILHO, 1), faixas[y])
	for x in [1, 6]:
		img.set_pixel(x, 2, claro.lightened(0.3))
		img.set_pixel(x, 3, escuro)


## Malha: anéis de 4x4 com o furo escuro; fileiras desencontradas.
func _malha(img: Image, cor: Color, claro: Color, escuro: Color) -> void:
	img.fill(escuro.darkened(0.2))
	for celula_y in 2:
		for celula_x in 2:
			var origem := Vector2i(celula_x * 4 + (2 if celula_y == 1 else 0), celula_y * 4)
			for p in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2)]:
				img.set_pixelv(_no_ladrilho(origem + p), escuro.darkened(0.45))
			for p in [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(0, 2)]:
				img.set_pixelv(_no_ladrilho(origem + p), claro)
			for p in [Vector2i(3, 1), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3)]:
				img.set_pixelv(_no_ladrilho(origem + p), cor)


## Acolchoado: costuras em losango e um ponto claro no meio de cada gomo.
func _acolchoado(img: Image, claro: Color, escuro: Color) -> void:
	for y in TAMANHO_LADRILHO:
		for x in TAMANHO_LADRILHO:
			if (x + y) % TAMANHO_LADRILHO == 0 or (x - y + TAMANHO_LADRILHO) % TAMANHO_LADRILHO == 0:
				img.set_pixel(x, y, escuro)
	img.set_pixel(4, 2, claro)
	img.set_pixel(4, 6, claro)


## Escamas: fileiras de escamas arredondadas, desencontradas.
func _escamas(img: Image, cor: Color, claro: Color, escuro: Color) -> void:
	img.fill(escuro)
	var forma := [[1, 2, claro], [0, 3, cor], [0, 3, cor.darkened(0.1)], [1, 2, escuro.darkened(0.2)]]
	for fileira in 2:
		for coluna in 2:
			var origem := Vector2i(coluna * 4 + (2 if fileira == 1 else 0), fileira * 4)
			for dy in forma.size():
				for dx in range(forma[dy][0], forma[dy][1] + 1):
					img.set_pixelv(_no_ladrilho(origem + Vector2i(dx, dy)), forma[dy][2])


func _no_ladrilho(p: Vector2i) -> Vector2i:
	return Vector2i(posmod(p.x, TAMANHO_LADRILHO), posmod(p.y, TAMANHO_LADRILHO))


## Anel costurado de 3x3. O centro fica com o que já estava (o couro aparece no furo).
func _anel_solto(img: Image, centro: Vector2i, metal: Color) -> void:
	img.set_pixelv(centro + Vector2i(0, -1), metal.lightened(0.35))
	img.set_pixelv(centro + Vector2i(-1, 0), metal.lightened(0.15))
	img.set_pixelv(centro + Vector2i(1, 0), metal.darkened(0.15))
	img.set_pixelv(centro + Vector2i(0, 1), metal.darkened(0.3))
