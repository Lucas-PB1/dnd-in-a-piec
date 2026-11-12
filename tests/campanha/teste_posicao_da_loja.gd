extends TesteBase
## Loja em chão firme e folga ≥ `Fase.FOLGA_INTERACAO_E` entre centros de interações com E
## (loja, baú no Treino/Clareira, desafios de perícia). Porta não entra (abre ao tocar).
## godot --headless --debug --path . --script res://tests/campanha/teste_posicao_da_loja.gd

const ALTURA_DA_SONDA := 200.0


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	await _checar_fase(Main.CENA_TUTORIAL.instantiate(), "Treino")
	for i in Main.CENAS_FASE.size():
		await _checar_fase(Main.CENAS_FASE[i].instantiate(), "fase %d" % (i + 1))
	_terminar("loja no chão e folga E entre interações")


func _checar_fase(fase: Fase, rotulo: String) -> void:
	root.add_child(fase)
	await physics_frame
	await physics_frame
	var destino := fase.posicao_loja()
	var raio := PhysicsRayQueryParameters2D.create(
		destino - Vector2(0.0, ALTURA_DA_SONDA), destino + Vector2(0.0, ALTURA_DA_SONDA), 1)
	var acerto := fase.get_world_2d().direct_space_state.intersect_ray(raio)
	_checar(not acerto.is_empty() and absf((acerto["position"] as Vector2).y - destino.y) < 4.0,
		"%s: a banca (x=%d) fica em chão firme à altura do começo" % [rotulo, destino.x])
	var centros := _centros_e(fase)
	for i in centros.size():
		for j in range(i + 1, centros.size()):
			var a: Dictionary = centros[i]
			var b: Dictionary = centros[j]
			var dist: float = absf(float(a.x) - float(b.x))
			_checar(dist >= Fase.FOLGA_INTERACAO_E,
				"%s: %s e %s a %.0f px (≥ %.0f)" % [rotulo, a.nome, b.nome, dist, Fase.FOLGA_INTERACAO_E])
	fase.queue_free()
	await physics_frame


## Centros X das coisas que usam E nesta fase (baú só no Treino/Clareira; posição como a main coloca).
func _centros_e(fase: Fase) -> Array[Dictionary]:
	var lista: Array[Dictionary] = [{"nome": "loja", "x": fase.posicao_loja().x}]
	if fase.indice <= 1:
		var bau_x := fase.posicao_inicio().x + Main.OFFSET_BAU_TUTORIAL.x if fase.indice == 0 else Main.POS_BAU_CLAREIRA.x
		lista.append({"nome": "baú", "x": bau_x})
	for no in fase.get_tree().get_nodes_in_group(&"desafio_pericia"):
		if fase.is_ancestor_of(no) and no is Node2D:
			lista.append({"nome": "desafio", "x": (no as Node2D).global_position.x})
	return lista
