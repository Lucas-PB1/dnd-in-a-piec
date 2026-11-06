extends SceneTree
## Teste das armas do PHB (fatia 11a): dados das 29 armas, Versátil, Pesada, Alcance, Duas Mãos,
## pilhas no inventário, pacotes iniciais e o baú do arsenal.
## godot --headless --debug --path . --script res://tests/teste_armas.gd

const PASTA := "res://data/armas/"
const TOTAL_ARMAS := 29
const TOTAL_ARMADURAS := 21
## Até onde a ponta tem de chegar (px à frente da mão): 5 pés; com Alcance, 10 pés.
const PONTA_NORMAL := 44.0
const PONTA_ALCANCE := PONTA_NORMAL + EscalaDnd.PIXELS_POR_LADRILHO

var _falhas := 0


func _initialize() -> void:
	_testar_dados()
	_testar_regras()
	_testar_inventario()
	_testar_pacotes()
	await _testar_bau()
	if _falhas == 0:
		print("PASSOU: todos os testes das armas")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _arma(id: String) -> Arma:
	return load(PASTA + id + ".tres")


func _testar_dados() -> void:
	var arquivos := Array(ResourceLoader.list_directory(PASTA)).filter(func(a: String) -> bool: return a.ends_with(".tres"))
	_checar(arquivos.size() == TOTAL_ARMAS, "29 armas corpo a corpo/arremesso do PHB (achou %d)" % arquivos.size())
	var todas_ok := true
	for arquivo: String in arquivos:
		var arma := load(PASTA + arquivo) as Arma
		todas_ok = todas_ok and arma.textura != null and arma.maestria in Proficiencias.NOMES_MAESTRIAS \
			and arma.categoria in [Proficiencias.ARMA_SIMPLES, Proficiencias.ARMA_MARCIAL] and Dado.de_texto(arma.dados_dano) != null
	_checar(todas_ok, "toda arma tem sprite, maestria, categoria e dado válidos")
	var grande := _arma("espada_grande")
	_checar(grande.dados_dano == "2d6" and grande.tipo_dano == TiposDano.CORTANTE and grande.pesada and grande.duas_maos
		and grande.maestria == Proficiencias.RASPAO, "Espada Grande: 2d6 cortante, Pesada, Duas Mãos, Raspão")
	var adaga := _arma("adaga")
	_checar(adaga.acuidade and adaga.leve and adaga.arremesso_normal_pes == 20 and adaga.arremesso_longo_pes == 60
		and adaga.categoria == Proficiencias.ARMA_SIMPLES, "Adaga: simples, Acuidade, Leve, Arremesso 20/60")
	_checar(_arma("azagaia").empilhavel and not _arma("espada_longa").empilhavel, "Azagaia empilha; Espada Longa não")
	_checar(_arma("espada_curta").tipo_dano == TiposDano.PERFURANTE and _arma("cimitarra").tipo_dano == TiposDano.CORTANTE,
		"Espada Curta perfurante, Cimitarra cortante")


func _testar_regras() -> void:
	var guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")
	var forte := Ficha.new(guerreiro, {Atributos.FORCA: 15})
	var fraco := Ficha.new(guerreiro, {Atributos.FORCA: 12})
	var longa := _arma("espada_longa")
	_checar(forte.texto_dano(longa) == "1d8+2" and forte.texto_dano(longa, true) == "1d10+2",
		"Espada Longa Versátil: 1d8 numa mão, 1d10 com as duas")
	_checar(forte.texto_dano(_arma("maca"), true) == "1d6+2", "arma não versátil ignora as duas mãos")
	var grande := _arma("espada_grande")
	_checar(not forte.golpe_com(grande).desvantagem and fraco.golpe_com(grande).desvantagem,
		"Pesada: FOR 15 normal, FOR 12 ataca com desvantagem")
	_checar(not fraco.golpe_com(longa).desvantagem, "arma não Pesada não liga para FOR")
	_testar_alcance()

	var inv := Inventario.new()
	var escudo: Armadura = load("res://data/armaduras/escudo.tres")
	inv.adicionar(longa)
	inv.adicionar(escudo)
	inv.equipar(longa)
	_checar(Equipamento.texto_dano(forte, inv, longa) == "1d10+2", "Espada Longa sem escudo usa 1d10")
	inv.equipar(escudo)
	_checar(Equipamento.texto_dano(forte, inv, longa) == "1d8+2" and Equipamento.golpe(forte, inv, longa).dano.faces == 8,
		"Espada Longa com escudo volta a 1d8 (no texto e no golpe)")


## Regra do livro: toda arma comum alcança 5 pés e com Alcance 10 pés (a ponta + o passo).
## Armas curtas dão um passo; as compridas não precisam.
func _testar_alcance() -> void:
	var ok := true
	var ruins: PackedStringArray = []
	for arquivo in ResourceLoader.list_directory(PASTA):
		var arma := load(PASTA + arquivo) as Arma
		var alvo := PONTA_ALCANCE if arma.alcance_estendido else PONTA_NORMAL
		var chega := arma.alcance_da_ponta() + arma.passo
		if chega < alvo - 0.5 or arma.poses.size() < 3 or not arma.poses.any(func(p: PoseGolpe) -> bool: return p.acerta):
			ok = false
			ruins.append(arma.nome)
	_checar(ok, "toda arma tem golpe próprio e a ponta chega a 5 pés (10 com Alcance) %s" % str(ruins))
	_checar(_arma("adaga").passo > 0.0 and _arma("pique").passo == 0.0, "Adaga dá passo à frente; Pique não precisa")
	_checar(_arma("pique").alcance_da_ponta() > _arma("espada_grande").alcance_da_ponta(), "Pique (Alcance) chega mais longe que a Espada Grande")
	var movimentos := {}
	for arquivo in ResourceLoader.list_directory(PASTA):
		var arma := load(PASTA + arquivo) as Arma
		movimentos[str(arma.poses.map(func(p: PoseGolpe) -> Array: return [p.tempo, p.angulo, p.mao]))] = true
	_checar(movimentos.size() == TOTAL_ARMAS, "cada uma das 29 armas tem um movimento diferente (%d)" % movimentos.size())


func _testar_inventario() -> void:
	var inv := Inventario.new(3)
	var azagaia := _arma("azagaia")
	_checar(inv.adicionar(azagaia.duplicate(), 5) and inv.adicionar(azagaia.duplicate(), 3), "adiciona Azagaias em duas vezes")
	_checar(inv.itens.size() == 1 and inv.quantidade_de(inv.itens[0]) == 8, "Azagaias empilham: 1 lugar, ×8")
	_checar(not inv.adicionar(_arma("maca").duplicate(), 2), "item não empilhável não entra com quantidade > 1")

	var grande := _arma("espada_grande").duplicate() as Arma
	var escudo := (load("res://data/armaduras/escudo.tres") as Armadura).duplicate() as Armadura
	inv.adicionar(grande)
	inv.adicionar(escudo)
	inv.equipar(escudo)
	inv.equipar(grande)
	_checar(inv.esta_equipado(grande) and not inv.esta_equipado(escudo) and not inv.livre(Item.ESPACO_MAO_SECUNDARIA),
		"Espada Grande (Duas Mãos) tira o escudo e ocupa a mão secundária")
	inv.equipar(escudo)
	_checar(inv.esta_equipado(escudo) and not inv.esta_equipado(grande), "escudo tira a Espada Grande da mão")
	inv.limpar()
	_checar(inv.itens.is_empty() and inv.livre(Item.ESPACO_MAO_SECUNDARIA) and inv.equipado(Item.ESPACO_MAO) == null,
		"limpar esvazia tudo")


func _testar_pacotes() -> void:
	var guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")
	_checar(guerreiro.pacotes_iniciais.size() == 2, "Guerreiro tem os pacotes A e B")
	var a := guerreiro.pacotes_iniciais[0]
	var b := guerreiro.pacotes_iniciais[1]
	_checar(a.arma().nome == "Espada Grande" and a.armadura().nome == "Cota de Malha"
		and a.texto_itens() == "Cota de Malha, Espada Grande, Mangual, 8× Azagaia", "pacote A como no livro (%s)" % a.texto_itens())
	_checar(b.arma().nome == "Cimitarra" and b.armadura().nome == "Couro Batido"
		and b.texto_itens() == "Couro Batido, Cimitarra, Espada Curta", "pacote B (sem o Arco Longo, que vem depois)")


func _testar_bau() -> void:
	var itens := Bau.carregar_itens(["res://data/armas/", "res://data/armaduras/"])
	_checar(itens.size() == TOTAL_ARMAS + TOTAL_ARMADURAS, "baú carrega as 29 armas e as 21 armaduras (%d)" % itens.size())

	var cena: Node = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	cena.get_node("GrayOoze").free()
	await physics_frame
	var jogador: Jogador = cena.get_node("Jogador")
	var bau: Bau = cena.get_node("Bau")
	var tela: TelaBau = cena.get_node("Interface/TelaBau")
	jogador.global_position = bau.global_position
	for i in 3:
		await physics_frame
	_checar((bau.get_node("Aviso") as Label).visible, "perto do baú aparece \"E: abrir arsenal\"")
	await _apertar("interagir")
	_checar(tela.visible and paused, "E abre o arsenal e pausa o jogo")
	var antes := jogador.inventario.itens.size()
	_checar(tela.pegar_selecionado() and jogador.inventario.itens.size() == antes + 1, "Pegar põe o item na mochila")
	var pego := jogador.inventario.itens[antes]
	_checar(pego not in bau.itens(), "na mochila vai uma cópia (o .tres do baú não muda)")
	while not jogador.inventario.esta_cheio():
		jogador.inventario.adicionar(Item.new())
	_checar(not tela.pegar_selecionado() and (tela.get_node("%Aviso") as Label).text == TelaBau.AVISO_CHEIA,
		"mochila cheia: não pega e avisa")
	await _apertar("interagir")
	_checar(not tela.visible and not paused, "E de novo fecha e despausa")
	jogador.global_position = bau.global_position + Vector2(400, 0)
	for i in 3:
		await physics_frame
	_checar(not (bau.get_node("Aviso") as Label).visible, "longe do baú o aviso some")
	await _apertar("interagir")
	_checar(not tela.visible, "longe do baú, E não abre nada")
	cena.queue_free()


## Aperta e solta a ação, esperando os quadros para o evento chegar aos nós.
func _apertar(acao: StringName) -> void:
	var evento := InputEventAction.new()
	evento.action = acao
	evento.pressed = true
	Input.parse_input_event(evento)
	await process_frame
	await process_frame
	var solta := InputEventAction.new()
	solta.action = acao
	Input.parse_input_event(solta)
	await process_frame


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
