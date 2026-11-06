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


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_ICONES))
	for arquivo in TABELA:
		_icone(arquivo).save_png(ProjectSettings.globalize_path(PASTA_ICONES + arquivo + ".png"))
	if TABELA.keys().any(func(arquivo: String) -> bool: return not ResourceLoader.exists(PASTA_ICONES + arquivo + ".png")):
		print("Ícones gerados. Rode --import e depois este script de novo para criar os .tres.")
		quit()
		return
	for arquivo in TABELA:
		ResourceSaver.save(_criar(arquivo, TABELA[arquivo]), PASTA + arquivo + ".tres")
	print("%d armaduras geradas em %s" % [TABELA.size(), PASTA])
	quit()


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
