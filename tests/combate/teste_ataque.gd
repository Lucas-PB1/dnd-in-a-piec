extends TesteBase
## Teste do golpe de espada e do boneco de treino (roda sem janela).
## godot --headless --debug --path . --script res://tests/combate/teste_ataque.gd

const DISTANCIA_DO_BONECO := 30.0
const CA_BONECO := 10

## Em repouso a arma pode inclinar um pouco menos que o ângulo da animação (não entra no chão).
const MARGEM_DESCANSO := 10.0

var _jogador: Jogador
var _boneco: BonecoTreino


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var cena: Node = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false  # joga direto com a sugestão da classe
	root.add_child(cena)
	_jogador = cena.get_node("Jogador")
	_boneco = cena.get_node("BonecoTreino")
	for monstro in get_nodes_in_group(&"monstros"):
		monstro.free()
	await _esperar(20)

	await _testar_soco_desarmado()
	_checar(_jogador.inventario.equipar(_jogador.inventario.itens[0]), "equipa a espada da mochila")
	await _testar_espada_na_mao()
	await _testar_golpe_no_chao()
	await _testar_corpo_do_golpe()
	await _testar_golpe_de_costas()
	await _testar_golpe_no_ar()
	await _testar_dano_rolado()
	await _testar_ritmo_de_ataque()
	cena.queue_free()
	await _testar_boneco_sozinho()

	if _falhas == 0:
		print("PASSOU: todos os testes do ataque")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


## Sem arma na mão: soco de D&D = 1 + mod. de Força, sem espada visível. O golpe rola d20 contra a CA.
func _testar_soco_desarmado() -> void:
	_checar(_jogador.inventario.equipado(Item.ESPACO_MAO) == null, "começa com a espada na mochila, mão vazia")
	_checar(_jogador.arma_atual() == _jogador.ataque_desarmado, "mão vazia = ataque desarmado")
	var resultados := await _golpear_e_coletar(1)
	_checar(not (_jogador.get_node("Ataque/Espada") as Sprite2D).visible, "soco não mostra espada")
	var mod := _jogador.ficha.modificador(Atributos.FORCA)
	_checar(resultados.size() == 1 and _resultado_coerente(resultados[0], 1 + mod, 2 + mod),
		"soco resolvido pela regra (dano 1 + FOR = %d, crítico %d)" % [1 + mod, 2 + mod])
	await _esperar(2)


func _testar_golpe_no_chao() -> void:
	await _colocar_ao_lado_do_boneco()
	var espada: Node2D = _jogador.get_node("Ataque/Espada")
	var antes := _boneco.golpes_recebidos
	await _golpear()
	_checar(_jogador.nome_estado() == &"Atacando", "J = estado Atacando")
	_checar(espada.visible, "espada aparece no golpe")
	_checar(_boneco.golpes_recebidos == antes, "não acerta antes da janela de acerto")
	await _esperar_golpe_acabar()
	_checar(_boneco.golpes_recebidos == antes + 1,
		"acerta o boneco UMA vez por golpe (deu %d)" % (_boneco.golpes_recebidos - antes))
	await _esperar(1)
	var animacao: AnimacaoJogador = _jogador.get_node("Sprite")
	var angulo := (espada as Sprite2D).rotation_degrees + _jogador.arma_atual().angulo_arte  # direção da lâmina
	_checar(espada.visible and angulo <= animacao.angulo_descanso() + 0.01 and angulo > animacao.angulo_descanso() - MARGEM_DESCANSO,
		"no fim do golpe a espada volta para a mão em repouso (%.1f°; sem a ponta entrar no chão)" % angulo)
	_checar(absf(_jogador.velocity.x) < 1.0, "no chão o herói fica parado golpeando")
	await _esperar(2)
	_checar(_jogador.nome_estado() == &"Parado", "depois do golpe volta para Parado")
	await _golpear()
	await _esperar_golpe_acabar()
	_checar(_boneco.golpes_recebidos == antes + 2, "segundo golpe acerta de novo")


## Equipada, a espada fica na mão da frente (ponto do quadro atual), dos dois lados.
func _testar_espada_na_mao() -> void:
	var ataque: Node2D = _jogador.get_node("Ataque")
	var espada: Sprite2D = _jogador.get_node("Ataque/Espada")
	var animacao: AnimacaoJogador = _jogador.get_node("Sprite")
	await _esperar(3)
	_checar(espada.visible and espada.texture != null, "espada equipada aparece na mão, parado")
	_checar(ataque.position.distance_to(animacao.ponto_da_mao()) < 0.5, "arma está no ponto da mão do quadro atual")
	_checar(ataque.position.x > 0.0, "olhando para a direita, a mão está à frente (x > 0)")
	await _apertar("mover_esquerda")
	await _esperar(3)
	_checar(ataque.position.x < 0.0 and ataque.scale.x < 0.0, "virado para a esquerda, mão e espada espelham")
	Input.action_press("mover_direita")
	await _esperar(20)
	_checar(espada.visible and ataque.position.distance_to(animacao.ponto_da_mao()) < 0.5,
		"andando, a espada acompanha a mão")
	Input.action_release("mover_direita")
	await _esperar(30)
	_jogador.inventario.desequipar(Item.ESPACO_MAO)
	await _esperar(2)
	_checar(not espada.visible, "desequipada, a espada some da mão")
	_jogador.inventario.equipar(_jogador.inventario.itens[0])
	await _esperar(2)


## Corte anima o corpo com `corte`; estocada (rapieira / espada curta) com `estocada`.
func _testar_corpo_do_golpe() -> void:
	var sprite: AnimatedSprite2D = _jogador.get_node("Sprite")
	_checar(sprite.sprite_frames.has_animation(&"estocada"), "heroi_frames tem a animação estocada")
	# A espada curta inicial é rastro (= estocada). Para o corte, equipa uma longa.
	var longa := (load("res://data/armas/espada_longa.tres") as Arma).duplicate() as Arma
	_jogador.inventario.adicionar(longa)
	_checar(_jogador.inventario.equipar(longa) and longa.efeito == Arma.EFEITO_CORTE, "equipa espada longa (corte)")
	await _colocar_ao_lado_do_boneco()
	await _golpear()
	_checar(await _esperar_animacao_do_golpe(&"corte"), "espada de corte toca o corpo `corte`")
	await _esperar_golpe_acabar()
	var rapieira := (load("res://data/armas/rapieira.tres") as Arma).duplicate() as Arma
	_jogador.inventario.adicionar(rapieira)
	_checar(_jogador.inventario.equipar(rapieira), "equipa a rapieira")
	await _colocar_ao_lado_do_boneco()
	await _golpear()
	_checar(await _esperar_animacao_do_golpe(&"estocada"), "rapieira toca o corpo `estocada`")
	await _esperar_golpe_acabar()
	_checar(_jogador.inventario.equipar(longa), "volta a espada longa")


## Espera o sprite entrar na animação de corpo do golpe (até ~0,5 s).
func _esperar_animacao_do_golpe(nome: StringName) -> bool:
	var sprite: AnimatedSprite2D = _jogador.get_node("Sprite")
	for i in 30:
		if _jogador.esta_golpeando() and sprite.animation == nome:
			return true
		await physics_frame
	return false


func _testar_golpe_de_costas() -> void:
	await _colocar_ao_lado_do_boneco()
	await _apertar("mover_esquerda")  # vira de costas para o boneco
	await _esperar(10)
	var antes := _boneco.golpes_recebidos
	await _golpear()
	await _esperar_golpe_acabar()
	_checar(_boneco.golpes_recebidos == antes, "golpe de costas não acerta o boneco")


func _testar_golpe_no_ar() -> void:
	await _colocar_ao_lado_do_boneco()
	Input.action_press("pular")
	await _esperar(8)
	await _golpear()
	_checar(_jogador.nome_estado() == &"Atacando" and not _jogador.is_on_floor(), "golpeia no ar")
	Input.action_release("pular")
	await _esperar_golpe_acabar()
	await _esperar(2)
	_checar(_jogador.nome_estado() in [&"NoAr", &"Parado"], "depois do golpe no ar continua caindo ou já pousou")
	for i in 120:
		if _jogador.is_on_floor() and _jogador.nome_estado() == &"Parado":
			break
		await physics_frame
	_checar(_jogador.nome_estado() == &"Parado", "pousa depois do golpe no ar")


## Cada golpe rola d20 + ataque contra a CA 10 do boneco; acertou = 1d6 + mod (crítico: 2d6 + mod).
func _testar_dano_rolado() -> void:
	const GOLPES := 12
	var dado := _jogador.ficha.dado_dano(_jogador.arma_atual())
	var maximo_critico := dado.quantidade * 2 * dado.faces + dado.bonus
	var resultados := await _golpear_e_coletar(GOLPES)
	var coerentes := resultados.all(func(r: Combate.Resultado) -> bool: return _resultado_coerente(r, dado.minimo(), maximo_critico))
	var danos := {}
	for r in resultados:
		if r.acertou:
			danos[r.dano] = true
	_checar(resultados.size() == GOLPES and coerentes, "%d golpes resolvidos pela regra (acerto: dano %d a %d)" % [GOLPES, dado.minimo(), maximo_critico])
	_checar(danos.size() > 1, "o dano varia de um acerto para outro")


## Golpeia `vezes` e devolve os resultados resolvidos pelo boneco.
func _golpear_e_coletar(vezes: int) -> Array[Combate.Resultado]:
	var resultados: Array[Combate.Resultado] = []
	var registrar := func(r: Combate.Resultado) -> void: resultados.append(r)
	_boneco.atingido.connect(registrar)
	await _colocar_ao_lado_do_boneco()
	for i in vezes:
		await _golpear()
		await _esperar_golpe_acabar()
		await _esperar(2)
	_boneco.atingido.disconnect(registrar)
	return resultados


## Acertou: dano entre `minimo` e `maximo`. Errou: só com 1 natural ou total abaixo da CA 10.
func _resultado_coerente(r: Combate.Resultado, minimo: int, maximo: int) -> bool:
	if r.acertou:
		return r.dano >= minimo and r.dano <= maximo and (r.critico or r.total >= CA_BONECO)
	return r.d20 == Combate.FALHA_AUTOMATICA or r.total < CA_BONECO


## A cena do boneco roda sozinha (como no F6) e reage a um golpe.
func _testar_boneco_sozinho() -> void:
	var boneco: BonecoTreino = load("res://features/boneco_treino/boneco_treino.tscn").instantiate()
	root.add_child(boneco)
	await _esperar(2)
	var acertos: Array[int] = []
	boneco.atingido.connect(func(r: Combate.Resultado) -> void:
		if r.acertou:
			acertos.append(r.dano))
	var golpe := Golpe.new("Teste", 100, Dado.new(1, 1, 4))  # +100: só erra com 1 natural
	for i in 5:
		(boneco.get_node("Hurtbox") as HurtboxComponent).receber_golpe(golpe, boneco.global_position + Vector2.LEFT)
	_checar(boneco.golpes_recebidos == 5 and not acertos.is_empty() and acertos[0] in [5, 6],
		"boneco sozinho resolve golpes contra a CA e avisa o dano (%s)" % str(acertos))
	boneco.queue_free()


func _colocar_ao_lado_do_boneco() -> void:
	for i in 60:  # espera terminar qualquer golpe/pulo anterior
		if _jogador.is_on_floor() and not _jogador.esta_golpeando():
			break
		await physics_frame
	while not _jogador.pode_golpear():
		await physics_frame
	var y_chao := _jogador.global_position.y
	_jogador.posicionar_no_inicio(Vector2(_boneco.global_position.x - DISTANCIA_DO_BONECO, y_chao))
	_jogador.velocity = Vector2.ZERO
	await _apertar("mover_direita")  # olha para o boneco
	await _esperar(20)


func _apertar(acao: String) -> void:
	Input.action_press(acao)
	await physics_frame
	Input.action_release(acao)
	await physics_frame


func _esperar_golpe_acabar() -> void:
	for i in 60:
		if not _jogador.esta_golpeando():
			return
		await physics_frame


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


## Espera o ritmo da iniciativa liberar e aperta atacar.
func _golpear() -> void:
	for i in 120:
		if _jogador.pode_golpear():
			break
		await physics_frame
	await _apertar("atacar")


## Iniciativa +2 (DES 14): um golpe a cada 0,8 s. Apertar antes não golpeia; apertar logo
## antes de liberar fica guardado (buffer) e sai na hora.
func _testar_ritmo_de_ataque() -> void:
	await _colocar_ao_lado_do_boneco()
	var intervalo := _jogador.intervalo_entre_golpes()
	_checar(is_equal_approx(intervalo, 0.8), "iniciativa +2: golpe a cada 0,8 s (deu %.2f)" % intervalo)
	await _golpear()
	await _esperar_golpe_acabar()
	await _apertar("atacar")  # cedo demais: ainda no intervalo
	_checar(_jogador.nome_estado() != &"Atacando", "apertar antes do intervalo não golpeia")
	while _jogador.tempo_para_proximo_golpe() > 0.1:
		await physics_frame
	await _apertar("atacar")  # 0,1 s antes de liberar: fica no buffer
	for i in 12:
		await physics_frame
	_checar(_jogador.nome_estado() == &"Atacando", "apertar logo antes de liberar golpeia assim que pode (buffer)")
	await _esperar_golpe_acabar()
