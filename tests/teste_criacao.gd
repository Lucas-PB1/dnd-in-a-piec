extends SceneTree
## Teste do início do jogo: tela de título, criação (nome, classe, atributos) e entrada no jogo.
## godot --headless --debug --path . --script res://tests/teste_criacao.gd

const NOME_TESTE := "Aldric"

var _falhas := 0


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
	tela.mudar_atributo(Atributos.FORCA, -1)
	tela.confirmar()
	_checar(recebida.is_empty(), "não deixa começar com pontos sobrando")
	tela.mudar_atributo(Atributos.FORCA, 1)
	tela.marcar_pericia(Pericia.PERCEPCAO, false)
	tela.confirmar()
	_checar(recebida.is_empty(), "não deixa começar com uma perícia só")
	tela.marcar_pericia(Pericia.PERCEPCAO, true)
	tela.confirmar()
	_checar(recebida.size() == 1 and recebida[0].nome == NOME_TESTE and recebida[0].atributos[Atributos.FORCA] == 15,
		"confirma com nome e sugestão e devolve a ficha")
	_checar(recebida[0].pericias.has(Pericia.PERCEPCAO) and recebida[0].pericias.has(Pericia.ATLETISMO)
		and recebida[0].percepcao_passiva() == 13, "a ficha guarda as perícias; SAB 12 treinada: passiva 13")
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


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
