extends TesteBase
## Teste do Goblin Warrior: ficha do livro, arco curto de longe (sem desvantagem dentro
## de 80 pés; flechas não acabam), cimitarra de perto, Fuga Ágil e morte.
## godot --headless --debug --path . --script res://tests/teste_goblin_guerreiro.gd

const CENA := "res://features/goblin/goblin_guerreiro.tscn"
## Dentro dos 60 pés (384 px) e dos 80 (512 px): o tiro acerta sem desvantagem de distância.
const LONGE := 300.0
## Ao alcance da cimitarra (5 pés a partir da borda do corpo).
const AO_ALCANCE := 30.0
const VIDA_DE_TESTE := 999
const POSICAO := Vector2(900, 288)

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
	_goblin = load(CENA).instantiate()
	cena.add_child(_goblin)
	_goblin.global_position = POSICAO
	_goblin.definir_alvo(_jogador)
	_goblin.definir_percepcao_passiva(100)
	await _esperar(10)

	await _testar_tiro()
	await _testar_golpe_e_fuga()
	await _testar_morte()
	await _testar_emboscada(cena)
	cena.queue_free()

	if _falhas == 0:
		print("PASSOU: todos os testes do Goblin Warrior")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha() -> void:
	var ficha: CriaturaRPG = load("res://data/goblin_warrior.tres")
	_checar(ficha.classe_armadura == 15 and ficha.vida_maxima(RandomNumberGenerator.new()) == 10
		and ficha.iniciativa == 2 and ficha.deslocamento_pes == 30.0,
		"Goblin Warrior: CA 15, 10 PV (3d6), iniciativa +2, 30 pés")
	var cimitarra := ficha.golpe()
	_checar(cimitarra.nome == "Cimitarra" and cimitarra.bonus_ataque == 4
		and cimitarra.tipo_dano == TiposDano.CORTANTE and cimitarra.dano.media() == 5,
		"Cimitarra: +4, 5 (1d6 + 2) cortante")
	var arco := ficha.golpe_disparo()
	_checar(arco.nome == "Arco Curto" and arco.bonus_ataque == 4
		and arco.tipo_dano == TiposDano.PERFURANTE and arco.dano.media() == 5
		and ficha.disparo_normal_pes == 80.0 and ficha.disparo_longo_pes == 320.0,
		"Arco Curto: +4, 5 (1d6 + 2) perfurante, 80/320 pés")
	_checar(ficha.disparos < 0 and ficha.arremessos == 0 and ficha.fuga_agil,
		"flechas não acabam, não arremessa adaga, tem Fuga Ágil")
	_checar(ficha.tem_furtividade and ficha.bonus_furtividade == 6
		and cimitarra.dano_extra != null and cimitarra.dano_extra.texto() == "1d4"
		and arco.dano_extra != null and arco.dano_extra.texto() == "1d4",
		"Furtividade +6, e o 1d4 entra na cimitarra e no arco quando há vantagem")


## A cena roda sozinha (como no F6): sem alvo, fica parada.
func _testar_sozinho() -> void:
	var goblin: Goblin = load(CENA).instantiate()
	root.add_child(goblin)
	await _esperar(10)
	_checar(goblin.nome_estado() == &"Escondido" and goblin.esta_escondido() and goblin.vida_atual() == 10
		and goblin.flechas_restantes() < 0, "Guerreiro sozinho: escondido, 10 PV, flechas sem fim")
	goblin.queue_free()
	await _esperar(1)


func _testar_tiro() -> void:
	var resultados: Array[Combate.Resultado] = []
	var defesa: DefesaComponent = _jogador.get_node("Defesa")
	var anotar := func(r: Combate.Resultado, _o: Vector2) -> void: resultados.append(r)
	defesa.golpe_resolvido.connect(anotar)
	var viu_flecha := false
	_colocar_heroi_a(100.0)
	await _esperar(20)
	_checar(_flechas_voando().is_empty() and _goblin.nome_estado() == &"Perseguindo",
		"a menos de 20 pés ele fecha para a cimitarra, sem metralhar flechas")
	_colocar_heroi_a(LONGE)
	await _esperar(5)
	_checar(not _goblin.esta_escondido() and _goblin.nome_estado() != &"Escondido",
		"passiva alta: aparece dentro da visão")
	for i in 240:
		await physics_frame
		_colocar_heroi_a(LONGE)
		viu_flecha = viu_flecha or not _flechas_voando().is_empty()
	defesa.golpe_resolvido.disconnect(anotar)
	_checar(viu_flecha and _goblin.flechas_restantes() < 0, "de longe, atira e as flechas não acabam")
	_checar(not resultados.is_empty() and resultados.all(func(r: Combate.Resultado) -> bool: return not r.golpe.desvantagem),
		"a flecha chega a 300 px (dentro de 80 pés) sem desvantagem")
	await _testar_alcance_da_flecha()


## Empurra uma flecha no ar para conferir a desvantagem e a queda, sem esperar o voo inteiro.
func _testar_alcance_da_flecha() -> void:
	_colocar_heroi_a(LONGE)
	var flecha: FlechaGoblin = null
	for i in 90:
		await physics_frame
		if not _flechas_voando().is_empty():
			flecha = _flechas_voando()[0]
			break
	_checar(flecha != null, "há uma flecha no ar para medir o alcance")
	if flecha == null:
		return
	flecha.global_position.x = _goblin.global_position.x - EscalaDnd.pes_para_pixels(100.0)
	flecha._aplicar_alcance()
	_checar(flecha.em_desvantagem(), "além de 80 pés a flecha fica com desvantagem")
	flecha.global_position.x = _goblin.global_position.x - EscalaDnd.pes_para_pixels(400.0)
	flecha._aplicar_alcance()
	var hitbox := flecha.get_node("Hitbox") as HitboxComponent
	_checar(not hitbox.esta_ligada(), "no alcance longo a flecha cai")


func _testar_golpe_e_fuga() -> void:
	for flecha in _flechas_voando():
		flecha.queue_free()
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
	_checar(not resultados.is_empty() and resultados[0].golpe.nome == "Cimitarra",
		"perto, golpeia o herói com a cimitarra")
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


## Passiva 0: continua invisível até o corpo a corpo, e o primeiro golpe tem vantagem.
func _testar_emboscada(cena: Main) -> void:
	_goblin = load(CENA).instantiate()
	cena.add_child(_goblin)
	_goblin.global_position = POSICAO
	_goblin.definir_alvo(_jogador)
	_goblin.definir_percepcao_passiva(0)
	(_jogador.get_node("Defesa") as DefesaComponent).invulneravel = false
	_colocar_heroi_a(LONGE)
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
	_checar(golpe != null and golpe.nome == "Cimitarra" and golpe.vantagem
		and golpe.dano_extra != null and golpe.dano_extra.texto() == "1d4",
		"no corpo a corpo aparece atacando; o primeiro golpe tem vantagem e leva o 1d4")
	var escondeu := false
	for i in 120:
		await physics_frame
		if is_instance_valid(_goblin) and _goblin.nome_estado() == &"Escondido" and _goblin.esta_escondido():
			escondeu = true
			break
	_checar(escondeu, "depois da cimitarra, com passiva 0, esconde de novo")
	if is_instance_valid(_goblin):
		_goblin.queue_free()


func _flechas_voando() -> Array[FlechaGoblin]:
	var lista: Array[FlechaGoblin] = []
	for filho in _goblin.get_children():
		if filho is FlechaGoblin and not filho.is_queued_for_deletion():
			lista.append(filho)
	return lista


## Herói à esquerda do goblin, no chão.
func _colocar_heroi_a(distancia: float) -> void:
	_jogador.posicionar_no_inicio(Vector2(_goblin.global_position.x - distancia, _jogador.global_position.y))


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
