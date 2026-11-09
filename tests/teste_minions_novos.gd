extends TesteBase
## Hobgoblin Warrior, Bugbear Warrior e Kobold Warrior (fichas do Monster Manual conferidas no Códice): números,
## Táticas de Matilha, Sensibilidade à Luz Solar, o agarrão do Bugbear e as cenas rodando sozinhas.
## godot --headless --debug --path . --script res://tests/teste_minions_novos.gd

const CENA_HOBGOBLIN := "res://features/goblin/hobgoblin_guerreiro.tscn"
const CENA_BUGBEAR := "res://features/goblin/bugbear_guerreiro.tscn"
const CENA_KOBOLD := "res://features/goblin/kobold_guerreiro.tscn"
const GRUPO := &"monstros"
const POSICAO := Vector2(400, 288)


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_hobgoblin()
	_testar_bugbear()
	_testar_kobold()
	_testar_regra_da_matilha()
	await _testar_cenas_sozinhas()
	await _testar_matilha_e_sol_no_mundo()
	_testar_agarrao_do_bugbear()
	_testar_main()
	print("PASSOU: todos os testes dos minions novos" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_hobgoblin() -> void:
	var ficha: CriaturaRPG = load("res://data/hobgoblin_warrior.tres")
	_checar(ficha.classe_armadura == 18 and ficha.vida_maxima(RandomNumberGenerator.new()) == 11
		and ficha.iniciativa == 3 and ficha.deslocamento_pes == 30.0, "Hobgoblin: CA 18, 11 PV (2d8+2), iniciativa +3, 30 pés")
	var espada := ficha.golpe()
	_checar(espada.nome == "Espada Longa" and espada.bonus_ataque == 3 and espada.dano.media() == 12
		and espada.tipo_dano == TiposDano.CORTANTE and ficha.ataque_alcance_pes == 5.0, "Espada Longa: +3, 12 (2d10+1) cortante, 5 pés")
	var arco := ficha.golpe_disparo()
	_checar(arco.nome == "Arco Longo" and arco.bonus_ataque == 3 and arco.dano.media() == 5
		and arco.tipo_dano == TiposDano.PERFURANTE and ficha.disparo_normal_pes == 150.0 and ficha.disparo_longo_pes == 600.0,
		"Arco Longo: +3, 5 (1d8+1) perfurante, 150/600 pés (45/180 m)")
	_checar(arco.tem(&"dano_adicional") and (arco.efeito(&"dano_adicional") as EfeitoDanoAdicional).dado.media() == 7
		and not espada.tem(&"dano_adicional"), "o tiro soma 7 (3d4) de veneno; a espada não")
	_checar(ficha.taticas_de_matilha and not ficha.tem_furtividade and ficha.experiencia == 100, "Táticas de Matilha, sem Furtividade, 100 XP (ND 1/2)")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var dano := Combate.dano_do_acerto(arco, rng, false)
	_checar(dano >= 5 + 3 and dano <= 9 + 12, "o dano do tiro inclui o veneno extra (%d)" % dano)


func _testar_bugbear() -> void:
	var ficha: CriaturaRPG = load("res://data/bugbear_warrior.tres")
	_checar(ficha.classe_armadura == 14 and ficha.vida_maxima(RandomNumberGenerator.new()) == 33
		and ficha.iniciativa == 2, "Bugbear: CA 14, 33 PV (6d8+6), iniciativa +2")
	var agarrar := ficha.golpe()
	_checar(agarrar.nome == "Agarrar" and agarrar.bonus_ataque == 4 and agarrar.dano.media() == 9
		and agarrar.tipo_dano == TiposDano.CONTUNDENTE and ficha.ataque_alcance_pes == 10.0,
		"Agarrar: +4, 9 (2d6+2) contundente, alcance 10 pés (3 m)")
	var efeito := agarrar.efeito(Proficiencias.EFEITO_AGARRAR) as EfeitosDeTalento.Agarrar
	_checar(efeito != null and efeito.cd == 12, "o acerto agarra com CD 12 de escape")
	var martelo := ficha.golpe_arremesso()
	_checar(martelo.nome == "Martelo Leve" and martelo.bonus_ataque == 4 and martelo.dano.media() == 9
		and not martelo.tem(Proficiencias.EFEITO_AGARRAR) and ficha.arremessos == 3
		and ficha.arremesso_normal_pes == 20.0 and ficha.arremesso_longo_pes == 60.0,
		"Martelo Leve arremessado: +4, 9 (3d4+2), 20/60 pés, 3 martelos, sem agarrar")
	_checar(ficha.tem_furtividade and ficha.bonus_furtividade == 6 and ficha.experiencia == 200, "Furtividade +6 e 200 XP (ND 1)")


func _testar_kobold() -> void:
	var ficha: CriaturaRPG = load("res://data/kobold_warrior.tres")
	_checar(ficha.classe_armadura == 14 and ficha.vida_maxima(RandomNumberGenerator.new()) == 7
		and ficha.iniciativa == 2, "Kobold: CA 14, 7 PV (3d6-3), iniciativa +2")
	var adaga := ficha.golpe()
	_checar(adaga.nome == "Adaga" and adaga.bonus_ataque == 4 and adaga.dano.media() == 4
		and adaga.tipo_dano == TiposDano.PERFURANTE and ficha.arremessos == 3, "Adaga: +4, 4 (1d4+2) perfurante, 3 adagas")
	_checar(ficha.golpe_arremesso().dano.media() == 4 and ficha.taticas_de_matilha and ficha.sensivel_ao_sol
		and ficha.experiencia == 25, "a adaga arremessada vale o mesmo; Matilha e Luz Solar; 25 XP (ND 1/8)")


func _testar_regra_da_matilha() -> void:
	var alvo := Vector2(100, 0)
	_checar(not TaticasDeMatilha.vale(alvo, []), "sem aliados não há matilha")
	_checar(TaticasDeMatilha.vale(alvo, [Vector2(120, 0)] as Array[Vector2]), "aliado a 20 px (menos de 5 pés) dá matilha")
	_checar(not TaticasDeMatilha.vale(alvo, [Vector2(200, 0)] as Array[Vector2]), "aliado a 100 px (mais de 5 pés) não dá")


func _testar_cenas_sozinhas() -> void:
	var hobgoblin: Goblin = await _nascer(CENA_HOBGOBLIN)
	_checar(hobgoblin.nome_estado() == &"Parado" and not hobgoblin.esta_escondido() and hobgoblin.vida_atual() == 11
		and hobgoblin.flechas_restantes() < 0, "Hobgoblin sozinho: parado à vista, 11 PV, flechas sem fim")
	var bugbear: Goblin = await _nascer(CENA_BUGBEAR)
	_checar(bugbear.nome_estado() == &"Escondido" and bugbear.esta_escondido() and bugbear.vida_atual() == 33
		and bugbear.adagas_restantes() == 3, "Bugbear sozinho: escondido, 33 PV, 3 martelos")
	var kobold: Goblin = await _nascer(CENA_KOBOLD)
	_checar(kobold.nome_estado() == &"Parado" and kobold.vida_atual() == 7 and kobold.adagas_restantes() == 3,
		"Kobold sozinho: parado à vista, 7 PV, 3 adagas")
	for goblin in [hobgoblin, bugbear, kobold]:
		goblin.queue_free()
	await _esperar(1)


## Dois kobolds e o alvo: com o aliado perto do alvo o golpe tem vantagem; ao sol, desvantagem. Os dois se anulam.
func _testar_matilha_e_sol_no_mundo() -> void:
	var alvo := Node2D.new()
	root.add_child(alvo)
	alvo.global_position = POSICAO
	var kobold: Goblin = await _nascer(CENA_KOBOLD)
	var aliado: Goblin = await _nascer(CENA_KOBOLD)
	for goblin in [kobold, aliado]:
		goblin.add_to_group(GRUPO)
	kobold.definir_alvo(alvo)
	kobold.global_position = POSICAO + Vector2(-150, 0)
	aliado.global_position = POSICAO + Vector2(20, 0)
	_checar(kobold._golpe_da_ficha().vantagem, "aliado a 5 pés do alvo: o Kobold ataca com vantagem")
	aliado.global_position = POSICAO + Vector2(300, 0)
	_checar(not kobold._golpe_da_ficha().vantagem, "aliado longe do alvo: sem vantagem")
	aliado.global_position = POSICAO + Vector2(20, 0)
	(aliado.get_node("Vida") as HealthComponent).receber_dano(99)
	_checar(not kobold._golpe_da_ficha().vantagem, "aliado morto não conta para a matilha")
	_checar(not kobold._golpe_da_ficha().desvantagem, "sem sol: sem desvantagem")
	kobold.definir_luz_do_sol(true)
	var ao_sol := kobold._golpe_da_ficha()
	_checar(ao_sol.desvantagem, "ao sol o Kobold ataca com desvantagem")
	_checar(kobold._golpe_do_arremesso().desvantagem and not kobold._golpe_do_arremesso().corpo_a_corpo,
		"a adaga arremessada também sofre com o sol e não é corpo a corpo")
	var hobgoblin: Goblin = await _nascer(CENA_HOBGOBLIN)
	hobgoblin.definir_luz_do_sol(true)
	hobgoblin.definir_alvo(alvo)
	_checar(not hobgoblin._golpe_da_ficha().desvantagem, "o Hobgoblin não sofre com o sol")
	for no in [alvo, kobold, aliado, hobgoblin]:
		no.queue_free()
	await _esperar(1)


## O acerto do Bugbear agarra o herói: sem deslocamento, e quem agarrou é o autor do golpe.
func _testar_agarrao_do_bugbear() -> void:
	var ficha: CriaturaRPG = load("res://data/bugbear_warrior.tres")
	var golpe := ficha.golpe()
	golpe.autor_id = 7
	var alvo := Node2D.new()
	var condicoes := CondicoesComponent.new()
	alvo.add_child(condicoes)
	root.add_child(alvo)
	var resultado := Combate.Resultado.new()
	resultado.golpe = golpe
	resultado.acertou = true
	resultado.dano = 9
	condicoes.aplicar_maestria(resultado, 1.0)
	_checar(condicoes.tem(CondicoesComponent.AGARRADO) and condicoes.reducao_deslocamento_pes() >= 30.0,
		"o acerto do Bugbear agarra: o alvo fica sem deslocamento")
	alvo.queue_free()


## Na main: os tipos novos têm cena, a fase sorteia e o bestiário e a tela de comandos conhecem os três.
func _testar_main() -> void:
	for tipo in [Main.TIPO_HOBGOBLIN, Main.TIPO_BUGBEAR, Main.TIPO_KOBOLD]:
		_checar(Main.CENAS_DOS_TIPOS.has(tipo), "a main tem a cena do tipo %s" % tipo)
	var nomes: Array[String] = []
	for entrada in Main.ENTRADAS_BESTIARIO:
		nomes.append(entrada.criatura.nome)
	_checar("Hobgoblin Warrior" in nomes and "Bugbear Warrior" in nomes and "Kobold Warrior" in nomes,
		"o bestiário tem as três páginas")
	var tipos_das_fases: Array[StringName] = []
	for cena in Main.CENAS_FASE:
		var fase := cena.instantiate() as Fase
		for tipo in fase.tipos_permitidos:
			if tipo not in tipos_das_fases:
				tipos_das_fases.append(tipo)
		fase.free()
	_checar(Main.TIPO_HOBGOBLIN in tipos_das_fases and Main.TIPO_BUGBEAR in tipos_das_fases and Main.TIPO_KOBOLD in tipos_das_fases,
		"a campanha sorteia os três tipos novos")


func _nascer(caminho: String) -> Goblin:
	var goblin: Goblin = load(caminho).instantiate()
	root.add_child(goblin)
	await _esperar(3)
	return goblin


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
