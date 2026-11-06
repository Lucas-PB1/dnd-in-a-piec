extends Node2D
## Cena principal: monta o jogo ligando fase, herói e interface (só pelas APIs públicas).
## Começa pela tela de criação do personagem, com o jogo pausado.

const CENA_CRIACAO := preload("res://ui/criacao_personagem/tela_criacao.tscn")

## Abre a tela de criação ao iniciar. Os testes desligam para jogar direto com a sugestão.
@export var mostrar_criacao: bool = true

var _criando_personagem: bool = false

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
	_hud.mostrar_vida(_jogador.vida_atual(), _jogador.vida_maxima())
	_inventario.abrir_pedido.connect(_abrir_inventario)
	if mostrar_criacao:
		_abrir_criacao()


func _abrir_inventario() -> void:
	if _criando_personagem:
		return
	_inventario.abrir(_jogador.inventario, _jogador.ficha, _jogador.vida_atual(),
		_jogador.vida_maxima(), _jogador.ataque_desarmado)


func _abrir_criacao() -> void:
	_criando_personagem = true
	get_tree().paused = true
	var tela: TelaCriacao = CENA_CRIACAO.instantiate()
	tela.classe = _jogador.classe
	tela.arma_previa = _primeira_arma(_jogador.inventario)
	tela.confirmada.connect(_ao_criar_personagem.bind(tela))
	_interface.add_child(tela)


func _ao_criar_personagem(ficha: Ficha, tela: TelaCriacao) -> void:
	_jogador.configurar_ficha(ficha)
	tela.queue_free()
	_criando_personagem = false
	get_tree().paused = false


## Primeira arma da mochila (para a prévia do dano na criação); null se não houver.
func _primeira_arma(inventario: Inventario) -> Arma:
	for item in inventario.itens:
		if item is Arma:
			return item
	return null
