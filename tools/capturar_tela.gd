extends SceneTree
## Tira prints do jogo segurando teclas, para conferir o visual sem precisar jogar.
## Uso (precisa de janela, NÃO use --headless):
##   godot --path . --script res://tools/capturar_tela.gd -- <acoes> <quadros> <arquivo.png> [opcoes]
## Ex.: ... -- mover_direita,pular 40 C:/tmp/print.png equipar
## <acoes> separadas por vírgula, ou "nenhuma". <quadros> = passos de física (60 por segundo)
## contados DEPOIS de apertar as teclas. [opcoes] separadas por vírgula:
##   criacao = mostra a tela de criação;  equipar = começa com a 1ª arma da mochila na mão.

## Passos de física de espera antes de apertar as teclas (a fase estabiliza depois de carregar).
const ESPERA_INICIAL := 30


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var args := OS.get_cmdline_user_args()
	var acoes: PackedStringArray = args[0].split(",") if args.size() > 0 else PackedStringArray()
	var quadros: int = int(args[1]) if args.size() > 1 else 30
	var arquivo: String = args[2] if args.size() > 2 else "user://print.png"

	var opcoes: PackedStringArray = args[3].split(",") if args.size() > 3 else PackedStringArray()

	var cena: Node = load("res://levels/main.tscn").instantiate()
	cena.mostrar_criacao = "criacao" in opcoes
	root.add_child(cena)
	if "equipar" in opcoes:
		var jogador: Jogador = cena.get_node("Jogador")
		jogador.inventario.equipar(jogador.inventario.itens[0])
	for i in ESPERA_INICIAL:
		await physics_frame
	for acao in acoes:
		if InputMap.has_action(acao):
			# Evento de verdade: segura a ação E chega em _unhandled_input (ex.: abrir inventário).
			var evento := InputEventAction.new()
			evento.action = acao
			evento.pressed = true
			Input.parse_input_event(evento)
	for i in quadros:
		await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(arquivo)
	print("Print salvo em ", arquivo)
	quit()
