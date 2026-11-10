extends TesteBase
## Teste da regra pura do Inventario.
## godot --headless --debug --path . --script res://tests/regras/teste_inventario.gd


func _initialize() -> void:
	var espada: Arma = load("res://data/armas/espada_curta.tres")
	var outra_espada := espada.duplicate() as Arma
	outra_espada.nome = "Espada Velha"
	var pedra := Item.new()
	pedra.nome = "Pedra"

	var inv := Inventario.new(2)
	var mudancas := [0]
	inv.mudou.connect(func() -> void: mudancas[0] += 1)

	_checar(inv.adicionar(espada) and inv.adicionar(pedra), "adiciona itens")
	_checar(inv.esta_cheio() and not inv.adicionar(outra_espada), "não passa da capacidade")
	_checar(inv.equipado(Item.ESPACO_MAO) == null, "começa sem nada na mão")
	_checar(not inv.equipar(pedra), "item não equipável não equipa")
	_checar(inv.equipar(espada) and inv.equipado(Item.ESPACO_MAO) == espada, "equipa a espada na mão")
	_checar(inv.esta_equipado(espada) and espada in inv.itens, "equipado continua na lista")
	_checar(not inv.equipar(outra_espada), "não equipa item que não está no inventário")
	_checar(inv.desequipar(Item.ESPACO_MAO) and inv.equipado(Item.ESPACO_MAO) == null, "desequipa")
	_checar(not inv.desequipar(Item.ESPACO_MAO), "desequipar espaço vazio não faz nada")
	inv.equipar(espada)
	_checar(inv.descartar(espada), "joga fora a espada")
	_checar(espada not in inv.itens and inv.equipado(Item.ESPACO_MAO) == null, "jogar fora item equipado desequipa antes")
	_checar(not inv.descartar(espada), "não joga fora o que não tem")
	_checar(mudancas[0] == 6, "avisa cada mudança (deu %d)" % mudancas[0])

	var troca := Inventario.new()
	troca.adicionar(espada)
	troca.adicionar(outra_espada)
	troca.equipar(espada)
	troca.equipar(outra_espada)
	_checar(troca.equipado(Item.ESPACO_MAO) == espada
		and troca.equipado(Item.ESPACO_MAO_SECUNDARIA) == outra_espada and troca.itens.size() == 2,
		"segunda arma leve vai para a outra mão")
	var terceira := espada.duplicate() as Arma
	terceira.nome = "Espada Nova"
	troca.adicionar(terceira)
	troca.equipar(terceira)
	_checar(troca.equipado(Item.ESPACO_MAO) == terceira
		and troca.equipado(Item.ESPACO_MAO_SECUNDARIA) == outra_espada,
		"com as duas mãos ocupadas, equipar troca a mão principal")

	# Sair da mão principal promove a arma da outra mão
	troca.desequipar(Item.ESPACO_MAO)
	_checar(troca.equipado(Item.ESPACO_MAO) == outra_espada and troca.equipado(Item.ESPACO_MAO_SECUNDARIA) == null,
		"desequipar a mão principal faz a arma da outra mão virar a principal")
	troca.equipar(terceira)
	troca.descartar(troca.equipado(Item.ESPACO_MAO))
	_checar(troca.equipado(Item.ESPACO_MAO) != null and troca.equipado(Item.ESPACO_MAO_SECUNDARIA) == null,
		"jogar fora a arma principal também promove a outra")

	if _falhas == 0:
		print("PASSOU: todos os testes do inventário")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)
