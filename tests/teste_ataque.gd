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
	root.add_child(cena)
	_jogador = cena.get_node("Jogador")
	_boneco = cena.get_node("BonecoTreino")
	await _esperar(20)

	await _testar_golpe_no_chao()
	await _testar_golpe_de_costas()
	await _testar_golpe_no_ar()
	cena.queue_free()
	await _testar_boneco_sozinho()

	if _falhas == 0:
		print("PASSOU: todos os testes do ataque")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_golpe_no_chao() -> void:
	await _colocar_ao_lado_do_boneco()
	var espada: Node2D = _jogador.get_node("Ataque/Espada")
	await _apertar("atacar")
	_checar(_jogador.nome_estado() == &"Atacando", "J = estado Atacando")
	_checar(espada.visible, "espada aparece no golpe")
	_checar(_boneco.golpes_recebidos == 0, "não acerta antes da janela de acerto")
	await _esperar_golpe_acabar()
	_checar(_boneco.golpes_recebidos == 1, "acerta o boneco UMA vez por golpe (deu %d)" % _boneco.golpes_recebidos)
	_checar(not espada.visible, "espada some no fim do golpe")
	_checar(absf(_jogador.velocity.x) < 1.0, "no chão o herói fica parado golpeando")
	await _esperar(2)
	_checar(_jogador.nome_estado() == &"Parado", "depois do golpe volta para Parado")
	await _apertar("atacar")
	await _esperar_golpe_acabar()
	_checar(_boneco.golpes_recebidos == 2, "segundo golpe acerta de novo")


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
