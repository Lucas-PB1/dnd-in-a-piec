extends SceneTree
## Tiro à distância: K gasta munição e a arma fica; a mira sobe o arco; longe e perto
## dão desvantagem; os dois talentos de tiro tiram a parte que é deles.
## godot --headless --debug --path . --script res://tests/teste_tiro.gd

const CENA_VOO := "res://features/arremesso/arma_arremessada.tscn"

var _falhas := 0


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_mao_da_besta()
	var cena: Node = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	await physics_frame
	var jogador: Jogador = cena.get_node("Jogador")
	jogador.global_position = Vector2(200, jogador.global_position.y)
	await _no_chao(jogador)
	await _testar_disparo(cena, jogador)
	await _testar_sem_municao(jogador)
	await _testar_j_nao_corta(jogador)
	await _testar_mira(cena, jogador)
	await _testar_alcance(cena)
	await _testar_perto_e_talentos(cena, jogador)
	await _testar_tiro_extra(jogador)
	cena.queue_free()
	if _falhas == 0:
		print("PASSOU: todos os testes do tiro")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_mao_da_besta() -> void:
	var inv := Inventario.new()
	var espada: Arma = load("res://data/armas/espada_curta.tres").duplicate()
	var besta: Arma = load("res://data/armas/besta_mao.tres").duplicate()
	inv.adicionar(espada)
	inv.adicionar(besta)
	inv.equipar(espada)
	inv.equipar(besta)
	_checar(inv.equipado(Item.ESPACO_MAO) == besta and inv.livre(Item.ESPACO_MAO_SECUNDARIA),
		"Besta de Mão não vira a 2ª arma leve")


func _testar_disparo(cena: Node, jogador: Jogador) -> void:
	var funda := _equipar(jogador, "funda", "pedra_funda", 3)
	await _olhar_esquerda(jogador)
	await _toque_k()
	var pedras := jogador.inventario.item_chamado("Pedra de Funda")
	_checar(jogador.inventario.quantidade_de(pedras) == 2 and jogador.inventario.esta_equipado(funda),
		"o tiro gasta 1 pedra e a funda continua na mão")
	var voo := _achar_voo(cena)
	_checar(voo != null, "a pedra saiu voando")
	for i in 90:
		if _achar_voo(cena) == null:
			break
		await physics_frame
	_checar(_achar_voo(cena) == null, "a munição some ao cair (não fica para pegar)")


func _testar_sem_municao(jogador: Jogador) -> void:
	var pedras := jogador.inventario.item_chamado("Pedra de Funda")
	jogador.inventario.descartar(pedras)
	await _toque_k()
	_checar(jogador.nome_estado() != &"Arremessando" and jogador.inventario.item_chamado("Pedra de Funda") == null,
		"sem munição não dispara")


func _testar_j_nao_corta(jogador: Jogador) -> void:
	await _no_chao(jogador)
	while not jogador.pode_golpear():
		await physics_frame
	Input.action_press("atacar")
	await physics_frame
	Input.action_release("atacar")
	await physics_frame
	_checar(jogador.nome_estado() != &"Atacando", "J não dá corte com arma à distância")


func _testar_mira(cena: Node, jogador: Jogador) -> void:
	var funda: Arma = load("res://data/armas/funda.tres")
	var pedra: Municao = load("res://data/municoes/pedra_funda.tres")
	var chao := jogador.global_position.y
	var reto := _voar(cena, funda, pedra, 0.0, chao)
	var alto := _voar(cena, funda, pedra, 60.0, chao)
	for i in 8:
		await physics_frame
	_checar(alto.global_position.y < reto.global_position.y - 4.0, "mirar para cima levanta o voo")
	reto.free()
	alto.free()


func _testar_alcance(cena: Node) -> void:
	var funda: Arma = load("res://data/armas/funda.tres")
	var pedra: Municao = load("res://data/municoes/pedra_funda.tres")
	var normal := EscalaDnd.pes_para_pixels(funda.disparo_normal_pes)
	var golpe := Golpe.new(funda.nome, 0, Dado.new(1, 4))
	var voo := _lancar(cena, funda, pedra, 1.0, 0.0, golpe, false, Vector2(2400, 200))
	await _passar_do_normal(voo, 2400.0, normal)
	_checar(is_instance_valid(voo) and voo.em_desvantagem(), "passou do alcance normal: desvantagem")
	var elite := Golpe.new(funda.nome, 0, Dado.new(1, 4))
	var longo := _lancar(cena, funda, pedra, 1.0, 0.0, elite, true, Vector2(2400, 180))
	await _passar_do_normal(longo, 2400.0, normal)
	_checar(is_instance_valid(longo) and not longo.em_desvantagem(), "Atirador de Elite: o longo não dá desvantagem")
	if is_instance_valid(voo):
		voo.free()
	if is_instance_valid(longo):
		longo.free()


func _testar_perto_e_talentos(cena: Node, jogador: Jogador) -> void:
	var ooze: Node2D = cena.get_node("GrayOoze")
	(jogador.get_node("Defesa") as DefesaComponent).invulneravel = true
	jogador.global_position = ooze.global_position
	jogador.ficha.talentos.clear()
	var golpes: Array[Golpe] = []
	jogador.arma_arremessada.connect(func(_a: Arma, g: Golpe, _p: int, _o: Vector2, _d: int, _f: float, _m: float, _mu: Municao, _i: bool) -> void: golpes.append(g))
	_equipar(jogador, "funda", "pedra_funda", 2)
	await _no_chao(jogador)
	while not jogador.pode_golpear():
		await physics_frame
	await _toque_k()
	_checar(not golpes.is_empty() and golpes[0].desvantagem, "inimigo a 5 pés: o tiro sai com desvantagem")
	jogador.ficha.talentos.append(Ficha.TALENTO_ESPECIALISTA_EM_BESTA)
	_equipar(jogador, "besta_mao", "virote", 4)
	while not jogador.pode_golpear():
		await physics_frame
	await _toque_k()
	_checar(golpes.size() >= 2 and not golpes[1].desvantagem, "Especialista em Besta: besta de perto não leva desvantagem")


func _testar_tiro_extra(jogador: Jogador) -> void:
	jogador.global_position = Vector2(200, jogador.global_position.y)
	await _no_chao(jogador)
	while not jogador.pode_golpear():
		await physics_frame
	var antes := jogador.inventario.quantidade_de(jogador.inventario.item_chamado("Virote"))
	Input.action_press("arremessar")
	await physics_frame
	await physics_frame
	Input.action_release("arremessar")
	await physics_frame
	Input.action_press("arremessar")
	await physics_frame
	await physics_frame
	Input.action_release("arremessar")
	await physics_frame
	var virotes := jogador.inventario.item_chamado("Virote")
	_checar(jogador.inventario.quantidade_de(virotes) == antes - 2 and not jogador.acao_bonus_livre(),
		"Especialista em Besta: o segundo K gasta a ação bônus e outro virote")


func _equipar(jogador: Jogador, arma_id: String, municao_id: String, quantidade: int) -> Arma:
	var arma: Arma = load("res://data/armas/%s.tres" % arma_id).duplicate()
	var municao: Municao = load("res://data/municoes/%s.tres" % municao_id)
	jogador.inventario.adicionar(arma)
	jogador.inventario.adicionar(municao.duplicate(), quantidade)
	jogador.inventario.equipar(arma)
	return arma


## Espera o projétil passar do alcance normal e mais um quadro: a desvantagem é marcada
## no quadro seguinte ao que a posição cruza a linha.
func _passar_do_normal(voo: ArmaArremessada, origem_x: float, normal: float) -> void:
	for i in 180:
		if not is_instance_valid(voo):
			return
		if absf(voo.global_position.x - origem_x) > normal + 16.0:
			await physics_frame
			return
		await physics_frame


func _voar(cena: Node, arma: Arma, municao: Municao, mira: float, chao_y: float) -> ArmaArremessada:
	return _lancar(cena, arma, municao, 0.0, mira, Golpe.new(arma.nome, 0, Dado.new(1, 4)), false,
		Vector2(3000, chao_y - ArmaArremessada.ALTURA_DA_MAO))


func _lancar(cena: Node, arma: Arma, municao: Municao, forca: float, mira: float, golpe: Golpe, ignora: bool, origem: Vector2) -> ArmaArremessada:
	var voo: ArmaArremessada = load(CENA_VOO).instantiate()
	cena.add_child(voo)
	voo.global_position = origem
	voo.lancar(arma, golpe, 0, 1, forca, mira, municao, ignora)
	return voo


func _achar_voo(cena: Node) -> ArmaArremessada:
	for filho in cena.get_children():
		if filho is ArmaArremessada and not filho.is_queued_for_deletion():
			return filho
	return null


func _toque_k() -> void:
	Input.action_press("arremessar")
	await physics_frame
	await physics_frame
	Input.action_release("arremessar")
	await physics_frame


func _olhar_esquerda(jogador: Jogador) -> void:
	Input.action_press("mover_esquerda")
	await physics_frame
	Input.action_release("mover_esquerda")
	await physics_frame
	jogador.direcao_olhar = -1


func _no_chao(jogador: Jogador) -> void:
	for i in 60:
		if jogador.is_on_floor():
			return
		await physics_frame


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
