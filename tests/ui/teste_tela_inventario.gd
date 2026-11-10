extends TesteBase
## Teste da tela de inventário dentro do jogo (abrir com I, equipar, desequipar, jogar fora).
## godot --headless --debug --path . --script res://tests/ui/teste_tela_inventario.gd


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
	var ficha_visual: FichaVisual = tela.get_node("%FichaVisual")
	var slots: SlotsDeEquipamento = tela.get_node("%Slots")
	for i in 10:
		await physics_frame

	await _apertar_inventario()
	_checar(tela.visible and paused, "I abre o inventário e pausa o jogo")
	_checar(lista.item_count == 1 and lista.get_item_text(0) == "Espada Curta", "espada curta está na mochila, sem equipar")
	_checar("Nível 1" in _texto(ficha_visual, "Cabecalho") and _texto(ficha_visual, "BarraXP/Texto") == "XP 0/300", "ficha mostra o nível e o XP do personagem")
	_checar(_texto(slots, "Slot_mao/Nome") == "Desarmado", "o slot da mão principal mostra a mão vazia (desarmado)")
	_checar(_texto(slots, "Slot_mao_secundaria/Nome") == SlotsDeEquipamento.TEXTO_VAZIO, "a mão secundária e o corpo aparecem vazios")

	tela.equipar_selecionado()
	_checar(jogador.arma_atual().nome == "Espada Curta", "Equipar coloca a espada na mão do herói")
	_checar(lista.get_item_text(0).begins_with("[P] "), "a lista marca o item equipado com o selo da mão principal [P]")
	_checar(_texto(slots, "Slot_mao/Nome") == "Espada Curta", "o slot da mão principal mostra a espada")
	_checar("Ataque +4 (FOR +2, prof. +2)   Dano 1d6+2" in _texto(ficha_visual, "Ataque"),
		"ficha mostra ataque +4, a proficiência e o dano 1d6+2 da espada")
	jogador.inventario.desgastar(jogador.arma_atual(), 3, 5)
	_checar("Ataque +1 (FOR +2, prof. +2, corroída -3)   Dano 1d6+2" in _texto(ficha_visual, "Ataque"),
		"com desgaste a proficiência continua na conta e o ataque cai")
	_checar(_texto(ficha_visual, "Chip_CA/Texto") == "CA 12", "ficha mostra a CA")
	_checar("salv." in _texto(ficha_visual, "Atributo_forca/Sigla") and "salv." not in _texto(ficha_visual, "Atributo_destreza/Sigla"),
		"o cartão da FOR marca a salvaguarda proficiente e o da DES não")
	_checar(_texto(ficha_visual, "Atributo_forca/Valor") == "15  +2", "o cartão do atributo mostra valor e modificador")
	_checar(_texto(ficha_visual, "Dica") == FichaVisual.TEXTO_DICA_PADRAO, "sem toque, a dica manda tocar num atributo")
	var toque := InputEventMouseButton.new()
	toque.button_index = MOUSE_BUTTON_LEFT
	toque.pressed = true
	(ficha_visual.find_child("Atributo_carisma", true, false) as Control).gui_input.emit(toque)
	_checar(_texto(ficha_visual, "Dica") == Atributos.dica(Atributos.CARISMA), "tocar no Carisma explica o que ele faz")
	_checar("ouro" in Atributos.DESCRICOES[Atributos.CARISMA], "o Carisma explica o saque")

	tela.desequipar_selecionado()
	_checar(jogador.arma_atual() == jogador.ataque_desarmado, "Desequipar volta para o ataque desarmado")

	# Clicar no slot seleciona o item e dá para desequipar por ele
	tela.equipar_selecionado()
	slots.slot_escolhido.emit(jogador.arma_atual())
	_checar(lista.get_selected_items() == PackedInt32Array([0]), "clicar no slot seleciona o item na mochila")

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


## O texto do nó (caminho a partir de `raiz`; procura em qualquer profundidade).
func _texto(raiz: Node, caminho: String) -> String:
	var partes := caminho.split("/")
	var no := raiz.find_child(partes[0], true, false)
	for i in range(1, partes.size()):
		no = no.find_child(partes[i], true, false)
	return (no as Label).text

func _apertar_inventario() -> void:
	var evento := InputEventAction.new()
	evento.action = &"inventario"
	evento.pressed = true
	Input.parse_input_event(evento)
	await process_frame
	await process_frame
