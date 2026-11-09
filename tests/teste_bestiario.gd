extends TesteBase
## Testa o bestiário: o registro de derrotas, a tela (silhueta ou ficha), o caminho pela pausa
## com o Esc voltando, e o save guardando o que foi descoberto.
## godot --headless --debug --path . --script res://tests/teste_bestiario.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	Salvamento.caminho = "user://save_teste.json"  # nunca o save de verdade
	Salvamento.apagar()
	_testar_registro()
	await _testar_tela()
	await _testar_no_jogo()
	Salvamento.apagar()
	print("PASSOU: todos os testes do bestiário" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _testar_registro() -> void:
	var b := Bestiario.new()
	_checar(not b.foi_derrotada("Gray Ooze") and b.conhecidas() == 0, "começa sem nenhuma criatura descoberta")
	b.registrar_derrota("Gray Ooze")
	b.registrar_derrota("Gray Ooze")
	_checar(b.foi_derrotada("Gray Ooze") and b.quantidade("Gray Ooze") == 2 and b.conhecidas() == 1, "conta as derrotas")
	var c := Bestiario.new()
	c.carregar(b.para_dicionario())
	_checar(c.quantidade("Gray Ooze") == 2, "o que foi salvo volta igual")
	c.carregar({"Fantasma": -3, "Goblin Minion": 1})
	_checar(not c.foi_derrotada("Fantasma") and c.foi_derrotada("Goblin Minion"), "ignora valores inválidos ao carregar")
	for caminho in ["gray_ooze", "goblin_minion", "goblin_warrior"]:
		var entrada := load("res://data/bestiario/%s.tres" % caminho) as EntradaBestiario
		_checar(entrada != null and entrada.criatura != null and entrada.retrato != null and not entrada.descricao.is_empty(), "página %s completa" % caminho)


func _testar_tela() -> void:
	var tela: TelaBestiario = load("res://ui/bestiario/tela_bestiario.tscn").instantiate()
	root.add_child(tela)
	await process_frame
	var entradas: Array[EntradaBestiario] = [load("res://data/bestiario/gray_ooze.tres"), load("res://data/bestiario/goblin_minion.tres")]
	var b := Bestiario.new()
	tela.abrir(b, entradas)
	var lista: ItemList = tela.get_node("%Lista")
	_checar(lista.get_item_text(0) == "???" and lista.get_item_text(1) == "???", "sem derrotas, a lista mostra ???")
	_checar((tela.get_node("%Retrato") as TextureRect).modulate == Color.BLACK, "criatura desconhecida aparece em silhueta")
	_checar((tela.get_node("%Ficha") as Label).text.is_empty(), "criatura desconhecida não mostra a ficha")
	tela.fechar()
	b.registrar_derrota("Gray Ooze")
	tela.abrir(b, entradas)
	var ficha: String = (tela.get_node("%Ficha") as Label).text
	_checar(lista.get_item_text(0) == "Gray Ooze" and lista.get_item_text(1) == "???", "só a derrotada ganha nome na lista")
	_checar(ficha.contains("CA 9") and ficha.contains("Pseudópode") and ficha.contains("ácido"), "a ficha mostra CA, ataque e dano do livro")
	_checar(ficha.contains("Resiste a:") and ficha.contains("Corrói"), "a ficha mostra resistências e a corrosão")
	_checar((tela.get_node("%Retrato") as TextureRect).modulate == Color.WHITE, "derrotada aparece colorida")
	b.registrar_derrota("Goblin Minion")
	tela.abrir(b, entradas)
	for i in entradas.size():
		lista.select(i)
		lista.item_selected.emit(i)
		await process_frame
		await process_frame
		var painel: Control = tela.get_node("Centro/Painel")
		_checar(painel.size.y <= 360.0 and painel.size.x <= 640.0, "a página %d cabe na tela (%dx%d)" % [i, painel.size.x, painel.size.y])
	tela.fechar()
	tela.queue_free()
	await process_frame


func _testar_no_jogo() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 5:
		await process_frame
	var pausa: TelaPausa = main.get_node("Interface/TelaPausa")
	var tela: TelaBestiario = main.get_node("Interface/TelaBestiario")
	pausa.abrir()
	pausa.get_node("%Bestiario").pressed.emit()
	await process_frame
	_checar(tela.visible and not pausa.visible and paused, "Bestiário pela pausa abre a tela")
	var evento := InputEventAction.new()
	evento.action = &"ui_cancel"
	evento.pressed = true
	Input.parse_input_event(evento)
	for i in 4:
		await process_frame
	_checar(not tela.visible and pausa.visible, "Esc no bestiário volta para a pausa")
	pausa.fechar()
	main.trazer_criatura(load("res://features/gray_ooze/gray_ooze.tscn"))
	var ooze: Node = main.get_tree().get_nodes_in_group(&"monstros").back()
	ooze.call(&"terminar_de_morrer")
	await process_frame
	pausa.abrir()
	pausa.get_node("%Bestiario").pressed.emit()
	await process_frame
	_checar((tela.get_node("%Lista") as ItemList).get_item_text(0) == "Gray Ooze", "derrotar o Gray Ooze no jogo o revela no bestiário")
	tela.fechar()
	pausa.abrir()
	pausa.salvar_escolhido.emit()
	var dados := Salvamento.ler()
	var lido := Bestiario.new()
	Salvamento.restaurar_bestiario(dados, lido)
	_checar(lido.foi_derrotada("Gray Ooze"), "o save guarda o bestiário")
	main.free()
	await process_frame
