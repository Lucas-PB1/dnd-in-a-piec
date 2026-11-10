extends TesteBase
## Teste do Wight (chefe da cripta): ficha do livro, Drenar Vida (máximo de PV reduzido até o descanso longo), acompanhantes que
## surgem ao despertar e a luta de verdade: golpeia de perto (espada e Drenar Vida), atira de longe e morre.
## godot --headless --debug --path . --script res://tests/teste_wight.gd

const VIDA_DE_TESTE := 9999
const QUADROS_POR_SEGUNDO := 60
## Perto o bastante para a espada (borda do corpo + 5 pés = 30 px).
const AO_ALCANCE := 24.0
## Longe o bastante para o arco (mais de 160 px) e ainda na mesma arena.
const DISTANCIA_DO_TIRO := 400.0
## Dentro da percepção (120 pés = 768 px) mas fora do alcance de qualquer golpe.
const DISTANCIA_DE_PERCEBER := 700.0
const CHAO_Y := 288.0
const FASE_DO_CHEFE := 8
const ACOMPANHANTES := 2

var _jogador: Jogador
var _wight: Wight


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_ficha()
	_testar_drenar_vida_na_ficha()
	_testar_maximo_de_vida()
	_testar_imunidades()
	var cena: Main = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	_jogador = cena.get_node("Jogador")
	(_jogador.get_node("Vida") as HealthComponent).configurar(VIDA_DE_TESTE)
	await _esperar(10)

	await _testar_fase_do_chefe(cena)
	if _wight != null:
		await _testar_acompanhantes(cena)
		await _testar_corpo_a_corpo()
		await _testar_tiro()
		await _testar_morte(cena)
	cena.queue_free()

	print("PASSOU: todos os testes do Wight" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha() -> void:
	var ficha: CriaturaRPG = load("res://data/wight.tres")
	_checar(ficha.classe_armadura == 14 and ficha.vida_maxima(RandomNumberGenerator.new()) == 82
		and ficha.deslocamento_pes == 30.0 and ficha.experiencia == 700 and ficha.iniciativa == 4,
		"Wight: CA 14, 82 PV (11d8+33), 30 pés, iniciativa +4, ND 3 (700 XP)")
	_checar(ficha.modificador(Atributos.FORCA) == 2 and ficha.modificador(Atributos.CONSTITUICAO) == 3
		and TiposDano.NECROTICO in ficha.resistencias and ficha.sensivel_ao_sol,
		"resistente a necrótico e sensível à luz do sol")
	var espada := ficha.golpe()
	_checar(espada.nome == "Espada Necrótica" and espada.bonus_ataque == 4 and espada.tipo_dano == TiposDano.CORTANTE
		and espada.dano.texto() == "1d8+2" and ficha.dano_medio(espada) == 10.0 and ficha.ataque_alcance_pes == 5.0,
		"Espada Necrótica: +4, 1d8+2 cortante + 1d8, alcance 5 pés")
	var arco := ficha.golpe_disparo()
	_checar(arco.nome == "Arco Necrótico" and arco.bonus_ataque == 4 and arco.tipo_dano == TiposDano.PERFURANTE
		and ficha.dano_medio(arco) == 10.0 and ficha.disparo_normal_pes == 150.0 and ficha.disparo_longo_pes == 600.0,
		"Arco Necrótico: +4, 1d8+2 perfurante + 1d8, alcance 150/600 pés")


func _testar_drenar_vida_na_ficha() -> void:
	var ficha: CriaturaRPG = load("res://data/wight.tres")
	var drenar := ficha.golpe_drenar()
	_checar(drenar.nome == "Drenar Vida" and drenar.cd_salvaguarda == 13 and drenar.atributo_salvaguarda == Atributos.CONSTITUICAO
		and drenar.dano.texto() == "1d8+2" and drenar.tipo_dano == TiposDano.NECROTICO
		and drenar.tem(Proficiencias.EFEITO_DRENAR_VIDA),
		"Drenar Vida: salvaguarda de Constituição CD 13, 1d8+2 necrótico, reduz o máximo")


## O máximo drenado: corta a vida atual, o mínimo é 1, subir de nível respeita o que foi drenado e o descanso devolve.
func _testar_maximo_de_vida() -> void:
	var vida := HealthComponent.new()
	vida.configurar(20)
	vida.reduzir_maximo(5)
	_checar(vida.vida_maxima == 15 and vida.vida_atual == 15 and vida.maximo_drenado == 5,
		"reduzir o máximo em 5: 20 vira 15 e a vida atual acompanha")
	vida.aumentar_maximo(30)
	_checar(vida.vida_maxima == 25 and vida.maximo_drenado == 5, "subir de nível (máximo 30) com 5 drenados dá 25")
	vida.reduzir_maximo(1000)
	_checar(vida.vida_maxima == 1, "o máximo nunca cai abaixo de 1")
	vida.restaurar_maximo()
	_checar(vida.vida_maxima == 30 and vida.maximo_drenado == 0, "restaurar devolve o que foi drenado")
	vida.free()


## Imune a veneno (dano) e à condição Envenenado; o Gray Ooze é imune a Caído e Agarrado (livro).
func _testar_imunidades() -> void:
	var wight: CriaturaRPG = load("res://data/wight.tres")
	var ooze: CriaturaRPG = load("res://data/gray_ooze.tres")
	_checar(TiposDano.VENENO in wight.imunidades_dano and CondicoesComponent.ENVENENADO in wight.imunidades_condicoes,
		"o Wight é imune a veneno e à condição Envenenado")
	var condicoes := CondicoesComponent.new()
	condicoes.imunidades = ooze.imunidades_condicoes
	condicoes.impor(CondicoesComponent.CAIDO, 1.0)
	condicoes.agarrar(1, 10)
	_checar(not condicoes.tem(CondicoesComponent.CAIDO) and not condicoes.tem(CondicoesComponent.AGARRADO),
		"o Gray Ooze é imune a Caído e Agarrado")
	condicoes.free()

## A fase 9 (índice 8) nasce com o Wight no marcador: conta na cota, a missão pede o chefe, a HUD mostra a barra.
func _testar_fase_do_chefe(cena: Main) -> void:
	cena._entrar_fase(Main.CENAS_FASE[FASE_DO_CHEFE])
	await _esperar(5)
	var chefes := cena.get_tree().get_nodes_in_group(Main.GRUPO_MONSTROS).filter(func(m: Node) -> bool: return m is Wight)
	_checar(chefes.size() == 1, "a fase da cripta nasce com um Wight")
	if chefes.is_empty():
		return
	_wight = chefes[0]
	var barra := cena.get_node("Hud").find_child("Chefe", true, false) as Control
	var missao := cena.get_node("Hud").find_child("Missao", true, false) as Label
	_checar(cena._ids_da_cota.has(_wight.get_instance_id()), "o chefe conta na cota da porta")
	_checar("Wight" in missao.text, "a missão pede para derrotar o Wight (%s)" % missao.text)
	_checar(barra.visible, "a HUD mostra a barra de vida do chefe")
	for monstro in cena.get_tree().get_nodes_in_group(Main.GRUPO_MONSTROS):
		if monstro != _wight:
			monstro.queue_free()  # só o chefe conta nesta luta
	await _esperar(3)


## Ao perceber o herói pela primeira vez, os acompanhantes da fase surgem perto dele (fora da cota e da missão).
func _testar_acompanhantes(cena: Main) -> void:
	var antes := cena._ids_da_cota.size()
	_checar(cena.get_tree().get_nodes_in_group(Main.GRUPO_MONSTROS).size() == 1, "antes de perceber o herói, o Wight está sozinho")
	_colocar_heroi_a(DISTANCIA_DE_PERCEBER)
	await _esperar(QUADROS_POR_SEGUNDO)
	var monstros := cena.get_tree().get_nodes_in_group(Main.GRUPO_MONSTROS)
	_checar(monstros.size() == 1 + ACOMPANHANTES, "ao despertar, surgem %d acompanhantes (%d monstros)" % [ACOMPANHANTES, monstros.size()])
	_checar(cena._ids_da_cota.size() == antes, "os acompanhantes não entram na cota da porta")
	for monstro in monstros:
		if monstro != _wight:
			_checar(absf(monstro.global_position.x - _wight.global_position.x) < 200.0, "o acompanhante surge perto do Wight")
			monstro.queue_free()
	await _esperar(3)


## De perto, golpeia com a espada e com o Drenar Vida; quem falha na salvaguarda perde o máximo de PV, e o descanso devolve.
func _testar_corpo_a_corpo() -> void:
	_wight.chance_drenar = 1.0
	_wight.chance_atirar = 0.0
	(_jogador.get_node("Defesa") as DefesaComponent).classe_armadura = 1
	var vida: HealthComponent = _jogador.get_node("Vida")
	var nomes: Dictionary = {}
	var defesa: DefesaComponent = _jogador.get_node("Defesa")
	defesa.golpe_resolvido.connect(func(r: Combate.Resultado, _o: Vector2) -> void: nomes[r.golpe.nome] = true)
	var estados: Dictionary = {}
	for i in QUADROS_POR_SEGUNDO * 30:
		await physics_frame
		_colocar_heroi_a(AO_ALCANCE)
		estados[_wight.nome_estado()] = true
		if vida.maximo_drenado > 0:
			break
	_checar(&"Atacando" in estados and "Drenar Vida" in nomes, "ao alcance, o Wight usa o Drenar Vida")
	_checar(vida.maximo_drenado > 0 and vida.vida_maxima < VIDA_DE_TESTE,
		"quem falha na salvaguarda perde o máximo de PV (drenado: %d)" % vida.maximo_drenado)
	_wight.chance_drenar = 0.0
	nomes.clear()
	for i in QUADROS_POR_SEGUNDO * 20:
		await physics_frame
		_colocar_heroi_a(AO_ALCANCE)
		if "Espada Necrótica" in nomes:
			break
	_checar("Espada Necrótica" in nomes, "e também golpeia com a Espada Necrótica")
	_jogador.descansar_longo()
	_checar(vida.maximo_drenado == 0 and vida.vida_maxima == VIDA_DE_TESTE, "o descanso longo devolve o máximo drenado")


## Com o herói longe e linha de tiro livre, atira flechas.
func _testar_tiro() -> void:
	_wight.chance_atirar = 1.0
	_wight.set("_prefere_atirar", true)
	_colocar_heroi_a(DISTANCIA_DO_TIRO)
	var estados: Dictionary = {}
	var flechas := 0
	for i in QUADROS_POR_SEGUNDO * 12:
		await physics_frame
		_jogador.posicionar_no_inicio(Vector2(_wight.global_position.x - DISTANCIA_DO_TIRO, CHAO_Y))
		estados[_wight.nome_estado()] = true
		flechas = maxi(flechas, _wight.get_children().filter(func(n: Node) -> bool: return n is Flecha).size())
		if flechas >= ACOMPANHANTES:
			break
	_checar(&"Atirando" in estados, "com o herói longe, o Wight atira")
	_checar(flechas >= 1, "uma flecha sai do arco (%d no ar)" % flechas)


func _testar_morte(cena: Main) -> void:
	var morreu := [false]
	var id := _wight.get_instance_id()
	_wight.morreu.connect(func() -> void: morreu[0] = true)
	(_wight.get_node("Vida") as HealthComponent).receber_dano(VIDA_DE_TESTE)
	await _esperar(QUADROS_POR_SEGUNDO * 3)
	var barra := cena.get_node("Hud").find_child("Chefe", true, false) as Control
	_checar(morreu[0], "ao zerar a vida, o Wight morre e emite morreu")
	_checar(not barra.visible and not cena._ids_da_cota.has(id), "ao cair, a barra some e a cota abre")


## O herói fica à esquerda do Wight, na mesma altura.
func _colocar_heroi_a(distancia: float) -> void:
	_jogador.posicionar_no_inicio(Vector2(_wight.global_position.x - distancia, CHAO_Y))


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
