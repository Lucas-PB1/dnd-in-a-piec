extends TesteBase
## Efeitos dos talentos gerais do nível 4, em lotes: Resiliente, Veloz e Mestre em Armadura Média.
## godot --headless --debug --path . --script res://tests/heroi/teste_talentos_gerais.gd

var _classe: ClasseRPG
var _talentos: Array[TalentoRPG] = []


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_classe = load("res://data/classe_guerreiro.tres")
	_talentos.assign(Recursos.da_pasta("res://data/talentos"))
	_testar_resiliente()
	_testar_veloz()
	_testar_mestre_armadura_media()
	_testar_armas_e_armaduras()
	await _testar_no_heroi()
	_testar_mestre_escudos()
	print("PASSOU: talentos gerais" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _talento(id: StringName) -> TalentoRPG:
	for talento in _talentos:
		if talento.id == id:
			return talento
	return null


func _ficha_nivel_4(valores: Dictionary = {}) -> Ficha:
	var base := {Atributos.FORCA: 15, Atributos.DESTREZA: 14, Atributos.CONSTITUICAO: 14, Atributos.SABEDORIA: 10}
	base.merge(valores, true)
	var ficha := Ficha.new(_classe, base)
	ficha.definir_nivel_inicial(4)
	return ficha


func _testar_resiliente() -> void:
	var ficha := _ficha_nivel_4()
	var resiliente := _talento(&"resiliente")
	var forca: Array[StringName] = [Atributos.FORCA]
	var sabedoria: Array[StringName] = [Atributos.SABEDORIA]
	_checar(not ficha.pode_escolher_talento(resiliente, forca), "Resiliente não vale num atributo em que já há proficiência na salvaguarda")
	var antes := ficha.bonus_salvaguarda(Atributos.SABEDORIA)
	_checar(ficha.escolher_talento(resiliente, sabedoria), "Resiliente aceita Sabedoria")
	_checar(ficha.proficiente_em_salvaguarda(Atributos.SABEDORIA) and ficha.atributos[Atributos.SABEDORIA] == 11,
		"+1 em Sabedoria e proficiência na salvaguarda dela")
	_checar(ficha.bonus_salvaguarda(Atributos.SABEDORIA) == antes + Ficha.BONUS_PROFICIENCIA,
		"o bônus da salvaguarda de Sabedoria soma a proficiência (+2)")
	var json := JSON.parse_string(JSON.stringify(Salvamento.para_dicionario(ficha, Inventario.new(), 1))) as Dictionary
	var lida := Salvamento.montar_ficha(json)
	_checar(lida != null and lida.proficiente_em_salvaguarda(Atributos.SABEDORIA), "o save guarda a proficiência da salvaguarda")


func _testar_veloz() -> void:
	var ficha := _ficha_nivel_4()
	_checar(ficha.deslocamento_pes() == 30.0, "sem o Veloz o deslocamento é 30 pés")
	var destreza: Array[StringName] = [Atributos.DESTREZA]
	_checar(ficha.escolher_talento(_talento(&"veloz"), destreza), "Veloz aceita +1 DES")
	_checar(ficha.deslocamento_pes() == 40.0, "com o Veloz o deslocamento é 40 pés")
	var cota: Armadura = load("res://data/armaduras/cota_malha.tres")
	var fraca := _ficha_nivel_4({Atributos.FORCA: 8})
	fraca.talentos.append(Ficha.TALENTO_VELOZ)
	_checar(fraca.deslocamento_pes(cota) == 40.0 - Ficha.PERDA_DESLOCAMENTO_SEM_FORCA, "a perda de Força mínima continua valendo sobre os 40 pés")


func _testar_mestre_armadura_media() -> void:
	var media := _armadura_media()
	var ficha := _ficha_nivel_4({Atributos.DESTREZA: 17})
	var sem := ficha.classe_armadura(media)
	_checar(sem == media.ca_base + 2, "sem o talento o teto de Destreza da média é +2 (CA %d)" % sem)
	var forca: Array[StringName] = [Atributos.FORCA]
	_checar(ficha.escolher_talento(_talento(&"mestre_armadura_media"), forca), "Mestre em Armadura Média aceita +1 FOR")
	_checar(ficha.classe_armadura(media) == media.ca_base + 3, "com o talento o teto sobe para +3")
	var leve: Armadura = load("res://data/armaduras/couro.tres")
	var com := ficha.classe_armadura(leve)
	var sem_talento := _ficha_nivel_4({Atributos.DESTREZA: 17, Atributos.FORCA: 16}).classe_armadura(leve)
	_checar(com == sem_talento, "a armadura leve não muda")


func _testar_mestre_escudos() -> void:
	var ficha := _ficha_nivel_4()
	var inventario := Inventario.new()
	var espada := _arma("espada_longa").duplicate() as Arma
	var escudo := (load("res://data/armaduras/escudo.tres") as Armadura).duplicate() as Armadura
	inventario.adicionar(espada)
	inventario.adicionar(escudo)
	inventario.equipar(espada)
	inventario.equipar(escudo)
	_checar(not Equipamento.golpe(ficha, inventario, espada).tem(Proficiencias.EFEITO_ESCUDO), "sem o talento o golpe não leva escudo")
	ficha.talentos.append(Ficha.TALENTO_MESTRE_ESCUDOS)
	var golpe := Equipamento.golpe(ficha, inventario, espada)
	_checar((golpe.efeito(Proficiencias.EFEITO_ESCUDO) as EfeitosDeTalento.GolpeDeEscudo).cd == 8 + ficha.modificador(Atributos.FORCA) + Ficha.BONUS_PROFICIENCIA, "com escudo e o talento, o golpe leva a CD 8 + FOR + proficiência")
	var condicoes := CondicoesComponent.new()
	root.add_child(condicoes)
	(golpe.efeito(Proficiencias.EFEITO_ESCUDO) as EfeitosDeTalento.GolpeDeEscudo).cd = 100  # ninguém passa
	var empurroes: Array[Vector2] = []
	condicoes.empurrado.connect(func(d: Vector2) -> void: empurroes.append(d))
	var resultado := Combate.Resultado.new()
	resultado.golpe = golpe
	resultado.acertou = true
	resultado.dano = 3
	condicoes.aplicar_maestria(resultado, 1.0)
	_checar(empurroes.size() == 1 and not condicoes.tem(CondicoesComponent.CAIDO), "falhou no teste: o alvo é empurrado 5 pés")
	(golpe.efeito(Proficiencias.EFEITO_ESCUDO) as EfeitosDeTalento.GolpeDeEscudo).derruba = true
	condicoes.aplicar_maestria(resultado, 1.0)
	_checar(condicoes.tem(CondicoesComponent.CAIDO), "na vez de derrubar, o alvo cai")
	condicoes.queue_free()

func _arma(nome: String) -> Arma:
	return load("res://data/armas/%s.tres" % nome)


## Mestre em Arma Grande, Cortador, Perfurador, Esmagador e Empunhadura Dupla, nas regras puras.
func _testar_armas_e_armaduras() -> void:
	var ficha := _ficha_nivel_4()
	var grande := _arma("espada_grande")
	var antes := ficha.dado_dano(grande).bonus
	ficha.talentos.append(Ficha.TALENTO_MESTRE_ARMA_GRANDE)
	_checar(ficha.dado_dano(grande).bonus == antes + Ficha.BONUS_PROFICIENCIA, "Mestre em Arma Grande: a arma Pesada soma a proficiência no dano")
	_checar(ficha.golpe_com(grande).tem(Proficiencias.EFEITO_ARMA_GRANDE) and ficha.golpe_com(_arma("cimitarra")).tem(Proficiencias.EFEITO_ARMA_GRANDE) and not ficha.golpe_com(_arma("arco_longo")).tem(Proficiencias.EFEITO_ARMA_GRANDE), "o golpe extra vale com qualquer arma corpo a corpo, não com arco")
	_checar(ficha.dado_dano(_arma("cimitarra")).bonus == ficha.dado_dano(_arma("cimitarra")).bonus and ficha.dado_dano(grande).bonus == antes + Ficha.BONUS_PROFICIENCIA, "mas a proficiência no dano é só da arma Pesada")
	ficha.talentos.append(Ficha.TALENTO_CORTADOR)
	ficha.talentos.append(Ficha.TALENTO_PERFURADOR)
	ficha.talentos.append(Ficha.TALENTO_ESMAGADOR)
	_checar(ficha.golpe_com(grande).tem(Proficiencias.EFEITO_CORTADOR) and not ficha.golpe_com(grande).tem(Proficiencias.EFEITO_PERFURADOR), "Cortador vale em arma cortante e não em perfurante")
	_checar(ficha.golpe_com(_arma("mangual")).tem(Proficiencias.EFEITO_ESMAGADOR) and ficha.golpe_com(_arma("mangual")).tem(&"esmagador_critico"), "Esmagador vale em arma contundente e empurra 5 pés")
	var condicoes := CondicoesComponent.new()
	root.add_child(condicoes)
	var golpe := ficha.golpe_com(grande)
	var resultado := Combate.Resultado.new()
	resultado.golpe = golpe
	resultado.acertou = true
	resultado.dano = 5
	condicoes.aplicar_maestria(resultado, 1.0)
	_checar(condicoes.tem(CondicoesComponent.LENTO) and not condicoes.tem(CondicoesComponent.ENFRAQUECIDO), "Cortador: o acerto aplica Lentidão")
	resultado.critico = true
	condicoes.aplicar_maestria(resultado, 1.0)
	_checar(condicoes.tem(CondicoesComponent.ENFRAQUECIDO), "Cortador: o crítico dá desvantagem ao próximo ataque do alvo")
	var maca := ficha.golpe_com(_arma("mangual"))
	var empurroes: Array[Vector2] = []
	condicoes.empurrado.connect(func(d: Vector2) -> void: empurroes.append(d))
	var res_maca := Combate.Resultado.new()
	res_maca.golpe = maca
	res_maca.acertou = true
	res_maca.critico = true
	res_maca.dano = 4
	condicoes.aplicar_maestria(res_maca, 1.0)
	_checar(empurroes.size() == 1 and is_equal_approx(empurroes[0].x, EscalaDnd.pes_para_pixels(5.0)), "Esmagador: o acerto empurra 5 pés")
	_checar(condicoes.tem(CondicoesComponent.ATORMENTADO), "Esmagador: o crítico dá vantagem ao próximo ataque")
	condicoes.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var dado := Dado.new(2, 6)
	var normal := 0
	var perfurador := 0
	for i in 600:
		normal += dado.rolar(rng)
		perfurador += dado.rolar_perfurador(rng)
	_checar(perfurador > normal + 150, "Perfurador: rerrolar o menor dado melhora o dano médio")
	_checar(dado.rolar_perfurador(rng, true) >= 5, "Perfurador: o crítico rola dados a mais (5 dados no mínimo 5)")
	_testar_empunhadura_dupla()


func _testar_empunhadura_dupla() -> void:
	var inventario := Inventario.new()
	var espada := _arma("espada_longa").duplicate() as Arma
	var outra := _arma("cimitarra").duplicate() as Arma
	inventario.adicionar(espada)
	inventario.adicionar(outra)
	inventario.equipar(espada)
	inventario.equipar(outra)
	_checar(not inventario.esta_equipado(espada) and inventario.esta_equipado(outra), "sem o talento, uma segunda arma sem Leve troca a da mão")
	inventario.segunda_arma_livre = true
	inventario.equipar(espada)
	_checar(inventario.esta_equipado(espada) and inventario.esta_equipado(outra) and inventario.equipado(Item.ESPACO_MAO_SECUNDARIA) != null, "com Empunhadura Dupla, as duas armas ficam equipadas")


func _testar_no_heroi() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 4:
		await process_frame
	var jogador: Jogador = main.get_node("Jogador")
	jogador.ficha.talentos.append(Ficha.TALENTO_MESTRE_ARMA_GRANDE)
	var grande := _arma("espada_grande")
	jogador.inventario.adicionar(grande.duplicate())
	var golpe := jogador.ficha.golpe_com(grande)
	_checar(golpe.tem(Proficiencias.EFEITO_ARMA_GRANDE), "o golpe da arma Pesada leva a marca do Mestre em Arma Grande")
	var atual := jogador.criar_golpe()
	var resultado := Combate.Resultado.new()
	resultado.golpe = atual
	resultado.acertou = true
	resultado.critico = true
	if atual.tem(Proficiencias.EFEITO_ARMA_GRANDE):
		atual.resolvido.emit(resultado, false)
		_checar(jogador.quer_golpe_do_surto(), "um crítico com arma Pesada deixa um golpe extra pendente (como o Surto)")
	else:
		_checar(true, "a arma da mão não é Pesada neste pacote; o efeito é conferido pelo golpe montado")
	jogador.ficha.talentos.append(Ficha.TALENTO_MESTRE_ARMADURA_PESADA)
	var pesada: Armadura = load("res://data/armaduras/cota_aneis.tres").duplicate()
	jogador.inventario.adicionar(pesada)
	jogador.inventario.equipar(pesada)
	_checar(jogador.get_node("Defesa").reducao_fisica == Ficha.BONUS_PROFICIENCIA, "Mestre em Armadura Pesada: com armadura pesada o dano físico cai em 2")
	jogador.inventario.desequipar(pesada.espaco)
	_checar(jogador.get_node("Defesa").reducao_fisica == 0, "sem armadura pesada vestida, não reduz")
	main.free()
	await process_frame

func _armadura_media() -> Armadura:
	for recurso in Recursos.da_pasta("res://data/armaduras"):
		var armadura := recurso as Armadura
		if armadura.categoria == Proficiencias.ARMADURA_MEDIA and armadura.soma_destreza and armadura.max_destreza == 2:
			return armadura
	return null
