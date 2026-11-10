extends TesteBase
## Teste do início do jogo: tela de título, criação (nome, classe, atributos) e entrada no jogo.
## godot --headless --debug --path . --script res://tests/teste_criacao.gd

const NOME_TESTE := "Aldric"


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_testar_regras_do_nome()
	await _testar_tela_sozinha()
	await _testar_fluxo_da_main()
	if _falhas == 0:
		print("PASSOU: todos os testes do início do jogo")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_regras_do_nome() -> void:
	_checar(Ficha.limpar_nome("  Aldric  ") == "Aldric", "nome sem espaços nas pontas")
	_checar(Ficha.limpar_nome("x".repeat(30)).length() == Ficha.TAMANHO_MAXIMO_NOME, "nome cortado no tamanho máximo")
	_checar(not Ficha.nome_valido("   ") and Ficha.nome_valido("A"), "nome vazio não vale")
	var guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")
	_checar(Ficha.new(guerreiro, {}).nome == Ficha.NOME_PADRAO, "sem nome, a ficha usa o padrão")


## A cena da criação roda sozinha (como no F6).
func _testar_tela_sozinha() -> void:
	var tela: TelaCriacao = load("res://ui/criacao_personagem/tela_criacao.tscn").instantiate()
	root.add_child(tela)
	await process_frame
	var recebida: Array[Ficha] = []
	tela.confirmada.connect(func(f: Ficha, _p: PacoteInicial) -> void: recebida.append(f))
	var escolha: OptionButton = tela.get_node("%Classe")
	_checar(escolha.item_count == 1 and escolha.get_item_text(0) == "Guerreiro", "classe: só Guerreiro por enquanto")
	var escolha_nivel: OptionButton = tela.get_node("%Nivel")
	_checar(escolha_nivel.item_count == Ficha.NIVEL_MAXIMO, "criação permite escolher do nível 1 ao 6")
	tela.escolher_nivel(2)
	var lista: ItemList = tela.get_node("%ListaMaestrias")
	_checar(lista.select_mode == ItemList.SELECT_TOGGLE, "clique marca e desmarca a maestria")
	_checar(tela.armas_marcadas().size() == 3, "o pacote já marca 3 armas")
	tela.marcar_arma("Adaga", true)
	_checar(tela.armas_marcadas().size() == 3 and not tela.armas_marcadas().has("Adaga"),
		"a quarta arma não entra")
	tela.marcar_arma("Espada Grande", false)
	var sem_espada := tela.armas_marcadas()
	_checar(sem_espada.size() == 2 and not sem_espada.has("Espada Grande")
		and sem_espada.has("Mangual") and sem_espada.has("Azagaia"),
		"desmarcar tira só a arma clicada")
	tela.marcar_arma("Adaga", true)
	_checar(tela.armas_marcadas().size() == 3 and tela.armas_marcadas().has("Adaga"),
		"com uma vaga, a outra arma entra")
	_checar(tela.pericias_marcadas().size() == 2 and Pericia.PERCEPCAO in tela.pericias_marcadas()
		and Pericia.ATLETISMO in tela.pericias_marcadas(), "abre com Percepção e Atletismo")
	tela.marcar_pericia(Pericia.ACROBACIA, true)
	_checar(not tela.pericias_marcadas().has(Pericia.ACROBACIA), "a terceira perícia não entra")
	tela.aplicar_sugestao()
	tela.confirmar()
	_checar(recebida.is_empty(), "não deixa começar sem nome")
	tela.definir_nome(NOME_TESTE)
	tela.marcar_pericia(Pericia.PERCEPCAO, false)
	tela.confirmar()
	_checar(recebida.is_empty(), "não deixa começar com uma perícia só")
	tela.marcar_pericia(Pericia.PERCEPCAO, true)
	tela.confirmar()
	_checar(recebida.size() == 1 and recebida[0].nome == NOME_TESTE and recebida[0].atributos[Atributos.FORCA] == 17,
		"confirma com nome, sugestão e antecedente e devolve a ficha (FOR 15 + 2 do Artesão)")
	_checar(recebida[0].antecedente == &"artesao" and recebida[0].tem_talento(&"artesao")
		and recebida[0].pericias.has(Pericia.INVESTIGACAO) and recebida[0].pericias.has(Pericia.PERSUASAO),
		"a ficha guarda o antecedente, o talento de origem e as perícias dele")
	_checar(recebida[0].pericias.has(Pericia.PERCEPCAO) and recebida[0].pericias.has(Pericia.ATLETISMO)
		and recebida[0].percepcao_passiva() == 13, "a ficha guarda as perícias; SAB 12 treinada: passiva 13")
	_checar(recebida[0].nivel == 3 and recebida[0].experiencia == 900,
		"o nível inicial escolhido e o XP correspondente vão para a ficha")
	await _testar_antecedente_e_passos()
	await _testar_perito()
	tela.queue_free()


func _testar_fluxo_da_main() -> void:
	var cena: Node = load("res://levels/main.tscn").instantiate()
	root.add_child(cena)
	await process_frame
	var titulo := _achar(cena, TelaTitulo) as TelaTitulo
	_checar(titulo != null and paused, "o jogo abre na tela de título, pausado")
	_checar((titulo.get_node("%Titulo") as Label).text == "DnD in a Piece", "título mostra o nome do jogo")
	var jogador: Jogador = cena.get_node("Jogador")
	var x_inicial := jogador.global_position.x
	Input.action_press("mover_direita")
	for i in 10:
		await physics_frame
	Input.action_release("mover_direita")
	_checar(jogador.global_position.x == x_inicial, "herói não anda no título")

	titulo.novo_jogo_escolhido.emit()
	await process_frame
	var tela := _achar(cena, TelaCriacao) as TelaCriacao
	_checar(tela != null and paused and _achar(cena, TelaTitulo) == null, "Novo Jogo abre a criação (ainda pausado)")

	var compra := CompraDePontos.new()
	compra.aplicar({Atributos.FORCA: 8, Atributos.DESTREZA: 15, Atributos.CONSTITUICAO: 15,
		Atributos.INTELIGENCIA: 15})
	tela.confirmada.emit(Ficha.new(jogador.classe, compra.valores, NOME_TESTE), jogador.classe.pacotes_iniciais[0])
	await process_frame
	_checar(not paused, "ao confirmar, o jogo despausa")
	_checar(jogador.ficha.nome == NOME_TESTE and jogador.vida_maxima() == 12, "herói recebe a ficha (nome e CON 15 -> 12 PV)")
	var hud_nome: String = (cena.get_node("Hud/%Personagem") as Label).text
	var hud_vida: String = (cena.get_node("Hud/%Vida") as Label).text
	_checar(hud_nome == "Aldric (Guerreiro)" and hud_vida == "PV 12/12", "HUD mostra nome, classe e vida (%s | %s)" % [hud_nome, hud_vida])
	_checar_pacote_a(jogador)
	cena.queue_free()


## Pacote A: Cota de Malha + Espada Grande vestidas, Mangual e 8 Azagaias na mochila (4 lugares).
func _checar_pacote_a(jogador: Jogador) -> void:
	var inventario := jogador.inventario
	var azagaias := inventario.itens.filter(func(i: Item) -> bool: return i.nome == "Azagaia")
	_checar(inventario.itens.size() == 4 and azagaias.size() == 1 and inventario.quantidade_de(azagaias[0]) == 8,
		"pacote A: 4 lugares na mochila, Azagaia empilhada ×8")
	_checar(jogador.arma_atual().nome == "Espada Grande" and jogador.armadura_atual().nome == "Cota de Malha",
		"pacote A: Espada Grande na mão e Cota de Malha vestida")
	_checar(not inventario.livre(Item.ESPACO_MAO_SECUNDARIA), "Espada Grande (Duas Mãos) ocupa a mão secundária")
	_checar(jogador.classe_armadura() == 16, "CA 16 com a Cota de Malha")


func _achar(cena: Node, tipo: Variant) -> Node:
	for filho in cena.get_node("Interface").get_children():
		if is_instance_of(filho, tipo) and not filho.is_queued_for_deletion():
			return filho
	return null


## O passo do antecedente: perícias travadas, aumento de atributo e passos que não se pulam.
func _testar_antecedente_e_passos() -> void:
	var tela: TelaCriacao = load("res://ui/criacao_personagem/tela_criacao.tscn").instantiate()
	root.add_child(tela)
	await process_frame
	var lista: ItemList = tela.get_node("%ListaAntecedentes")
	_checar(lista.item_count == 11, "a lista oferece os 11 antecedentes liberados")
	var passo_antecedente: Control = tela.get_node("%PassoAntecedente")
	var botao_ir: Button = tela.get_node("%Atributos")
	_checar(botao_ir.disabled and botao_ir.text == "Escreva um nome", "sem nome, o botão de avançar fica apagado e diz o que falta")
	tela.get_node("%IrAtributos").pressed.emit()
	_checar(not passo_antecedente.visible, "não dá para pular de passo sem completar o atual")
	tela.definir_nome(NOME_TESTE)
	botao_ir.pressed.emit()
	_checar(passo_antecedente.visible and not tela.get_node("%PassoQuem").visible, "com nome, avança para o antecedente")
	var botao_atributos: Button = tela.get_node("%IrAtributos")
	_checar(not botao_atributos.disabled, "o antecedente já vem escolhido, então dá para seguir")
	botao_atributos.pressed.emit()
	var botao_pericias: Button = tela.get_node("%IrPericias")
	_checar(botao_pericias.disabled and botao_pericias.text == "Gaste todos os pontos", "sem gastar os pontos, não vai para as perícias")
	tela.get_node("%IrPericias").pressed.emit()
	_checar(not tela.get_node("%PassoPericias").visible, "e o passo das perícias não abre")
	tela.aplicar_sugestao()
	_checar(not botao_pericias.disabled, "gastos os pontos, as perícias liberam")
	# Guarda: Atletismo e Percepção vêm do antecedente, travadas.
	tela.escolher_antecedente(_indice_do_antecedente(lista, "Guarda"))
	_checar(tela.pericias_marcadas().is_empty(), "com o Guarda, as duas perícias sugeridas já vêm do antecedente")
	tela.marcar_pericia(Pericia.ATLETISMO, false)
	var lista_pericias: ItemList = tela.get_node("%ListaPericias")
	_checar(lista_pericias.is_selected(_indice_da_pericia(Pericia.ATLETISMO)), "a perícia do antecedente não se desmarca")
	tela.marcar_pericia(Pericia.ACROBACIA, true)
	tela.marcar_pericia(Pericia.HISTORIA, true)
	_checar(tela.pericias_marcadas().size() == 2, "o Guerreiro escolhe as 2 dele entre as que sobram")
	# Aumento de atributo: +2 e +1 entre os 3 do antecedente.
	tela.escolher_aumento(0)
	var recebida: Array[Ficha] = []
	tela.confirmada.connect(func(f: Ficha, _p: PacoteInicial) -> void: recebida.append(f))
	tela.confirmar()
	var ficha := recebida[0] if recebida.size() == 1 else null
	_checar(ficha != null and ficha.antecedente == &"guarda" and ficha.tem_talento(&"alerta"), "o Guarda leva o talento Alerta")
	_checar(ficha != null and ficha.pericias.size() == 4, "a ficha tem 2 do antecedente e 2 escolhidas")
	_checar(ficha != null and ficha.atributos[Atributos.FORCA] == 17
		and ficha.atributos[Atributos.INTELIGENCIA] == _sugerido(Atributos.INTELIGENCIA) + 1,
		"+2 em Força e +1 em Inteligência somam à compra (FOR 15→17)")
	tela.queue_free()
	await process_frame


func _indice_do_antecedente(lista: ItemList, nome: String) -> int:
	for i in lista.item_count:
		if lista.get_item_text(i) == nome:
			return i
	return 0


func _indice_da_pericia(id: StringName) -> int:
	var classe: ClasseRPG = load("res://data/classe_guerreiro.tres")
	return classe.pericias_escolhiveis.find(id)


func _sugerido(atributo: StringName) -> int:
	var classe: ClasseRPG = load("res://data/classe_guerreiro.tres")
	return classe.atributos_sugeridos[atributo]


## Perito (Charlatão, Nobre, Escriba): mais 3 perícias à escolha entre todas as do jogo.
func _testar_perito() -> void:
	var tela: TelaCriacao = load("res://ui/criacao_personagem/tela_criacao.tscn").instantiate()
	root.add_child(tela)
	await process_frame
	var lista: ItemList = tela.get_node("%ListaAntecedentes")
	var lista_pericias: ItemList = tela.get_node("%ListaPericias")
	_checar(lista_pericias.item_count == 9, "sem o Perito a lista tem as 9 perícias do Guerreiro")
	tela.escolher_antecedente(_indice_do_antecedente(lista, "Charlatão"))
	_checar(lista_pericias.item_count == Pericia.ATRIBUTO.size(), "com o Perito a lista tem todas as %d perícias do jogo" % Pericia.ATRIBUTO.size())
	_checar(lista_pericias.is_selected(_indice_na_lista(lista_pericias, "Enganação")), "a perícia do antecedente fora da lista do Guerreiro vem marcada")
	tela.definir_nome(NOME_TESTE)
	tela.aplicar_sugestao()
	_checar(tela.pericias_marcadas().size() == 2, "abre com as 2 sugeridas; faltam 3 do Perito")
	var botao: Button = tela.get_node("%IrMaestrias")
	tela.get_node("%Atributos").pressed.emit()
	tela.get_node("%IrAtributos").pressed.emit()
	tela.get_node("%IrPericias").pressed.emit()
	_checar(botao.disabled and botao.text == "Escolha 5 perícias", "com 2 de 5 marcadas, as maestrias não abrem")
	tela.marcar_pericia(Pericia.ARCANISMO, true)
	tela.marcar_pericia(Pericia.MEDICINA, true)
	tela.marcar_pericia(Pericia.NATUREZA, true)
	tela.marcar_pericia(Pericia.RELIGIAO, true)
	_checar(tela.pericias_marcadas().size() == 5, "o sexto não entra: são 5 no total")
	_checar(not botao.disabled, "completas as 5, as maestrias abrem")
	var recebida: Array[Ficha] = []
	tela.confirmada.connect(func(f: Ficha, _p: PacoteInicial) -> void: recebida.append(f))
	tela.confirmar()
	_checar(recebida.size() == 1 and recebida[0].pericias.size() == 7 and recebida[0].tem_talento(&"perito"),
		"a ficha tem 2 do antecedente, 5 escolhidas e o talento Perito")
	_checar(not recebida.is_empty() and recebida[0].pericias.has(Pericia.ARCANISMO), "e uma perícia fora da lista do Guerreiro")
	tela.queue_free()
	await process_frame


func _indice_na_lista(lista: ItemList, nome: String) -> int:
	for i in lista.item_count:
		if lista.get_item_text(i).begins_with(nome):
			return i
	return 0
