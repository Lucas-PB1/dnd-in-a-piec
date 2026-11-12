extends TesteBase
## Salto dos monstros: a regra pura (Força do livro, degrau, vão, queda) e o Hobgoblin saltando de verdade num
## mundo de blocos (subir um degrau, atravessar um buraco, descer atrás do alvo).
## godot --headless --debug --path . --script res://tests/criaturas/teste_salto_monstros.gd

const CENA_HOBGOBLIN := "res://features/humanoides/hobgoblin_guerreiro.tscn"
const LADRILHO := 32.0
const CHAO_Y := 300.0
const QUADROS_MAXIMOS := 360


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_capacidade()
	_testar_plano()
	await _testar_degrau()
	await _testar_vao()
	await _testar_descida()
	await _testar_muro_alto()
	await _testar_degrau_dos_outros()
	await _testar_patrulha_salta_vao()
	await _testar_fuga_salta_vao()
	await _testar_mantem_altura()
	print("PASSOU: todos os testes do salto dos monstros" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_capacidade() -> void:
	_checar(is_equal_approx(SaltoDnd.distancia_px(15), 96.0), "salto em distância = Força em pés (15 pés = 96 px)")
	_checar(is_equal_approx(SaltoDnd.altura_px(15), EscalaDnd.pes_para_pixels(8.0)),
		"altura = 3 pés + mod. de Força (+2) + alcance dos braços (3 pés)")
	_checar(SaltoDnd.altura_px(8) >= LADRILHO and SaltoDnd.altura_px(7) < LADRILHO,
		"Força 8 (Goblin) sobe 1 ladrilho; Força 7 (Kobold) não")


func _testar_plano() -> void:
	var alto := SaltoDnd.altura_px(15)
	var longe := SaltoDnd.distancia_px(15)
	var sem := SaltoDnd.SEM_CHAO
	_checar(SaltoDnd.planejar([0.0, 0.0] as Array[float], 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.NENHUM, "chão plano: não salta")
	_checar(SaltoDnd.planejar([32.0] as Array[float], 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.SUBIR, "degrau de 1 ladrilho: sobe")
	_checar(SaltoDnd.planejar([64.0] as Array[float], 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.NENHUM, "degrau alto demais: não sobe")
	_checar(SaltoDnd.planejar([SaltoDnd.MURO] as Array[float], 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.NENHUM, "muro ou teto baixo: não salta")
	var vao := SaltoDnd.planejar([sem, sem, 0.0] as Array[float], 8.0, 14.0, alto, longe, false)
	_checar(vao.tipo == SaltoDnd.Tipo.VAO and is_equal_approx(vao.distancia_px, 30.0), "buraco com chão do outro lado: salta o vão")
	var largo: Array[float] = []
	for i in 14:
		largo.append(sem)
	largo.append(0.0)
	_checar(SaltoDnd.planejar(largo, 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.NENHUM, "vão maior que o salto em distância: não salta")
	_checar(SaltoDnd.planejar([sem, sem] as Array[float], 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.NENHUM, "buraco sem outro lado: não salta")
	_checar(SaltoDnd.planejar([-64.0] as Array[float], 8.0, 14.0, alto, longe, false).tipo == SaltoDnd.Tipo.NENHUM, "queda grande sem alvo embaixo: fica")
	_checar(SaltoDnd.planejar([-64.0] as Array[float], 8.0, 14.0, alto, longe, true).tipo == SaltoDnd.Tipo.DESCER, "queda grande com alvo embaixo: desce")
	_checar(SaltoDnd.planejar([-200.0] as Array[float], 8.0, 14.0, alto, longe, true).tipo == SaltoDnd.Tipo.NENHUM, "queda acima do limite seguro: não desce")


## Mundo de teste: blocos de chão (x inicial, x final, topo) e um alvo; devolve o Hobgoblin sem flechas.
func _montar_mundo(blocos: Array[Vector3], alvo_em: Vector2, goblin_em: Vector2) -> Array:
	var mundo := Node2D.new()
	root.add_child(mundo)
	for bloco in blocos:
		var corpo := StaticBody2D.new()
		var forma := CollisionShape2D.new()
		var retangulo := RectangleShape2D.new()
		retangulo.size = Vector2(bloco.y - bloco.x, 400.0)
		forma.shape = retangulo
		corpo.add_child(forma)
		corpo.position = Vector2((bloco.x + bloco.y) / 2.0, bloco.z + 200.0)
		corpo.collision_layer = 1
		mundo.add_child(corpo)
	var alvo := Node2D.new()
	mundo.add_child(alvo)
	alvo.global_position = alvo_em
	var ficha: CriaturaRPG = (load("res://data/hobgoblin_warrior.tres") as CriaturaRPG).duplicate()
	ficha.disparos = 0
	var goblin: Goblin = load(CENA_HOBGOBLIN).instantiate()
	goblin.criatura = ficha
	mundo.add_child(goblin)
	goblin.global_position = goblin_em
	goblin.definir_alvo(alvo)
	return [mundo, goblin]


func _esperar_ate(condicao: Callable) -> bool:
	for i in QUADROS_MAXIMOS:
		await physics_frame
		if condicao.call():
			return true
	return false


func _testar_degrau() -> void:
	var m := _montar_mundo([Vector3(0, 300, CHAO_Y), Vector3(300, 700, CHAO_Y - LADRILHO)] as Array[Vector3],
		Vector2(480, CHAO_Y - LADRILHO), Vector2(200, CHAO_Y))
	var goblin: Goblin = m[1]
	var passou := await _esperar_ate(func() -> bool: return goblin.global_position.x > 340.0)
	_checar(passou and absf(goblin.global_position.y - (CHAO_Y - LADRILHO)) < 4.0, "Hobgoblin sobe o degrau de 1 ladrilho atrás do alvo")
	m[0].queue_free()
	await physics_frame


func _testar_vao() -> void:
	var m := _montar_mundo([Vector3(0, 300, CHAO_Y), Vector3(350, 800, CHAO_Y)] as Array[Vector3],
		Vector2(520, CHAO_Y), Vector2(200, CHAO_Y))
	var goblin: Goblin = m[1]
	var passou := await _esperar_ate(func() -> bool: return goblin.global_position.x > 400.0)
	_checar(passou and goblin.is_on_floor(), "Hobgoblin salta um buraco de 50 px (1,5 ladrilho) e continua")
	m[0].queue_free()
	await physics_frame


func _testar_descida() -> void:
	var m := _montar_mundo([Vector3(0, 300, CHAO_Y - 2 * LADRILHO), Vector3(300, 800, CHAO_Y)] as Array[Vector3],
		Vector2(520, CHAO_Y), Vector2(200, CHAO_Y - 2 * LADRILHO))
	var goblin: Goblin = m[1]
	var passou := await _esperar_ate(func() -> bool: return goblin.global_position.x > 400.0)
	_checar(passou and absf(goblin.global_position.y - CHAO_Y) < 4.0, "Hobgoblin desce 2 ladrilhos atrás de um alvo embaixo")
	m[0].queue_free()
	await physics_frame


func _testar_muro_alto() -> void:
	var m := _montar_mundo([Vector3(0, 300, CHAO_Y), Vector3(300, 700, CHAO_Y - 4 * LADRILHO)] as Array[Vector3],
		Vector2(480, CHAO_Y - 4 * LADRILHO), Vector2(200, CHAO_Y))
	var goblin: Goblin = m[1]
	var passou := await _esperar_ate(func() -> bool: return goblin.global_position.x > 330.0)
	_checar(not passou, "muro de 4 ladrilhos: o Hobgoblin não consegue e fica no pé dele")
	m[0].queue_free()
	await physics_frame


## Os demais monstros também sobem um degrau de 1 ladrilho atrás do alvo (Gray Ooze, Minotauro e Wight; o Ankheg tem o seu em teste_ankheg).
func _testar_degrau_dos_outros() -> void:
	var cenas := {
		"Gray Ooze": "res://features/gray_ooze/gray_ooze.tscn",
		"Minotauro": "res://features/minotauro/minotauro.tscn", "Wight": "res://features/wight/wight.tscn",
	}
	for nome: String in cenas:
		var mundo := Node2D.new()
		root.add_child(mundo)
		for bloco in [Vector3(0, 300, CHAO_Y), Vector3(300, 800, CHAO_Y - LADRILHO)]:
			var corpo := StaticBody2D.new()
			var forma := CollisionShape2D.new()
			var retangulo := RectangleShape2D.new()
			retangulo.size = Vector2(bloco.y - bloco.x, 400.0)
			forma.shape = retangulo
			corpo.add_child(forma)
			corpo.position = Vector2((bloco.x + bloco.y) / 2.0, bloco.z + 200.0)
			corpo.collision_layer = 1
			mundo.add_child(corpo)
		var alvo := Node2D.new()
		mundo.add_child(alvo)
		alvo.global_position = Vector2(560, CHAO_Y - LADRILHO)
		var monstro: Node2D = load(cenas[nome]).instantiate()
		mundo.add_child(monstro)
		monstro.global_position = Vector2(200, CHAO_Y)
		monstro.call(&"definir_alvo", alvo)
		if "chance_atirar" in monstro:
			monstro.chance_atirar = 0.0  # o Wight atiraria de longe em vez de subir
		var passou := await _esperar_ate(func() -> bool: return monstro.global_position.x > 340.0)
		_checar(passou and absf(monstro.global_position.y - (CHAO_Y - LADRILHO)) < 4.0, "%s sobe o degrau de 1 ladrilho atrás do alvo" % nome)
		mundo.queue_free()
		await physics_frame


## Sem alvo: a patrulha salta um vão no caminho do extremo (à direita).
func _testar_patrulha_salta_vao() -> void:
	var m := _montar_mundo([Vector3(0, 280, CHAO_Y), Vector3(330, 900, CHAO_Y)] as Array[Vector3],
		Vector2(2000, CHAO_Y), Vector2(200, CHAO_Y))
	var goblin: Goblin = m[1]
	goblin.definir_alvo(null)
	goblin.criatura.patrulha_pes = 40.0
	# O 1º extremo é à esquerda; descarta e pega o da direita (com o vão no caminho).
	goblin.garantir_destino_patrulha()
	goblin.limpar_destino_patrulha()
	goblin.garantir_destino_patrulha()
	goblin.get_node("MaquinaEstados").trocar(&"Patrulhando")
	var passou := await _esperar_ate(func() -> bool: return goblin.global_position.x > 360.0)
	_checar(passou and goblin.is_on_floor(), "patrulha salta o vão e segue até o extremo")
	m[0].queue_free()
	await physics_frame


## Fuga Ágil: Desengaja saltando um vão nas costas (perto da beira, recuo de 15 pés basta).
func _testar_fuga_salta_vao() -> void:
	var m := _montar_mundo([Vector3(0, 280, CHAO_Y), Vector3(330, 900, CHAO_Y)] as Array[Vector3],
		Vector2(420, CHAO_Y), Vector2(345, CHAO_Y))
	var goblin: Goblin = m[1]
	goblin.criatura.fuga_agil = true
	await _esperar_ate(func() -> bool: return goblin.is_on_floor())
	goblin.global_position.x = 345.0
	goblin.direcao_olhar = 1
	goblin.parar()
	goblin.get_node("MaquinaEstados").trocar(&"Desengajando")
	var passou := await _esperar_ate(func() -> bool: return goblin.global_position.x < 270.0 and goblin.is_on_floor())
	_checar(passou, "Fuga Ágil salta o vão para trás")
	m[0].queue_free()
	await physics_frame


## Atirador no alto (≥ 1 ladrilho) não desce atrás do herói; atira mesmo "perto" do arco.
## Plataforma curta + chão fino: o herói fica além da beira (linha de tiro livre) e a < 20 pés.
func _testar_mantem_altura() -> void:
	var mundo := Node2D.new()
	root.add_child(mundo)
	for bloco in [Vector3(0, 250, CHAO_Y - 2 * LADRILHO), Vector3(0, 900, CHAO_Y)]:
		var corpo := StaticBody2D.new()
		var forma := CollisionShape2D.new()
		var retangulo := RectangleShape2D.new()
		retangulo.size = Vector2(bloco.y - bloco.x, LADRILHO)
		forma.shape = retangulo
		corpo.add_child(forma)
		corpo.position = Vector2((bloco.x + bloco.y) / 2.0, bloco.z + LADRILHO / 2.0)
		corpo.collision_layer = 1
		mundo.add_child(corpo)
	var alvo := Node2D.new()
	mundo.add_child(alvo)
	alvo.global_position = Vector2(320, CHAO_Y)
	var ficha: CriaturaRPG = (load("res://data/hobgoblin_warrior.tres") as CriaturaRPG).duplicate()
	var goblin: Goblin = load(CENA_HOBGOBLIN).instantiate()
	goblin.criatura = ficha
	mundo.add_child(goblin)
	goblin.global_position = Vector2(200, CHAO_Y - 2 * LADRILHO)
	goblin.definir_alvo(alvo)
	await _esperar_ate(func() -> bool: return goblin.is_on_floor())
	var y0 := goblin.global_position.y
	_checar(goblin.quer_manter_altura(), "Hobgoblin no alto quer manter a altura")
	var dist := absf(goblin.global_position.x - alvo.global_position.x)
	_checar(dist <= EscalaDnd.pes_para_pixels(20.0), "cenário: herói na faixa 'perto' do arco")
	_checar(goblin.pode_atirar(), "no alto, atira mesmo com o herói 'perto' na horizontal")
	var desceu := false
	for i in 120:
		await physics_frame
		if goblin.global_position.y > y0 + LADRILHO:
			desceu = true
			break
	_checar(not desceu, "atirador em vantagem de terreno não desce atrás do herói")
	mundo.queue_free()
	await physics_frame
