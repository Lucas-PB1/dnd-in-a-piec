extends SceneTree
## Abre o jogo já numa fase da campanha, para ver ou testar sem jogar as anteriores (precisa de janela, NÃO use --headless).
## Uso: godot --path . --script res://tools/abrir_fase.gd -- <numero da fase, 1 a 5>

const ESPERA_INICIAL := 20


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var args := OS.get_cmdline_user_args()
	var numero: int = clampi(int(args[0]) if args.size() > 0 else 1, 1, Main.CENAS_FASE.size())
	var cena: Main = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	for i in ESPERA_INICIAL:
		await physics_frame
	if numero > 1:
		cena._entrar_fase(Main.CENAS_FASE[numero - 1])
