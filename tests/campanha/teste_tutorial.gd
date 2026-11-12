extends TesteBase
## Tutorial: Treino sem inimigos, placas (incl. F/R), baú/loja/boneco, 50 po, ferimento para
## o Fôlego; porta → Clareira. godot --headless --debug --path . --script res://tests/campanha/teste_tutorial.gd

const QUADROS := 20
const NOME := "Treino"


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	await _testar_cena()
	await _testar_fluxo()
	_terminar("tutorial: Fôlego/Surto, baú/loja/alvo e fluxo → Clareira")


func _testar_cena() -> void:
	var fase: Fase = load("res://levels/fase_tutorial.tscn").instantiate()
	root.add_child(fase)
	await physics_frame
	_checar(fase.indice == 0 and fase.nome_ambiente == NOME, "Treino: índice 0 e nome Treino")
	_checar(fase.quantidade == 0 and fase.tipos_permitidos.is_empty() and fase.chefe == &"",
		"Treino: sem cota, sem tipos e sem chefe")
	_checar(fase.get_node_or_null("Porta") != null, "Treino tem porta")
	var placas: Node = fase.get_node_or_null("Placas")
	_checar(placas != null and placas.get_child_count() >= 8, "Treino tem pelo menos 8 placas")
	var textos: Array[String] = []
	for filho in placas.get_children():
		if filho is Label:
			textos.append((filho as Label).text)
	_checar(textos.any(func(t: String) -> bool: return "andar" in t), "placa ensina a andar")
	_checar(textos.any(func(t: String) -> bool: return "baú" in t or "bau" in t.to_lower()), "placa ensina o baú")
	_checar(textos.any(func(t: String) -> bool: return "loja" in t), "placa ensina a loja")
	_checar(textos.any(func(t: String) -> bool: return "Fôlego" in t or "Folego" in t), "placa ensina o Fôlego")
	_checar(textos.any(func(t: String) -> bool: return "Surto" in t), "placa ensina o Surto")
	_checar(textos.any(func(t: String) -> bool: return "azagaia" in t or "K" in t), "placa ensina arremesso")
	_checar(textos.any(func(t: String) -> bool: return "arco" in t or "segure" in t), "placa ensina o arco")
	_checar(textos.any(func(t: String) -> bool: return "Porta" in t or "Clareira" in t), "placa aponta a porta")
	fase.queue_free()
	await physics_frame


func _testar_fluxo() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = true
	root.add_child(main)
	await _esperar(QUADROS)
	var titulo := _achar(main, TelaTitulo)
	_checar(titulo != null, "abre no título")
	titulo.novo_jogo_escolhido.emit()
	await process_frame
	var criacao := _achar(main, TelaCriacao) as TelaCriacao
	_checar(criacao != null, "Novo Jogo abre a criação")
	var jogador: Jogador = main.get_node("Jogador")
	var compra := CompraDePontos.new()
	compra.aplicar({Atributos.FORCA: 15, Atributos.DESTREZA: 14, Atributos.CONSTITUICAO: 15,
		Atributos.INTELIGENCIA: 8, Atributos.SABEDORIA: 10, Atributos.CARISMA: 8})
	criacao.confirmada.emit(Ficha.new(jogador.classe, compra.valores, "Guia"), jogador.classe.pacotes_iniciais[0])
	await _esperar(QUADROS)
	_checar(main._fase.nome_ambiente == NOME and main._fase.indice == 0, "após criar, entra no Treino")
	_checar(main._ids_da_cota.is_empty(), "Treino não sorteia inimigos")
	_checar(jogador.ficha.ouro >= Main.OURO_TUTORIAL, "Novo Jogo dá ouro do tutorial")
	_checar(jogador.vida_atual() == jogador.vida_maxima() - Main.DANO_DEMONSTRACAO_TUTORIAL,
		"Treino tira PV para ensinar o Fôlego")
	_checar(jogador.usos_folego() > 0, "ainda tem uso de Fôlego para curar")
	var bau: Bau = main.get_node("Bau")
	var boneco: Node2D = main.get_node("BonecoTreino")
	var lojista: Node2D = main.get_node("Lojista")
	_checar(bau.visible and boneco.visible and lojista.visible, "Treino mostra baú, boneco e loja")
	_checar(absf(bau.global_position.x - lojista.global_position.x) >= Fase.FOLGA_INTERACAO_E,
		"baú e loja ficam a pelo menos %.0f px" % Fase.FOLGA_INTERACAO_E)
	_checar(boneco.global_position.x > lojista.global_position.x,
		"boneco fica depois da loja no corredor")
	main._heroi_na_porta = true
	main._tentar_atravessar()
	await _esperar(QUADROS)
	_checar(main._fase.indice == 1 and main._fase.nome_ambiente == "Clareira",
		"porta do Treino leva à Clareira")
	main.queue_free()


func _achar(cena: Node, tipo: Variant) -> Node:
	for filho in cena.get_node("Interface").get_children():
		if is_instance_of(filho, tipo) and not filho.is_queued_for_deletion():
			return filho
	return null


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
