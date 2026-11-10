extends TesteBase
## A banca do lojista tem chão firme embaixo, à altura do começo, em todas as fases, e fica longe do baú (50 px de
## folga entre as áreas de interação, para o E não abrir a loja em vez do arsenal).
## godot --headless --debug --path . --script res://tests/teste_posicao_da_loja.gd

const BAU_X := 150.0
const DISTANCIA_MINIMA_DO_BAU := 96.0
const ALTURA_DA_SONDA := 200.0


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	for i in Main.CENAS_FASE.size():
		var fase: Fase = Main.CENAS_FASE[i].instantiate()
		root.add_child(fase)
		await physics_frame
		await physics_frame
		var destino := fase.posicao_inicio() + fase.deslocamento_loja
		var raio := PhysicsRayQueryParameters2D.create(destino - Vector2(0.0, ALTURA_DA_SONDA), destino + Vector2(0.0, ALTURA_DA_SONDA), 1)
		var acerto := fase.get_world_2d().direct_space_state.intersect_ray(raio)
		_checar(not acerto.is_empty() and absf((acerto["position"] as Vector2).y - destino.y) < 4.0,
			"fase %d: a banca (x=%d) fica em chão firme à altura do começo" % [i + 1, destino.x])
		if i == 0:
			_checar(absf(destino.x - BAU_X) >= DISTANCIA_MINIMA_DO_BAU, "fase 1: a banca fica longe do baú")
		fase.queue_free()
		await physics_frame
	print("PASSOU: a banca fica bem em todas as fases" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)
