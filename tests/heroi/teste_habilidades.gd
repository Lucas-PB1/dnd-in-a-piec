extends TesteBase
## Testa a árvore de habilidades: os dados do Guerreiro, a árvore, a tela e o caminho pela pausa.
## godot --headless --debug --path . --script res://tests/heroi/teste_habilidades.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	Salvamento.caminho = "user://save_teste.json"  # nunca o save de verdade
	_testar_dados()
	await _testar_tela()
	await _testar_pela_pausa()
	print("PASSOU: todos os testes das habilidades" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _guerreiro() -> ClasseRPG:
	return load("res://data/classe_guerreiro.tres") as ClasseRPG


func _habilidade(id: StringName) -> HabilidadeClasse:
	for habilidade in _guerreiro().habilidades:
		if habilidade.id == id:
			return habilidade
	return null


func _testar_dados() -> void:
	var habilidades := _guerreiro().habilidades
	_checar(habilidades.size() == 9, "o Guerreiro tem 9 habilidades na árvore")
	var ids: Array[StringName] = []
	for habilidade in habilidades:
		ids.append(habilidade.id)
		for pai in habilidade.requer:
			_checar(pai in ids or _habilidade(pai) != null, "%s exige uma habilidade que existe (%s)" % [habilidade.nome, pai])
	_checar(_habilidade(&"segundo_folego").liberada(1), "Segundo Fôlego está liberado no nível 1")
	_checar(not _habilidade(&"surto_acao").liberada(1) and _habilidade(&"surto_acao").liberada(2), "Surto de Ação chega no nível 2")
	_checar(_habilidade(&"subclasse").liberada(3), "a Subclasse libera no nível 3")


func _testar_tela() -> void:
	var tela: TelaHabilidades = load("res://ui/habilidades/tela_habilidades.tscn").instantiate()
	root.add_child(tela)
	await process_frame
	var ficha := Ficha.new(_guerreiro(), {}, "Teste")
	tela.abrir(ficha)
	await process_frame
	await process_frame
	var arvore: ArvoreHabilidades = tela.get_node("%Arvore")
	_checar(arvore.no_de(&"segundo_folego") != null and arvore.no_de(&"subclasse") != null, "a árvore tem um botão por habilidade")
	_checar(arvore.no_de(&"surto_acao").modulate != Color.WHITE and arvore.no_de(&"segundo_folego").modulate == Color.WHITE, "no nível 1 o Surto de Ação aparece apagado")
	_checar((tela.get_node("%Nome") as Label).text == "Segundo Fôlego" and (tela.get_node("%Situacao") as Label).text.contains("já tem"), "abre na primeira habilidade, que o herói já tem")
	_checar((tela.get_node("%Tecla") as Label).text == "Tecla: %s" % Comandos.tecla_de(&"folego"), "mostra a tecla do Fôlego")
	arvore.no_de(&"surto_acao").pressed.emit()
	_checar((tela.get_node("%Situacao") as Label).text == "Chega no nível 2", "habilidade ainda bloqueada diz em que nível chega")
	arvore.no_de(&"subclasse").pressed.emit()
	_checar((tela.get_node("%Situacao") as Label).text == "Chega no nível 3", "no nível 1 a Subclasse ainda não chegou")
	var painel: Control = tela.get_node("Centro/Painel")
	_checar(painel.size.x <= 640.0 and painel.size.y <= 360.0, "a tela cabe em 640x360 (%dx%d)" % [painel.size.x, painel.size.y])
	tela.fechar()
	ficha.definir_nivel_inicial(2)
	tela.abrir(ficha)
	await process_frame
	_checar(arvore.no_de(&"surto_acao").modulate == Color.WHITE, "no nível 2 o Surto de Ação acende")
	tela.fechar()
	tela.queue_free()
	await process_frame


func _testar_pela_pausa() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 5:
		await process_frame
	var pausa: TelaPausa = main.get_node("Interface/TelaPausa")
	var tela: TelaHabilidades = main.get_node("Interface/TelaHabilidades")
	pausa.abrir()
	pausa.get_node("%Habilidades").pressed.emit()
	await process_frame
	_checar(tela.visible and not pausa.visible and paused, "Habilidades pela pausa abre a tela")
	var evento := InputEventAction.new()
	evento.action = &"ui_cancel"
	evento.pressed = true
	Input.parse_input_event(evento)
	for i in 4:
		await process_frame
	_checar(not tela.visible and pausa.visible, "Esc nas habilidades volta para a pausa")
	main.free()
	await process_frame
