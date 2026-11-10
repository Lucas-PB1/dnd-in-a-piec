extends SceneTree
## Monta o SpriteFrames de uma criatura feita com tiras do Gemini (saída de montar_tiras_gemini.gd).
## Cada tira tem quadros lado a lado, todos do mesmo tamanho. Sem tira de `dano`, ela repete o 1º quadro de `parado`
## (a cena já treme e pisca por código).
## Rodar (sem --debug):
##   godot --headless --path . --script res://tools/montar_frames_gemini.gd -- PASTA PREFIXO LARGURA_QUADRO \
##       nome:arquivo.png:quadros:fps:loop ...   (loop = 1 ou 0)
## Escreve PASTA/PREFIXO_frames.tres e imprime o offset que põe os pés na origem.

const ANIMACAO_DANO := &"dano"
const FPS_DANO := 8.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 4:
		push_error("Uso: -- PASTA PREFIXO LARGURA nome:arquivo:quadros:fps:loop ...")
		quit(1)
		return
	var pasta := args[0]
	var largura := int(args[2])
	var quadros := SpriteFrames.new()
	quadros.remove_animation(&"default")
	var parado: Texture2D = null
	var altura := 0
	for i in range(3, args.size()):
		var d := args[i].split(":")
		var tira: Texture2D = load(pasta + d[1])
		altura = tira.get_height()
		if d[0] == "parado":
			parado = tira
		_adicionar(quadros, StringName(d[0]), tira, largura, int(d[2]), float(d[3]), d[4] == "1")
	if not quadros.has_animation(ANIMACAO_DANO):  # a criatura que ganhou arte de dano (Quimera) mantém a dela
		_adicionar(quadros, ANIMACAO_DANO, parado, largura, 1, FPS_DANO, false)
	ResourceSaver.save(quadros, "%s%s_frames.tres" % [pasta, args[1]])
	var corpo := (parado.get_image()).get_region(Rect2i(0, 0, largura, altura)).get_used_rect()
	print("quadro %dx%d, corpo %s, offset = (%s, %s)" % [largura, altura, corpo,
		largura / 2.0 - (corpo.position.x + corpo.size.x / 2.0), altura / 2.0 - corpo.end.y])
	quit()


func _adicionar(quadros: SpriteFrames, nome: StringName, tira: Texture2D, largura: int, quantidade: int, fps: float, repete: bool) -> void:
	quadros.add_animation(nome)
	quadros.set_animation_speed(nome, fps)
	quadros.set_animation_loop(nome, repete)
	for i in quantidade:
		var quadro := AtlasTexture.new()
		quadro.atlas = tira
		quadro.region = Rect2(Vector2(i * largura, 0), Vector2(largura, tira.get_height()))
		quadros.add_frame(nome, quadro)
