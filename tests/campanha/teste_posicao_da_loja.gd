extends TesteBase
## A banca do lojista tem chão firme embaixo, à altura do começo, em todas as fases, e fica longe do baú (50 px de
## folga entre as áreas de interação, para o E não abrir a loja em vez do arsenal).
## godot --headless --debug --path . --script res://tests/campanha/teste_posicao_da_loja.gd

const BAU_X := 150.0
const DISTANCIA_MINIMA_DO_BAU := 96.0
const ALTURA_DA_SONDA := 200.0


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	await _checar_fase(Main.CENA_TUTORIAL.instantiate(), "Treino", true)
	for i in Main.CENAS_FASE.size():
		await _checar_fase(Main.CENAS_FASE[i].instantiate(), "fase %d" % (i + 1), i == 0)
	_terminar("a banca fica bem em todas as fases")


func _checar_fase(fase: Fase, rotulo: String, com_bau: bool) -> void:
	root.add_child(fase)
	await physics_frame
	await physics_frame
	var destino := fase.posicao_loja()
	var raio := PhysicsRayQueryParameters2D.create(destino - Vector2(0.0, ALTURA_DA_SONDA), destino + Vector2(0.0, ALTURA_DA_SONDA), 1)
	var acerto := fase.get_world_2d().direct_space_state.intersect_ray(raio)
	_checar(not acerto.is_empty() and absf((acerto["position"] as Vector2).y - destino.y) < 4.0,
		"%s: a banca (x=%d) fica em chão firme à altura do começo" % [rotulo, destino.x])
	if com_bau:
		var bau_x := fase.posicao_inicio().x + Main.OFFSET_BAU_TUTORIAL.x if fase.indice == 0 else BAU_X
		_checar(absf(destino.x - bau_x) >= DISTANCIA_MINIMA_DO_BAU,
			"%s: a banca fica longe do baú" % rotulo)
	fase.queue_free()
	await physics_frame
