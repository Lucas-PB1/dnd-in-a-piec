extends SceneTree
## Tira prints do jogo segurando teclas, para conferir o visual sem precisar jogar.
## Uso (precisa de janela, NÃO use --headless):
##   godot --path . --script res://scripts/ferramentas/capturar_tela.gd -- <acoes> <quadros> <arquivo.png>
## Ex.: ... -- mover_esquerda,mover_cima 40 C:/tmp/print.png
## <acoes> separadas por vírgula, ou "nenhuma".

func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var args := OS.get_cmdline_user_args()
	var acoes: PackedStringArray = args[0].split(",") if args.size() > 0 else PackedStringArray()
	var quadros: int = int(args[1]) if args.size() > 1 else 30
	var arquivo: String = args[2] if args.size() > 2 else "user://print.png"

	root.add_child(load("res://scenes/main.tscn").instantiate())
	for acao in acoes:
		if InputMap.has_action(acao):
			Input.action_press(acao)
	for i in quadros:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(arquivo)
	print("Print salvo em ", arquivo)
	quit()
