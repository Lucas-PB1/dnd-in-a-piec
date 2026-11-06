extends SceneTree
## Teste do golpe de espada e do boneco de treino (roda sem janela).
## godot --headless --debug --path . --script res://tests/teste_ataque.gd

const DISTANCIA_DO_BONECO := 30.0

var _falhas := 0
var _jogador: Jogador
var _boneco: BonecoTreino


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var cena: Node = load("res://levels/main.tscn").instantiate()
	cena.mostrar_criacao = false  # joga direto com a sugestão da classe
	root.add_child(cena)
	_jogador = cena.get_node("Jogador")
	_boneco = cena.get_node("BonecoTreino")
	await _esperar(20)

	await _testar_soco_desarmado()
	_checar(_jogador.inventario.equipar(_jogador.inventario.itens[0]), "equipa a espada da mochila")
	await _testar_espada_na_mao()
	await _testar_golpe_no_chao()
	await _testar_golpe_de_costas()
	await _testar_golpe_no_ar()
	await _testar_dano_rolado()
	cena.queue_free()
	await _testar_boneco_sozinho()

	if _falhas == 0:
		print("PASSOU: todos os testes do ataque")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


## Sem arma na mão: soco de D&D = 1 + mod. de Força (FOR 15 da sugestão -> 3), sem espada visível.
func _testar_soco_desarmado() -> void:
	_checar(_jogador.inventario.equipado(Item.ESPACO_MAO) == null, "começa com a espada na mochila, mão vazia")
	_checar(_jogador.arma_atual() == _jogador.ataque_desarmado, "mão vazia = ataque desarmado")
	var danos: Array[int] = []
	var registrar := func(dano: int) -> void: danos.append(dano)
	_boneco.atingido.connect(registrar)
	await _colocar_ao_lado_do_boneco()
	await _apertar("atacar")
	_checar(not (_jogador.get_node("Ataque/Espada") as Node2D).visible or \
		(_jogador.get_node("Ataque/Espada") as Sprite2D).texture == null, "soco não mostra espada")
	await _esperar_golpe_acabar()
	var esperado := 1 + _jogador.ficha.modificador(Atributos.FORCA)
	_checar(danos == [esperado], "soco acerta com dano %d (deu %s)" % [esperado, str(danos)])
	_boneco.atingido.disconnect(registrar)
	await _esperar(2)


func _testar_golpe_no_chao() -> void:
	await _colocar_ao_lado_do_boneco()
	var espada: Node2D = _jogador.get_node("Ataque/Espada")
	var antes := _boneco.golpes_recebidos
	await _apertar("atacar")
	_checar(_jogador.nome_estado() == &"Atacando", "J = estado Atacando")
	_checar(espada.visible, "espada aparece no golpe")
	_checar(_boneco.golpes_recebidos == antes, "não acerta antes da janela de acerto")
	await _esperar_golpe_acabar()
	_checar(_boneco.golpes_recebidos == antes + 1,
		"acerta o boneco UMA vez por golpe (deu %d)" % (_boneco.golpes_recebidos - antes))
	await _esperar(1)
	var animacao: AnimacaoJogador = _jogador.get_node("Sprite")
	_checar(espada.visible and is_equal_approx((espada as Sprite2D).rotation_degrees, animacao.angulo_descanso()),
		"no fim do golpe a espada volta para a mão em repouso")
	_checar(absf(_jogador.velocity.x) < 1.0, "no chão o herói fica parado golpeando")
	await _esperar(2)
	_checar(_jogador.nome_estado() == &"Parado", "depois do golpe volta para Parado")
	await _apertar("atacar")
	await _esperar_golpe_acabar()
	_checar(_boneco.golpes_recebidos == antes + 2, "segundo golpe acerta de novo")


## Equipada, a espada fica na mão da frente (ponto do quadro atual), dos dois lados.
func _testar_espada_na_mao() -> void:
	var ataque: Node2D = _jogador.get_node("Ataque")
	var espada: Sprite2D = _jogador.get_node("Ataque/Espada")
	var animacao: AnimacaoJogador = _jogador.get_node("Sprite")
	await _esperar(3)
	_checar(espada.visible and espada.texture != null, "espada equipada aparece na mão, parado")
	_checar(ataque.position.distance_to(animacao.ponto_da_mao()) < 0.5, "arma está no ponto da mão do quadro atual")
	_checar(ataque.position.x > 0.0, "olhando para a direita, a mão está à frente (x > 0)")
	await _apertar("mover_esquerda")
	await _esperar(3)
	_checar(ataque.position.x < 0.0 and ataque.scale.x < 0.0, "virado para a esquerda, mão e espada espelham")
	Input.action_press("mover_direita")
	await _esperar(20)
	_checar(espada.visible and ataque.position.distance_to(animacao.ponto_da_mao()) < 0.5,
		"andando, a espada acompanha a mão")
	Input.action_release("mover_direita")
	await _esperar(30)
	_jogador.inventario.desequipar(Item.ESPACO_MAO)
	await _esperar(2)
	_checar(not espada.visible, "desequipada, a espada some da mão")
	_jogador.inventario.equipar(_jogador.inventario.itens[0])
	await _esperar(2)


func _testar_golpe_de_costas() -> void:
	await _colocar_ao_lado_do_boneco()
	await _apertar("mover_esquerda")  # vira de costas para o boneco
	await _esperar(10)
	var antes := _boneco.golpes_recebidos
	await _apertar("atacar")
	await _esperar_golpe_acabar()
	_checar(_boneco.golpes_recebidos == antes, "golpe de costas não acerta o boneco")


func _testar_golpe_no_ar() -> void:
	await _colocar_ao_lado_do_boneco()
	Input.action_press("pular")
	await _esperar(8)
	await _apertar("atacar")
	_checar(_jogador.nome_estado() == &"Atacando" and not _jogador.is_on_floor(), "golpeia no ar")
	Input.action_release("pular")
	await _esperar_golpe_acabar()
	await _esperar(2)
	_checar(_jogador.nome_estado() in [&"NoAr", &"Parado"], "depois do golpe no ar continua caindo ou já pousou")
	for i in 120:
		if _jogador.is_on_floor() and _jogador.nome_estado() == &"Parado":
			break
		await physics_frame
	_checar(_jogador.nome_estado() == &"Parado", "pousa depois do golpe no ar")


## Cada golpe rola 1d6 + modificador (FOR ou DES, o maior, porque a espada curta tem acuidade).
func _testar_dano_rolado() -> void:
	const GOLPES := 12
	var arma := _jogador.arma_atual()
	var bonus := _jogador.ficha.bonus_dano(arma)
	var minimo := arma.dado().minimo() + bonus
	var maximo := arma.dado().maximo() + bonus
	var danos: Array[int] = []
	_boneco.atingido.connect(func(dano: int) -> void: danos.append(dano))
	await _colocar_ao_lado_do_boneco()
	for i in GOLPES:
		await _apertar("atacar")
		await _esperar_golpe_acabar()
		await _esperar(2)
	var dentro := danos.all(func(d: int) -> bool: return d >= minimo and d <= maximo)
	var diferentes := {}
	for d in danos:
		diferentes[d] = true
	_checar(danos.size() == GOLPES and dentro, "dano de cada golpe entre %d e %d (%s)" % [minimo, maximo, str(danos)])
	_checar(diferentes.size() > 1, "o dano varia de um golpe para outro")


## A cena do boneco roda sozinha (como no F6) e reage a um golpe.
func _testar_boneco_sozinho() -> void:
	var boneco: BonecoTreino = load("res://features/boneco_treino/boneco_treino.tscn").instantiate()
	root.add_child(boneco)
	await _esperar(2)
	var recebido := [0]
	boneco.atingido.connect(func(dano: int) -> void: recebido[0] = dano)
	(boneco.get_node("Hurtbox") as HurtboxComponent).receber_golpe(5, boneco.global_position + Vector2.LEFT)
	_checar(boneco.golpes_recebidos == 1 and recebido[0] == 5, "boneco sozinho recebe golpe e avisa o dano")
	boneco.queue_free()


func _colocar_ao_lado_do_boneco() -> void:
	for i in 60:  # espera terminar qualquer golpe/pulo anterior
		if _jogador.is_on_floor() and not _jogador.esta_golpeando():
			break
		await physics_frame
	var y_chao := _jogador.global_position.y
	_jogador.posicionar_no_inicio(Vector2(_boneco.global_position.x - DISTANCIA_DO_BONECO, y_chao))
	_jogador.velocity = Vector2.ZERO
	await _apertar("mover_direita")  # olha para o boneco
	await _esperar(20)


func _apertar(acao: String) -> void:
	Input.action_press(acao)
	await physics_frame
	Input.action_release(acao)
	await physics_frame


func _esperar_golpe_acabar() -> void:
	for i in 60:
		if not _jogador.esta_golpeando():
			return
		await physics_frame


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
