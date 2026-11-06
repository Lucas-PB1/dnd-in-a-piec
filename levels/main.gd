extends Node2D
## Cena principal: monta o jogo ligando fase, herói e interface (só pelas APIs públicas).
## Fluxo: tela de título -> criação do personagem -> jogo. Título, criação e "Você caiu!"
## pausam o jogo.

const CENA_TITULO := preload("res://ui/titulo/tela_titulo.tscn")
const CENA_CRIACAO := preload("res://ui/criacao_personagem/tela_criacao.tscn")
const CENA_DERROTA := preload("res://ui/derrota/tela_derrota.tscn")
const GRUPO_MONSTROS := &"monstros"

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


func _ready() -> void:
	_jogador.posicionar_no_inicio(_fase.posicao_inicio())
	_jogador.definir_limites_camera(_fase.area_jogavel())
	_jogador.limite_queda = _fase.limite_queda()
	_jogador.vida_mudou.connect(_hud.mostrar_vida)
	_jogador.caiu.connect(_ao_cair)
	_mostrar_personagem_no_hud()
	_inventario.abrir_pedido.connect(_abrir_inventario)
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
	tela.arma_previa = _primeira_arma(_jogador.inventario)
	tela.confirmada.connect(_ao_criar_personagem.bind(tela))
	_interface.add_child(tela)


func _ao_criar_personagem(ficha: Ficha, armadura: Armadura, tela: TelaCriacao) -> void:
	_jogador.configurar_ficha(ficha)
	_jogador.vestir_armadura_inicial(armadura)
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


# --- Interface --------------------------------------------------------------------

func _abrir_inventario() -> void:
	if _em_tela_de_pausa:
		return
	_inventario.abrir(_jogador.inventario, _jogador.ficha, _jogador.vida_atual(),
		_jogador.vida_maxima(), _jogador.ataque_desarmado)


## Telas de pausa (título, criação, derrota) param o jogo e escondem o HUD.
func _pausar(pausar: bool) -> void:
	_em_tela_de_pausa = pausar
	get_tree().paused = pausar
	_hud.visible = not pausar


func _mostrar_personagem_no_hud() -> void:
	_hud.mostrar_personagem(_jogador.ficha.nome, _jogador.ficha.classe.nome)
	_hud.mostrar_vida(_jogador.vida_atual(), _jogador.vida_maxima())


## Primeira arma da mochila (para a prévia do dano na criação); null se não houver.
func _primeira_arma(inventario: Inventario) -> Arma:
	for item in inventario.itens:
		if item is Arma:
			return item
	return null
