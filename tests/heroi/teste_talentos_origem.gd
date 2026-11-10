extends TesteBase
## Efeitos dos talentos de origem: Alerta, Resistente, Atacante Selvagem e Brigão de Taverna
## (Sortudo, Artesão e Perito têm testes próprios).
## godot --headless --debug --path . --script res://tests/heroi/teste_talentos_origem.gd

var _classe: ClasseRPG


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_classe = load("res://data/classe_guerreiro.tres")
	_testar_alerta()
	_testar_resistente()
	_testar_brigao()
	_testar_atacante_selvagem()
	await _testar_recarga_no_heroi()
	await _testar_sorte()
	await _testar_artesao()
	print("PASSOU: talentos de origem" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _ficha(nivel: int = 1) -> Ficha:
	var ficha := Ficha.new(_classe, {Atributos.FORCA: 15, Atributos.DESTREZA: 14, Atributos.CONSTITUICAO: 14})
	ficha.definir_nivel_inicial(nivel)
	return ficha


func _testar_alerta() -> void:
	var ficha := _ficha()
	_checar(ficha.iniciativa() == 2 and is_equal_approx(EscalaDnd.intervalo_ataque(ficha.iniciativa()), 0.8),
		"sem Alerta: iniciativa +2, 0,8 s entre ataques")
	ficha.talentos.append(Ficha.TALENTO_ALERTA)
	_checar(ficha.iniciativa() == 4 and is_equal_approx(EscalaDnd.intervalo_ataque(ficha.iniciativa()), 0.6),
		"com Alerta: +2 de proficiência, iniciativa +4, 0,6 s entre ataques")


func _testar_resistente() -> void:
	var ficha := _ficha(4)
	var sem := ficha.vida_maxima()
	ficha.talentos.append(Ficha.TALENTO_RESISTENTE)
	_checar(ficha.vida_maxima() == sem + 8, "Resistente: +2 PV por nível (nível 4: +8)")
	var nivel_1 := _ficha(1)
	var base := nivel_1.vida_maxima()
	nivel_1.talentos.append(Ficha.TALENTO_RESISTENTE)
	_checar(nivel_1.vida_maxima() == base + 2, "Resistente no nível 1: +2 PV")


func _testar_brigao() -> void:
	var soco: Arma = load("res://data/ataque_desarmado.tres")
	var ficha := _ficha()
	_checar(ficha.dado_dano(soco).faces == 1, "sem o talento o soco é 1d1")
	var golpe_antes := ficha.golpe_com(soco)
	_checar(not golpe_antes.rerrola_um() and not golpe_antes.tem(Proficiencias.EFEITO_BRIGAO), "sem o talento o soco não empurra nem rerrola")
	ficha.talentos.append(Ficha.TALENTO_BRIGAO)
	var dado := ficha.dado_dano(soco)
	_checar(dado.quantidade == 1 and dado.faces == 4 and dado.bonus == ficha.modificador(Atributos.FORCA),
		"Brigão: o soco passa a 1d4 + Força")
	var golpe := ficha.golpe_com(soco)
	_checar(golpe.rerrola_um() and golpe.tem(Proficiencias.EFEITO_BRIGAO), "o golpe do soco rerrola 1 e empurra 5 pés")
	var espada: Arma = load("res://data/armas/espada_longa.tres")
	var golpe_espada := ficha.golpe_com(espada)
	_checar(not golpe_espada.rerrola_um() and not golpe_espada.tem(Proficiencias.EFEITO_BRIGAO), "com arma na mão o Brigão não vale")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var dado_d4 := Dado.new(1, 4)
	var uns := 0
	for i in 400:
		if dado_d4.rolar(rng, false, true) == 1:
			uns += 1
	var sem_rerrolar := 0
	for i in 400:
		if dado_d4.rolar(rng) == 1:
			sem_rerrolar += 1
	_checar(uns < sem_rerrolar, "rerrolar o 1 deixa o 1 menos frequente (%d contra %d em 400)" % [uns, sem_rerrolar])


func _testar_atacante_selvagem() -> void:
	var golpe := Golpe.new("teste", 0, Dado.new(1, 20))
	var usos: Array[StringName] = []
	golpe.efeito_usado.connect(func(e: StringName) -> void: usos.append(e))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var soma_normal := 0
	for i in 600:
		soma_normal += Combate.dano_do_acerto(golpe, rng, false)
	_checar(usos.is_empty(), "sem o talento o golpe não avisa gasto de efeito")
	golpe.efeitos.append(EfeitosDeTalento.AtacanteSelvagem.new())
	var soma_selvagem := 0
	for i in 600:
		soma_selvagem += Combate.dano_do_acerto(golpe, rng, false)
	_checar(soma_selvagem > soma_normal + 600 * 3, "Atacante Selvagem rola duas vezes e fica o maior (média sobe)")
	_checar(usos.size() == 600 and usos[0] == Proficiencias.EFEITO_SELVAGEM, "cada acerto avisa que gastou o efeito")


func _testar_recarga_no_heroi() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 4:
		await process_frame
	var jogador: Jogador = main.get_node("Jogador")
	jogador.ficha.talentos.append(Ficha.TALENTO_ATACANTE_SELVAGEM)
	var primeiro := jogador.criar_golpe()
	_checar(primeiro.rola_duas_vezes(), "o herói com o talento monta o golpe com o efeito ligado")
	primeiro.efeito_usado.emit(Proficiencias.EFEITO_SELVAGEM)
	_checar(not jogador.criar_golpe().rola_duas_vezes(), "depois de gastar, o efeito fica desligado na mesma rodada")
	for i in 100:
		await physics_frame
	_checar(jogador.criar_golpe().rola_duas_vezes(), "passada a rodada (1,5 s) o efeito volta")
	main.free()
	await process_frame


func _testar_sorte() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 4:
		await process_frame
	var jogador: Jogador = main.get_node("Jogador")
	var hud: Hud = main.get_node("Hud")
	_checar(not jogador.armar_sorte() and jogador.pontos_sorte_total() == 0, "sem o Sortudo não há sorte para armar")
	jogador.ficha.talentos.append(Ficha.TALENTO_SORTUDO)
	jogador.descansar_longo()
	_checar(jogador.pontos_sorte() == 2 and not jogador.sorte_armada(), "o Sortudo começa a fase com 2 pontos (a proficiência)")
	_checar((hud.get_node("%Sorte") as Label).visible and (hud.get_node("%Sorte") as Label).text == "Sorte 2/2", "o HUD mostra Sorte 2/2")
	Input.action_press(&"sorte")
	await physics_frame
	await physics_frame
	Input.action_release(&"sorte")
	_checar(jogador.sorte_armada() and (hud.get_node("%Sorte") as Label).text == "Sorte 2/2 · armada", "a tecla G arma a sorte")
	_checar(not jogador.armar_sorte(), "já armada, não arma de novo")
	var golpe := jogador.criar_golpe()
	_checar(golpe.vantagem and jogador.pontos_sorte() == 1 and not jogador.sorte_armada(), "o próximo ataque sai com vantagem e gasta 1 ponto")
	_checar(not jogador.criar_golpe().vantagem, "o ataque seguinte volta ao normal")
	jogador.armar_sorte()
	_checar(jogador.pontos_sorte() == 1 and jogador.sorte_armada(), "com 1 ponto ainda dá para armar")
	jogador.criar_golpe()
	_checar(jogador.pontos_sorte() == 0 and not jogador.armar_sorte(), "sem pontos a sorte não arma")
	jogador.descansar_longo()
	_checar(jogador.pontos_sorte() == 2, "a fase nova devolve os pontos")
	main.free()
	await process_frame


func _testar_artesao() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var a := ItemAleatorio.sortear(rng)
	var b := ItemAleatorio.sortear(rng)
	_checar(a != null and (a is Arma or a is Armadura), "o sorteio devolve uma arma ou armadura do arsenal")
	_checar(a != b, "cada sorteio é uma cópia nova")
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 4:
		await process_frame
	var jogador: Jogador = main.get_node("Jogador")
	jogador.inventario.limpar()
	jogador.ganhar_item_do_artesao()
	_checar(jogador.inventario.itens.is_empty(), "sem o talento nada cai na mochila")
	jogador.ficha.talentos.append(Ficha.TALENTO_ARTESAO)
	jogador.ganhar_item_do_artesao()
	_checar(jogador.inventario.itens.size() == 1, "com o Artesão, um item cai na mochila")
	main._entrar_fase(load("res://levels/fase_2.tscn"))
	await physics_frame
	_checar(jogador.inventario.itens.size() == 2, "entrar numa fase nova traz mais um item")
	while not jogador.inventario.esta_cheio():
		jogador.inventario.adicionar(load("res://data/armas/adaga.tres").duplicate())
	var antes := jogador.inventario.itens.size()
	jogador.ganhar_item_do_artesao()
	_checar(jogador.inventario.itens.size() == antes, "mochila cheia: o item não entra")
	main.free()
	await process_frame
