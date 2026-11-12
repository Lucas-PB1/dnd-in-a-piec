extends TesteBase
## Poções de cura: preço, estoque da loja, beber no inventário.
## godot --headless --debug --path . --script res://tests/heroi/teste_pocoes.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var cura := load("res://data/itens/pocao_cura.tres") as Item
	var maior := load("res://data/itens/pocao_cura_maior.tres") as Item
	_checar(cura != null and cura.e_pocao_de_cura() and cura.cura == "2d4+2", "Poção de Cura é consumível 2d4+2")
	_checar(maior != null and maior.e_pocao_de_cura() and maior.cura == "4d4+4", "Poção de Cura Maior é 4d4+4")
	_checar(Loja.preco(cura) == 50, "Poção de Cura custa 50 GP")
	_checar(Loja.preco(maior) == 200, "Poção de Cura Maior custa 200 GP")

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var viu_cura := false
	var viu_maior := false
	for i in 80:
		# Cura 50 po → teto 50 a partir da fase 3; Maior 200 po → teto 200 a partir da 7.
		for item in Loja.sortear_estoque(3, rng):
			if item.nome == "Poção de Cura":
				viu_cura = true
		for item in Loja.sortear_estoque(7, rng):
			if item.nome == "Poção de Cura Maior":
				viu_maior = true
	_checar(viu_cura, "na fase 3 a Poção de Cura pode sair no estoque")
	_checar(viu_maior, "na fase 7 a Poção Maior pode sair no estoque")

	var cena: Node = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	var jogador: Jogador = cena.get_node("Jogador")
	for monstro in get_nodes_in_group(&"monstros"):
		monstro.free()
	var tela: TelaInventario = cena.get_node("Interface/TelaInventario")
	for i in 10:
		await physics_frame

	var vida: HealthComponent = jogador.get_node("Vida")
	vida.receber_dano(8)
	var vida_ferida := jogador.vida_atual()
	var pocao := cura.duplicate() as Item
	jogador.inventario.adicionar(pocao, 2)
	_checar(jogador.inventario.quantidade_de(pocao) == 2, "duas poções empilham na mochila")

	await _apertar_inventario()
	_checar(tela.visible, "I abre o inventário")
	var lista: ItemList = tela.get_node("%Lista")
	var indice_pocao := -1
	for i in lista.item_count:
		if "Poção de Cura" in lista.get_item_text(i):
			indice_pocao = i
			break
	_checar(indice_pocao >= 0, "a poção aparece na lista")
	lista.select(indice_pocao)
	lista.item_selected.emit(indice_pocao)
	var botao_usar: Button = tela.get_node("%Usar")
	_checar(botao_usar.visible and not botao_usar.disabled, "botão Usar aparece na poção")
	tela.usar_selecionado()
	_checar(jogador.vida_atual() > vida_ferida, "Usar cura PV")
	_checar(jogador.inventario.quantidade_de(pocao) == 1, "gasta 1 da pilha")

	vida.configurar(jogador.vida_maxima())
	tela.atualizar_vida(jogador.vida_atual(), jogador.vida_maxima())
	var antes_cheia := jogador.inventario.quantidade_de(pocao)
	tela.usar_selecionado()
	_checar(jogador.inventario.quantidade_de(pocao) == antes_cheia, "vida cheia não gasta poção")

	cena.queue_free()
	_terminar("poções de cura")


func _apertar_inventario() -> void:
	var evento := InputEventAction.new()
	evento.action = &"inventario"
	evento.pressed = true
	Input.parse_input_event(evento)
	await process_frame
	await process_frame
