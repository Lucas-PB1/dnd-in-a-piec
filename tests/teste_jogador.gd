extends SceneTree
## Teste automático do movimento do jogador (roda sem janela).
## godot --headless --path . --script res://tests/teste_jogador.gd

var _falhas := 0


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var cena: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	var jogador: Jogador = cena.get_node("Jogador")
	var sprite: AnimatedSprite3D = jogador.get_node("Sprite")
	var camera: Camera3D = cena.get_node("Camera")

	await _esperar_fisica(10)
	_checar(jogador.is_on_floor(), "jogador começa no chão")
	_checar(sprite.animation == &"idle", "parado toca idle")
	var inicio := jogador.global_position

	# Direita por 1 segundo
	Input.action_press("mover_direita")
	await _esperar_fisica(60)
	_checar(jogador.global_position.x > inicio.x + 2.0, "anda para a direita (+X)")
	_checar(sprite.animation == &"walk", "andando toca walk")
	_checar(not sprite.flip_h, "virado para a direita")
	Input.action_release("mover_direita")

	# Esquerda
	Input.action_press("mover_esquerda")
	await _esperar_fisica(30)
	_checar(sprite.flip_h, "espelha ao ir para a esquerda")
	Input.action_release("mover_esquerda")

	# Cima = para longe da câmera (-Z)
	var z_antes := jogador.global_position.z
	Input.action_press("mover_cima")
	await _esperar_fisica(30)
	_checar(jogador.global_position.z < z_antes - 1.0, "cima anda para -Z")
	_checar(sprite.flip_h, "só cima mantém o lado anterior")
	Input.action_release("mover_cima")

	# Diagonal não pode ser mais rápida que reto
	Input.action_press("mover_direita")
	Input.action_press("mover_baixo")
	await _esperar_fisica(60)
	var rapidez := Vector2(jogador.velocity.x, jogador.velocity.z).length()
	_checar(rapidez <= jogador.velocidade + 0.01, "diagonal não passa da velocidade máxima")
	Input.action_release("mover_direita")
	Input.action_release("mover_baixo")

	# Para ao soltar
	await _esperar_fisica(30)
	_checar(jogador.velocity.length() < 0.01, "para ao soltar as teclas")
	_checar(sprite.animation == &"idle", "volta para idle")
	_checar(jogador.is_on_floor(), "continua no chão")

	# Câmera acompanhou o jogador
	var distancia := (camera.global_position - (jogador.global_position + Vector3(0, 6, 6))).length()
	_checar(distancia < 0.5, "câmera alcança o jogador (distância %.2f)" % distancia)

	if _falhas == 0:
		print("PASSOU: todos os testes do jogador")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _esperar_fisica(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
