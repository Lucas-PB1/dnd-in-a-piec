extends TesteBase
## Testa o menu de pausa (Esc), o Salvar e o Continuar do título.
## godot --headless --debug --path . --script res://tests/ui/teste_pausa.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	Salvamento.caminho = "user://save_teste.json"  # nunca o save de verdade
	Salvamento.apagar()
	await _testar_pausa_e_salvar()
	await _testar_continuar()
	await _testar_esc_volta()
	await _testar_opcoes_e_compendio_no_titulo()
	Salvamento.apagar()
	print("PASSOU: todos os testes da pausa" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _testar_pausa_e_salvar() -> void:
	var main := await _criar_main(false)
	var pausa: TelaPausa = main.get_node("Interface/TelaPausa")
	var aviso: Label = pausa.get_node("%Aviso")
	_checar(not pausa.visible and not paused, "a pausa começa fechada")
	_apertar(&"pausa")
	await _esperar(3)
	_checar(pausa.visible and paused, "Esc abre a pausa e para o jogo")
	pausa.salvar_escolhido.emit()
	_checar(Salvamento.existe() and aviso.text == "Jogo salvo", "Salvar grava o arquivo e avisa")
	_apertar(&"pausa")
	await _esperar(3)
	_checar(not pausa.visible and not paused, "Esc de novo fecha e volta ao jogo")
	pausa.abrir()
	pausa.get_node("%Continuar").pressed.emit()
	_checar(not pausa.visible and not paused, "o botão Continuar fecha a pausa")
	main.free()
	await _esperar(2)


func _testar_continuar() -> void:
	var classe := load("res://data/classe_guerreiro.tres") as ClasseRPG
	var ficha := Ficha.new(classe, {Atributos.FORCA: 16}, "Brenna")
	ficha.definir_nivel_inicial(2)
	var inventario := Inventario.new()
	inventario.adicionar(Salvamento.item_chamado("Espada Longa").duplicate() as Item)
	Salvamento.gravar(ficha, inventario, 3)

	var main := await _criar_main(true)
	var titulo: TelaTitulo = main.get_node("Interface").get_child(-1)
	_checar(titulo is TelaTitulo and not titulo.get_node("%Continuar").disabled, "com jogo salvo, o Continuar do título está ativo")
	titulo.continuar_escolhido.emit()
	await _esperar(3)
	var jogador: Jogador = main.get_node("Jogador")
	_checar(jogador.ficha.nome == "Brenna" and jogador.ficha.nivel == 2, "Continuar carrega a ficha salva")
	_checar(jogador.inventario.item_chamado("Espada Longa") != null, "Continuar carrega a mochila salva")
	_checar((main.get_node("Fase") as Fase).indice == 3, "Continuar volta à fase salva (3)")
	_checar(not paused, "depois de continuar o jogo anda")
	main.free()
	await _esperar(2)
	Salvamento.apagar()
	var sem_save := await _criar_main(true)
	var titulo2: TelaTitulo = sem_save.get_node("Interface").get_child(-1)
	_checar(titulo2.get_node("%Continuar").disabled, "sem jogo salvo, o Continuar fica apagado")
	sem_save.free()
	await _esperar(2)


## Esc volta um nível em cada menu: da Mochila e das Opções para a pausa, e da criação para o título.
func _testar_esc_volta() -> void:
	var main := await _criar_main(false)
	var pausa: TelaPausa = main.get_node("Interface/TelaPausa")
	var inventario: TelaInventario = main.get_node("Interface/TelaInventario")
	var opcoes: TelaComandos = main.get_node("Interface/TelaComandos")
	var compendio: TelaCompendio = main.get_node("Interface/TelaCompendio")
	pausa.abrir()
	pausa.get_node("%Mochila").pressed.emit()
	await _esperar(2)
	_checar(inventario.visible and not pausa.visible, "Mochila pela pausa: abre a mochila")
	_apertar(&"ui_cancel")
	await _esperar(4)
	_checar(not inventario.visible and pausa.visible and paused, "Esc na mochila volta para a pausa")
	pausa.get_node("%Opcoes").pressed.emit()
	await _esperar(2)
	_checar(opcoes.visible and not pausa.visible, "Opções pela pausa: abre as opções")
	_apertar(&"ui_cancel")
	await _esperar(4)
	_checar(not opcoes.visible and pausa.visible, "Esc nas opções volta para a pausa")
	pausa.get_node("%Compendio").pressed.emit()
	await _esperar(2)
	_checar(compendio.visible and not pausa.visible and paused, "Compêndio pela pausa abre por cima do menu")
	compendio.get_node("%Fechar").pressed.emit()
	await _esperar(4)
	_checar(not compendio.visible and pausa.visible and paused, "fechar o Compêndio volta à pausa")
	_apertar(&"ui_cancel")
	await _esperar(4)
	_checar(not pausa.visible and not paused, "Esc na pausa volta ao jogo")
	main.free()
	await _esperar(2)
	await _testar_esc_na_criacao()


func _testar_opcoes_e_compendio_no_titulo() -> void:
	var main := await _criar_main(true)
	var interface := main.get_node("Interface")
	var titulo: TelaTitulo = interface.get_child(-1)
	var opcoes: TelaComandos = interface.get_node("TelaComandos")
	var compendio: TelaCompendio = interface.get_node("TelaCompendio")
	titulo.get_node("%Opcoes").pressed.emit()
	await _esperar(2)
	_checar(opcoes.visible and not titulo.visible and paused, "Opções no título abrem por cima e o título se esconde")
	_checar(not opcoes.find_child("AjustarToque", true, false).visible, "no título, Ajustar botões não aparece")
	_apertar(&"ui_cancel")
	await _esperar(4)
	_checar(not opcoes.visible and titulo.visible and paused, "Esc nas Opções volta ao título, com o jogo ainda parado")
	titulo.get_node("%Compendio").pressed.emit()
	await _esperar(2)
	_checar(compendio.visible and not titulo.visible and paused, "Compêndio no menu inicial abre por cima do título")
	compendio.get_node("%Fechar").pressed.emit()
	await _esperar(4)
	_checar(not compendio.visible and titulo.visible and paused, "fechar o Compêndio volta ao título pausado")
	main.free()
	await _esperar(2)


func _testar_esc_na_criacao() -> void:
	var main := await _criar_main(true)
	var interface := main.get_node("Interface")
	var titulo: TelaTitulo = interface.get_child(-1)
	titulo.novo_jogo_escolhido.emit()
	await _esperar(3)
	var criacao: TelaCriacao = interface.get_child(-1)
	_checar(criacao is TelaCriacao and criacao.visible, "Novo Jogo abre a criação")
	criacao.get_node("%Atributos").pressed.emit()
	await _esperar(2)
	_checar(criacao.get_node("%PassoQuem").visible, "sem nome não passa do primeiro passo")
	criacao.definir_nome("Aldric")
	criacao.get_node("%Atributos").pressed.emit()
	await _esperar(2)
	_checar(criacao.get_node("%PassoAntecedente").visible, "com nome, o botão leva ao passo do antecedente")
	_apertar(&"ui_cancel")
	await _esperar(3)
	_checar(criacao.get_node("%PassoQuem").visible, "Esc no passo 2 volta ao passo 1")
	_apertar(&"ui_cancel")
	await _esperar(4)
	var de_novo: Node = interface.get_child(-1)
	_checar(de_novo is TelaTitulo, "Esc no passo 1 volta ao título")
	main.free()
	await _esperar(2)


func _criar_main(com_titulo: bool) -> Main:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = com_titulo
	root.add_child(main)
	await _esperar(5)
	return main


func _apertar(acao: StringName) -> void:
	var evento := InputEventAction.new()
	evento.action = acao
	evento.pressed = true
	Input.parse_input_event(evento)


func _esperar(quadros: int) -> void:
	for i in quadros:
		await process_frame
