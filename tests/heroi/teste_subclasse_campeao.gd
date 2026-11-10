extends TesteBase
## Subclasse Campeão no nível 3: pendência, escolha, save, crítico 19, iniciativa +prof
## (sem empilhar com Alerta), Atletismo com vantagem e meio deslocamento após crítico.
## godot --headless --debug --path . --script res://tests/heroi/teste_subclasse_campeao.gd

var _classe: ClasseRPG
var _campeao: SubclasseRPG


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_classe = load("res://data/classe_guerreiro.tres")
	_campeao = _subclasse(&"campeao")
	_checar(_campeao != null and _campeao.no_jogo, "Campeão existe em data/subclasses")
	_testar_pendencia_e_escolha()
	_testar_iniciativa_e_critico()
	_testar_atletismo()
	_testar_save()
	await _testar_tela()
	await _testar_movimento_pos_critico()
	await _testar_na_main()
	print("PASSOU: subclasse Campeão" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _subclasse(id: StringName) -> SubclasseRPG:
	for recurso in Recursos.da_pasta(Ficha.PASTA_SUBCLASSES):
		var candidata := recurso as SubclasseRPG
		if candidata != null and candidata.id == id:
			return candidata
	return null


func _ficha_nivel(nivel: int) -> Ficha:
	var ficha := Ficha.new(_classe, {
		Atributos.FORCA: 15,
		Atributos.DESTREZA: 14,
		Atributos.CONSTITUICAO: 14,
	})
	ficha.definir_nivel_inicial(nivel)
	return ficha


func _testar_pendencia_e_escolha() -> void:
	var nv2 := _ficha_nivel(2)
	_checar(not nv2.escolha_de_subclasse_pendente(), "no nível 2 não há subclasse")
	var nv3 := _ficha_nivel(3)
	_checar(nv3.escolha_de_subclasse_pendente(), "no nível 3 a escolha fica pendente")
	_checar(nv3.limiar_critico() == 20, "sem subclasse o crítico é 20")
	_checar(nv3.escolher_subclasse(_campeao), "escolhe Campeão")
	_checar(nv3.tem_subclasse(Ficha.SUBCLASSE_CAMPEAO) and not nv3.escolha_de_subclasse_pendente(),
		"Campeão fica na ficha e a pendência some")
	_checar(not nv3.escolher_subclasse(_campeao), "não escolhe de novo")


func _testar_iniciativa_e_critico() -> void:
	var ficha := _ficha_nivel(3)
	ficha.escolher_subclasse(_campeao)
	# DES 14 → mod +2; prof +2 → iniciativa 4 (igual Alerta).
	_checar(ficha.iniciativa() == 4, "Campeão soma +prof na iniciativa")
	_checar(ficha.limiar_critico() == 19, "Campeão critica no 19")
	ficha.talentos.append(Ficha.TALENTO_ALERTA)
	_checar(ficha.iniciativa() == 4, "Alerta + Campeão não empilham +prof")
	var golpe := Golpe.new("Teste", 0, Dado.new(1, 6, 0))
	golpe.limiar_critico = ficha.limiar_critico()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var viu_crit_19 := false
	for _i in 400:
		var r := Combate.resolver_ataque(golpe, 10, rng)
		if r.d20 == 19 and r.acertou:
			_checar(r.critico, "19 que acerta é crítico no Campeão")
			viu_crit_19 = true
		if r.d20 == 20:
			_checar(r.critico and r.acertou, "20 natural é crítico e acerta")
	_checar(viu_crit_19, "saiu pelo menos um crítico no 19")
	var so_vinte := true
	for _i in 80:
		var r := Combate.resolver_ataque(golpe, 100, rng)
		if r.critico:
			so_vinte = so_vinte and r.d20 == 20
	_checar(so_vinte, "contra CA impossível só o 20 critica (e acerta)")


func _testar_atletismo() -> void:
	var ficha := _ficha_nivel(3)
	ficha.escolher_subclasse(_campeao)
	_checar(ficha.vantagem_na_pericia(Pericia.ATLETISMO), "Campeão tem vantagem em Atletismo")
	_checar(not ficha.vantagem_na_pericia(Pericia.PERCEPCAO), "outras perícias sem vantagem")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var com := Pericia.resolver_teste(5, 30, false, false, rng, true)
	_checar(com.has("vantagem") and com.vantagem, "resolver_teste marca vantagem")


func _testar_save() -> void:
	var caminho_antigo := Salvamento.caminho
	Salvamento.caminho = "user://save_subclasse_teste.json"
	var ficha := _ficha_nivel(3)
	ficha.escolher_subclasse(_campeao)
	var dados := Salvamento.para_dicionario(ficha, Inventario.new(), 1)
	var lida := Salvamento.montar_ficha(JSON.parse_string(JSON.stringify(dados)) as Dictionary)
	_checar(lida != null and lida.tem_subclasse(Ficha.SUBCLASSE_CAMPEAO), "o save guarda a subclasse")
	_checar(lida.limiar_critico() == 19 and lida.iniciativa() == 4, "efeitos voltam do save")
	DirAccess.remove_absolute(Salvamento.caminho)
	Salvamento.caminho = caminho_antigo


func _testar_tela() -> void:
	var ficha := _ficha_nivel(3)
	var tela: TelaSubclasse = load("res://ui/subclasse/tela_subclasse.tscn").instantiate()
	root.add_child(tela)
	await process_frame
	var opcoes: Array[SubclasseRPG] = [_campeao]
	tela.abrir(ficha, opcoes)
	var lista: ItemList = tela.get_node("%Lista")
	_checar(lista.item_count == 1 and lista.get_item_text(0) == "Campeão", "a tela lista o Campeão")
	var escolhida: Array[SubclasseRPG] = []
	tela.subclasse_escolhida.connect(func(s: SubclasseRPG) -> void: escolhida.append(s))
	(tela.get_node("%Escolher") as Button).pressed.emit()
	_checar(escolhida.size() == 1 and ficha.tem_subclasse(Ficha.SUBCLASSE_CAMPEAO), "Escolher grava na ficha")
	_checar(not tela.visible and not paused, "fecha e despausa")
	tela.queue_free()
	await process_frame


func _testar_movimento_pos_critico() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 4:
		await process_frame
	var jogador: Jogador = main.get_node("Jogador")
	var tela_sub: TelaSubclasse = main.get_node("Interface/TelaSubclasse")
	if tela_sub.visible:
		tela_sub.fechar()
	jogador.ficha.definir_nivel_inicial(3)
	jogador.ficha.escolher_subclasse(_campeao)
	jogador.ao_mudar_ficha()
	var golpe := Golpe.new("Crit", 100, Dado.new(1, 4, 0))
	golpe.limiar_critico = 19
	var resultado := Combate.Resultado.new()
	resultado.acertou = true
	resultado.critico = true
	resultado.d20 = 19
	resultado.golpe = golpe
	jogador._ao_resolver_golpe_do_atacante(resultado, false)
	var esperado := EscalaDnd.pes_para_pixels(Equipamento.deslocamento_pes(jogador.ficha, jogador.inventario) * 0.5)
	_checar(jogador.orcamento_atleta_ativo() and is_equal_approx(jogador.orcamento_atleta_px(), esperado),
		"crítico libera meio deslocamento em pixels")
	jogador._consumir_orcamento_atleta(esperado)
	_checar(not jogador.orcamento_atleta_ativo(), "andar o orçamento zera")
	main.free()
	await process_frame


func _testar_na_main() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 4:
		await process_frame
	var jogador: Jogador = main.get_node("Jogador")
	var tela: TelaSubclasse = main.get_node("Interface/TelaSubclasse")
	var pausa: TelaPausa = main.get_node("Interface/TelaPausa")
	main.tirar_criaturas()
	jogador.ganhar_experiencia(Ficha.XP_POR_NIVEL[3])
	for i in 3:
		await process_frame
	_checar(jogador.ficha.nivel == 3 and tela.visible and paused, "subir ao nível 3 abre a subclasse")
	tela.fechar()
	pausa.abrir()
	_checar((pausa.get_node("%Subclasse") as Button).visible, "pausa mostra Escolher subclasse")
	pausa.fechar()
	_checar(jogador.ficha.escolher_subclasse(_campeao), "escolhe Campeão na ficha")
	jogador.ao_mudar_ficha()
	pausa.abrir()
	_checar(not (pausa.get_node("%Subclasse") as Button).visible, "sem pendência o botão some")
	pausa.fechar()
	main.free()
	await process_frame
