extends TesteBase
## Teste do Minotauro (chefe da fase 6): ficha do livro, Chifrada com e sem carreira, bloco quebrável, herói derrubado e a
## luta de verdade na arena: investe, quebra os pilares, derruba o herói, golpeia com o glaive, e morre.
## godot --headless --debug --path . --script res://tests/criaturas/teste_minotauro.gd

const VIDA_DE_TESTE := 9999
const QUADROS_POR_SEGUNDO := 60
## Distância do herói à investida: longe o bastante para a corrida de 10 pés e com os pilares da arena no caminho.
const DISTANCIA_DA_INVESTIDA := 300.0
## Perto o bastante para o glaive (borda do corpo + 10 pés).
const AO_ALCANCE := 70.0
const CHAO_Y := 288.0
## Herói fora do alcance do glaive (borda do corpo + 10 pés = 94 px) e bloco encostado no chefe (meia largura do corpo + do bloco).
const DISTANCIA_ATRAS_DO_BLOCO := 200.0
const BLOCO_ENCOSTADO := 46.0
const FASE_DO_CHEFE := 5

var _jogador: Jogador
var _minotauro: Minotauro


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_ficha()
	_testar_golpes_da_chifrada()
	var cena: Main = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	_jogador = cena.get_node("Jogador")
	(_jogador.get_node("Vida") as HealthComponent).configurar(VIDA_DE_TESTE)
	await _esperar(10)

	await _testar_bloco_quebravel(cena)
	await _testar_heroi_derrubado()
	await _testar_fase_do_chefe(cena)
	if _minotauro != null:
		await _testar_investida_e_pilares()
		await _testar_glaive_e_blocos(cena)
		await _testar_bloco_que_barra(cena)
		await _testar_morte(cena)
	cena.queue_free()

	print("PASSOU: todos os testes do Minotauro" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha() -> void:
	var ficha: CriaturaRPG = load("res://data/minotauro.tres")
	_checar(ficha.classe_armadura == 14 and ficha.vida_maxima(RandomNumberGenerator.new()) == 85
		and ficha.deslocamento_pes == 40.0 and ficha.experiencia == 700,
		"Minotauro: CA 14, 85 PV (10d10+30), 40 pés, ND 3 (700 XP)")
	var glaive := ficha.golpe()
	_checar(glaive.nome == "Glaive Abissal" and glaive.bonus_ataque == 6 and glaive.tipo_dano == TiposDano.CORTANTE
		and glaive.dano.texto() == "1d12+4" and ficha.dano_medio(glaive) == 20.0 and ficha.ataque_alcance_pes == 10.0,
		"Glaive Abissal: +6, 1d12+4 cortante + 3d6, alcance 10 pés")


## A Chifrada sem corrida é só 4d6+4 perfurante; com 10 pés de corrida soma 3d6 e derruba.
func _testar_golpes_da_chifrada() -> void:
	var ficha: CriaturaRPG = load("res://data/minotauro.tres")
	var sem := ficha.golpe_chifrada(false)
	_checar(sem.bonus_ataque == 6 and sem.dano.texto() == "4d6+4" and sem.tipo_dano == TiposDano.PERFURANTE
		and not sem.tem(Proficiencias.EFEITO_DERRUBADA) and ficha.dano_medio(sem) == 18.0,
		"Chifrada sem carreira: +6, 4d6+4 perfurante, não derruba")
	var com := ficha.golpe_chifrada(true)
	_checar(com.tem(Proficiencias.EFEITO_DERRUBADA) and ficha.dano_medio(com) == 28.0 and ficha.chifrada_recarga == 5
		and ficha.chifrada_carreira_pes == 10.0,
		"Chifrada com carreira de 10 pés: soma 3d6, derruba, recarga 5-6")


## O bloco marcado é sólido até quebrar; quebrado, sai do grupo, perde a colisão e some.
func _testar_bloco_quebravel(cena: Node) -> void:
	var bloco: BlocoQuebravel = load("res://features/bloco_quebravel/bloco_quebravel.tscn").instantiate()
	cena.add_child(bloco)
	_checar(bloco.is_in_group(&"quebravel") and not bloco.esta_quebrado(), "bloco novo: no grupo quebravel e inteiro")
	var avisos := [0]
	bloco.quebrado.connect(func() -> void: avisos[0] += 1)
	bloco.quebrar()
	bloco.quebrar()
	await _esperar(3)
	_checar(avisos[0] == 1 and bloco.esta_quebrado() and not bloco.is_in_group(&"quebravel")
		and (bloco.get_node("Colisao") as CollisionShape2D).disabled, "quebrar (duas vezes): avisa uma vez, sai do grupo e perde a colisão")
	await _esperar(int(BlocoQuebravel.TEMPO_DOS_PEDACOS * QUADROS_POR_SEGUNDO) + 10)
	_checar(not is_instance_valid(bloco), "depois dos pedaços, o bloco some")


## O golpe com Derrubada joga o herói no chão (estado Caído) e ele se levanta depois.
func _testar_heroi_derrubado() -> void:
	var caiu := false
	for tentativa in 3:  # o d20 pode tirar 1 (erro automático): tenta de novo
		for i in 300:  # espera passar a invencibilidade do golpe anterior
			if not _jogador.esta_invencivel():
				break
			await physics_frame
		var golpe := Golpe.new("Chifrada", 100, Dado.new(1, 4), TiposDano.PERFURANTE)
		golpe.efeitos.append(EfeitosDeTalento.Derrubada.new())
		(_jogador.get_node("Hurtbox") as HurtboxComponent).receber_golpe(golpe, _jogador.global_position + Vector2(-60.0, 0.0))
		await _esperar(3)
		caiu = _jogador.nome_estado() == &"Caido"
		if caiu:
			break
	_checar(caiu, "a Chifrada com carreira derruba o herói (estado %s)" % _jogador.nome_estado())
	await _esperar(QUADROS_POR_SEGUNDO * 2)
	_checar(_jogador.nome_estado() != &"Caido", "e ele se levanta depois")


## A fase 6 nasce com o Minotauro no marcador: conta na cota, a missão pede o chefe, a HUD mostra a barra e há pilares.
func _testar_fase_do_chefe(cena: Main) -> void:
	cena._entrar_fase(Main.CENAS_FASE[FASE_DO_CHEFE])
	await _esperar(5)
	var chefes := cena.get_tree().get_nodes_in_group(Main.GRUPO_MONSTROS).filter(func(m: Node) -> bool: return m is Minotauro)
	_checar(chefes.size() == 1, "a fase 6 nasce com um Minotauro")
	if chefes.is_empty():
		return
	_minotauro = chefes[0]
	var barra := cena.get_node("Hud").find_child("Chefe", true, false) as Control
	var missao := cena.get_node("Hud").find_child("Missao", true, false) as Label
	_checar(cena._ids_da_cota.has(_minotauro.get_instance_id()), "o chefe conta na cota da porta")
	_checar("Minotauro" in missao.text, "a missão pede para derrotar o Minotauro (%s)" % missao.text)
	_checar(barra.visible, "a HUD mostra a barra de vida do chefe")
	_checar(cena.get_tree().get_nodes_in_group(&"quebravel").size() == 4, "a arena tem 4 blocos quebráveis (2 pilares de 2)")
	for monstro in cena.get_tree().get_nodes_in_group(Main.GRUPO_MONSTROS):
		if monstro != _minotauro:
			monstro.queue_free()  # só o chefe conta nesta luta
	await _esperar(3)


## Herói parado longe: o Minotauro investe, quebra os pilares no caminho e derruba o herói com a carreira.
func _testar_investida_e_pilares() -> void:
	(_jogador.get_node("Defesa") as DefesaComponent).classe_armadura = 1  # a investida acerta (só o 1 natural erra); nova investida tira a dúvida
	_colocar_heroi_a(DISTANCIA_DA_INVESTIDA)
	var estados: Dictionary = {}
	var derrubou := false
	for i in QUADROS_POR_SEGUNDO * 20:
		await physics_frame
		estados[_minotauro.nome_estado()] = true
		derrubou = derrubou or _jogador.nome_estado() == &"Caido"
		if derrubou and get_nodes_in_group(&"quebravel").is_empty():
			break
	_checar(&"Investindo" in estados, "com o herói longe e a Chifrada pronta, o Minotauro investe")
	_checar(get_nodes_in_group(&"quebravel").is_empty(), "a investida quebrou os pilares no caminho")
	_checar(derrubou, "a investida com carreira derrubou o herói")
	_checar(not _minotauro.chifrada_pronta() or &"Investindo" in estados, "a Chifrada gasta a recarga")


## Ao alcance, o glaive acerta o herói; um bloco à frente quebra com o golpe.
func _testar_glaive_e_blocos(cena: Node) -> void:
	_minotauro.definir_chifrada_pronta(false)
	var resultados: Array[Combate.Resultado] = []
	var defesa: DefesaComponent = _jogador.get_node("Defesa")
	defesa.golpe_resolvido.connect(func(r: Combate.Resultado, _o: Vector2) -> void: resultados.append(r))
	var estados: Dictionary = {}
	for i in QUADROS_POR_SEGUNDO * 8:
		await physics_frame
		_colocar_heroi_a(AO_ALCANCE)
		estados[_minotauro.nome_estado()] = true
		if resultados.any(func(r: Combate.Resultado) -> bool: return r.golpe.nome == "Glaive Abissal"):
			break
	_checar(&"Atacando" in estados, "ao alcance, golpeia com o glaive")
	_checar(resultados.any(func(r: Combate.Resultado) -> bool: return r.golpe.nome == "Glaive Abissal"), "o Glaive Abissal chega ao herói")
	var bloco: BlocoQuebravel = load("res://features/bloco_quebravel/bloco_quebravel.tscn").instantiate()
	cena.add_child(bloco)
	_minotauro.set_physics_process(false)
	bloco.global_position = Vector2(_minotauro.global_position.x + 60.0 * _minotauro.direcao_olhar, CHAO_Y)
	_minotauro.global_position.x += 1.0  # a área só vê um corpo parado que apareceu depois se ela se mexer
	await _esperar(3)
	_minotauro.ligar_glaive()
	_checar(bloco.esta_quebrado(), "o golpe de glaive quebra o bloco à frente")
	_minotauro.desligar_glaive()
	_minotauro.set_physics_process(true)


## Um bloco encostado no chefe, com o herói fora do alcance do glaive: ele não fica preso, golpeia o bloco e abre passagem.
func _testar_bloco_que_barra(cena: Node) -> void:
	var bloco: BlocoQuebravel = load("res://features/bloco_quebravel/bloco_quebravel.tscn").instantiate()
	cena.add_child(bloco)
	_minotauro.global_position = Vector2(_minotauro.global_position.x, CHAO_Y)
	_colocar_heroi_a(DISTANCIA_ATRAS_DO_BLOCO)
	bloco.global_position = Vector2(_minotauro.global_position.x - BLOCO_ENCOSTADO, CHAO_Y)
	_minotauro.definir_chifrada_pronta(false)
	for i in QUADROS_POR_SEGUNDO * 6:
		await physics_frame
		if bloco.esta_quebrado():
			break
	_checar(bloco.esta_quebrado(), "encostado num bloco que barra o caminho, o chefe o golpeia em vez de ficar preso")


func _testar_morte(cena: Main) -> void:
	var morreu := [false]
	var id := _minotauro.get_instance_id()
	_minotauro.morreu.connect(func() -> void: morreu[0] = true)
	(_minotauro.get_node("Vida") as HealthComponent).receber_dano(VIDA_DE_TESTE)
	await _esperar(QUADROS_POR_SEGUNDO * 3)
	var barra := cena.get_node("Hud").find_child("Chefe", true, false) as Control
	_checar(morreu[0], "ao zerar a vida, o Minotauro morre e emite morreu")
	_checar(not barra.visible and not cena._ids_da_cota.has(id), "ao cair, a barra some e a cota abre")


## O herói fica à esquerda do Minotauro, na mesma altura.
func _colocar_heroi_a(distancia: float) -> void:
	_jogador.posicionar_no_inicio(Vector2(_minotauro.global_position.x - distancia, CHAO_Y))


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
