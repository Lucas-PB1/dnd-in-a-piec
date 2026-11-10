extends TesteBase
## Talentos que criam sistemas novos: Durável (dados de vida), Envenenador (veneno e o item Veneno Básico)
## e Agarrador (condição Agarrado).
## godot --headless --debug --path . --script res://tests/heroi/teste_talentos_lote4.gd

var _classe: ClasseRPG


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_classe = load("res://data/classe_guerreiro.tres")
	_testar_regras_do_veneno()
	await _testar_agarrador()
	await _testar_no_heroi()
	print("PASSOU: talentos do lote 4" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _ficha() -> Ficha:
	var ficha := Ficha.new(_classe, {Atributos.FORCA: 15, Atributos.DESTREZA: 14, Atributos.CONSTITUICAO: 14})
	ficha.definir_nivel_inicial(4)
	return ficha


func _arma(nome: String) -> Arma:
	return load("res://data/armas/%s.tres" % nome)


func _testar_regras_do_veneno() -> void:
	var ficha := _ficha()
	_checar(ficha.dados_de_vida() == 0 and ficha.doses_de_veneno() == 0, "sem os talentos não há dados de vida nem doses")
	ficha.talentos.append(Ficha.TALENTO_DURAVEL)
	ficha.talentos.append(Ficha.TALENTO_ENVENENADOR)
	_checar(ficha.dados_de_vida() == 4 and ficha.doses_de_veneno() == 2, "Durável: 4 dados no nível 4; Envenenador: 2 doses")
	_checar(ficha.cd_veneno() == 8 + 2 + 2, "CD do veneno: 8 + melhor de DES e INT + proficiência")
	var golpe := Golpe.new("x", 0, Dado.new(1, 1))
	golpe.efeitos.append(EfeitosDeTalento.VenenoBasico.new())
	var usos: Array[StringName] = []
	golpe.efeito_usado.connect(func(e: StringName) -> void: usos.append(e))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var dano := Combate.dano_do_acerto(golpe, rng, false)
	_checar(dano >= 2 and dano <= 5 and usos == [Proficiencias.EFEITO_VENENO], "Veneno Básico soma 1d4 e gasta o veneno ao acertar")
	_checar(TiposDano.nome(TiposDano.VENENO) == "veneno", "o jogo conhece o tipo de dano veneno")


func _testar_agarrador() -> void:
	var soco: Arma = load("res://data/ataque_desarmado.tres")
	var ficha := _ficha()
	_checar(not ficha.golpe_com(soco).tem(Proficiencias.EFEITO_AGARRAR), "sem o talento o soco não agarra")
	ficha.talentos.append(Ficha.TALENTO_AGARRADOR)
	var golpe := ficha.golpe_com(soco)
	_checar(golpe.tem(Proficiencias.EFEITO_AGARRAR) and (golpe.efeito(Proficiencias.EFEITO_AGARRAR) as EfeitosDeTalento.Agarrar).cd == 8 + ficha.modificador(Atributos.FORCA) + Ficha.BONUS_PROFICIENCIA, "com o Agarrador o soco agarra, com CD 8 + FOR + proficiência")
	_checar(not ficha.golpe_com(_arma("espada_longa")).tem(Proficiencias.EFEITO_AGARRAR), "com uma arma na mão não agarra")
	var heroi := Node2D.new()
	root.add_child(heroi)
	var alvo := Node2D.new()
	var condicoes := CondicoesComponent.new()
	alvo.add_child(condicoes)
	root.add_child(alvo)
	golpe.autor_id = heroi.get_instance_id()
	(golpe.efeito(Proficiencias.EFEITO_AGARRAR) as EfeitosDeTalento.Agarrar).cd = 100  # ninguém escapa
	var resultado := Combate.Resultado.new()
	resultado.golpe = golpe
	resultado.acertou = true
	resultado.dano = 2
	condicoes.aplicar_maestria(resultado, 1.0)
	_checar(condicoes.tem(CondicoesComponent.AGARRADO) and condicoes.reducao_deslocamento_pes() >= 30.0, "o soco acertado agarra: o alvo fica sem deslocamento")
	var contra := Golpe.new("y", 0, Dado.new(1, 4))
	contra.autor_id = heroi.get_instance_id()
	condicoes.preparar_golpe_recebido(contra)
	_checar(contra.vantagem, "o herói ataca o agarrado com vantagem")
	var de_outro := Golpe.new("z", 0, Dado.new(1, 4))
	de_outro.autor_id = 12345
	condicoes.preparar_golpe_recebido(de_outro)
	_checar(not de_outro.vantagem, "outro atacante não ganha a vantagem")
	for i in 120:  # mais de uma rodada de tentativas com CD impossível
		await physics_frame
	_checar(condicoes.tem(CondicoesComponent.AGARRADO), "com CD impossível, o agarrado não escapa")
	condicoes.bonus_salvaguardas[Atributos.FORCA] = 100
	for i in 120:
		await physics_frame
	_checar(not condicoes.tem(CondicoesComponent.AGARRADO), "com bônus enorme, escapa na próxima tentativa (a cada rodada)")
	(golpe.efeito(Proficiencias.EFEITO_AGARRAR) as EfeitosDeTalento.Agarrar).cd = 100
	condicoes.bonus_salvaguardas.clear()
	condicoes.aplicar_maestria(resultado, 1.0)
	heroi.position.x = 500.0  # o herói se afastou
	await physics_frame
	await physics_frame
	_checar(not condicoes.tem(CondicoesComponent.AGARRADO), "se o herói se afasta, o agarrão se desfaz")
	# Envenenado: desvantagem enquanto durar.
	_checar(condicoes.rolar_veneno(Dado.new(2, 8), 100) >= 2 and condicoes.tem(CondicoesComponent.ENVENENADO), "falhou na salvaguarda: leva o dano de veneno e fica Envenenado")
	_checar(condicoes.consumir_desvantagem() and condicoes.consumir_desvantagem(), "Envenenado dá desvantagem em todo ataque enquanto dura")
	condicoes.bonus_salvaguardas[Atributos.CONSTITUICAO] = 100
	_checar(condicoes.rolar_veneno(Dado.new(2, 8), 5) == 0, "passou na salvaguarda: sem dano extra")
	heroi.queue_free()
	alvo.queue_free()
	await process_frame


func _testar_no_heroi() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 4:
		await process_frame
	var jogador: Jogador = main.get_node("Jogador")
	var vida: HealthComponent = jogador.get_node("Vida")
	main.tirar_criaturas()
	jogador.ficha.definir_nivel_inicial(4)
	# Durável
	_checar(not jogador.gastar_dado_de_vida(), "sem o Durável não há dados de vida")
	jogador.ficha.talentos.append(Ficha.TALENTO_DURAVEL)
	jogador.descansar_longo()
	_checar(jogador.dados_de_vida_restantes() == 4, "o Durável começa a fase com 4 dados de vida")
	_checar(not jogador.gastar_dado_de_vida(), "com a vida cheia o dado não é gasto")
	vida.receber_dano(10)
	var antes := jogador.vida_atual()
	_checar(jogador.gastar_dado_de_vida() and jogador.vida_atual() > antes and jogador.dados_de_vida_restantes() == 3, "gasta um dado de vida e cura o valor rolado")
	_checar(not jogador.gastar_dado_de_vida(), "é ação bônus: o segundo dado espera a rodada")
	jogador.descansar_longo()
	_checar(jogador.dados_de_vida_restantes() == 4, "a fase nova devolve todos os dados")
	# Veneno
	var espada := _arma("espada_longa").duplicate() as Arma
	jogador.inventario.adicionar(espada)
	jogador.inventario.equipar(espada)
	_checar(not jogador.aplicar_veneno(), "sem dose nem item não há veneno para passar")
	var frasco := (load("res://data/itens/veneno_basico.tres") as Item).duplicate() as Item
	jogador.inventario.adicionar(frasco)
	_checar(jogador.tem_item_veneno(), "o item Veneno Básico fica na mochila")
	jogador.descansar_longo()
	_checar(jogador.aplicar_veneno() and jogador.veneno_na_arma() == VenenoDoHeroi.BASICO, "o Veneno Básico é passado na espada")
	_checar(not jogador.tem_item_veneno(), "e o frasco é gasto")
	_checar(jogador.criar_golpe().tem(Proficiencias.EFEITO_VENENO), "o golpe leva +1d4 de veneno")
	jogador.criar_golpe().efeito_usado.emit(Proficiencias.EFEITO_VENENO)
	_checar(jogador.veneno_na_arma() == &"", "o primeiro acerto gasta o veneno")
	jogador.ficha.talentos.append(Ficha.TALENTO_ENVENENADOR)
	jogador.descansar_longo()
	_checar(jogador.doses_de_veneno() == 2, "o Envenenador começa a fase com 2 doses")
	jogador.descansar_longo()
	_checar(jogador.aplicar_veneno() and jogador.veneno_na_arma() == VenenoDoHeroi.POTENTE and jogador.doses_de_veneno() == 1, "a dose potente é passada (sobram 1)")
	var potente := jogador.criar_golpe()
	_checar(potente.tem(Proficiencias.EFEITO_VENENO) and (potente.efeito(Proficiencias.EFEITO_VENENO) as EfeitosDeTalento.VenenoPotente).cd == jogador.ficha.cd_veneno(),
		"o golpe leva 2d8 de veneno e a CD do Envenenador")
	main.free()
	await process_frame
