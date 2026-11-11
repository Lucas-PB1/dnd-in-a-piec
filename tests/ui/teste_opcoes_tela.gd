extends TesteBase
## Modo de tela (janela / tela cheia) nas Opções: grava, carrega e aparece na aba Som.
## godot --headless --debug --path . --script res://tests/ui/teste_opcoes_tela.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	OpcoesTela.caminho = "user://tela_teste.cfg"
	DirAccess.remove_absolute(OpcoesTela.caminho)
	OpcoesTela.modo = OpcoesTela.JANELA
	OpcoesTela.definir(OpcoesTela.TELA_CHEIA)
	OpcoesTela.salvar()
	OpcoesTela.modo = OpcoesTela.JANELA
	OpcoesTela.carregar()
	_checar(OpcoesTela.modo == OpcoesTela.TELA_CHEIA, "tela cheia gravada volta ao carregar")
	OpcoesTela.definir(OpcoesTela.JANELA)
	OpcoesTela.salvar()
	await _testar_na_tela_de_opcoes()
	DirAccess.remove_absolute(OpcoesTela.caminho)
	OpcoesTela.modo = OpcoesTela.JANELA
	print("PASSOU: opções de tela" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _testar_na_tela_de_opcoes() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 6:
		await process_frame
	var opcoes: TelaComandos = main.get_node("Interface/TelaComandos")
	opcoes.abrir(false)
	await process_frame
	var grade: GridContainer = opcoes.get_node("%GradeSom")
	var seletor: OptionButton = null
	for filho in grade.get_children():
		if filho is OptionButton:
			seletor = filho
	_checar(seletor != null and seletor.item_count == 2, "aba Som tem o seletor Janela / Tela cheia")
	seletor.select(OpcoesTela.TELA_CHEIA)
	seletor.item_selected.emit(OpcoesTela.TELA_CHEIA)
	await process_frame
	_checar(OpcoesTela.modo == OpcoesTela.TELA_CHEIA, "escolher Tela cheia nas Opções muda o modo")
	opcoes.fechar()
	main.queue_free()
	await process_frame
