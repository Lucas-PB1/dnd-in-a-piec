extends TesteBase
## Intro de lore: Resource editável, tela Continuar/Pular, fluxo Novo Jogo → intro → Treino.
## godot --headless --debug --path . --script res://tests/ui/teste_intro_lore.gd

const QUADROS := 20


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_resource()
	await _testar_fluxo()
	_terminar("intro de lore")


func _testar_resource() -> void:
	var lore: IntroLoreRPG = load("res://data/intro_lore.tres")
	_checar(lore != null and not lore.titulo.is_empty() and not lore.texto.is_empty(),
		"data/intro_lore.tres tem título e texto")
	_checar("pedaço" in lore.titulo.to_lower() or "pedaco" in lore.titulo.to_lower()
		or "aventura" in lore.titulo.to_lower(), "título no tom do jogo")
	var tela: TelaIntroLore = load("res://ui/intro_lore/tela_intro_lore.tscn").instantiate()
	root.add_child(tela)
	tela.configurar(lore)
	_checar(tela.get_node("%Titulo").text == lore.titulo, "tela mostra o título do Resource")
	_checar(tela.get_node("%Texto").text == lore.texto, "tela mostra o texto do Resource")
	tela.queue_free()


func _testar_fluxo() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = true
	root.add_child(main)
	await _esperar(QUADROS)
	var titulo := _achar(main, TelaTitulo) as TelaTitulo
	titulo.novo_jogo_escolhido.emit()
	await process_frame
	var criacao := _achar(main, TelaCriacao) as TelaCriacao
	var jogador: Jogador = main.get_node("Jogador")
	var compra := CompraDePontos.new()
	compra.aplicar({Atributos.FORCA: 15, Atributos.DESTREZA: 14, Atributos.CONSTITUICAO: 15,
		Atributos.INTELIGENCIA: 8, Atributos.SABEDORIA: 10, Atributos.CARISMA: 8})
	criacao.confirmada.emit(Ficha.new(jogador.classe, compra.valores, "Lore"), jogador.classe.pacotes_iniciais[0])
	await process_frame
	_checar(main.get_tree().paused, "intro mantém o jogo pausado")
	var intro := _achar(main, TelaIntroLore) as TelaIntroLore
	_checar(intro != null and intro.visible, "intro aparece depois da criação")
	_checar(_achar(main, TelaCriacao) == null, "criação fechou antes da intro")
	intro.seguir_pedido.emit()
	await _esperar(QUADROS)
	_checar(_achar(main, TelaIntroLore) == null, "intro some ao seguir")
	_checar(not main.get_tree().paused, "jogo despausa no Treino")
	_checar(main._fase.nome_ambiente == "Treino", "depois da intro vem o Treino")
	main.queue_free()


func _achar(cena: Node, tipo: Variant) -> Node:
	for filho in cena.get_node("Interface").get_children():
		if is_instance_of(filho, tipo) and not filho.is_queued_for_deletion():
			return filho
	return null


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
