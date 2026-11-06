extends SceneTree
## Tiro à distância: K gasta munição e a arma fica; a mira sobe o arco; longe e perto
## dão desvantagem; os dois talentos de tiro tiram a parte que é deles.
## godot --headless --debug --path . --script res://tests/teste_tiro.gd

const CENA_VOO := "res://features/arremesso/arma_arremessada.tscn"
## Mira para cima (graus) que leva a pedra da funda além do alcance normal antes de cair.
const MIRA_LONGE := 20.0

var _falhas := 0


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_mao_da_besta()
	var cena: Main = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	cena.tirar_criaturas()
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
	_testar_curva(cena)
	await _testar_gesto(cena, jogador)
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
	var voo := _lancar(cena, funda, pedra, 1.0, MIRA_LONGE, golpe, false, Vector2(2400, 200))
	await _passar_do_normal(voo, 2400.0, normal)
	_checar(is_instance_valid(voo) and voo.em_desvantagem(), "passou do alcance normal: desvantagem")
	var elite := Golpe.new(funda.nome, 0, Dado.new(1, 4))
	var longo := _lancar(cena, funda, pedra, 1.0, MIRA_LONGE, elite, true, Vector2(2400, 180))
	await _passar_do_normal(longo, 2400.0, normal)
	_checar(is_instance_valid(longo) and not longo.em_desvantagem(), "Atirador de Elite: o longo não dá desvantagem")
	if is_instance_valid(voo):
		voo.free()
	if is_instance_valid(longo):
		longo.free()


func _testar_perto_e_talentos(cena: Node, jogador: Jogador) -> void:
	var ooze: Node2D = load("res://features/gray_ooze/gray_ooze.tscn").instantiate()
	ooze.add_to_group(&"monstros")
	cena.add_child(ooze)
	ooze.global_position = jogador.global_position
	(jogador.get_node("Defesa") as DefesaComponent).invulneravel = true
	jogador.ficha.talentos.clear()
	var golpes: Array[Golpe] = []
	jogador.arma_arremessada.connect(func(_a: Arma, g: Golpe, _p: int, _o: Vector2, _d: int, _f: float, _m: float, _mu: Municao, _i: bool, _des: int) -> void: golpes.append(g))
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


func _testar_curva(cena: Node) -> void:
	var guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")
	var referencia := Ficha.new(guerreiro, {Atributos.DESTREZA: 14})
	var media := Ficha.new(guerreiro, {Atributos.DESTREZA: 10})
	var baixa := Ficha.new(guerreiro, {Atributos.DESTREZA: 8})
	var alta := Ficha.new(guerreiro, {Atributos.DESTREZA: 18})
	_checar(is_equal_approx(referencia.teto_da_carga(), 1.0) and is_equal_approx(alta.teto_da_carga(), 1.0),
		"Destreza 14 ou mais enche até o alcance longo")
	_checar(media.teto_da_carga() > 0.4 and media.teto_da_carga() < 0.55, "Destreza 10 para perto do meio")
	_checar(baixa.teto_da_carga() > 0.0 and baixa.teto_da_carga() <= 0.25, "Destreza 8 quase não passa do normal")
	_checar(media.tempo_ate_teto_da_carga() > referencia.tempo_ate_teto_da_carga()
		and alta.tempo_ate_teto_da_carga() < referencia.tempo_ate_teto_da_carga(),
		"Destreza alta enche o teto dela mais rápido")
	var bala: Municao = load("res://data/municoes/bala.tres")
	var virote: Municao = load("res://data/municoes/virote.tres")
	var flecha: Municao = load("res://data/municoes/flecha.tres")
	var agulha: Municao = load("res://data/municoes/agulha.tres")
	var pedra: Municao = load("res://data/municoes/pedra_funda.tres")
	_checar(bala.peso < virote.peso and virote.peso < flecha.peso and flecha.peso < agulha.peso and agulha.peso < pedra.peso,
		"bala, virote, flecha, agulha e pedra, da mais reta para a mais curva (peso)")
	var funda: Arma = load("res://data/armas/funda.tres")
	var pedra_voo := _soltar(cena, funda, pedra, 1.0, 14)
	var bala_voo := _soltar(cena, funda, bala, 1.0, 14)
	_checar(bala_voo.velocity.length() > pedra_voo.velocity.length(), "na mesma arma, a bala sai mais rápida que a pedra")
	var lenta := _soltar(cena, funda, pedra, 1.0, 8)
	var rapida := _soltar(cena, funda, pedra, 1.0, 18)
	_checar(absf(rapida.velocity.x) > absf(lenta.velocity.x), "Destreza maior atira mais rápido")
	var flecha_longo := _soltar(cena, load("res://data/armas/arco_longo.tres"), flecha, 1.0, 14)
	var flecha_curto := _soltar(cena, load("res://data/armas/arco_curto.tres"), flecha, 1.0, 14)
	_checar(flecha_longo.velocity.length() > flecha_curto.velocity.length()
		and flecha_curto.velocity.length() > pedra_voo.velocity.length(),
		"pelo alcance longo do livro: arco longo mais rápido que o curto, e o curto mais que a funda")
	var toque := _soltar(cena, funda, pedra, 0.0, 14)
	_checar(toque.velocity.length() < pedra_voo.velocity.length(), "toque no K sai mais fraco que a carga cheia")
	for voo in [pedra_voo, bala_voo, lenta, rapida, flecha_longo, flecha_curto, toque]:
		voo.free()


func _soltar(cena: Node, arma: Arma, municao: Municao, forca: float, destreza: int) -> ArmaArremessada:
	return _lancar(cena, arma, municao, forca, 0.0, Golpe.new(arma.nome, 0, Dado.new(1, 4)), false,
		Vector2(3200, 200), destreza)


func _testar_gesto(cena: Node, jogador: Jogador) -> void:
	jogador.ficha.atributos[Atributos.DESTREZA] = 14
	var arco := _equipar(jogador, "arco_curto", "flecha", 4)
	jogador.global_position = Vector2(200, jogador.global_position.y)
	await _no_chao(jogador)
	await _olhar_esquerda(jogador)
	while not jogador.pode_golpear():
		await physics_frame
	Input.action_press("arremessar")
	for i in 5:
		await physics_frame
		if jogador.nome_estado() == &"Arremessando":
			break
	_checar(_indice_do_quadro(jogador) == 0, "toque curto mostra o preparo")
	for i in 50:
		await physics_frame
	_checar(_indice_do_quadro(jogador) == AtaqueJogador.PASSOS_DA_CARGA - 1, "segurar até o fim, com Destreza 14, mostra o quadro cheio")
	Input.action_release("arremessar")
	await physics_frame
	_checar(_indice_do_quadro(jogador) == AtaqueJogador.QUADRO_SOLTURA, "soltar mostra a soltura antes de voltar ao descanso")
	for i in 30:
		if jogador.nome_estado() != &"Arremessando":
			break
		await physics_frame
	_limpar_voos(cena)
	jogador.ficha.atributos[Atributos.DESTREZA] = 8
	while not jogador.pode_golpear():
		await physics_frame
	Input.action_press("arremessar")
	for i in 100:
		await physics_frame
	_checar(_indice_do_quadro(jogador) < AtaqueJogador.PASSOS_DA_CARGA - 1, "Destreza 8 não chega no quadro cheio")
	Input.action_release("arremessar")
	await physics_frame
	var tiro := _achar_voo(cena)
	var referencia := _soltar(cena, arco, load("res://data/municoes/flecha.tres"), jogador.teto_da_carga(), 8)
	_checar(tiro != null and absf(absf(tiro.velocity.x) - absf(referencia.velocity.x)) < 8.0,
		"segurar o K com Destreza 8 para no teto, antes do alcance longo")
	referencia.free()
	if tiro:
		tiro.free()
	jogador.ficha.atributos[Atributos.DESTREZA] = 14


func _limpar_voos(cena: Node) -> void:
	for filho in cena.get_children():
		if filho is ArmaArremessada:
			filho.free()


func _indice_do_quadro(jogador: Jogador) -> int:
	var sprite := jogador.get_node("Ataque/Espada") as Sprite2D
	var atlas := sprite.texture as AtlasTexture
	if atlas == null or atlas.region.size.x == 0.0:
		return -1
	return int(atlas.region.position.x / atlas.region.size.x)


func _lancar(cena: Node, arma: Arma, municao: Municao, forca: float, mira: float, golpe: Golpe, ignora: bool, origem: Vector2, destreza: int = 14) -> ArmaArremessada:
	var voo: ArmaArremessada = load(CENA_VOO).instantiate()
	cena.add_child(voo)
	voo.global_position = origem
	voo.lancar(arma, golpe, 0, 1, forca, mira, municao, ignora, destreza)
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
