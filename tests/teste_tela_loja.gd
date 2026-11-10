extends TesteBase
## A tela da loja: abre pausando, lista com preços, comprar, vender e fechar. Também o lojista da fase.


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var cena: Main = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	cena.tirar_criaturas()
	await physics_frame
	var jogador: Jogador = cena.get_node("Jogador")
	var tela: TelaLoja = cena.get_node("Interface/TelaLoja")
	var lojista: Lojista = cena.get_node("Lojista")
	_checar(lojista.visible and absf(lojista.global_position.x - (cena.get_node("Bau") as Node2D).global_position.x) >= 96.0, "o lojista fica longe do baú (as áreas não se sobrepõem)")
	var espada := (load("res://data/armas/espada_curta.tres") as Arma).duplicate() as Arma
	var estoque: Array[Item] = [espada]
	jogador.ficha.ouro = 30
	lojista.abrir_pedido.emit()
	await process_frame
	_checar(tela.visible and paused, "a loja abre e pausa o jogo")
	var lista: ItemList = tela.find_child("Lista", true, false)
	_checar(lista.item_count >= 1 and "po)" in lista.get_item_text(0), "a lista mostra o preço de cada item")
	tela.abrir(estoque, jogador.ficha, jogador.inventario)
	var mochila_antes := jogador.inventario.itens.size()
	_checar(tela.confirmar() and jogador.ficha.ouro == 20, "comprar tira o ouro")
	_checar(jogador.inventario.itens.size() == mochila_antes + 1 and estoque.is_empty(), "o item vai para a mochila e sai do estoque")
	(tela.find_child("ModoVender", true, false) as Button).pressed.emit()
	var comprada := jogador.inventario.itens[jogador.inventario.itens.size() - 1]
	for i in lista.item_count:
		if comprada.nome in lista.get_item_text(i):
			lista.select(i)
	_checar(tela.confirmar() and jogador.ficha.ouro == 25, "vender paga metade")
	tela.fechar()
	_checar(not tela.visible and not paused, "fechar devolve o jogo")
	_terminar("tela da loja e lojista")
