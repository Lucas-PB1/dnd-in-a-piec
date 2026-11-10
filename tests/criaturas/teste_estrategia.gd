extends TesteBase
## Estratégia dos monstros: a regra pura (manter distância, recuar ferido), as fichas e o Hobgoblin no mundo
## (afasta-se do herói que chega perto para atirar; ferido, com aliado por perto, recua uma vez).
## godot --headless --debug --path . --script res://tests/criaturas/teste_estrategia.gd

const CENA_HOBGOBLIN := "res://features/goblin/hobgoblin_guerreiro.tscn"
const CHAO_Y := 300.0
const QUADROS_MAXIMOS := 240


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_regra()
	_testar_fichas()
	await _testar_mantem_distancia()
	await _testar_recua_ferido()
	print("PASSOU: todos os testes da estratégia" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_regra() -> void:
	_checar(EstrategiaDeMonstro.prefere_distancia(12.0, 12.5), "o arco bate tanto quanto a espada: prefere distância")
	_checar(not EstrategiaDeMonstro.prefere_distancia(12.0, 5.0), "o arco bate bem menos: luta de perto")
	_checar(not EstrategiaDeMonstro.prefere_distancia(5.0, 0.0), "sem ataque à distância: luta de perto")
	_checar(EstrategiaDeMonstro.deve_recuar_ferido(3, 10, 1), "com 1/3 da vida e aliado vivo: recua")
	_checar(not EstrategiaDeMonstro.deve_recuar_ferido(4, 10, 1), "acima de 1/3 da vida: luta")
	_checar(not EstrategiaDeMonstro.deve_recuar_ferido(3, 10, 0), "sem aliado: luta até o fim")


func _testar_fichas() -> void:
	var hobgoblin: CriaturaRPG = load("res://data/hobgoblin_warrior.tres")
	_checar(is_equal_approx(hobgoblin.dano_medio_a_distancia(), 12.0) or hobgoblin.dano_medio_a_distancia() > 11.0,
		"Hobgoblin: o arco (1d8+1 + 3d4) vale %.1f" % hobgoblin.dano_medio_a_distancia())
	var gray: CriaturaRPG = load("res://data/gray_ooze.tres")
	_checar(gray.dano_medio_a_distancia() == 0.0, "Gray Ooze não tem ataque à distância")


func _montar(alvo_x: float, goblin_x: float, com_flechas: bool, vida_para_tirar: int) -> Array:
	var mundo := Node2D.new()
	root.add_child(mundo)
	var corpo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(1600.0, 400.0)
	forma.shape = retangulo
	corpo.add_child(forma)
	corpo.position = Vector2(400.0, CHAO_Y + 200.0)
	corpo.collision_layer = 1
	mundo.add_child(corpo)
	var alvo := Node2D.new()
	mundo.add_child(alvo)
	alvo.global_position = Vector2(alvo_x, CHAO_Y)
	var ficha: CriaturaRPG = (load("res://data/hobgoblin_warrior.tres") as CriaturaRPG).duplicate()
	if not com_flechas:
		ficha.disparos = 0
	var goblin: Goblin = load(CENA_HOBGOBLIN).instantiate()
	goblin.criatura = ficha
	mundo.add_child(goblin)
	goblin.add_to_group(&"monstros")
	goblin.global_position = Vector2(goblin_x, CHAO_Y)
	goblin.definir_alvo(alvo)
	if vida_para_tirar > 0:
		(goblin.get_node("Vida") as HealthComponent).receber_dano(vida_para_tirar)
	return [mundo, goblin, alvo]


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func _testar_mantem_distancia() -> void:
	var m := _montar(200.0, 300.0, true, 0)
	var goblin: Goblin = m[1]
	var afastou := false
	var maior_distancia := 0.0
	for i in QUADROS_MAXIMOS:
		await physics_frame
		afastou = afastou or goblin.nome_estado() == &"Afastando"
		maior_distancia = maxf(maior_distancia, goblin.global_position.x - 200.0)
	_checar(afastou, "o herói a 100 px do arqueiro: ele recua (Afastando)")
	_checar(maior_distancia > 150.0, "ele ganhou distância (chegou a %d px)" % maior_distancia)
	m[0].queue_free()
	await physics_frame


func _testar_recua_ferido() -> void:
	var m := _montar(200.0, 300.0, false, 9)
	var goblin: Goblin = m[1]
	var aliado: Goblin = load(CENA_HOBGOBLIN).instantiate()
	m[0].add_child(aliado)
	aliado.add_to_group(&"monstros")
	aliado.global_position = Vector2(420.0, CHAO_Y)
	var recuou_ferido := false
	var vezes := 0
	var estava := false
	for i in QUADROS_MAXIMOS * 2:
		await physics_frame
		var agora := goblin.nome_estado() == &"Afastando"
		recuou_ferido = recuou_ferido or (agora and goblin.motivo_afastar() == Goblin.MOTIVO_FERIDO)
		if agora and not estava:
			vezes += 1
		estava = agora
	_checar(recuou_ferido, "ferido (2 de 11 PV) e com aliado por perto: recua")
	_checar(vezes == 1, "recua uma vez só por vida (%d)" % vezes)
	m[0].queue_free()
	await physics_frame
