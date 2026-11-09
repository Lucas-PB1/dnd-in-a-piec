extends TesteBase
## Atleta escala paredes; a fase tem teto, laterais invisíveis e uma porta de verdade; o tiro do Atirador
## de Elite atravessa paredes do cenário.
## godot --headless --debug --path . --script res://tests/teste_escalada.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	await _testar_escalada(false)
	await _testar_escalada(true)
	await _testar_fase()
	await _testar_limites_do_mapa()
	await _testar_tiro(false)
	await _testar_tiro(true)
	print("PASSOU: escalada, limites, porta e tiro que atravessa" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _bloco(posicao: Vector2, tamanho: Vector2) -> StaticBody2D:
	var corpo := StaticBody2D.new()
	corpo.collision_layer = 1
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = tamanho
	forma.shape = retangulo
	corpo.add_child(forma)
	corpo.position = posicao
	root.add_child(corpo)
	return corpo


func _testar_escalada(com_atleta: bool) -> void:
	var chao := _bloco(Vector2(400, 304), Vector2(1200, 32))  # topo em y = 288
	var parede := _bloco(Vector2(300, 188), Vector2(32, 200))  # de y = 88 a 288: um degrau alto
	var heroi: Jogador = load("res://features/jogador/jogador.tscn").instantiate()
	heroi.position = Vector2(200, 270)
	root.add_child(heroi)
	await physics_frame
	if com_atleta:
		heroi.ficha.talentos.append(Ficha.TALENTO_ATLETA)
	Input.action_press(&"mover_direita")
	for i in 240:
		await physics_frame
		if com_atleta and heroi.is_on_floor() and heroi.global_position.y < 100.0:
			break  # já está em cima da parede: solta a tecla antes de andar até cair do outro lado
	Input.action_release(&"mover_direita")
	for i in 20:
		await physics_frame
	if com_atleta:
		_checar(heroi.global_position.x > 283.0 and heroi.global_position.y < 100.0, "o Atleta sobe a parede de 200 px e passa para cima dela (y %d)" % heroi.global_position.y)
	else:
		_checar(heroi.global_position.x < 290.0 and heroi.global_position.y > 250.0, "sem o talento o herói fica parado diante da parede")
	heroi.queue_free()
	chao.queue_free()
	parede.queue_free()
	await process_frame


func _testar_fase() -> void:
	var fase: Fase = load("res://levels/fase_1.tscn").instantiate()
	root.add_child(fase)
	await process_frame
	var limites := fase.get_node_or_null("Limites") as StaticBody2D
	_checar(limites != null and limites.get_child_count() == 3, "a fase tem as duas laterais e o teto invisíveis")
	var porta := fase.get_node("Porta")
	var desenho := porta.get_node_or_null("Desenho") as Sprite2D
	_checar(desenho != null and desenho.texture.get_size() == Vector2(50, 81), "a saída tem a porta de verdade (arte CC0, 50x81)")
	fase.queue_free()
	await process_frame


## O teto e as laterais invisíveis seguram o herói de verdade (e a defesa do Duelista fecha ao reviver).
func _testar_limites_do_mapa() -> void:
	var fase: Fase = load("res://levels/fase_1.tscn").instantiate()
	root.add_child(fase)
	var heroi: Jogador = load("res://features/jogador/jogador.tscn").instantiate()
	root.add_child(heroi)
	heroi.global_position = fase.posicao_inicio()
	await physics_frame
	var area := fase.area_jogavel()
	Input.action_press(&"mover_esquerda")
	for i in 300:
		await physics_frame
	Input.action_release(&"mover_esquerda")
	_checar(heroi.global_position.x >= area.position.x, "a lateral esquerda segura o herói (x %d)" % heroi.global_position.x)
	heroi.global_position = Vector2(area.position.x + 200.0, 150.0)
	for i in 60:
		heroi.velocity.y = -400.0  # empurra sempre para cima: sem teto subiria uns 400 px
		await physics_frame
	_checar(heroi.global_position.y > area.position.y - Fase.ALTURA_DO_TETO_ACIMA_PX, "o teto invisível segura quem sobe (y %d)" % heroi.global_position.y)
	heroi.global_position = Vector2(area.end.x - 100.0, 250.0)
	Input.action_press(&"mover_direita")
	for i in 300:
		await physics_frame
	Input.action_release(&"mover_direita")
	_checar(heroi.global_position.x <= area.end.x, "a lateral direita segura o herói (x %d)" % heroi.global_position.x)
	heroi.ficha.talentos.append(Ficha.TALENTO_DUELISTA_DEFENSIVO)
	var espada := (load("res://data/armas/rapieira.tres") as Arma).duplicate() as Arma
	heroi.inventario.adicionar(espada)
	heroi.inventario.equipar(espada)
	_checar(heroi.defender(), "a defesa abre")
	heroi.reviver()
	_checar((heroi.get_node("Defesa") as DefesaComponent).bonus_ca_corpo_a_corpo == 0 and heroi.defesa_pronta(), "reviver fecha a janela de defesa e libera a espera")
	heroi.queue_free()
	fase.queue_free()
	await process_frame

func _testar_tiro(atravessa: bool) -> void:
	var parede := _bloco(Vector2(200, 0), Vector2(32, 800))
	var chao := _bloco(Vector2(300, 600), Vector2(2000, 32))
	var flecha: ArmaArremessada = load("res://features/arremesso/arma_arremessada.tscn").instantiate()
	root.add_child(flecha)
	flecha.global_position = Vector2(0, 0)
	var arma: Arma = load("res://data/armas/arco_longo.tres")
	var municoes := Recursos.da_pasta("res://data/municoes")
	await physics_frame
	flecha.lancar(arma, Golpe.new("tiro", 0, Dado.new(1, 6)), 0, 1, 1.0, 0.0, municoes[0] as Municao, atravessa)
	for i in 40:
		await physics_frame
	if atravessa:
		_checar(is_instance_valid(flecha) and flecha.global_position.x > 230.0, "a flecha do Atirador de Elite passa pela parede do cenário")
	else:
		_checar(not is_instance_valid(flecha) or flecha.global_position.x < 190.0, "a flecha comum para na parede")
	if is_instance_valid(flecha):
		flecha.queue_free()
	parede.queue_free()
	chao.queue_free()
	await process_frame
