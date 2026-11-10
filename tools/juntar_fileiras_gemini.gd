extends SceneTree
## Junta as duas fileiras de uma imagem do Gemini (metade de cima e metade de baixo) numa tira só, que é o que
## `montar_tiras_gemini.gd` espera. Os pés da 2ª fileira costumam ficar mais baixos na imagem: sobe a fileira até a linha do
## chão ficar igual à da 1ª.
## Rodar (sem --debug):
##   godot --headless --path . --script res://tools/juntar_fileiras_gemini.gd -- ENTRADA SAIDA.png

## Distância de cor (soma de R, G e B) a partir da qual um pixel já é desenho e não fundo.
const LIMIAR_DESENHO := 0.45


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Uso: -- ENTRADA SAIDA.png")
		quit(1)
		return
	var imagem := Image.load_from_file(args[0])
	imagem.convert(Image.FORMAT_RGBA8)
	var metade := imagem.get_height() / 2
	var tira := Image.create_empty(imagem.get_width() * 2, metade, false, Image.FORMAT_RGBA8)
	tira.fill(imagem.get_pixel(0, 0))
	var chao_1 := _chao(imagem, 0, metade)
	var chao_2 := _chao(imagem, metade, imagem.get_height()) - metade
	print("Chão: fileira 1 em %d, fileira 2 em %d" % [chao_1, chao_2])
	tira.blit_rect(imagem, Rect2i(0, 0, imagem.get_width(), metade), Vector2i.ZERO)
	tira.blit_rect(imagem, Rect2i(0, metade, imagem.get_width(), metade), Vector2i(imagem.get_width(), chao_1 - chao_2))
	tira.save_png(args[1])
	print("Tira: %dx%d" % [tira.get_width(), tira.get_height()])
	quit(0)


## Linha mais baixa (y) com desenho entre `de` e `ate`: o chão, onde estão os pés.
func _chao(imagem: Image, de: int, ate: int) -> int:
	var fundo := imagem.get_pixel(0, 0)
	for y in range(ate - 1, de - 1, -1):
		for x in imagem.get_width():
			var cor := imagem.get_pixel(x, y)
			if absf(cor.r - fundo.r) + absf(cor.g - fundo.g) + absf(cor.b - fundo.b) > LIMIAR_DESENHO:
				return y
	return ate
