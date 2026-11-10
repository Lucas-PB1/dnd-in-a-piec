extends TesteBase
## Progressão, Mente Tática, descanso longo e Surto de Ação.
## godot --headless --debug --path . --script res://tests/teste_progressao.gd

const QUADROS_INICIAIS := 3
const ESPERA_SURTO_SEGUNDOS := 1.2

var _main: Main
var _jogador: Jogador


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_ficha()
	_main = load("res://levels/main.tscn").instantiate()
	_main.mostrar_inicio = false
	_main.semente_armadilhas = 17
	root.add_child(_main)
	_jogador = _main.get_node("Jogador")
	await _esperar(QUADROS_INICIAIS)
	_testar_dificuldade()
	_testar_mente_tatica()
	await _testar_surto_e_descanso()
	_main.queue_free()
	if _falhas == 0:
		print("PASSOU: progressão, Mente Tática e Surto de Ação")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_ficha() -> void:
	var classe := load("res://data/classe_guerreiro.tres") as ClasseRPG
	var ficha := Ficha.new(classe, {Atributos.CONSTITUICAO: 14})
	_checar(ficha.nivel == 1 and ficha.experiencia == 0 and ficha.vida_maxima() == 12,
		"nível 1 começa com 0 XP e PV iniciais máximos")
	_checar(ficha.adicionar_experiencia(299) == 0 and ficha.nivel == 1, "299 XP ainda não sobe de nível")
	_checar(ficha.adicionar_experiencia(1) == 1 and ficha.nivel == 2 and ficha.vida_maxima() == 20,
		"300 XP sobe ao nível 2 e acrescenta 6 + CON aos PV")
	_checar(ficha.xp_proximo_nivel() == 900, "nível 2 mostra o marco de 900 XP")
	_checar(ficha.adicionar_experiencia(600) == 1 and ficha.nivel == 3 and ficha.vida_maxima() == 28,
		"900 XP sobe ao nível 3 e acrescenta PV")
	_checar(ficha.adicionar_experiencia(1000) == 0 and ficha.nivel == 3,
		"1900 XP ainda é nível 3")
	_checar(ficha.adicionar_experiencia(800) == 1 and ficha.nivel == 4 and ficha.vida_maxima() == 36,
		"2700 XP sobe ao nível 4 e acrescenta PV")
	_checar(ficha.bonus_proficiencia() == Ficha.BONUS_PROFICIENCIA and ficha.golpes_por_ataque() == 1,
		"no nível 4 a proficiência é +2 e o ataque é um golpe só")
	_checar(ficha.adicionar_experiencia(Ficha.XP_POR_NIVEL[5] - ficha.experiencia) == 1 and ficha.nivel == 5 and ficha.vida_maxima() == 44,
		"o nível 5 acrescenta PV")
	_checar(ficha.bonus_proficiencia() == 3 and ficha.golpes_por_ataque() == 2,
		"no nível 5 a proficiência vai a +3 e o Ataque Extra dobra o ataque")
	_checar(ficha.adicionar_experiencia(Ficha.XP_POR_NIVEL[6] - ficha.experiencia) == 1 and ficha.nivel == Ficha.NIVEL_MAXIMO and ficha.vida_maxima() == 52,
		"o nível 6 acrescenta PV")
	_checar(ficha.adicionar_experiencia(100000) == 0 and ficha.nivel == 6,
		"nível não passa do limite 6")
	var ficha_inicial := Ficha.new(classe, {})
	ficha_inicial.definir_nivel_inicial(3)
	_checar(ficha_inicial.nivel == 3 and ficha_inicial.experiencia == 900,
		"criação de nível 3 começa no marco de 900 XP")


func _testar_dificuldade() -> void:
	_checar(_main.quantidade_inimigos_da_fase(1) == 1
		and _main.quantidade_inimigos_da_fase(2) == 2
		and _main.quantidade_inimigos_da_fase(3) == 3,
		"a cota da fase 1 aumenta com o nível até a capacidade de pontos")


func _testar_mente_tatica() -> void:
	_jogador.ficha.pericias = [Pericia.ATLETISMO]
	var vida := _jogador.get_node("Vida") as HealthComponent
	vida.receber_dano(2)
	var pv_antes := _jogador.vida_atual()
	var maximo_antes := _jogador.vida_maxima()
	var ganho_por_nivel := 6 + _jogador.ficha.modificador(Atributos.CONSTITUICAO)
	_checar(_jogador.ganhar_experiencia(Ficha.XP_POR_NIVEL[2]) == 1
		and _jogador.ficha.nivel == 2, "ganhar 300 XP aumenta o nível durante a campanha")
	_checar(_jogador.vida_maxima() == maximo_antes + ganho_por_nivel
		and _jogador.vida_atual() == pv_antes + ganho_por_nivel,
		"ao subir de nível, os PV máximos e atuais sobem juntos")
	_main._alternar_mente_tatica()
	_checar(_jogador.mente_tatica_ligada(), "no nível 2 a Mente Tática liga pela ação (tecla T ou botão)")
	_main._alternar_mente_tatica()
	_checar(not _jogador.mente_tatica_ligada(), "e desliga pela mesma ação")
	_jogador.definir_mente_tatica(true)
	var bonus := _jogador.ficha.bonus_pericia(Pericia.ATLETISMO)
	var semente_sucesso := _semente_para_teste(bonus, 20, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente_sucesso
	var usos_antes := _jogador.usos_folego()
	var resultado := _jogador.rolar_teste_pericia(Pericia.ATLETISMO, 20, rng)
	_checar(resultado.passou and resultado.usou_mente_tatica and resultado.d10 > 0,
		"Mente Tática tenta o d10 quando o teste falha e transforma a falha em sucesso")
	_checar(_jogador.usos_folego() == usos_antes - 1,
		"só gasta Second Wind quando o d10 garante o sucesso")

	_jogador.definir_mente_tatica(false)
	var semente_falha := _semente_para_teste(bonus, 20, false)
	rng.seed = semente_falha
	usos_antes = _jogador.usos_folego()
	resultado = _jogador.rolar_teste_pericia(Pericia.ATLETISMO, 20, rng)
	_checar(not resultado.passou and resultado.d10 == 0 and _jogador.usos_folego() == usos_antes,
		"toggle desligado não rola nem gasta o dado")

	_jogador.definir_mente_tatica(true)
	rng.seed = _semente_para_teste(bonus, 40, false)
	resultado = _jogador.rolar_teste_pericia(Pericia.ATLETISMO, 40, rng)
	_checar(not resultado.passou and resultado.d10 > 0 and _jogador.usos_folego() == usos_antes,
		"uma tentativa que ainda falha não gasta Second Wind")


func _testar_surto_e_descanso() -> void:
	_main.tirar_criaturas()  # o novo Surto não depende de inimigo: funciona com a arena vazia
	_jogador.get_node("Vida").receber_dano(1)
	Input.action_press(&"surto_acao")
	await _esperar(2)
	Input.action_release(&"surto_acao")
	_checar(_main._surto_usado, "a ação de input ativa o Surto")
	_checar(_jogador.surto_ativo(), "o Surto acende a aura do herói mesmo sem inimigo")
	_main._usar_surto_acao()
	_checar(not _jogador.armar_surto(), "o Surto não pode ser usado de novo enquanto está ativo")
	_main._entrar_fase(load("res://levels/fase_2.tscn"))
	await physics_frame
	_checar(not _main._surto_usado and not _jogador.surto_ativo() and _jogador.usos_folego() == _jogador.usos_folego_total(),
		"a fase seguinte funciona como descanso longo e recupera recursos")
	_checar(_jogador.vida_atual() == _jogador.vida_maxima(), "o descanso longo recupera PV")
	_checar(_main._tipos_da_fase(3).has(Main.TIPO_WARRIOR),
		"nível 3 libera o Guerreiro nas fases anteriores")
	_checar(_main.quantidade_inimigos_da_fase(3) == 4,
		"a fase 2 sorteia mais inimigos para um herói de nível 3")


func _semente_para_teste(bonus: int, cd: int, sucesso_com_d10: bool) -> int:
	for semente in range(1, 10000):
		var rng := RandomNumberGenerator.new()
		rng.seed = semente
		var total := rng.randi_range(1, 20) + bonus
		if total >= cd:
			continue
		var total_com_d10 := total + rng.randi_range(1, 10)
		if (total_com_d10 >= cd) == sucesso_com_d10:
			return semente
	return 1


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
