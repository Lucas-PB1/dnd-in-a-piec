class_name Main
extends Node2D
## Cena principal: monta o jogo ligando fase, herói e interface (só pelas APIs públicas).
## Fluxo: tela de título -> criação do personagem -> jogo. Título, criação e "Você caiu!"
## pausam o jogo.

const CENA_TITULO := preload("res://ui/titulo/tela_titulo.tscn")
const CENA_CRIACAO := preload("res://ui/criacao_personagem/tela_criacao.tscn")
const CENA_DERROTA := preload("res://ui/derrota/tela_derrota.tscn")
const CENA_ARREMESSO := preload("res://features/arremesso/arma_arremessada.tscn")
const CENA_OOZE := preload("res://features/gray_ooze/gray_ooze.tscn")
const CENA_GOBLIN := preload("res://features/goblin/goblin.tscn")
const CENA_GOBLIN_GUERREIRO := preload("res://features/goblin/goblin_guerreiro.tscn")
const GRUPO_MONSTROS := &"monstros"
## Onde a criatura trazida pela tela de comandos nasce, à frente do herói (pés).
const DISTANCIA_CRIATURA_PES := 15.0

## Começa pelo título e pela criação. Os testes desligam para jogar direto com a sugestão.
@export var mostrar_inicio: bool = true
## Classes que dá para escolher na criação.
@export var classes_disponiveis: Array[ClasseRPG] = []

## True enquanto uma tela de pausa está aberta (título, criação, derrota): o inventário não abre.
var _em_tela_de_pausa: bool = false
## Como cada monstro começou (cena e posição), para recriar a luta em "Tentar de novo".
var _monstros_iniciais: Array[Dictionary] = []

@onready var _fase: Fase = $FaseTeste
@onready var _jogador: Jogador = $Jogador
@onready var _hud: Hud = $Hud
@onready var _interface: CanvasLayer = $Interface
@onready var _inventario: TelaInventario = $Interface/TelaInventario
@onready var _bau: Bau = $Bau
@onready var _tela_bau: TelaBau = $Interface/TelaBau
@onready var _comandos: TelaComandos = $Interface/TelaComandos
@onready var _controles_toque: ControlesToque = $ControlesToque


func _ready() -> void:
	Comandos.carregar()
	OpcoesToque.carregar()
	_jogador.posicionar_no_inicio(_fase.posicao_inicio())
	_jogador.definir_limites_camera(_fase.area_jogavel())
	_jogador.limite_queda = _fase.limite_queda()
	_jogador.vida_mudou.connect(_hud.mostrar_vida)
	_jogador.folego_mudou.connect(_hud.mostrar_folego)
	_jogador.caiu.connect(_ao_cair)
	_mostrar_personagem_no_hud()
	_inventario.abrir_pedido.connect(_abrir_inventario)
	_bau.abrir_pedido.connect(_abrir_bau)
	_comandos.abrir_pedido.connect(_abrir_comandos)
	_comandos.trazer_pedido.connect(trazer_criatura)
	_comandos.tirar_pedido.connect(tirar_criaturas)
	_comandos.opcoes_toque_mudaram.connect(_controles_toque.atualizar)
	_comandos.editar_toque_pedido.connect(_editar_toque)
	_controles_toque.edicao_terminada.connect(func() -> void: get_tree().paused = false)
	_comandos.definir_criaturas(PackedStringArray(["Gray Ooze", "Goblin Minion", "Goblin Warrior"]), _cenas_criaturas())
	_jogador.arma_arremessada.connect(_ao_arremessar)
	_guardar_monstros_iniciais()
	_apontar_monstros_para(_jogador)
	if mostrar_inicio:
		_abrir_titulo()


# --- Início -----------------------------------------------------------------------

func _abrir_titulo() -> void:
	_pausar(true)
	var titulo: TelaTitulo = CENA_TITULO.instantiate()
	titulo.novo_jogo_escolhido.connect(_ao_escolher_novo_jogo.bind(titulo))
	titulo.sair_escolhido.connect(get_tree().quit)
	_interface.add_child(titulo)


func _ao_escolher_novo_jogo(titulo: TelaTitulo) -> void:
	titulo.queue_free()
	_abrir_criacao()


func _abrir_criacao() -> void:
	var tela: TelaCriacao = CENA_CRIACAO.instantiate()
	if not classes_disponiveis.is_empty():
		tela.classes = classes_disponiveis
	tela.arma_previa = _jogador.ataque_desarmado
	tela.confirmada.connect(_ao_criar_personagem.bind(tela))
	_interface.add_child(tela)


func _ao_criar_personagem(ficha: Ficha, pacote: PacoteInicial, tela: TelaCriacao) -> void:
	_jogador.configurar_ficha(ficha)
	_jogador.receber_pacote(pacote)
	_mostrar_personagem_no_hud()
	tela.queue_free()
	_pausar(false)


# --- Derrota ----------------------------------------------------------------------

func _ao_cair() -> void:
	_pausar(true)
	var tela: TelaDerrota = CENA_DERROTA.instantiate()
	tela.tentar_de_novo_escolhido.connect(_tentar_de_novo.bind(tela))
	_interface.add_child(tela)
	tela.mostrar_personagem(_jogador.ficha.nome, _jogador.ficha.classe.nome)


## Recomeça a luta: herói no início com vida cheia e monstros de volta, como no começo.
func _tentar_de_novo(tela: TelaDerrota) -> void:
	tela.queue_free()
	_jogador.reviver()
	_recriar_monstros()
	_pausar(false)


func _guardar_monstros_iniciais() -> void:
	for monstro in get_tree().get_nodes_in_group(GRUPO_MONSTROS):
		_monstros_iniciais.append({"cena": load(monstro.scene_file_path), "posicao": monstro.position})


func _recriar_monstros() -> void:
	for monstro in get_tree().get_nodes_in_group(GRUPO_MONSTROS):
		monstro.free()
	for inicial in _monstros_iniciais:
		var monstro: Node2D = (inicial["cena"] as PackedScene).instantiate()
		monstro.position = inicial["posicao"]
		monstro.add_to_group(GRUPO_MONSTROS)
		add_child(monstro)
	_apontar_monstros_para(_jogador)


## Todo nó do grupo "monstros" persegue o herói (cada monstro tem definir_alvo()).
func _apontar_monstros_para(alvo: Node2D) -> void:
	for monstro in get_tree().get_nodes_in_group(GRUPO_MONSTROS):
		monstro.definir_alvo(alvo)


## Cenas da lista "Trazer" da tela de comandos, na ordem dos nomes.
func _cenas_criaturas() -> Array[PackedScene]:
	var cenas: Array[PackedScene] = [CENA_OOZE, CENA_GOBLIN, CENA_GOBLIN_GUERREIRO]
	return cenas


# --- Interface --------------------------------------------------------------------

func _abrir_inventario() -> void:
	if _em_tela_de_pausa or _controles_toque.esta_editando() or _tela_bau.visible or _comandos.visible:
		return
	_inventario.abrir(_jogador.inventario, _jogador.ficha, _jogador.vida_atual(),
		_jogador.vida_maxima(), _jogador.ataque_desarmado)


func _ao_arremessar(arma: Arma, golpe: Golpe, penalidade: int, origem: Vector2, direcao: int, forca: float, mira: float, municao: Municao, ignora_alcance_longo: bool, destreza: int) -> void:
	var voo: ArmaArremessada = CENA_ARREMESSO.instantiate()
	if municao == null:
		voo.recolhida.connect(_ao_recolher_arma.bind(voo))
		voo.derreteu.connect(_jogador.avisar)
	add_child(voo)
	voo.global_position = origem
	voo.lancar(arma, golpe, penalidade, direcao, forca, mira, municao, ignora_alcance_longo, destreza)


func _ao_recolher_arma(arma: Arma, penalidade: int, voo: ArmaArremessada) -> void:
	if _jogador.recolher_arma(arma, penalidade):
		voo.queue_free()
	else:
		voo.avisar_cheia()


func _abrir_bau(itens: Array[Item]) -> void:
	if _em_tela_de_pausa or _controles_toque.esta_editando() or _inventario.visible or _comandos.visible:
		return
	_tela_bau.abrir(itens, _jogador.inventario)


func _abrir_comandos() -> void:
	if _em_tela_de_pausa or _controles_toque.esta_editando() or _inventario.visible or _tela_bau.visible:
		return
	_comandos.abrir()


## Ajustar os controles de toque: o jogo fica pausado até o Pronto.
func _editar_toque() -> void:
	get_tree().paused = true
	_controles_toque.editar()


## Põe uma cópia da criatura à frente do herói. Não entra na lista do "Tentar de novo".
func trazer_criatura(cena: PackedScene) -> void:
	if cena == null:
		return
	var monstro: Node2D = cena.instantiate()
	monstro.add_to_group(GRUPO_MONSTROS)
	add_child(monstro)
	var frente := Vector2(EscalaDnd.pes_para_pixels(DISTANCIA_CRIATURA_PES) * _jogador.direcao_olhar, 0.0)
	monstro.global_position = _jogador.global_position + frente
	if monstro.has_method(&"definir_alvo"):
		monstro.call(&"definir_alvo", _jogador)


## Apaga os monstros que estão na fase (os do mapa e os trazidos).
func tirar_criaturas() -> void:
	var presentes := get_tree().get_nodes_in_group(GRUPO_MONSTROS)
	for monstro in presentes:
		monstro.free()


## Telas de pausa (título, criação, derrota) param o jogo e escondem o HUD.
func _pausar(pausar: bool) -> void:
	_em_tela_de_pausa = pausar
	get_tree().paused = pausar
	_hud.visible = not pausar
	_controles_toque.atualizar(pausar)


func _mostrar_personagem_no_hud() -> void:
	_hud.mostrar_personagem(_jogador.ficha.nome, _jogador.ficha.classe.nome)
	_hud.mostrar_vida(_jogador.vida_atual(), _jogador.vida_maxima())
	_hud.mostrar_folego(_jogador.usos_folego(), _jogador.usos_folego_total())

