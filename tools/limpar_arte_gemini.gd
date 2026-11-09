extends SceneTree
## Limpa uma arte gerada por IA (ex.: Gemini): tira o fundo liso, corta nas bordas do personagem e reduz para o
## tamanho de pixel do jogo, sem suavizar. Também monta uma comparação ao lado do herói e do Goblin Warrior,
## na altura que cada um tem no jogo, para aprovar a escala.
## Rodar (sem --debug):
##   godot --headless --path . --script res://tools/limpar_arte_gemini.gd -- ENTRADA.png SAIDA.png ALTURA_PX COMPARACAO.png
## ALTURA_PX = altura da arte reduzida (o desenho em "pixels"); a altura no jogo sai da escala da cena.

const TOLERANCIA_FUNDO := 0.12
## Alturas, em px do jogo, usadas na comparação.
const ALTURA_HEROI := 73
const ALTURA_WARRIOR := 49
## Altura da arte nova na comparação (px do jogo); o 5º argumento troca.
var _altura_novo := 60
const AMPLIACAO := 4
const MARGEM := 12
const COR_PAINEL := Color(0.16, 0.16, 0.2)
const ARTE_HEROI := "res://features/jogador/sprites/heroi_base.png"
const ARTE_WARRIOR := "res://features/goblin/sprites/warrior_base_spritecook.png"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 4:
		push_error("Uso: -- ENTRADA.png SAIDA.png ALTURA_PX COMPARACAO.png")
		quit(1)
		return
	var imagem := Image.load_from_file(args[0])
	if imagem == null:
		push_error("Não abriu " + args[0])
		quit(1)
		return
	imagem.convert(Image.FORMAT_RGBA8)
	FerramentasPixel.tirar_fundo(imagem, TOLERANCIA_FUNDO)
	var limpa := _aparar(imagem)
	var altura := int(args[2])
	var largura := roundi(limpa.get_width() * float(altura) / limpa.get_height())
	limpa.resize(largura, altura, Image.INTERPOLATE_NEAREST)
	FerramentasPixel.endurecer_alfa(limpa)
	limpa.save_png(args[1])
	print("Arte limpa: %dx%d -> %s" % [limpa.get_width(), limpa.get_height(), args[1]])
	if args.size() > 4:
		_altura_novo = int(args[4])
	_comparar(limpa, args[3])
	quit(0)


func _aparar(imagem: Image) -> Image:
	return imagem.get_region(imagem.get_used_rect())


## Heroi, Goblin Warrior e a arte nova lado a lado, pés alinhados, cada um na altura que tem no jogo.
func _comparar(nova: Image, caminho: String) -> void:
	var figuras: Array[Image] = [
		_na_altura(_carregar(ARTE_HEROI), ALTURA_HEROI),
		_na_altura(_carregar(ARTE_WARRIOR), ALTURA_WARRIOR),
		_na_altura(nova, _altura_novo),
	]
	var largura := MARGEM
	for figura in figuras:
		largura += figura.get_width() + MARGEM
	var painel := Image.create_empty(largura, ALTURA_HEROI + 2 * MARGEM, false, Image.FORMAT_RGBA8)
	painel.fill(COR_PAINEL)
	var x := MARGEM
	for figura in figuras:
		painel.blend_rect(figura, Rect2i(Vector2i.ZERO, figura.get_size()), Vector2i(x, MARGEM + ALTURA_HEROI - figura.get_height()))
		x += figura.get_width() + MARGEM
	painel.resize(painel.get_width() * AMPLIACAO, painel.get_height() * AMPLIACAO, Image.INTERPOLATE_NEAREST)
	painel.save_png(caminho)
	print("Comparação (herói, Goblin Warrior, novo): " + caminho)


func _carregar(caminho: String) -> Image:
	var imagem := (load(caminho) as Texture2D).get_image()
	imagem.convert(Image.FORMAT_RGBA8)
	return _aparar(imagem)


func _na_altura(imagem: Image, altura: int) -> Image:
	var copia := imagem.duplicate() as Image
	copia.resize(roundi(copia.get_width() * float(altura) / copia.get_height()), altura, Image.INTERPOLATE_NEAREST)
	return copia
