extends SceneTree
## Teste do Goblin Minion: ficha do livro, arremessa as adagas de longe (com desvantagem
## além de 20 pés), golpeia de perto, Desengaja (Fuga Ágil) e morre.
## godot --headless --debug --path . --script res://tests/teste_goblin.gd

const CENA_GOBLIN := "res://features/goblin/goblin.tscn"
## Dentro dos 60 pés (384 px) e além dos 20 (128 px): arremessa com desvantagem.
const LONGE_PARA_ARREMESSO := 300.0
## Ao alcance da adaga (5 pés a partir da borda do corpo).
const AO_ALCANCE := 30.0
const VIDA_DE_TESTE := 999
## Onde o goblin fica no teste (longe do Ooze e do boneco do mapa, que são tirados).
const POSICAO_GOBLIN := Vector2(900, 288)

var _falhas := 0
var _jogador: Jogador
var _goblin: Goblin


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_ficha()
	await _testar_sozinho()
	var cena: Main = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	_jogador = cena.get_node("Jogador")
	(_jogador.get_node("Vida") as HealthComponent).configurar(VIDA_DE_TESTE)
	cena.tirar_criaturas()
	_goblin = load(CENA_GOBLIN).instantiate()
	cena.add_child(_goblin)
	_goblin.global_position = POSICAO_GOBLIN
	_goblin.definir_alvo(_jogador)
	_goblin.definir_percepcao_passiva(100)
	await _esperar(10)

	await _testar_arremesso()
	await _testar_golpe_e_fuga()
	await _testar_morte()
	await _testar_emboscada(cena)
	cena.queue_free()

	if _falhas == 0:
		print("PASSOU: todos os testes do Goblin")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha() -> void:
	var ficha: CriaturaRPG = load("res://data/goblin_minion.tres")
	_checar(ficha.classe_armadura == 12 and ficha.vida_maxima(RandomNumberGenerator.new()) == 7
		and ficha.iniciativa == 2 and ficha.deslocamento_pes == 30.0, "Goblin Minion: CA 12, 7 PV (2d6), iniciativa +2, 30 pés")
	var golpe := ficha.golpe()
	_checar(golpe.bonus_ataque == 4 and golpe.tipo_dano == TiposDano.PERFURANTE and golpe.dano.media() == 4,
		"Adaga: +4, 4 (1d4 + 2) perfurante")
	_checar(ficha.arremessos == 3 and ficha.arremesso_normal_pes == 20.0 and ficha.arremesso_longo_pes == 60.0
		and ficha.fuga_agil, "3 adagas, arremesso 20/60 pés e Fuga Ágil")
	_checar(ficha.tem_furtividade and ficha.bonus_furtividade == 6 and ficha.dano_extra_com_vantagem == ""
		and ficha.golpe().dano_extra == null, "Furtividade +6, sem o dado extra do Warrior")


## A cena roda sozinha (como no F6): sem alvo, fica parado.
func _testar_sozinho() -> void:
	var goblin: Goblin = load(CENA_GOBLIN).instantiate()
	root.add_child(goblin)
	await _esperar(10)
	_checar(goblin.nome_estado() == &"Escondido" and goblin.esta_escondido() and goblin.vida_atual() == 7
		and goblin.adagas_restantes() == 3, "Goblin sozinho: escondido, 7 PV, 3 adagas")
	goblin.queue_free()
	await _esperar(1)


func _testar_arremesso() -> void:
	var resultados: Array[Combate.Resultado] = []
	var defesa: DefesaComponent = _jogador.get_node("Defesa")
	var anotar := func(r: Combate.Resultado, _o: Vector2) -> void: resultados.append(r)
	defesa.golpe_resolvido.connect(anotar)
	var viu_adaga := false
	_colocar_heroi_a(LONGE_PARA_ARREMESSO)
	await _esperar(5)
	_checar(not _goblin.esta_escondido() and _goblin.nome_estado() != &"Escondido",
		"passiva alta: aparece dentro da visão")
	for i in 90:
		await physics_frame
		_colocar_heroi_a(LONGE_PARA_ARREMESSO)
		viu_adaga = viu_adaga or not _adagas_voando().is_empty()
	_checar(_goblin.adagas_restantes() < 3 and viu_adaga, "de longe (dentro de 60 pés), o goblin arremessa adaga")
	for i in 240:
		await physics_frame
		_colocar_heroi_a(LONGE_PARA_ARREMESSO)
	defesa.golpe_resolvido.disconnect(anotar)
	_checar(not resultados.is_empty() and resultados.all(func(r: Combate.Resultado) -> bool: return r.golpe.desvantagem),
		"a adaga chega no herói a 300 px (além de 20 pés) com desvantagem")
	_checar(_goblin.adagas_restantes() == 0, "gasta as 3 adagas e não arremessa mais")
	_checar(_goblin.nome_estado() == &"Perseguindo", "sem adagas, corre até o herói")


func _testar_golpe_e_fuga() -> void:
	var resultados: Array[Combate.Resultado] = []
	var defesa: DefesaComponent = _jogador.get_node("Defesa")
	defesa.golpe_resolvido.connect(func(r: Combate.Resultado, _o: Vector2) -> void: resultados.append(r))
	_colocar_heroi_a(AO_ALCANCE)
	var desengajou := false
	var mais_longe := 0.0
	for i in 180:
		await physics_frame
		if _goblin.nome_estado() == &"Desengajando":
			desengajou = true
			mais_longe = maxf(mais_longe, absf(_goblin.global_position.x - _jogador.global_position.x))
		elif not desengajou:
			_colocar_heroi_a(AO_ALCANCE)
	_checar(not resultados.is_empty() and resultados[0].golpe.nome == "Adaga", "perto, golpeia o herói com a adaga")
	_checar(desengajou and mais_longe > AO_ALCANCE + 40.0, "Fuga Ágil: depois do golpe, salta para longe (%.0f px)" % mais_longe)


func _testar_morte() -> void:
	(_goblin.get_node("Vida") as HealthComponent).receber_dano(99)
	await _esperar(5)
	_checar(_goblin.nome_estado() == &"Morrendo", "vida zerou: toca a morte")
	for i in 180:
		await physics_frame
		if not is_instance_valid(_goblin):
			break
	_checar(not is_instance_valid(_goblin), "termina de morrer e some")


## Passiva 0: a Furtividade sempre alcança. Continua invisível até o corpo a corpo.
func _testar_emboscada(cena: Main) -> void:
	_goblin = load(CENA_GOBLIN).instantiate()
	cena.add_child(_goblin)
	_goblin.global_position = POSICAO_GOBLIN
	_goblin.definir_alvo(_jogador)
	_goblin.definir_percepcao_passiva(0)
	(_jogador.get_node("Defesa") as DefesaComponent).invulneravel = false
	_colocar_heroi_a(LONGE_PARA_ARREMESSO)
	await _esperar(8)
	_checar(_goblin.nome_estado() == &"Escondido" and _goblin.esta_escondido(),
		"passiva 0: dentro da visão continua escondido")
	var resultados: Array[Combate.Resultado] = []
	var defesa: DefesaComponent = _jogador.get_node("Defesa")
	defesa.golpe_resolvido.connect(func(r: Combate.Resultado, _o: Vector2) -> void: resultados.append(r))
	_colocar_heroi_a(AO_ALCANCE)
	for i in 180:
		await physics_frame
		if resultados.is_empty():
			_colocar_heroi_a(AO_ALCANCE)
	var golpe: Golpe = null if resultados.is_empty() else resultados[0].golpe
	_checar(golpe != null and golpe.nome == "Adaga" and golpe.vantagem and golpe.dano_extra == null,
		"no corpo a corpo aparece atacando; o primeiro golpe tem vantagem e não soma dado extra")
	if is_instance_valid(_goblin):
		_goblin.queue_free()


func _adagas_voando() -> Array[AdagaGoblin]:
	var lista: Array[AdagaGoblin] = []
	for filho in _goblin.get_children():
		if filho is AdagaGoblin and not filho.is_queued_for_deletion():
			lista.append(filho)
	return lista


## Herói à esquerda do goblin, no chão.
func _colocar_heroi_a(distancia: float) -> void:
	_jogador.posicionar_no_inicio(Vector2(_goblin.global_position.x - distancia, _jogador.global_position.y))


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
