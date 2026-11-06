extends Node2D
## Cena principal: monta o jogo ligando fase, herói e interface (só pelas APIs públicas).
## Fluxo: tela de título -> criação do personagem -> jogo. Título e criação pausam o jogo.

const CENA_TITULO := preload("res://ui/titulo/tela_titulo.tscn")
const CENA_CRIACAO := preload("res://ui/criacao_personagem/tela_criacao.tscn")

## Começa pelo título e pela criação. Os testes desligam para jogar direto com a sugestão.
@export var mostrar_inicio: bool = true
## Classes que dá para escolher na criação.
@export var classes_disponiveis: Array[ClasseRPG] = []

## True enquanto o título ou a criação estão abertos (o inventário não abre).
var _no_inicio: bool = false

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
	_mostrar_personagem_no_hud()
	_inventario.abrir_pedido.connect(_abrir_inventario)
	if mostrar_inicio:
		_abrir_titulo()


func _abrir_titulo() -> void:
	_pausar_inicio(true)
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


func _ao_criar_personagem(ficha: Ficha, tela: TelaCriacao) -> void:
	_jogador.configurar_ficha(ficha)
	_mostrar_personagem_no_hud()
	tela.queue_free()
	_pausar_inicio(false)


func _abrir_inventario() -> void:
	if _no_inicio:
		return
	_inventario.abrir(_jogador.inventario, _jogador.ficha, _jogador.vida_atual(),
		_jogador.vida_maxima(), _jogador.ataque_desarmado)


## Título e criação pausam o jogo e escondem o HUD (o personagem ainda não existe).
func _pausar_inicio(pausar: bool) -> void:
	_no_inicio = pausar
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
