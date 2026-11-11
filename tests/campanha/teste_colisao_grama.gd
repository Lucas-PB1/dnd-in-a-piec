extends TesteBase
## Colisão da grama afunda RECUO_PES_NA_GRAMA_PX para os pés entrarem na relva.
## godot --headless --debug --path . --script res://tests/campanha/teste_colisao_grama.gd

const ALTURA_DA_SONDA := 80.0


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var fase: Fase = Main.CENAS_FASE[0].instantiate()
	root.add_child(fase)
	await physics_frame
	await physics_frame
	var inicio := fase.posicao_inicio()
	var raio := PhysicsRayQueryParameters2D.create(
		inicio - Vector2(0.0, ALTURA_DA_SONDA),
		inicio + Vector2(0.0, ALTURA_DA_SONDA),
		1)
	var acerto := fase.get_world_2d().direct_space_state.intersect_ray(raio)
	_checar(not acerto.is_empty(), "há chão sob o início da Clareira")
	if not acerto.is_empty():
		var topo: float = (acerto["position"] as Vector2).y
		_checar(
			is_equal_approx(topo, inicio.y + Fase.RECUO_PES_NA_GRAMA_PX),
			"topo da grama afunda %.0f px (viu %.1f, esperava %.1f)" % [
				Fase.RECUO_PES_NA_GRAMA_PX, topo, inicio.y + Fase.RECUO_PES_NA_GRAMA_PX])
	fase.queue_free()
	_terminar("colisão da grama afunda os pés")
