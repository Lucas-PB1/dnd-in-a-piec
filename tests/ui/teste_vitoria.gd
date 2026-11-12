extends TesteBase
## Tela de vitória: epílogo editável, placar, Menu e Jogar de novo.
## godot --headless --debug --path . --script res://tests/ui/teste_vitoria.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var lore: IntroLoreRPG = load("res://data/epilogo_lore.tres")
	_checar(lore != null and not lore.titulo.is_empty() and not lore.texto.is_empty(),
		"data/epilogo_lore.tres tem título e texto")
	var tela: TelaVitoria = load("res://ui/vitoria/tela_vitoria.tscn").instantiate()
	root.add_child(tela)
	await process_frame
	tela.configurar(lore)
	tela.mostrar_resumo("Abates: 3 nesta fase · 12 na run\nTempo: fase 1:05 · run 12:00")
	_checar((tela.get_node("%Titulo") as Label).text == lore.titulo, "título do epílogo")
	_checar((tela.get_node("%Epilogo") as Label).text == lore.texto, "corpo do epílogo")
	_checar((tela.get_node("%Resumo") as Label).visible and "Abates" in (tela.get_node("%Resumo") as Label).text,
		"resumo do placar visível")
	var pediu_menu := [false]
	var pediu_novo := [false]
	tela.menu_escolhido.connect(func() -> void: pediu_menu[0] = true)
	tela.jogar_de_novo_escolhido.connect(func() -> void: pediu_novo[0] = true)
	(tela.get_node("%Menu") as Button).pressed.emit()
	(tela.get_node("%JogarDeNovo") as Button).pressed.emit()
	_checar(pediu_menu[0] and pediu_novo[0], "Menu e Jogar de novo emitem sinais")
	tela.queue_free()
	_terminar("tela de vitória com epílogo")
