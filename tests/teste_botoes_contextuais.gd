extends SceneTree
## Garante que a tela só mostra o que o herói tem: os botões de toque e as linhas do HUD
## aparecem quando servem (Surto e Mente Tática no nível 2, Lançar com arma na mão, E perto de algo).
## godot --headless --debug --path . --script res://tests/teste_botoes_contextuais.gd

var _falhas: int = 0


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	OpcoesToque.caminho = "user://toque_teste.cfg"  # nunca a configuração de verdade
	DirAccess.remove_absolute(OpcoesToque.caminho)  # começa sem opções salvas
	OpcoesToque.slots = OpcoesToque.padrao_slots()
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 6:
		await process_frame
	var toque: ControlesToque = main.get_node("ControlesToque")
	var jogador: Jogador = main.get_node("Jogador")
	var hud: Hud = main.get_node("Hud")
	_checar(not toque.botao(&"surto_acao").visible, "nível 1: o botão do Surto de Ação está escondido")
	_checar(toque.botao(&"folego").visible, "o botão do Fôlego aparece (o Guerreiro tem a habilidade)")
	_checar(not toque.botao(&"interagir").visible, "longe de tudo, o botão Abrir/Pegar está escondido")
	_checar(toque.botao(&"pular").visible and toque.botao(&"atacar").visible, "Atacar e Pular ficam sempre na tela")
	_checar(not hud.get_node("%Surto").visible and not toque.botao(&"mente_tatica").visible, "nível 1: nem o HUD nem a barra mostram Surto e Mente Tática")
	var tinha_arma := jogador.inventario.equipado(Item.ESPACO_MAO) != null
	_checar(toque.botao(&"arremessar").visible == tinha_arma, "Lançar só aparece com arma na mão")
	jogador.inventario.limpar()
	jogador.inventario.adicionar(Salvamento.item_chamado("Espada Curta").duplicate() as Item)
	jogador.inventario.equipar(jogador.inventario.itens[0])
	_checar(toque.botao(&"arremessar").visible, "ao equipar uma arma, o Lançar aparece")
	jogador.inventario.desequipar(Item.ESPACO_MAO)
	_checar(not toque.botao(&"arremessar").visible, "sem arma na mão, o Lançar some")
	var bau: Bau = main.get_node("Bau")
	bau.perto_mudou.emit(true)
	_checar(toque.botao(&"interagir").visible and toque.botao(&"interagir").texto == "Abrir", "perto do baú, aparece o botão Abrir")
	_checar(toque.botao(&"atacar").acao == &"atacar", "o botão de ataque nunca muda")
	bau.perto_mudou.emit(false)
	_checar(not toque.botao(&"interagir").visible, "ao se afastar, o botão Abrir some")
	OpcoesToque.slots = OpcoesToque.padrao_slots()
	toque.atualizar()
	_checar(toque.botao(&"folego").visible and toque.botao(&"folego").texto == "Fôlego", "o 1º slot traz o Fôlego")
	OpcoesToque.slots[0] = &""
	toque.atualizar()
	_checar(toque.botao(&"folego") == null, "esvaziar o slot tira o Fôlego da tela")
	OpcoesToque.slots = OpcoesToque.padrao_slots()
	toque.atualizar()
	jogador.ganhar_experiencia(300)
	await process_frame
	_checar(toque.botao(&"surto_acao").visible and hud.get_node("%Surto").visible and toque.botao(&"mente_tatica").visible, "no nível 2 o Surto e a Mente Tática aparecem")
	toque.editar()
	_checar(toque.botao(&"surto_acao").visible and toque.botao(&"interagir").visible, "na edição do layout todos os botões aparecem")
	toque.terminar_edicao()
	_checar(not toque.botao(&"interagir").visible and toque.botao(&"surto_acao").visible, "depois da edição, esconde só o que não serve (o Surto serve no nível 2)")
	_checar(_vazio_escondido(toque), "os slots sem habilidade ficam escondidos no jogo")
	await _testar_escolha_de_atalhos(main)
	DirAccess.remove_absolute(OpcoesToque.caminho)
	main.free()
	await process_frame
	print("PASSOU: a tela só mostra o que o herói tem" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


## Slots sem habilidade não aparecem na tela (só na edição do layout).
## Nas Opções, a aba Atalhos escolhe o que vai em cada slot e o botão acompanha.
func _testar_escolha_de_atalhos(main: Main) -> void:
	var opcoes: TelaComandos = main.get_node("Interface/TelaComandos")
	var toque: ControlesToque = main.get_node("ControlesToque")
	opcoes.abrir()
	var grade: GridContainer = opcoes.get_node("%GradeAtalhos")
	_checar(grade.get_child_count() == OpcoesToque.QUANTIDADE_SLOTS * 2, "a aba Atalhos tem um seletor por slot")
	var primeiro: OptionButton = grade.get_child(1)
	_checar(primeiro.get_item_count() == OpcoesToque.HABILIDADES.size() + 1, "cada seletor tem Vazio e as habilidades especiais")
	var segundo: OptionButton = grade.get_child(3)
	segundo.select(1)
	segundo.item_selected.emit(1)
	_checar(OpcoesToque.slots[1] == &"folego" and toque.botao(&"folego") != null, "escolher Fôlego no 2º slot muda a barra")
	opcoes.fechar()
	OpcoesToque.slots = OpcoesToque.padrao_slots()
	toque.atualizar()


func _vazio_escondido(toque: ControlesToque) -> bool:
	for id in ["slot4", "slot5", "slot6"]:
		if (toque.get_node("Raiz/Botao_%s" % id) as Control).visible:
			return false
	return true


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		print("  ERRO - ", descricao)
		_falhas += 1
