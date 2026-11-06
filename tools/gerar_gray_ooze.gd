extends SceneTree
## Gera a arte do Gray Ooze a partir do slime azul (CC0, rvros) e o SpriteFrames dele.
##   godot --headless --path . --script res://tools/gerar_gray_ooze.gd
## Depois rode "godot --headless --path . --import".
## Recolore para tons de cinza mantendo os olhos vermelhos. A folha tem 8 colunas de 32x25
## e as animações vêm em ordem: parado 4, andar 4, atacar 5, levar dano 4, morrer 4.

const ORIGEM := "res://features/gray_ooze/sprites/slime_original.png"
const DESTINO_PNG := "res://features/gray_ooze/sprites/gray_ooze.png"
const DESTINO_FRAMES := "res://features/gray_ooze/sprites/gray_ooze_frames.tres"
const TAMANHO_QUADRO := Vector2i(32, 25)
const COLUNAS := 8
## Leve tom esverdeado no cinza (gosma ácida).
const TINTA := Color(0.92, 1.0, 0.9)

## nome -> [primeiro quadro, quantidade, fps, repete]
const ANIMACOES := {
	"parado": [0, 4, 6.0, true],
	"andar": [4, 4, 6.0, true],
	"atacar": [8, 5, 10.0, false],
	"dano": [13, 4, 12.0, false],
	"morrer": [17, 4, 8.0, false],
}


func _initialize() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(ORIGEM))
	_deixar_cinza(img)
	img.save_png(DESTINO_PNG)
	print("Arte cinza salva em ", DESTINO_PNG, ". Rode --import e depois este script de novo para os quadros.")
	if not ResourceLoader.exists(DESTINO_PNG):
		quit()  # primeira vez: o PNG ainda não foi importado
		return
	ResourceSaver.save(_montar_frames(load(DESTINO_PNG)), DESTINO_FRAMES)
	print("SpriteFrames salvo em ", DESTINO_FRAMES)
	quit()


## Troca cada cor pelo seu brilho (cinza), menos os vermelhos (olhos).
func _deixar_cinza(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0 or (c.r > 0.6 and c.g < 0.4):
				continue
			var brilho := 0.3 * c.r + 0.59 * c.g + 0.11 * c.b
			brilho = clampf(brilho * 1.35, 0.0, 1.0)  # o slime azul é escuro; clareia um pouco
			img.set_pixel(x, y, Color(brilho * TINTA.r, brilho * TINTA.g, brilho * TINTA.b, c.a))


func _montar_frames(textura: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for nome in ANIMACOES:
		var dados: Array = ANIMACOES[nome]
		frames.add_animation(nome)
		frames.set_animation_speed(nome, dados[2])
		frames.set_animation_loop(nome, dados[3])
		for i in dados[1]:
			frames.add_frame(nome, _recorte(textura, dados[0] + i))
	return frames


func _recorte(textura: Texture2D, indice: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = textura
	var celula := Vector2i(indice % COLUNAS, indice / COLUNAS)
	atlas.region = Rect2(celula * TAMANHO_QUADRO, TAMANHO_QUADRO)
	return atlas
