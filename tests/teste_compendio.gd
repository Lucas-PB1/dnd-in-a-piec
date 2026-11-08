extends SceneTree
## O Compêndio mostra o que já está disponível e não cria abas para conteúdo ainda documental.
## godot --headless --debug --path . --script res://tests/teste_compendio.gd

var _falhas: int = 0


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var antecedentes: Array[AntecedenteRPG] = []
	antecedentes.assign(Recursos.da_pasta("res://data/antecedentes"))
	var talentos: Array[TalentoRPG] = []
	talentos.assign(Recursos.da_pasta("res://data/talentos"))
	var classe: ClasseRPG = load("res://data/classe_guerreiro.tres")
	var secoes := Compendio.montar(classe)
	_testar_conteudo(secoes, antecedentes, talentos)
	await _testar_tela(secoes)
	await _testar_atalho_do_titulo()
	print("PASSOU: compêndio" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _testar_conteudo(secoes: Dictionary[String, Array], antecedentes: Array[AntecedenteRPG], talentos: Array[TalentoRPG]) -> void:
	_checar(antecedentes.size() == 16, "são 16 antecedentes do livro")
	var origem := talentos.filter(func(t: TalentoRPG) -> bool: return t.categoria == TalentoRPG.Categoria.ORIGEM)
	_checar(talentos.size() == 52 and origem.size() == 10, "são 52 talentos, 10 de origem")
	for antecedente in antecedentes:
		var talento: TalentoRPG = null
		for t in talentos:
			if t.id == antecedente.talento:
				talento = t
		_checar(talento != null and talento.categoria == TalentoRPG.Categoria.ORIGEM, "%s aponta para um talento de origem" % antecedente.nome)
		_checar(antecedente.atributos.size() == 3 and antecedente.pericias.size() == 2, "%s tem 3 atributos e 2 perícias" % antecedente.nome)
		for pericia in antecedente.pericias:
			_checar(Pericia.ATRIBUTO.has(pericia), "%s: a perícia %s existe" % [antecedente.nome, pericia])
	_checar(not secoes.has(Compendio.ABA_ANTECEDENTES), "antecedentes sem acesso não ganham aba")
	_checar(not secoes.has(Compendio.ABA_TALENTOS), "talentos sem acesso não ganham aba")
	_checar(secoes.has(Compendio.ABA_GUERREIRO), "o Guerreiro disponível aparece")
	_checar(secoes[Compendio.ABA_PACOTES].size() == 2, "os pacotes iniciais selecionáveis aparecem")
	_checar(secoes.has(Compendio.ABA_MAESTRIAS), "maestrias disponíveis aparecem")
	_checar(secoes[Compendio.ABA_ARMAS].size() == Recursos.da_pasta("res://data/armas").size(), "o arsenal aparece no Compêndio")
	_checar(secoes[Compendio.ABA_ARMADURAS].size() == Recursos.da_pasta("res://data/armaduras").size(), "as armaduras e escudos aparecem")
	_checar(secoes[Compendio.ABA_ITENS].size() == Recursos.da_pasta("res://data/municoes").size(), "as munições acessíveis aparecem como itens")
	_checar((secoes[Compendio.ABA_ITENS][0] as EntradaCompendio).tipo == "Munição", "cada munição é identificada pelo tipo")


func _testar_tela(secoes: Dictionary[String, Array]) -> void:
	var tela: TelaCompendio = load("res://ui/compendio/tela_compendio.tscn").instantiate()
	root.add_child(tela)
	await process_frame
	tela.abrir(secoes)
	var lista: ItemList = tela.get_node("%Lista")
	var abas: TabBar = tela.get_node("%Abas")
	_checar(abas.tab_count == secoes.size(), "a tela só cria abas com conteúdo disponível")
	_checar(lista.item_count > 0, "a primeira aba mostra páginas")
	var nomes_abas: Array[String] = []
	for indice in abas.tab_count:
		var nome_aba := abas.get_tab_title(indice)
		nomes_abas.append(nome_aba)
		abas.current_tab = indice
		await process_frame
		_checar(lista.item_count == secoes[nome_aba].size(), "%s lista todas as páginas" % nome_aba)
	_checar(not nomes_abas.has(Compendio.ABA_ANTECEDENTES), "não mostra a aba Antecedentes")
	_checar(not nomes_abas.has(Compendio.ABA_TALENTOS), "não mostra a aba Talentos")
	tela.fechar()
	_checar(not paused, "fechar despausa o jogo")
	tela.queue_free()
	await process_frame


func _testar_atalho_do_titulo() -> void:
	var titulo: TelaTitulo = load("res://ui/titulo/tela_titulo.tscn").instantiate()
	root.add_child(titulo)
	await process_frame
	var resultado: Array[bool] = [false]
	titulo.compendio_escolhido.connect(func() -> void: resultado[0] = true)
	(titulo.get_node("%Compendio") as Button).pressed.emit()
	_checar(resultado[0], "o botão do menu inicial pede o Compêndio")
	titulo.queue_free()
	await process_frame


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		print("  ERRO - ", descricao)
		_falhas += 1
