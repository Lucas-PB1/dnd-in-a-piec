extends TesteBase
## Fatia 11c: maestrias de arma. Vantagem/desvantagem, Raspão, CD, condições (Derrubar com
## salvaguarda, Empurrar, Enfraquecer, Lentidão, Atormentar), um alvo por golpe + Trespassar,
## Gray Ooze Caído e Corte Duplo no golpe extra.
## godot --headless --debug --path . --script res://tests/teste_maestrias.gd

const ROLAGENS := 2000

var _rng := RandomNumberGenerator.new()
var _guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")


func _initialize() -> void:
	_rng.seed = 11
	_testar_vantagem()
	_testar_ficha_e_raspao()
	_testar_condicoes()
	await _testar_alvos_e_trespassar()
	await _testar_ooze_caido()
	await _testar_corte_duplo()
	if _falhas == 0:
		print("PASSOU: todos os testes das maestrias")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _arma(id: String) -> Arma:
	return load("res://data/armas/%s.tres" % id)


func _ficha(dominadas: Array[String]) -> Ficha:
	var ficha := Ficha.new(_guerreiro, _guerreiro.atributos_sugeridos)  # FOR 15, DES 14
	ficha.armas_dominadas = dominadas
	return ficha


func _testar_vantagem() -> void:
	var soma := {"normal": 0, "vantagem": 0, "desvantagem": 0, "as_duas": 0}
	for i in ROLAGENS:
		soma["normal"] += Combate.rolar_d20(_rng)
		soma["vantagem"] += Combate.rolar_d20(_rng, false, true)
		soma["desvantagem"] += Combate.rolar_d20(_rng, true, false)
		soma["as_duas"] += Combate.rolar_d20(_rng, true, true)
	var media := func(chave: String) -> float: return float(soma[chave]) / ROLAGENS
	_checar(media.call("vantagem") > 13.0 and media.call("desvantagem") < 8.0,
		"vantagem fica com o maior d20 (média %.1f), desvantagem com o menor (%.1f)" % [media.call("vantagem"), media.call("desvantagem")])
	_checar(absf(media.call("as_duas") - media.call("normal")) < 0.8, "vantagem e desvantagem juntas se anulam")


func _testar_ficha_e_raspao() -> void:
	var grande := _arma("espada_grande")
	var sem := _ficha([])
	var com := _ficha(["Espada Grande", "Machado Grande"])
	_checar(not sem.domina(grande) and com.domina(grande) and com.maestria_de(grande) == Proficiencias.RASPAO,
		"só domina as armas escolhidas")
	_checar(com.cd_maestria(grande) == 12, "CD da maestria = 8 + FOR (+2) + proficiência (+2) = 12")
	var golpe := com.golpe_com(grande)
	_checar(golpe.maestria == Proficiencias.RASPAO and golpe.dano_raspao == 2 and sem.golpe_com(grande).maestria == &"",
		"golpe leva a maestria (Raspão: dano no erro = mod. +2) só se domina")
	golpe.bonus_ataque = -100  # erra sempre (menos o 20 natural)
	var raspoes := 0
	var resistiu_certo := true
	for i in 200:
		var r := Combate.resolver_ataque(golpe, 30, _rng)
		if not r.acertou and r.raspao and r.dano == 2:
			raspoes += 1
		var r2 := Combate.resolver_ataque(golpe, 30, _rng, [TiposDano.CORTANTE])
		resistiu_certo = resistiu_certo and (r2.acertou or r2.dano == 1)
	_checar(raspoes > 150 and resistiu_certo, "Raspão: errou e causou 2 de dano; com resistência, 1 (%d)" % raspoes)
	var machado := com.golpe_com(_arma("machado_grande"))
	_checar(machado.trespassar != null and machado.trespassar.trespassar == null
		and machado.trespassar.dano.bonus == 0 and machado.dano.bonus == 2,
		"Trespassar: 2º ataque com o mesmo bônus, dano sem o mod. positivo")


func _testar_condicoes() -> void:
	var condicoes := CondicoesComponent.new()
	root.add_child(condicoes)
	var avisos: Array[String] = []
	condicoes.aviso.connect(func(t: String) -> void: avisos.append(t))
	var empurroes: Array[Vector2] = []
	condicoes.empurrado.connect(func(d: Vector2) -> void: empurroes.append(d))

	condicoes.bonus_salvaguardas = {Atributos.CONSTITUICAO: 100}
	condicoes.aplicar_maestria(_acerto(Proficiencias.DERRUBAR, 5), 1.0)
	_checar(not condicoes.esta_caido() and avisos.back().begins_with("Salvou"), "Derrubar: passou na salvaguarda de CON, não cai")
	condicoes.bonus_salvaguardas = {Atributos.CONSTITUICAO: -100}
	condicoes.aplicar_maestria(_acerto(Proficiencias.DERRUBAR, 5), 1.0)
	_checar(condicoes.esta_caido() and avisos.back() == "Caído!", "Derrubar: falhou na salvaguarda, fica Caído")
	var contra := Golpe.new("Teste", 0, Dado.new(1, 4))
	condicoes.preparar_golpe_recebido(contra)
	_checar(contra.vantagem, "ataque contra criatura Caída tem vantagem")
	condicoes._physics_process(CondicoesComponent.DURACAO_CAIDO + 0.01)
	_checar(not condicoes.esta_caido(), "levanta depois de meia rodada")

	condicoes.aplicar_maestria(_acerto(Proficiencias.ENFRAQUECER, 5), 1.0)
	_checar(condicoes.consumir_desvantagem() and not condicoes.consumir_desvantagem(),
		"Enfraquecer: só o próximo ataque do alvo tem desvantagem")
	condicoes.aplicar_maestria(_acerto(Proficiencias.LENTIDAO, 0), 1.0)
	_checar(condicoes.reducao_deslocamento_pes() == 0.0, "Lentidão sem dano não vale")
	condicoes.aplicar_maestria(_acerto(Proficiencias.LENTIDAO, 3), 1.0)
	condicoes.aplicar_maestria(_acerto(Proficiencias.LENTIDAO, 3), 1.0)
	_checar(condicoes.reducao_deslocamento_pes() == 10.0, "Lentidão: -10 pés, sem acumular")
	condicoes.aplicar_maestria(_acerto(Proficiencias.EMPURRAR, 3), -1.0)
	_checar(empurroes.size() == 1 and empurroes[0].x == -EscalaDnd.pes_para_pixels(10.0), "Empurrar: 10 pés para longe de quem bateu")

	var marca := _acerto(Proficiencias.ATORMENTAR, 3)
	marca.golpe.autor_id = 42
	condicoes.aplicar_maestria(marca, 1.0)
	var de_outro := Golpe.new("Outro", 0, Dado.new(1, 4))
	de_outro.autor_id = 7
	condicoes.preparar_golpe_recebido(de_outro)
	var do_autor := Golpe.new("Autor", 0, Dado.new(1, 4))
	do_autor.autor_id = 42
	condicoes.preparar_golpe_recebido(do_autor)
	var de_novo := Golpe.new("Autor de novo", 0, Dado.new(1, 4))
	de_novo.autor_id = 42
	condicoes.preparar_golpe_recebido(de_novo)
	_checar(not de_outro.vantagem and do_autor.vantagem and not de_novo.vantagem,
		"Atormentar: vantagem só para quem marcou, e só no próximo ataque")
	var errou := _acerto(Proficiencias.ENFRAQUECER, 0)
	errou.acertou = false
	condicoes.aplicar_maestria(errou, 1.0)
	_checar(not condicoes.tem(CondicoesComponent.ENFRAQUECIDO), "maestria não vale quando o ataque erra")
	condicoes.free()


func _acerto(maestria: StringName, dano: int) -> Combate.Resultado:
	var golpe := Golpe.new("Teste", 0, Dado.new(1, 4))
	golpe.maestria = maestria
	golpe.cd_maestria = 12
	var r := Combate.Resultado.new()
	r.golpe = golpe
	r.acertou = true
	r.dano = dano
	return r


## Dois bonecos encostados: sem Trespassar, só o 1º apanha; com Trespassar, o 2º também
## (quando o 1º foi acertado).
func _testar_alvos_e_trespassar() -> void:
	var cena: Node = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	for monstro in get_nodes_in_group(&"monstros"):
		monstro.free()
	var jogador: Jogador = cena.get_node("Jogador")
	var primeiro: BonecoTreino = cena.get_node("BonecoTreino")
	var segundo: BonecoTreino = load("res://features/boneco_treino/boneco_treino.tscn").instantiate()
	segundo.position = primeiro.position + Vector2(20, 0)
	cena.add_child(segundo)
	for boneco in [primeiro, segundo]:
		var defesa: DefesaComponent = boneco.get_node("Defesa")
		defesa.classe_armadura = -100  # só erra no 1 natural; a semente fixa evita o 1
		defesa.rng.seed = 5
	await _esperar(10)
	jogador.ficha.armas_dominadas = ["Machado Grande"]
	await _bater_com(jogador, "espada_longa", primeiro)
	_checar(primeiro.golpes_recebidos == 1 and segundo.golpes_recebidos == 0, "um golpe acerta UM alvo (o mais perto)")
	await _bater_com(jogador, "machado_grande", primeiro)
	_checar(primeiro.golpes_recebidos == 2 and segundo.golpes_recebidos == 1,
		"Trespassar: o 2º boneco, encostado no 1º, leva o 2º ataque")
	cena.queue_free()
	await _esperar(2)


func _bater_com(jogador: Jogador, id: String, alvo: Node2D) -> void:
	jogador.inventario.limpar()
	var arma := _arma(id).duplicate() as Arma
	jogador.inventario.adicionar(arma)
	jogador.inventario.equipar(arma)
	jogador.posicionar_no_inicio(Vector2(alvo.global_position.x - 34, jogador.global_position.y))
	jogador.direcao_olhar = 1
	await _esperar(40)
	jogador.iniciar_golpe()
	await _esperar(45)


## Gray Ooze derrubado: estado Caido, não anda, levanta e volta a perseguir.
func _testar_ooze_caido() -> void:
	var ooze: GrayOoze = load("res://features/gray_ooze/gray_ooze.tscn").instantiate()
	root.add_child(ooze)
	await _esperar(3)
	var sprite: Node2D = ooze.get_node("Sprite")
	var escala_normal := sprite.scale  # a da cena
	var condicoes: CondicoesComponent = ooze.get_node("Condicoes")
	_checar(condicoes.bonus_salvaguardas.get(Atributos.CONSTITUICAO) == 3, "o Ooze usa a CON da ficha (+3) na salvaguarda")
	condicoes.bonus_salvaguardas[Atributos.CONSTITUICAO] = -100
	var r := _acerto(Proficiencias.DERRUBAR, 3)
	r.golpe.bonus_ataque = 100  # só erraria no 1 natural; a semente fixa evita o 1
	(ooze.get_node("Defesa") as DefesaComponent).rng.seed = 5
	(ooze.get_node("Hurtbox") as HurtboxComponent).golpe_recebido.emit(r.golpe, ooze.global_position + Vector2.LEFT * 10)
	await _esperar(2)
	_checar(not ooze.esta_caido(), "o Ooze é imune a Caído (livro): a maestria Derrubar não o derruba")
	condicoes.imunidades = []  # sem a imunidade, testa o estado e o visual do Caído
	await _esperar(60)  # passa a invencibilidade do golpe anterior
	(ooze.get_node("Hurtbox") as HurtboxComponent).golpe_recebido.emit(r.golpe, ooze.global_position + Vector2.LEFT * 10)
	await _esperar(2)
	_checar(ooze.esta_caido() and ooze.nome_estado() == &"Caido", "Ooze falhou na salvaguarda: estado Caído")
	_checar(sprite.scale.x > escala_normal.x and sprite.scale.y < escala_normal.y, "Caído: achatado em relação ao tamanho normal")
	await _esperar(int(CondicoesComponent.DURACAO_CAIDO * 60) + 5)
	_checar(not ooze.esta_caido() and ooze.nome_estado() != &"Caido", "Ooze levanta depois de meia rodada")
	_checar(sprite.scale == escala_normal, "ao levantar, volta ao tamanho de antes (não fica pequeno)")
	ooze.queue_free()
	await _esperar(2)


## Sem Corte Duplo, o golpe extra gasta a ação bônus (1 por rodada); com ele, não gasta.
func _testar_corte_duplo() -> void:
	var cena: Node = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	for monstro in get_nodes_in_group(&"monstros"):
		monstro.free()
	var jogador: Jogador = cena.get_node("Jogador")
	await _esperar(10)
	jogador.inventario.limpar()
	for id in ["espada_curta", "cimitarra"]:
		var arma := _arma(id).duplicate() as Arma
		jogador.inventario.adicionar(arma)
		jogador.inventario.equipar(arma)
	jogador.ficha.armas_dominadas = []
	jogador.iniciar_golpe_extra()
	_checar(not jogador.acao_bonus_livre(), "sem Corte Duplo: o golpe extra gasta a ação bônus da rodada")
	await _esperar(int(EscalaDnd.RODADA_SEGUNDOS * 60) + 2)
	_checar(jogador.acao_bonus_livre(), "a ação bônus volta depois de 1 rodada")
	jogador.ficha.armas_dominadas = ["Cimitarra"]
	jogador.iniciar_golpe_extra()
	_checar(jogador.acao_bonus_livre(), "com Corte Duplo (Cimitarra): o extra não gasta a ação bônus")
	cena.queue_free()
	await _esperar(2)


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
