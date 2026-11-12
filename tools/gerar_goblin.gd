extends SceneTree
## Monta o SpriteFrames do Goblin Minion a partir das tiras PNG (convertidas dos GIFs CC0 de
## thekingphoenix, "Goblin Free Pixelart"; créditos em assets/CREDITOS.md).
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/gerar_goblin.gd
## Cada tira tem quadros de 48x32 (o ataque é mais largo por causa da lança). A arte olha
## para a direita. Também imprime onde ficam os pés e o meio do corpo no 1º quadro parado,
## para acertar o `offset` do sprite na cena.

const PASTA := "res://features/humanoides/sprites/"
const DESTINO := PASTA + "goblin_frames.tres"
const TAMANHO_QUADRO := Vector2i(48, 32)
## nome da animação -> [quantidade de quadros, fps, repete]. O pacote usa 0,1 s por quadro.
const ANIMACOES := {
	"parado": [19, 10.0, true],
	"correr": [8, 10.0, true],
	"atacar": [3, 10.0, false],
	"morrer": [19, 10.0, false],
}


func _initialize() -> void:
	var quadros := SpriteFrames.new()
	quadros.remove_animation(&"default")
	for nome: String in ANIMACOES:
		var d: Array = ANIMACOES[nome]
		var tira: Texture2D = load(PASTA + "goblin_%s.png" % nome)
		quadros.add_animation(nome)
		quadros.set_animation_speed(nome, d[1])
		quadros.set_animation_loop(nome, d[2])
		for i in int(d[0]):
			var quadro := AtlasTexture.new()
			quadro.atlas = tira
			quadro.region = Rect2(Vector2(i * TAMANHO_QUADRO.x, 0), Vector2(TAMANHO_QUADRO))
			quadros.add_frame(nome, quadro)
	ResourceSaver.save(quadros, DESTINO)
	var parado := Image.load_from_file(ProjectSettings.globalize_path(PASTA + "goblin_parado.png"))
	var corpo := parado.get_region(Rect2i(Vector2i.ZERO, TAMANHO_QUADRO)).get_used_rect()
	print("Quadros salvos em ", DESTINO, ". 1º quadro parado: ", corpo)
	quit()
