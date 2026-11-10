extends TesteBase
## Campanha: as nove fases têm porta, pontos de armadilha de sobra e a cota certa; a porta
## barra enquanto a cota está viva e abre quando morre; a última fase mostra a vitória e
## "Jogar de novo" volta à primeira. godot --headless --debug --path . --script res://tests/teste_campanha.gd

const CENAS_FASE: Array[String] = [
	"res://levels/fase_1.tscn", "res://levels/fase_2.tscn", "res://levels/fase_3.tscn",
	"res://levels/fase_4.tscn", "res://levels/fase_5.tscn", "res://levels/fase_6.tscn", "res://levels/fase_7.tscn", "res://levels/fase_8.tscn", "res://levels/fase_9.tscn",
]
const SEMENTE := 7
const VIDA_DE_TESTE := 999
const DANO_QUE_MATA := 999
## Quadros para uma morte (a animação do goblin dura ~1,9 s) e para a porta reagir.
const QUADROS_MORTE := 300
const QUADROS_CURTOS := 20
const ULTIMA := 8
const ALTURA_LADRILHO := 32.0
const ATLAS_PLATAFORMA := 2
## Maior buraco (ladrilhos) que dá para atravessar pulando, e colunas ao lado de uma plataforma onde se pode subir.
const MAIOR_BURACO := 3
const VIZINHANCA := 2

var _main: Main
var _jogador: Jogador


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	await _testar_fases_prontas()
	await _testar_alcance_das_fases()
	_main = load("res://levels/main.tscn").instantiate()
	_main.mostrar_inicio = false
	_main.semente_armadilhas = SEMENTE
	root.add_child(_main)
	_jogador = _main.get_node("Jogador")
	(_jogador.get_node("Vida") as HealthComponent).configurar(VIDA_DE_TESTE)
	(_jogador.get_node("Defesa") as DefesaComponent).invulneravel = true
	await _esperar(QUADROS_CURTOS)

	await _testar_porta_barra_e_abre()
	await _testar_vitoria_e_jogar_de_novo()
	_main.queue_free()

	if _falhas == 0:
		print("PASSOU: todos os testes da campanha")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


## Cada fase da campanha: índice certo, porta, pontos de sobra e só a última conclui o jogo.
func _testar_fases_prontas() -> void:
	for i in CENAS_FASE.size():
		var fase: Fase = load(CENAS_FASE[i]).instantiate()
		root.add_child(fase)
		await physics_frame
		var pontos := fase.pontos_armadilha().size()
		_checar(fase.indice == i + 1 and fase.get_node_or_null("Porta") != null, "fase %d: índice %d e porta" % [i + 1, i + 1])
		_checar(fase.quantidade > 0 and pontos > fase.quantidade and not fase.tipos_permitidos.is_empty(),
			"fase %d: %d de %d pontos de armadilha, com tipos permitidos" % [i + 1, fase.quantidade, pontos])
		_checar(fase.ultima == (i == ULTIMA), "fase %d: só a última conclui o jogo" % [i + 1])
		_checar(fase.get_node_or_null("Fundo") != null and not (fase.get_node("Ceu") as CanvasItem).visible, "fase %d: fundo em camadas no lugar do céu liso" % [i + 1])
		fase.queue_free()
		await physics_frame


## O herói alcança tudo: nenhuma subida passa do que o pulo vence, nenhum buraco é largo demais e
## toda plataforma tem chão ou outra plataforma a uma altura que o pulo alcança.
func _testar_alcance_das_fases() -> void:
	var stats: StatsJogador = load("res://data/jogador_padrao.tres")
	var pulo := int(stats.altura_pulo / ALTURA_LADRILHO)
	var subida_maxima := pulo - 1
	for i in CENAS_FASE.size():
		var fase: Fase = load(CENAS_FASE[i]).instantiate()
		root.add_child(fase)
		await physics_frame
		var terreno := fase.get_node("Terreno") as TileMapLayer
		var primeira := int(fase.posicao_inicio().x / ALTURA_LADRILHO)
		var porta := int(fase.posicao_porta().x / ALTURA_LADRILHO)
		var subida := 0
		var buraco := 0
		var maior_buraco := 0
		var anterior := -1
		for x in range(primeira, porta + 1):
			var topo := _topo_solido(terreno, x)
			if topo < 0:
				buraco += 1
				maior_buraco = maxi(maior_buraco, buraco)
				continue
			buraco = 0
			if anterior >= 0:
				subida = maxi(subida, anterior - topo)
			anterior = topo
		_checar(subida <= subida_maxima, "fase %d: a maior subida é de %d ladrilho(s) (o pulo vence %d)" % [i + 1, subida, subida_maxima])
		_checar(maior_buraco <= MAIOR_BURACO, "fase %d: o maior buraco tem %d ladrilho(s) (máximo %d)" % [i + 1, maior_buraco, MAIOR_BURACO])
		var sem_acesso := 0
		for celula in terreno.get_used_cells():
			if terreno.get_cell_atlas_coords(celula).x == ATLAS_PLATAFORMA and not _plataforma_alcancavel(terreno, celula, pulo):
				sem_acesso += 1
		_checar(sem_acesso == 0, "fase %d: toda plataforma tem como subir com o pulo (%d sem acesso)" % [i + 1, sem_acesso])
		fase.queue_free()
		await physics_frame


## Fileira do ladrilho sólido mais alto da coluna (a plataforma de atravessar não conta); -1 = buraco.
func _topo_solido(terreno: TileMapLayer, x: int) -> int:
	var topo := -1
	for celula in terreno.get_used_cells():
		if celula.x == x and terreno.get_cell_atlas_coords(celula).x != ATLAS_PLATAFORMA:
			topo = celula.y if topo < 0 else mini(topo, celula.y)
	return topo


## Há chão (ou outra plataforma) até `pulo` ladrilhos abaixo, nesta coluna ou nas 2 de cada lado?
func _plataforma_alcancavel(terreno: TileMapLayer, celula: Vector2i, pulo: int) -> bool:
	for dx in range(-VIZINHANCA, VIZINHANCA + 1):
		for dy in range(1, pulo + 1):
			var abaixo := Vector2i(celula.x + dx, celula.y + dy)
			if terreno.get_cell_source_id(abaixo) >= 0:
				return true
	return false


func _testar_porta_barra_e_abre() -> void:
	var fase := _fase()
	_checar(fase.indice == 1, "o jogo começa na fase 1")
	var cota := _monstros().size()
	_checar(cota == fase.quantidade, "a fase 1 nasce com a cota de %d inimigo(s)" % fase.quantidade)
	_jogador.posicionar_no_inicio(fase.posicao_porta())
	await _esperar(QUADROS_CURTOS)
	_checar(_fase().indice == 1, "com a cota viva, a porta não abre")
	_main.tirar_criaturas()
	await _esperar(QUADROS_CURTOS)
	_checar(_fase().indice == 2, "tirar a cota na porta libera a fase 2")
	_checar(_jogador.global_position.distance_to(_fase().posicao_inicio()) < 64.0, "o herói nasce no início da fase 2")
	_checar(not _monstros().is_empty(), "a fase 2 sorteia a própria cota")
	for indice_esperado: int in range(3, ULTIMA + 2):
		_main.tirar_criaturas()
		_jogador.posicionar_no_inicio(_fase().posicao_porta())
		await _esperar(QUADROS_CURTOS)
		_checar(_fase().indice == indice_esperado, "a porta leva à fase %d" % indice_esperado)


func _testar_vitoria_e_jogar_de_novo() -> void:
	_checar(_fase().ultima, "entrou na última fase")
	_jogador.posicionar_no_inicio(_fase().posicao_inicio())
	_matar_todos()
	await _esperar(QUADROS_MORTE)
	_jogador.posicionar_no_inicio(_fase().posicao_porta())
	await _esperar(QUADROS_CURTOS)
	var tela := _achar_vitoria()
	_checar(tela != null and paused, "cota zerada na última fase: aparece a vitória e o jogo pausa")
	if tela == null:
		return
	(tela.find_child("JogarDeNovo", true, false) as Button).pressed.emit()
	await _esperar(QUADROS_CURTOS)
	_checar(_fase().indice == 1 and not paused, "Jogar de novo volta à fase 1 e despausa")
	_checar(_jogador.vida_atual() == _jogador.vida_maxima(), "e o herói volta com a vida cheia")


func _fase() -> Fase:
	return _main.get_node("Fase")


func _monstros() -> Array[Node]:
	return get_nodes_in_group(&"monstros").filter(func(m: Node) -> bool: return not m.is_queued_for_deletion())


func _matar_todos() -> void:
	for monstro in _monstros():
		(monstro.get_node("Vida") as HealthComponent).receber_dano(DANO_QUE_MATA)


func _achar_vitoria() -> TelaVitoria:
	for filho in _main.get_node("Interface").get_children():
		if filho is TelaVitoria:
			return filho
	return null


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame
