extends TesteBase
## Amorfo (Gray Ooze): atravessa pranchas one-way (camada "plataforma"); herói e minions pisam.
## godot --headless --debug --path . --script res://tests/criaturas/teste_amorfo.gd

const GRAVIDADE := 980.0
const CHAO_Y := 300.0
const PLATAFORMA_Y := 200.0
const QUADROS := 90


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_mascaras()
	await _testar_atravessa_prancha()
	_terminar("Amorfo atravessa prancha; herói fica")


func _testar_mascaras() -> void:
	_checar(MontagemDeCriatura.mascara_do_chao() == 33, "máscara normal = mundo|plataforma (33)")
	_checar(MontagemDeCriatura.mascara_do_chao(false) == 1, "máscara Amorfo = só mundo (1)")


func _testar_atravessa_prancha() -> void:
	var mundo := Node2D.new()
	root.add_child(mundo)
	_bloco(mundo, Rect2(-200, CHAO_Y, 800, 40), MontagemDeCriatura.CAMADA_MUNDO, false)
	_bloco(mundo, Rect2(-80, PLATAFORMA_Y, 200, 10), MontagemDeCriatura.CAMADA_PLATAFORMA, true)

	var heroi := _corpo(mundo, Vector2(0, PLATAFORMA_Y - 30), true)
	var ooze := _corpo(mundo, Vector2(40, PLATAFORMA_Y - 30), false)

	for i in QUADROS:
		_cair(heroi)
		_cair(ooze)
		await physics_frame

	_checar(absf(heroi.global_position.y - PLATAFORMA_Y) < 4.0, "herói fica na prancha one-way")
	_checar(absf(ooze.global_position.y - CHAO_Y) < 4.0, "Ooze (Amorfo) cai pela prancha até o chão")
	mundo.queue_free()
	await physics_frame


func _bloco(mundo: Node2D, ret: Rect2, camada: int, one_way: bool) -> void:
	var corpo := StaticBody2D.new()
	corpo.collision_layer = 1 << (camada - 1)
	corpo.collision_mask = 0
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = ret.size
	forma.shape = retangulo
	forma.one_way_collision = one_way
	corpo.add_child(forma)
	corpo.position = ret.position + ret.size / 2.0
	mundo.add_child(corpo)


func _corpo(mundo: Node2D, posicao: Vector2, pisa_plataforma: bool) -> CharacterBody2D:
	var corpo := CharacterBody2D.new()
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(16, 24)
	forma.shape = retangulo
	forma.position = Vector2(0, -12)
	corpo.add_child(forma)
	mundo.add_child(corpo)
	corpo.global_position = posicao
	MontagemDeCriatura.configurar_colisao_chao(corpo, pisa_plataforma)
	return corpo


func _cair(corpo: CharacterBody2D) -> void:
	corpo.velocity.y += GRAVIDADE / float(Engine.physics_ticks_per_second)
	corpo.move_and_slide()
