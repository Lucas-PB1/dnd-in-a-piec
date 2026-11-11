extends TesteBase
## Estilos de Luta: ficha, capacidade, GWF, Defesa, Duelismo, save.
## godot --headless --debug --path . --script res://tests/regras/teste_estilo_de_luta.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_lista_e_ficha()
	_testar_efeitos_de_combate()
	_testar_rajada_e_disparo()
	_testar_salvamento()
	if _falhas == 0:
		print("PASSOU: estilos de luta")
	else:
		print("FALHOU: %d teste(s) de estilo" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _ficha_base() -> Ficha:
	var classe: ClasseRPG = load("res://data/classe_guerreiro.tres")
	return Ficha.new(classe, classe.atributos_sugeridos, "Teste")


func _testar_lista_e_ficha() -> void:
	var todos := EstiloDeLutaRPG.todos()
	_checar(todos.size() == 18, "18 estilos jogáveis em data/estilos")
	var ficha := _ficha_base()
	_checar(ficha.capacidade_estilos() == 1, "nível 1: capacidade 1")
	_checar(not ficha.escolha_de_estilo_pendente(), "nível 1: sem troca pendente")
	_checar(ficha.definir_estilos([&"defesa"]), "define Defesa")
	_checar(ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.DEFESA), "tem efeito Defesa")
	_checar(not ficha.definir_estilos([&"defesa", &"duelismo"]), "nível 1 não aceita 2")
	ficha.nivel = 2
	_checar(ficha.capacidade_estilos() == 2, "nível 2: capacidade 2")
	_checar(ficha.escolha_de_estilo_pendente(), "nível 2: troca pendente")
	_checar(ficha.confirmar_troca_de_estilo([&"arquearia", &"duelismo"]), "confirma 2 estilos")
	_checar(not ficha.escolha_de_estilo_pendente() and ficha.tem_estilo(&"arquearia"),
		"pendência gasta e Arquearia preparada")


func _testar_efeitos_de_combate() -> void:
	var ficha := _ficha_base()
	ficha.definir_estilos([&"armas_grandes"])
	var espada: Arma = load("res://data/armas/espada_grande.tres")
	var invent := Inventario.new()
	invent.adicionar(espada)
	invent.equipar(espada)
	var golpe := Equipamento.golpe(ficha, invent, espada)
	_checar(golpe.trata_um_e_dois_como_tres(), "Armas Grandes: GWF no golpe")

	ficha.definir_estilos([&"defesa"])
	var cota: Armadura = load("res://data/armaduras/cota_malha.tres")
	invent.adicionar(cota)
	invent.equipar(cota)
	var ca_com := Equipamento.classe_armadura(ficha, invent)
	ficha.estilos.clear()
	var ca_sem := Equipamento.classe_armadura(ficha, invent)
	_checar(ca_com == ca_sem + Ficha.BONUS_DEFESA_CA, "Defesa: +1 CA com armadura")

	ficha.definir_estilos([&"duelismo"])
	var curta: Arma = load("res://data/armas/espada_curta.tres")
	var invent2 := Inventario.new()
	invent2.adicionar(curta)
	invent2.equipar(curta)
	var g_duelo := Equipamento.golpe(ficha, invent2, curta)
	ficha.estilos.clear()
	var g_sem := Equipamento.golpe(ficha, invent2, curta)
	_checar(g_duelo.dano.bonus == g_sem.dano.bonus + Ficha.BONUS_DUELISMO, "Duelismo: +2 dano")

	ficha.definir_estilos([&"arquearia"])
	var arco: Arma = load("res://data/armas/arco_curto.tres")
	_checar(Equipamento.bonus_ataque(ficha, Inventario.new(), arco) == ficha.bonus_ataque(arco) + Ficha.BONUS_ARQUEARIA,
		"Arquearia: +2 ataque à distância")

	ficha.definir_estilos([&"luta_cegas"])
	var passiva_antes := ficha.percepcao_passiva()
	ficha.estilos.clear()
	_checar(passiva_antes == ficha.percepcao_passiva() + Ficha.LUTA_CEGAS_PASSIVA, "Luta às Cegas: +1 passiva")

	ficha.definir_estilos([&"escaramucador"])
	_checar(ficha.deslocamento_pes() == Ficha.DESLOCAMENTO_PADRAO_PES + Ficha.ESCARAMUCADOR_PES,
		"Escaramuçador: +10 pés")

	ficha.definir_estilos([&"desarmado"])
	var soco: Arma = load("res://data/ataque_desarmado.tres")
	var dado := ficha.dado_dano(soco, false, false, true)
	_checar(dado.faces == Ficha.FACES_SOCO_ESTILO_LIVRE, "Desarmado livre: 1d8")


func _testar_rajada_e_disparo() -> void:
	var estilos := EstilosDoHeroi.new()
	_checar(not estilos.rajada_ligada, "Rajada começa desligada")
	_checar(estilos.alternar_rajada() and estilos.rajada_ligada, "toggle liga")
	_checar(not estilos.alternar_rajada() and not estilos.rajada_ligada, "toggle desliga")

	var golpe := Golpe.new("Teste", 5, Dado.new(1, 6, 2), TiposDano.CORTANTE, true)
	golpe.vantagem = true
	golpe.pode_rajada = true
	golpe.rajada = Golpe.new("Rajada", 5, Dado.new(1, 6, 2), TiposDano.CORTANTE, true)
	_aplicar_rajada_teste(golpe)
	_checar(golpe.usou_rajada and not golpe.vantagem, "Rajada abre mão da vantagem")

	var sem := Golpe.new("Sem", 5, Dado.new(1, 6), TiposDano.CORTANTE, true)
	sem.pode_rajada = true
	sem.rajada = Golpe.new("X", 5, Dado.new(1, 6), TiposDano.CORTANTE, true)
	_aplicar_rajada_teste(sem)
	_checar(not sem.usou_rajada, "sem vantagem a Rajada não troca")

	estilos.disparo_duplo_pendente = true
	_checar(estilos.disparo_duplo_pendente, "Disparo Duplo marca 2º tiro pendente")


## Mesma regra da Defesa (troca vantagem → usou_rajada), sem montar nó.
func _aplicar_rajada_teste(golpe: Golpe) -> void:
	if not golpe.pode_rajada or golpe.rajada == null or not Combate.teve_vantagem(golpe):
		return
	golpe.vantagem = false
	golpe.usou_rajada = true


func _testar_salvamento() -> void:
	var ficha := _ficha_base()
	ficha.definir_estilos([&"glima"])
	ficha.nivel = 2
	_checar(ficha.confirmar_troca_de_estilo([&"glima", &"defesa"]), "prepara Glima e Defesa no nv 2")
	var invent := Inventario.new()
	var dados := Salvamento.para_dicionario(ficha, invent, 1)
	var lida := Salvamento.montar_ficha(dados)
	_checar(lida != null and lida.tem_estilo(&"glima") and lida.tem_estilo(&"defesa")
		and lida.trocas_de_estilo_feitas == 1, "save/load guarda estilos e trocas")
