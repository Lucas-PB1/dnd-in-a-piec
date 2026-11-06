extends SceneTree
## Monta as tiras e o SpriteFrames do Goblin Warrior a partir da folha CC0 do soldado
## (MoikMellah, Goblin Corps). Créditos em assets/CREDITOS.md.
##   godot --headless --path . --script res://tools/gerar_goblin_guerreiro.gd
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/gerar_goblin_guerreiro.gd
## A folha é 10×4 células de 32×64; o corpo fica na base da célula. O ataque horizontal
## (chão) ganha a espada do pacote na mão nos quadros em que o braço estica.

const PASTA := "res://features/goblin/sprites/"
const FONTE := PASTA + "fonte_goblin_corps/"
const DESTINO := PASTA + "goblin_guerreiro_frames.tres"
const LARGURA := 56
const ALTURA := 44
const CELULA := Vector2i(32, 64)
## Dentro da célula de 64 px, os pés estão em y = 63. O corte começa um pouco acima da cabeça.
const CORTE_Y := 20
## Punho medido na célula (x, y) e cabo na arte da espada, quadro a quadro do golpe.
const PUNHOS: Array[Vector2i] = [Vector2i(18, 37), Vector2i(31, 41), Vector2i(26, 40)]
const CABOS: Array[Vector2i] = [Vector2i(6, 16), Vector2i(12, 21), Vector2i(12, 19)]
## nome -> [quadros, fps, repete]
const ANIMACOES := {
	"parado": [1, 8.0, true],
	"correr": [6, 10.0, true],
	"atacar": [3, 10.0, false],
	"morrer": [4, 8.0, false],
}


func _initialize() -> void:
	var soldado := Image.load_from_file(ProjectSettings.globalize_path(FONTE + "goblin.soldier.png"))
	var espada := Image.load_from_file(ProjectSettings.globalize_path(FONTE + "sword.png"))
	if soldado == null or espada == null:
		print("Folha do Goblin Corps não encontrada em ", FONTE)
		quit(1)
		return
	var tiras := {
		"parado": _faixa(soldado, espada, 0, 0, 1, false, false),
		"correr": _faixa(soldado, espada, 0, 1, 6, false, false),
		"atacar": _faixa(soldado, espada, 2, 4, 3, false, true),
		"morrer": _morte(soldado),
	}
	for nome: String in tiras:
		var caminho := ProjectSettings.globalize_path(PASTA + "goblin_guerreiro_%s.png" % nome)
		(tiras[nome] as Image).save_png(caminho)
	_imprimir_pes(tiras["parado"])
	_montar_quadros(tiras)
	quit(0)


func _faixa(folha: Image, espada: Image, linha: int, coluna: int, quantidade: int, larga: bool, com_espada: bool) -> Image:
	var tira := Image.create(LARGURA * quantidade, ALTURA, false, Image.FORMAT_RGBA8)
	for i in quantidade:
		var quadro := _quadro(folha, coluna + i, linha, larga)
		if com_espada and i > 0:
			_por_espada(quadro, espada, i)
		tira.blit_rect(quadro, Rect2i(Vector2i.ZERO, Vector2i(LARGURA, ALTURA)), Vector2i(i * LARGURA, 0))
	return tira


## Dano (dois quadros) e os dois de caído. O caído ocupa duas células, deitado no chão.
func _morte(folha: Image) -> Image:
	var quadros: Array[Image] = [
		_quadro(folha, 1, 1, false),
		_quadro(folha, 2, 1, false),
		_quadro(folha, 4, 1, true),
		_quadro(folha, 6, 1, true),
	]
	var tira := Image.create(LARGURA * quadros.size(), ALTURA, false, Image.FORMAT_RGBA8)
	for i in quadros.size():
		tira.blit_rect(quadros[i], Rect2i(Vector2i.ZERO, Vector2i(LARGURA, ALTURA)), Vector2i(i * LARGURA, 0))
	return tira


func _quadro(folha: Image, coluna: int, linha: int, larga: bool) -> Image:
	var quadro := Image.create(LARGURA, ALTURA, false, Image.FORMAT_RGBA8)
	var origem := Vector2i(coluna * CELULA.x, linha * CELULA.y + CORTE_Y)
	var largura_fonte := LARGURA if larga else CELULA.x
	quadro.blit_rect(folha, Rect2i(origem, Vector2i(largura_fonte, ALTURA)), Vector2i.ZERO)
	return quadro


## Encaixa o cabo da espada no punho. O primeiro quadro é a guarda; a lâmina sai nos dois seguintes.
func _por_espada(quadro: Image, espada: Image, indice: int) -> void:
	var punho := PUNHOS[indice]
	var cabo := CABOS[indice]
	var destino := Vector2i(punho.x - cabo.x, punho.y - CORTE_Y - cabo.y)
	quadro.blend_rect(espada, Rect2i(indice * CELULA.x, 0, CELULA.x, CELULA.x), destino)


## Prefere a textura importada. Na primeira rodada, antes do --import, grava a imagem
## dentro do SpriteFrames para a cena já abrir.
func _montar_quadros(tiras: Dictionary) -> void:
	var quadros := SpriteFrames.new()
	quadros.remove_animation(&"default")
	for nome: String in ANIMACOES:
		var d: Array = ANIMACOES[nome]
		var caminho := PASTA + "goblin_guerreiro_%s.png" % nome
		var atlas_tex: Texture2D = load(caminho) if ResourceLoader.exists(caminho) else null
		if atlas_tex == null:
			atlas_tex = ImageTexture.create_from_image(tiras[nome])
		quadros.add_animation(nome)
		quadros.set_animation_speed(nome, d[1])
		quadros.set_animation_loop(nome, d[2])
		for i in int(d[0]):
			var quadro := AtlasTexture.new()
			quadro.atlas = atlas_tex
			quadro.region = Rect2(Vector2(i * LARGURA, 0), Vector2(LARGURA, ALTURA))
			quadros.add_frame(nome, quadro)
	ResourceSaver.save(quadros, DESTINO)
	print("Quadros salvos em ", DESTINO)


## Pés no meio da base do corpo, para o offset do sprite (a cena põe os pés na origem).
func _imprimir_pes(parado: Image) -> void:
	var corpo := parado.get_region(Rect2i(Vector2i.ZERO, Vector2i(LARGURA, ALTURA))).get_used_rect()
	var pes := Vector2(corpo.position.x + corpo.size.x * 0.5, corpo.end.y - 1)
	var offset := Vector2(LARGURA * 0.5 - pes.x, ALTURA * 0.5 - pes.y)
	print("1º quadro parado: ", corpo, " offset sugerido: ", offset)
