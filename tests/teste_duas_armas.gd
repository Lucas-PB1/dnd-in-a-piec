extends SceneTree
## Fatia 11b: duas armas leves (J J) e arremesso (K, pegar com E).
## godot --headless --debug --path . --script res://tests/teste_duas_armas.gd

const CENA_VOO := "res://features/arremesso/arma_arremessada.tscn"

var _falhas := 0


func _initialize() -> void:
	_testar_regras()
	await _testar_no_jogo()
	if _falhas == 0:
		print("PASSOU: duas armas e arremesso")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_regras() -> void:
	var guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")
	var ficha := Ficha.new(guerreiro, guerreiro.atributos_sugeridos)
	var curta: Arma = load("res://data/armas/espada_curta.tres")
	var extra := ficha.golpe_com(curta, 0, null, false, true)
	var normal := ficha.golpe_com(curta)
	_checar(extra.dano.bonus == 0 and extra.bonus_ataque == normal.bonus_ataque,
		"golpe extra não soma mod. positivo no dano; o ataque continua igual")
	var fraco := Ficha.new(guerreiro, {Atributos.FORCA: 8, Atributos.DESTREZA: 8})
	_checar(fraco.golpe_com(curta, 0, null, false, true).dano.bonus == -1,
		"mod. negativo entra no dano do golpe extra")
	_checar(Equipamento.texto_dano_extra(ficha, curta) == "1d6", "texto do extra sem o +2")

	var inv := Inventario.new()
	var principal := curta.duplicate() as Arma
	var adaga := (load("res://data/armas/adaga.tres") as Arma).duplicate() as Arma
	var escudo := (load("res://data/armaduras/escudo.tres") as Armadura).duplicate() as Armadura
	inv.adicionar(principal)
	inv.adicionar(adaga)
	inv.adicionar(escudo)
	inv.equipar(principal)
	inv.equipar(escudo)
	inv.equipar(adaga)
	_checar(inv.equipado(Item.ESPACO_MAO) == principal and inv.equipado(Item.ESPACO_MAO_SECUNDARIA) == adaga
		and not inv.esta_equipado(escudo), "2ª arma leve tira o escudo e fica na outra mão")
	_checar(Equipamento.arma_secundaria(inv) == adaga and Equipamento.escudo(inv) == null,
		"equipamento lê a arma da outra mão, não um escudo")

	var azagaia := (load("res://data/armas/azagaia.tres") as Arma).duplicate() as Arma
	var pilha := Inventario.new()
	pilha.adicionar(azagaia, 8)
	pilha.equipar(azagaia)
	var tirada := pilha.extrair_uma(azagaia)
	_checar(tirada != azagaia and pilha.quantidade_de(azagaia) == 7 and pilha.esta_equipado(azagaia),
		"arremessar uma Azagaia tira 1 da pilha e a mão continua com ela")


func _testar_no_jogo() -> void:
	var cena: Node = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	var jogador: Jogador = cena.get_node("Jogador")
	var boneco: BonecoTreino = cena.get_node("BonecoTreino")
	cena.get_node("GrayOoze").free()
	await _esperar(20)
	await _testar_combo(jogador, boneco)
	await _testar_alcance(cena)
	await _testar_arremesso(cena, jogador)
	cena.queue_free()


func _testar_combo(jogador: Jogador, boneco: BonecoTreino) -> void:
	var adaga := (load("res://data/armas/adaga.tres") as Arma).duplicate() as Arma
	jogador.inventario.adicionar(adaga)
	jogador.inventario.equipar(jogador.inventario.itens[0])
	jogador.inventario.equipar(adaga)
	await _colocar(jogador, boneco)
	var nomes: Array[String] = []
	var bonus: Array[int] = []
	boneco.atingido.connect(func(r: Combate.Resultado) -> void:
		nomes.append(r.golpe.nome)
		bonus.append(r.golpe.dano.bonus))
	var antes := boneco.golpes_recebidos
	await _apertar("atacar")
	await _esperar(6)
	await _apertar("atacar")
	await _esperar(40)
	_checar(boneco.golpes_recebidos == antes + 2, "J J acerta duas vezes antes do intervalo (deu %d)" % (boneco.golpes_recebidos - antes))
	_checar(nomes.size() >= 2 and nomes[0] == "Espada Curta" and nomes[1] == "Adaga" and bonus[1] == 0,
		"o 2º golpe é a Adaga, sem modificador no dano (%s)" % ", ".join(nomes))


func _testar_alcance(cena: Node) -> void:
	var voo: ArmaArremessada = load(CENA_VOO).instantiate()
	cena.add_child(voo)
	voo.global_position = Vector2(80, 80)
	var adaga: Arma = load("res://data/armas/adaga.tres")
	voo.lancar(adaga, Golpe.new(adaga.nome, 4, Dado.new(1, 4)), 0, 1)
	voo.global_position.x += EscalaDnd.pes_para_pixels(adaga.arremesso_normal_pes) + 8.0
	await physics_frame
	_checar(voo.em_desvantagem(), "passou da distância normal: desvantagem")
	voo.free()


func _testar_arremesso(cena: Node, jogador: Jogador) -> void:
	var adaga := (load("res://data/armas/adaga.tres") as Arma).duplicate() as Arma
	jogador.inventario.adicionar(adaga)
	if jogador.inventario.equipado(Item.ESPACO_MAO) != adaga:
		jogador.inventario.desequipar(Item.ESPACO_MAO)
		jogador.inventario.equipar(adaga)
	await _esperar(5)
	while not jogador.pode_golpear():
		await physics_frame
	await _apertar("arremessar")
	await _esperar(3)
	_checar(jogador.inventario.equipado(Item.ESPACO_MAO) != adaga, "K tira a Adaga da mão")
	var voo := _achar_voo(cena)
	_checar(voo != null, "a Adaga está no ar")
	if voo == null:
		return
	var pousou := false
	for i in 180:
		if voo.esta_no_chao():
			pousou = true
			break
		await physics_frame
	_checar(pousou, "a arma cai no chão")
	if not pousou:
		return
	jogador.posicionar_no_inicio(voo.global_position)
	await _esperar(8)
	await _evento("interagir")
	await _esperar(3)
	_checar(not is_instance_valid(voo) or not voo.is_inside_tree(), "E recolhe a arma do chão")
	_checar(jogador.inventario.equipado(Item.ESPACO_MAO) == adaga, "a mão vazia equipa a arma recolhida")


func _achar_voo(cena: Node) -> ArmaArremessada:
	for filho in cena.get_children():
		if filho is ArmaArremessada:
			return filho
	return null


func _colocar(jogador: Jogador, boneco: BonecoTreino) -> void:
	for i in 60:
		if jogador.is_on_floor() and not jogador.esta_golpeando():
			break
		await physics_frame
	while not jogador.pode_golpear():
		await physics_frame
	jogador.posicionar_no_inicio(Vector2(boneco.global_position.x - 30.0, jogador.global_position.y))
	jogador.velocity = Vector2.ZERO
	await _apertar("mover_direita")
	await _esperar(15)


## Evento de verdade: chega em _unhandled_input (pegar do chão, abrir baú).
func _evento(acao: String) -> void:
	var evento := InputEventAction.new()
	evento.action = acao
	evento.pressed = true
	Input.parse_input_event(evento)
	await process_frame
	await physics_frame
	evento.pressed = false
	Input.parse_input_event(evento)
	await physics_frame


func _apertar(acao: String) -> void:
	Input.action_press(acao)
	await physics_frame
	Input.action_release(acao)
	await physics_frame


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
