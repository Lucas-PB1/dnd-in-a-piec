extends SceneTree
## Teste automático do herói 2D (roda sem janela).
## godot --headless --path . --script res://tests/teste_jogador.gd

var _falhas := 0
var _jogador: Jogador
var _sprite: AnimatedSprite2D


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var cena: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	_jogador = cena.get_node("Jogador")
	_sprite = _jogador.get_node("Sprite")
	var camera: Camera2D = _jogador.get_node("Camera")

	await _esperar(20)
	_checar(_jogador.is_on_floor(), "começa no chão")
	_checar(_sprite.animation == &"idle", "parado toca idle")
	_checar(camera.limit_left == 0, "câmera limitada à esquerda da fase")
	var inicio := _jogador.global_position

	# Corre para a direita
	Input.action_press("mover_direita")
	await _esperar(30)
	_checar(_jogador.global_position.x > inicio.x + 40.0, "corre para a direita")
	_checar(_sprite.animation == &"walk", "correndo toca walk")
	_checar(not _sprite.flip_h and _jogador.direcao_olhar == 1, "olha para a direita")
	Input.action_release("mover_direita")

	# Vira para a esquerda
	Input.action_press("mover_esquerda")
	await _esperar(10)
	_checar(_sprite.flip_h and _jogador.direcao_olhar == -1, "espelha ao ir para a esquerda")
	Input.action_release("mover_esquerda")
	await _esperar(30)
	_checar(absf(_jogador.velocity.x) < 0.01, "para ao soltar")

	# Pulo cheio (segura o botão)
	var altura_cheia := await _medir_pulo(60)
	_checar(absf(altura_cheia - _jogador.altura_pulo) < 12.0,
		"pulo cheio ~%.0f px (deu %.0f)" % [_jogador.altura_pulo, altura_cheia])

	# Pulo curto (toque rápido)
	var altura_curta := await _medir_pulo(2)
	_checar(altura_curta < altura_cheia * 0.6,
		"toque rápido pula mais baixo (%.0f < %.0f)" % [altura_curta, altura_cheia])

	# Buffer: aperta pular pouco antes de tocar o chão
	Input.action_press("pular")
	await _esperar(1)
	Input.action_release("pular")
	while _jogador.velocity.y <= 0.0:  # espera começar a cair
		await physics_frame
	while _jogador.global_position.y < inicio.y - 12.0:  # perto do chão
		await physics_frame
	Input.action_press("pular")
	await _esperar(12)
	_checar(not _jogador.is_on_floor() and _jogador.velocity.y < 0.0, "buffer de pulo funciona")
	Input.action_release("pular")
	await _esperar_chao()

	# Caiu no buraco -> volta ao início
	_jogador.global_position.y = _jogador.limite_queda + 10.0
	await _esperar(3)
	_checar(_jogador.global_position.distance_to(_jogador.posicao_inicial) < 40.0, "reaparece no início ao cair")

	if _falhas == 0:
		print("PASSOU: todos os testes do jogador")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


## Pula segurando o botão por `quadros` e devolve a altura máxima atingida (px).
func _medir_pulo(quadros: int) -> float:
	await _esperar_chao()
	var y_inicial := _jogador.global_position.y
	var y_min := y_inicial
	var viu_subindo := false
	Input.action_press("pular")
	for i in 90:
		if i == quadros:
			Input.action_release("pular")
		await physics_frame
		y_min = minf(y_min, _jogador.global_position.y)
		viu_subindo = viu_subindo or _sprite.animation == &"pulo_subindo"
		if i > 5 and _jogador.is_on_floor():
			break
	Input.action_release("pular")
	_checar(viu_subindo, "pulando toca pulo_subindo")
	await _esperar_chao()
	return y_inicial - y_min


func _esperar_chao() -> void:
	for i in 180:
		if _jogador.is_on_floor():
			break
		await physics_frame
	await _esperar(5)


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
