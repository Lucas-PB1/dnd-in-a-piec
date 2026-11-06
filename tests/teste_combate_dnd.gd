extends SceneTree
## Teste das regras puras de combate: dados com bônus, ataque contra CA, crítico,
## salvaguarda, ficha (proficiência, CA, ataque) e bloco de criatura (Gray Ooze).
## godot --headless --debug --path . --script res://tests/teste_combate_dnd.gd

const ROLAGENS := 400

var _falhas := 0
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 2024
	_testar_dado_com_bonus()
	_testar_ataque()
	_testar_salvaguarda()
	_testar_ficha_de_combate()
	_testar_gray_ooze()
	_testar_tipos_e_resistencia()
	_testar_desgaste()
	_testar_proficiencias()
	if _falhas == 0:
		print("PASSOU: todos os testes de combate de D&D")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_dado_com_bonus() -> void:
	var d := Dado.de_texto("2d8+1")
	_checar(d != null and d.quantidade == 2 and d.faces == 8 and d.bonus == 1, "lê '2d8+1'")
	_checar(Dado.de_texto("1d4-1").bonus == -1 and Dado.de_texto("1d4-1").texto() == "1d4-1", "lê bônus negativo")
	_checar(Dado.de_texto("2d8+x") == null, "recusa bônus inválido")
	_checar(Dado.de_texto("3d8+9").media() == 22, "média de 3d8+9 = 22 (vida do Gray Ooze)")
	var normal_ok := true
	var critico_ok := true
	for i in ROLAGENS:
		var n := d.rolar(_rng)
		var c := d.rolar(_rng, true)
		normal_ok = normal_ok and n >= 3 and n <= 17
		critico_ok = critico_ok and c >= 5 and c <= 33
	_checar(normal_ok, "2d8+1 normal fica entre 3 e 17")
	_checar(critico_ok, "2d8+1 crítico (4d8+1, bônus não dobra) fica entre 5 e 33")


func _testar_ataque() -> void:
	var golpe := Golpe.new("Teste", 3, Dado.new(1, 6))
	var regras_ok := true
	var viu_critico := false
	var viu_erro := false
	for i in ROLAGENS:
		var r := Combate.resolver_ataque(golpe, 12, _rng)
		var esperado := r.d20 == 20 or (r.d20 != 1 and r.d20 + 3 >= 12)
		regras_ok = regras_ok and r.acertou == esperado and r.total == r.d20 + 3
		regras_ok = regras_ok and (r.dano > 0) == r.acertou and r.critico == (r.d20 == 20)
		viu_critico = viu_critico or r.critico
		viu_erro = viu_erro or not r.acertou
	_checar(regras_ok, "acerta se d20 + bônus >= CA; 20 sempre acerta (crítico); 1 sempre erra")
	_checar(viu_critico and viu_erro, "em %d ataques saiu crítico e erro" % ROLAGENS)
	var impossivel := Golpe.new("Fraco", -50, Dado.new(1, 4))
	var so_criticos := true
	for i in ROLAGENS:
		var r := Combate.resolver_ataque(impossivel, 30, _rng)
		so_criticos = so_criticos and r.acertou == (r.d20 == 20)
	_checar(so_criticos, "contra CA impossível, só o 20 natural acerta")


func _testar_salvaguarda() -> void:
	var sempre := true
	var nunca := true
	for i in ROLAGENS:
		sempre = sempre and Combate.passou_salvaguarda(20, 21, _rng)
		nunca = nunca and not Combate.passou_salvaguarda(-1, 20, _rng)
	_checar(sempre and nunca, "salvaguarda passa se d20 + bônus >= CD")


func _testar_ficha_de_combate() -> void:
	var guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")
	var espada: Arma = load("res://data/arma_espada_curta.tres")
	var ficha := Ficha.new(guerreiro, guerreiro.atributos_sugeridos)  # FOR 15, DES 14, CON 13
	_checar(ficha.classe_armadura() == 12, "CA sem armadura = 10 + DES (14 -> 12)")
	_checar(ficha.bonus_ataque(espada) == 4, "ataque com espada curta = +2 proficiência +2 FOR = +4")
	var golpe := ficha.golpe_com(espada)
	_checar(golpe.bonus_ataque == 4 and golpe.dano.texto() == "1d6+2", "golpe da espada: +4 para acertar, 1d6+2")
	_checar(ficha.bonus_salvaguarda(Atributos.FORCA) == 4 and ficha.bonus_salvaguarda(Atributos.CONSTITUICAO) == 3,
		"Guerreiro é proficiente em FOR (+2+2) e CON (+1+2)")
	_checar(ficha.bonus_salvaguarda(Atributos.DESTREZA) == 2 and not ficha.proficiente_em_salvaguarda(Atributos.DESTREZA),
		"DES não é proficiente (só o modificador +2)")


func _testar_gray_ooze() -> void:
	var ooze: CriaturaRPG = load("res://data/gray_ooze.tres")
	_checar(ooze.classe_armadura == 9 and ooze.vida_maxima(_rng) == 22, "Gray Ooze: CA 9, PV 22 (média de 3d8+9)")
	_checar(ooze.modificador(Atributos.CONSTITUICAO) == 3 and ooze.modificador(Atributos.DESTREZA) == -2,
		"Gray Ooze: CON 16 (+3), DES 6 (-2)")
	_checar(ooze.bonus_salvaguarda(Atributos.FORCA) == 1 and ooze.bonus_salvaguarda(Atributos.CARISMA) == -4,
		"salvaguardas do Ooze = modificadores (sem proficiência)")
	var pseudopode := ooze.golpe()
	_checar(pseudopode.nome == "Pseudópode" and pseudopode.bonus_ataque == 3 and pseudopode.dano.texto() == "2d8+1",
		"Pseudópode: +3 para acertar, 2d8+1")
	_checar(is_equal_approx(EscalaDnd.pes_para_pixels(5.0), 32.0), "5 pés = 1 ladrilho (32 px)")
	_checar(is_equal_approx(EscalaDnd.deslocamento_para_velocidade(10.0), 64.0 / 1.5), "10 pés por rodada = 64 px em 1,5 s")
	_checar(is_equal_approx(EscalaDnd.deslocamento_para_velocidade(30.0), 128.0), "30 pés por rodada (herói) = 128 px/s")
	_checar(is_equal_approx(EscalaDnd.intervalo_ataque(0), 1.0) and is_equal_approx(EscalaDnd.intervalo_ataque(2), 0.8)
		and is_equal_approx(EscalaDnd.intervalo_ataque(-2), 1.2), "ritmo: (10 - iniciativa) tiques de 0,1 s (0 -> 1,0 s, +2 -> 0,8 s, -2 -> 1,2 s)")
	_checar(is_equal_approx(EscalaDnd.intervalo_ataque(20), 0.3), "iniciativa altíssima tem limite (mínimo 3 tiques)")
	var guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")
	var ficha := Ficha.new(guerreiro, guerreiro.atributos_sugeridos)
	_checar(ficha.iniciativa() == 2 and ooze.iniciativa == -2, "iniciativa: herói = mod. DES (+2), Ooze = -2 da ficha")


func _testar_tipos_e_resistencia() -> void:
	var espada: Arma = load("res://data/arma_espada_curta.tres")
	var soco: Arma = load("res://data/ataque_desarmado.tres")
	var ooze: CriaturaRPG = load("res://data/gray_ooze.tres")
	_checar(espada.tipo_dano == TiposDano.PERFURANTE and soco.tipo_dano == TiposDano.CONTUNDENTE,
		"espada curta = perfurante (livro), soco = contundente")
	_checar(ooze.golpe().tipo_dano == TiposDano.ACIDO, "Pseudópode = dano ácido")
	_checar(TiposDano.ACIDO in ooze.resistencias and TiposDano.FRIO in ooze.resistencias
		and TiposDano.FOGO in ooze.resistencias, "Ooze resiste a ácido, frio e fogo")
	_checar(TiposDano.aplicar_resistencia(9) == 4 and TiposDano.aplicar_resistencia(1) == 0,
		"resistência = metade, arredondado para baixo (9 -> 4, 1 -> 0)")
	var acido := Golpe.new("Ácido", 100, Dado.new(1, 1, 9), TiposDano.ACIDO)
	var perfurante := Golpe.new("Estocada", 100, Dado.new(1, 1, 9), TiposDano.PERFURANTE)
	var resistencias: Array[StringName] = ooze.resistencias
	var metade_ok := true
	var inteiro_ok := true
	for i in 50:
		var r1 := Combate.resolver_ataque(acido, 9, _rng, resistencias)
		var r2 := Combate.resolver_ataque(perfurante, 9, _rng, resistencias)
		# 1d1+9 = 10 (crítico: 2d1+9 = 11). Com resistência: 5 nos dois casos.
		metade_ok = metade_ok and (not r1.acertou or (r1.resistido and r1.dano == 5))
		inteiro_ok = inteiro_ok and (not r2.acertou or (not r2.resistido and r2.dano in [10, 11]))
	_checar(metade_ok, "golpe de ácido no Ooze: dano pela metade (10 -> 5)")
	_checar(inteiro_ok, "golpe perfurante no Ooze: dano inteiro")
	var golpe_espada := Ficha.new(load("res://data/classe_guerreiro.tres"), {}).golpe_com(espada, 2)
	_checar(golpe_espada.tipo_dano == TiposDano.PERFURANTE and golpe_espada.arma_corroivel and golpe_espada.bonus_ataque == 0,
		"golpe da espada leva o tipo, é corroível e desconta o desgaste (+2 - 2 = 0)")


## Corrosão no inventário: -1 por toque, destruída em -5; cópias da mesma arma são separadas.
func _testar_desgaste() -> void:
	var espada: Arma = load("res://data/arma_espada_curta.tres")
	var inv := Inventario.new()
	var minha := espada.duplicate() as Arma
	var outra := espada.duplicate() as Arma
	inv.adicionar(minha)
	inv.adicionar(outra)
	inv.equipar(minha)
	for i in 4:
		inv.desgastar(minha, 1, 5)
	_checar(inv.penalidade(minha) == 4 and inv.penalidade(outra) == 0 and minha in inv.itens,
		"desgaste é por item: -4 numa espada, a outra intacta")
	_checar(espada.resource_path != "" and inv.penalidade(espada) == 0, "o .tres original nunca é desgastado")
	_checar(inv.desgastar(minha, 1, 5) and minha not in inv.itens and inv.equipado(Item.ESPACO_MAO) == null,
		"no -5 a arma é destruída e sai da mão")


## Guerreiro: armas simples e marciais; armaduras leves, médias, pesadas e escudos.
## Sem proficiência na arma, o ataque perde o +2 de proficiência.
func _testar_proficiencias() -> void:
	var guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")
	var espada: Arma = load("res://data/arma_espada_curta.tres")
	var soco: Arma = load("res://data/ataque_desarmado.tres")
	_checar(espada.categoria == Proficiencias.ARMA_MARCIAL, "espada curta é arma marcial")
	_checar(Proficiencias.ARMA_SIMPLES in guerreiro.proficiencias_armas and Proficiencias.ARMA_MARCIAL in guerreiro.proficiencias_armas,
		"Guerreiro: proficiente em armas simples e marciais")
	_checar(guerreiro.treinamento_armaduras.size() == 4 and Proficiencias.ESCUDO in guerreiro.treinamento_armaduras,
		"Guerreiro: treinado em armaduras leves, médias, pesadas e escudos")
	var valores := {Atributos.FORCA: 15}
	var ficha_guerreiro := Ficha.new(guerreiro, valores)
	_checar(ficha_guerreiro.proficiente_com(espada) and ficha_guerreiro.bonus_ataque(espada) == 4,
		"Guerreiro com espada curta: proficiente, +2 FOR +2 proficiência = +4")
	var sem_marciais := guerreiro.duplicate() as ClasseRPG
	sem_marciais.proficiencias_armas = [Proficiencias.ARMA_SIMPLES]
	var ficha_sem := Ficha.new(sem_marciais, valores)
	_checar(not ficha_sem.proficiente_com(espada) and ficha_sem.bonus_ataque(espada) == 2,
		"classe sem armas marciais: espada curta só com +2 FOR (sem proficiência)")
	_checar(ficha_sem.proficiente_com(soco) and ficha_sem.bonus_ataque(soco) == 4, "ataque desarmado: todo mundo é proficiente")
	_checar(Proficiencias.texto_armaduras(guerreiro.treinamento_armaduras) == "armaduras leves, médias, pesadas e escudos",
		"texto do treinamento em português")


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
