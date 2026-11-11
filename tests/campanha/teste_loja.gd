extends TesteBase
## A loja: preços do livro, desconto do Artesão, compra, venda e estoque por fase.


func _initialize() -> void:
	var adaga := load("res://data/armas/adaga.tres") as Arma
	var espada_curta := load("res://data/armas/espada_curta.tres") as Arma
	var ficha := _ficha()
	var inventario := Inventario.new(3)
	_checar(Loja.preco(adaga) == 2, "a Adaga custa os 2 GP do livro")
	_checar(Loja.preco(espada_curta) == 10, "a Espada Curta custa 10 po")
	_checar(Loja.preco_de_venda(adaga) == 1, "a loja paga metade (mínimo 1)")
	_checar(Loja.preco(adaga.com_bonus_magico(2)) == 2 + Loja.EXTRA_POR_BONUS_MAGICO[2], "a arma mágica custa mais")
	_checar(Loja.comprar(espada_curta, ficha, inventario) == Loja.Resultado.SEM_OURO and inventario.itens.is_empty(), "sem ouro não compra")
	ficha.ouro = 25
	_checar(Loja.comprar(espada_curta, ficha, inventario) == Loja.Resultado.OK and ficha.ouro == 15, "comprar tira o ouro")
	_checar(inventario.itens.size() == 1 and inventario.itens[0] != espada_curta and inventario.itens[0].nome == "Espada Curta", "e põe uma cópia na mochila")
	ficha.talentos.append(Ficha.TALENTO_ARTESAO)
	_checar(Loja.preco_de_compra(espada_curta, ficha) == 8, "o Artesão tem 20% de desconto")
	ficha.talentos.clear()
	ficha.atributos[Atributos.CARISMA] = 16
	ficha.pericias = [Pericia.PERSUASAO]
	# CAR +3 + prof +2 = 5 → 10% de Persuasão
	_checar(is_equal_approx(Loja.desconto_de_compra(ficha), 0.1), "Persuasão +5 dá 10% de desconto")
	_checar(Loja.preco_de_compra(espada_curta, ficha) == 9, "10 po com 10% = 9")
	ficha.talentos.append(Ficha.TALENTO_ARTESAO)
	_checar(is_equal_approx(Loja.desconto_de_compra(ficha), 0.3), "Artesão + Persuasão somam")
	ficha.talentos.clear()
	ficha.pericias.clear()
	ficha.atributos[Atributos.CARISMA] = 10
	inventario.equipar(inventario.itens[0])
	_checar(Loja.vender(inventario.itens[0], ficha, inventario) == Loja.Resultado.OK and ficha.ouro == 20 and inventario.itens.is_empty(), "vender paga metade e tira da mochila")
	_checar(inventario.equipado(Item.ESPACO_MAO) == null, "vender o equipado esvazia a mão")
	_checar(Loja.vender(espada_curta, ficha, inventario) == Loja.Resultado.ITEM_INVALIDO, "não vende o que não está na mochila")
	var cheia := Inventario.new(1)
	cheia.adicionar(adaga.duplicate() as Item)
	ficha.ouro = 100
	_checar(Loja.comprar(espada_curta, ficha, cheia) == Loja.Resultado.MOCHILA_CHEIA and ficha.ouro == 100, "mochila cheia não gasta ouro")
	_checar(not Loja.fica_no_estoque(espada_curta), "arma comprada sai do estoque")
	_testar_estoque()
	_testar_renovar()
	_terminar("regra da loja e estoque")


func _testar_renovar() -> void:
	_checar(Loja.preco_da_renovacao(0) == 0, "1ª renovação é grátis")
	_checar(Loja.preco_da_renovacao(1) == 10, "2ª renovação custa 10 po")
	_checar(Loja.preco_da_renovacao(2) == 20, "3ª renovação custa 20 po")
	var ficha := _ficha()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	ficha.ouro = 0
	var sem := Loja.renovar(ficha, 1, 1, rng)
	_checar(sem.resultado == Loja.Resultado.SEM_OURO and ficha.ouro == 0, "sem ouro não renova")
	ficha.ouro = 25
	var gratis := Loja.renovar(ficha, 0, 1, rng)
	_checar(gratis.resultado == Loja.Resultado.OK and ficha.ouro == 25, "1ª renovação não gasta ouro")
	_checar((gratis.estoque as Array).size() == Loja.TAMANHO_DO_ESTOQUE, "renovar devolve estoque completo")
	var paga := Loja.renovar(ficha, 1, 1, rng)
	_checar(paga.resultado == Loja.Resultado.OK and ficha.ouro == 15, "2ª renovação tira 10 po")


func _testar_estoque() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var fase_1 := Loja.sortear_estoque(1, rng)
	var barato := true
	for item in fase_1:
		barato = barato and Loja.preco(item) <= Loja.TETO_DE_PRECO_NA_FASE_1 + Arma.BONUS_MAGICO_MAXIMO * 1000
		if item is Arma and (item as Arma).bonus_magico > 1:
			barato = false  # na fase 1 só +1
	_checar(fase_1.size() == Loja.TAMANHO_DO_ESTOQUE, "o estoque tem o tamanho certo")
	_checar(barato, "na fase 1 só aparece coisa barata e no máximo +1")
	var caro := false
	for i in 40:
		for item in Loja.sortear_estoque(8, rng):
			caro = caro or Loja.preco(item) > 100
	_checar(caro, "nas fases altas aparecem itens caros")
	var diferentes := {}
	for item in Loja.sortear_estoque(5, rng):
		diferentes[item.nome] = true
	_checar(diferentes.size() > 1, "o estoque tem variedade")


func _ficha() -> Ficha:
	return Ficha.new(load("res://data/classe_guerreiro.tres") as ClasseRPG, {&"forca": 15, &"destreza": 14, &"constituicao": 14, &"inteligencia": 10, &"sabedoria": 10, &"carisma": 10}, "Teste")
