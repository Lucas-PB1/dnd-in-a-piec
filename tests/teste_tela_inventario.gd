extends SceneTree
## Teste da tela de inventário dentro do jogo (abrir com I, equipar, desequipar, jogar fora).
## godot --headless --debug --path . --script res://tests/teste_tela_inventario.gd

var _falhas := 0


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var cena: Node = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	var jogador: Jogador = cena.get_node("Jogador")
	for monstro in get_nodes_in_group(&"monstros"):
		monstro.free()
	var tela: TelaInventario = cena.get_node("Interface/TelaInventario")
	var lista: ItemList = tela.get_node("%Lista")
	var texto_ficha: Label = tela.get_node("%TextoFicha")
	for i in 10:
		await physics_frame

	await _apertar_inventario()
	_checar(tela.visible and paused, "I abre o inventário e pausa o jogo")
	_checar(lista.item_count == 1 and lista.get_item_text(0) == "Espada Curta", "espada curta está na mochila, sem equipar")
	_checar("Nível 1 · XP 0/300" in texto_ficha.text, "ficha mostra o nível e o XP do personagem")
	_checar("Mão: Desarmado" in texto_ficha.text, "ficha mostra a mão vazia (desarmado)")

	tela.equipar_selecionado()
	_checar(jogador.arma_atual().nome == "Espada Curta", "Equipar coloca a espada na mão do herói")
	_checar(lista.get_item_text(0).begins_with(TelaInventario.MARCA_EQUIPADO), "lista marca o item equipado")
	_checar("Ataque +4 (FOR +2, prof. +2)   Dano 1d6+2" in texto_ficha.text,
		"ficha mostra ataque +4, a proficiência e o dano 1d6+2 da espada")
	jogador.inventario.desgastar(jogador.arma_atual(), 3, 5)
	_checar("Ataque +1 (FOR +2, prof. +2, corroída -3)   Dano 1d6+2" in texto_ficha.text,
		"com desgaste a proficiência continua na conta e o ataque cai")
	_checar("CA 12" in texto_ficha.text and "FOR 15 +2*" in texto_ficha.text and "DES 14 +2 " in texto_ficha.text,
		"ficha mostra CA e salvaguardas (FOR proficiente, DES não)")

	tela.desequipar_selecionado()
	_checar(jogador.arma_atual() == jogador.ataque_desarmado, "Desequipar volta para o ataque desarmado")

	tela.equipar_selecionado()
	tela.jogar_fora_selecionado()
	_checar(jogador.inventario.itens.is_empty() and jogador.arma_atual() == jogador.ataque_desarmado,
		"Jogar fora some com a espada e esvazia a mão")
	_checar(lista.item_count == 0, "lista fica vazia")

	await _apertar_inventario()
	_checar(not tela.visible and not paused, "I de novo fecha e despausa")
	cena.queue_free()

	if _falhas == 0:
		print("PASSOU: todos os testes da tela de inventário")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _apertar_inventario() -> void:
	var evento := InputEventAction.new()
	evento.action = &"inventario"
	evento.pressed = true
	Input.parse_input_event(evento)
	await process_frame
	await process_frame


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
