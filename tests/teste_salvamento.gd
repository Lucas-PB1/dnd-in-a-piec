extends TesteBase
## Testa salvar e carregar: a ficha, a mochila (desgaste, pilhas, equipados) e a fase.
## godot --headless --debug --path . --script res://tests/teste_salvamento.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	Salvamento.caminho = "user://save_teste.json"  # nunca o save de verdade
	var guardado := Salvamento.caminho
	Salvamento.apagar()
	_checar(not Salvamento.existe() and Salvamento.ler().is_empty(), "sem arquivo: não há jogo salvo")

	var classe := load("res://data/classe_guerreiro.tres") as ClasseRPG
	var ficha := Ficha.new(classe, {Atributos.FORCA: 15, Atributos.CONSTITUICAO: 14}, "Aldric")
	ficha.definir_nivel_inicial(2)
	ficha.experiencia += 40
	ficha.pericias.append(&"percepcao")
	ficha.armas_dominadas.append("Espada Longa")
	var inventario := _montar_mochila()
	_checar(Salvamento.gravar(ficha, inventario, 3), "gravou o arquivo")
	_checar(Salvamento.existe(), "o arquivo existe depois de gravar")

	var dados := Salvamento.ler()
	_checar(Salvamento.fase_de(dados) == 3, "a fase salva volta (3)")
	var nova := Salvamento.montar_ficha(dados)
	_checar(nova != null and nova.nome == "Aldric" and nova.nivel == 2 and nova.experiencia == ficha.experiencia, "ficha: nome, nível e XP")
	_checar(nova.atributos[Atributos.FORCA] == 15 and nova.atributos[Atributos.CONSTITUICAO] == 14, "ficha: atributos")
	_checar(nova.pericias == ficha.pericias and nova.armas_dominadas == ficha.armas_dominadas, "ficha: perícias e armas dominadas")
	_checar(nova.classe == classe, "ficha: a mesma classe")

	var depois := Inventario.new()
	Salvamento.restaurar_inventario(dados, depois)
	_checar(depois.itens.size() == inventario.itens.size(), "mochila: mesma quantidade de lugares")
	_checar(_nomes(depois) == _nomes(inventario), "mochila: os mesmos itens na mesma ordem")
	var espada := depois.item_chamado("Espada Curta")
	_checar(depois.esta_equipado(espada), "mochila: a espada continua equipada")
	_checar(depois.penalidade(espada) == 2, "mochila: o desgaste volta (2)")
	_checar(depois.quantidade_de(depois.item_chamado("Azagaia")) == 4, "mochila: a pilha volta com 4")
	_checar(depois.equipados_em_ordem().size() == inventario.equipados_em_ordem().size(), "mochila: o mesmo número de equipados")

	var arquivo := FileAccess.open(guardado, FileAccess.WRITE)
	arquivo.store_string("isto não é json {")
	arquivo = null
	_checar(Salvamento.ler().is_empty(), "arquivo estragado: lê como vazio")
	Salvamento.apagar()
	_checar(not Salvamento.existe(), "apagar remove o arquivo")

	print("PASSOU: todos os testes do Salvamento" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _montar_mochila() -> Inventario:
	var inv := Inventario.new()
	var espada := Salvamento.item_chamado("Espada Curta").duplicate() as Item
	var cimitarra := Salvamento.item_chamado("Cimitarra").duplicate() as Item
	var azagaia := Salvamento.item_chamado("Azagaia").duplicate() as Item
	inv.adicionar(espada)
	inv.adicionar(cimitarra)
	inv.adicionar(azagaia, 4)
	inv.equipar(espada)
	inv.equipar(cimitarra)
	inv.desgastar(espada, 2, 99)
	return inv


func _nomes(inv: Inventario) -> Array[String]:
	var nomes: Array[String] = []
	for item in inv.itens:
		nomes.append(item.nome)
	return nomes
