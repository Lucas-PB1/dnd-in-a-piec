extends TesteBase
## Talentos do lote 3 (parte 2): Sentinela, Duelista Defensivo, Investida, Mestre em Armas de Haste, Atleta.
## godot --headless --debug --path . --script res://tests/teste_talentos_lote3.gd

var _classe: ClasseRPG


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_classe = load("res://data/classe_guerreiro.tres")
	await _testar_sentinela()
	_testar_duelista_no_alvo()
	_testar_regras_da_ficha()
	await _testar_no_heroi()
	print("PASSOU: talentos do lote 3" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _ficha() -> Ficha:
	var ficha := Ficha.new(_classe, {Atributos.FORCA: 15, Atributos.DESTREZA: 14, Atributos.CONSTITUICAO: 14})
	ficha.definir_nivel_inicial(4)
	return ficha


func _arma(nome: String) -> Arma:
	return load("res://data/armas/%s.tres" % nome)


func _testar_sentinela() -> void:
	var ficha := _ficha()
	_checar(not ficha.golpe_com(_arma("espada_longa")).sentinela, "sem o talento o golpe não prende")
	ficha.talentos.append(Ficha.TALENTO_SENTINELA)
	var golpe := ficha.golpe_com(_arma("espada_longa"))
	_checar(golpe.sentinela, "com a Sentinela o golpe leva a marca")
	var alvo := Node2D.new()
	var condicoes := CondicoesComponent.new()
	alvo.add_child(condicoes)
	root.add_child(alvo)
	await physics_frame
	var resultado := Combate.Resultado.new()
	resultado.golpe = golpe
	resultado.acertou = true
	resultado.dano = 4
	condicoes.aplicar_maestria(resultado, 1.0)
	_checar(not condicoes.tem(CondicoesComponent.IMOBILIZADO), "um alvo parado não fica preso")
	alvo.position.x += 5.0
	await physics_frame
	_checar(condicoes.esta_se_movendo(), "o componente percebe que o alvo andou")
	condicoes.aplicar_maestria(resultado, 1.0)
	_checar(condicoes.tem(CondicoesComponent.IMOBILIZADO) and condicoes.reducao_deslocamento_pes() >= 30.0, "acertar quem se move o deixa preso, sem deslocamento")
	for i in 80:
		await physics_frame
	_checar(not condicoes.tem(CondicoesComponent.IMOBILIZADO), "passado 1 s, o alvo se solta")
	alvo.queue_free()
	await process_frame


func _testar_duelista_no_alvo() -> void:
	_checar(Golpe.new("x", 0, Dado.new(1, 4)).corpo_a_corpo, "um golpe é corpo a corpo por padrão")
	var defesa := DefesaComponent.new()
	var hurtbox := HurtboxComponent.new()
	defesa.hurtbox = hurtbox
	root.add_child(hurtbox)
	root.add_child(defesa)
	defesa.classe_armadura = 15
	defesa.bonus_ca_corpo_a_corpo = 2
	defesa.rng.seed = 4
	var aparados: Array[bool] = []
	defesa.aparou.connect(func(_o: Vector2) -> void: aparados.append(true))
	for i in 400:
		hurtbox.golpe_recebido.emit(Golpe.new("x", 3, Dado.new(1, 4)), Vector2.ZERO)
	_checar(not aparados.is_empty(), "na janela de defesa, um golpe que passaria por pouco é aparado")
	defesa.bonus_ca_corpo_a_corpo = 0
	aparados.clear()
	for i in 100:
		hurtbox.golpe_recebido.emit(Golpe.new("y", 5, Dado.new(1, 4)), Vector2.ZERO)
	_checar(aparados.is_empty(), "sem a janela de defesa nada é aparado")
	defesa.bonus_ca_corpo_a_corpo = 2
	for i in 400:
		var golpe_a_distancia := Golpe.new("z", 5, Dado.new(1, 4))
		golpe_a_distancia.corpo_a_corpo = false
		hurtbox.golpe_recebido.emit(golpe_a_distancia, Vector2.ZERO)
	_checar(aparados.is_empty(), "um golpe de longe (flecha, adaga) não é aparado")
	defesa.queue_free()
	hurtbox.queue_free()


func _testar_regras_da_ficha() -> void:
	var ficha := _ficha()
	_checar(ficha.deslocamento_pes() == 30.0, "sem o Atleta o deslocamento é 30 pés")
	ficha.talentos.append(Ficha.TALENTO_ATLETA)
	_checar(ficha.deslocamento_pes() == 35.0, "o Atleta dá +5 pés")
	_checar(ficha.e_arma_de_haste(_arma("glaive")) and ficha.e_arma_de_haste(_arma("bordao")) and ficha.e_arma_de_haste(_arma("lanca")),
		"Glaive, Bordão e Lança servem ao Golpe com a Haste")
	_checar(not ficha.e_arma_de_haste(_arma("espada_longa")) and not ficha.e_arma_de_haste(_arma("arco_longo")), "espada e arco não servem")


func _testar_no_heroi() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 4:
		await process_frame
	var jogador: Jogador = main.get_node("Jogador")
	var defesa: DefesaComponent = jogador.get_node("Defesa")
	main.tirar_criaturas()
	# Duelista Defensivo
	_checar(not jogador.defender(), "sem o talento a defesa não abre")
	jogador.ficha.talentos.append(Ficha.TALENTO_DUELISTA_DEFENSIVO)
	_checar(not jogador.defender(), "com a Espada Grande (sem acuidade) a defesa não abre")
	var rapieira := (_arma("rapieira")).duplicate() as Arma
	jogador.inventario.adicionar(rapieira)
	jogador.inventario.equipar(rapieira)
	_checar(jogador.defender() and defesa.bonus_ca_corpo_a_corpo == Ficha.BONUS_PROFICIENCIA and jogador.defesa_ativa(), "com arma de acuidade a defesa abre: +2 de CA no corpo a corpo")
	_checar(not jogador.defender(), "aberta, não abre de novo")
	for i in 50:
		await physics_frame
	_checar(defesa.bonus_ca_corpo_a_corpo == 0 and not jogador.defesa_ativa() and not jogador.defesa_pronta(), "passados 0,75 s a janela fecha e começa a espera")
	for i in 70:
		await physics_frame
	_checar(jogador.defesa_pronta(), "em até 1 s a defesa volta a ficar pronta")
	# Investida
	_checar(not jogador.alternar_investida(), "sem o talento a Investida não alterna")
	jogador.ficha.talentos.append(Ficha.TALENTO_INVESTIDA)
	var parado := jogador.criar_golpe()
	_checar(parado.investida_dano == null and parado.empurrao_pes == 0.0, "parado, o golpe não leva a Investida")
	jogador._corrida_reta_px = 100.0
	var de_dano := jogador.criar_golpe()
	_checar(de_dano.investida_dano != null and de_dano.investida_dano.faces == 8, "depois de correr 10 pés, o golpe soma 1d8")
	_checar(jogador.alternar_investida() and jogador.investida_empurra(), "o botão troca para o empurrão")
	var de_empurrao := jogador.criar_golpe()
	_checar(de_empurrao.empurrao_pes == 10.0 and de_empurrao.investida_dano == null, "no modo empurrão o golpe empurra 10 pés")
	de_empurrao.efeito_usado.emit(Proficiencias.EFEITO_INVESTIDA)
	_checar(jogador.criar_golpe().empurrao_pes == 0.0, "gasta a Investida, a próxima espera a rodada")
	# Mestre em Armas de Haste
	jogador.ficha.talentos.append(Ficha.TALENTO_MESTRE_ARMAS_DE_HASTE)
	var glaive := (_arma("glaive")).duplicate() as Arma
	jogador.inventario.adicionar(glaive)
	jogador.inventario.equipar(glaive)
	jogador.descansar_longo()
	jogador._combo_pedido = true
	_checar(jogador.quer_golpe_extra(), "com o Glaive na mão, o 2º J pede o golpe com a outra ponta")
	var cabo: Arma = jogador._cabo_da_haste()
	var dado := jogador.ficha.dado_dano(cabo)
	_checar(dado.faces == 4 and dado.bonus == jogador.ficha.modificador(Atributos.FORCA), "o golpe com a haste é 1d4 + Força inteira")
	_checar(cabo.tipo_dano == TiposDano.CONTUNDENTE, "e causa dano contundente")
	# Atleta
	var recuo := jogador.tempo_de_recuo()
	var andar := jogador.velocidade_andar()
	jogador.ficha.talentos.append(Ficha.TALENTO_ATLETA)
	_checar(recuo > 0.0 and jogador.tempo_de_recuo() == 0.0, "o Atleta não perde o controle ao levar um golpe")
	_checar(jogador.velocidade_andar() > andar, "e anda um pouco mais rápido")
	main.free()
	await process_frame
