class_name Bau
extends Area2D
## Baú do arsenal. Com o herói perto, mostra "E: abrir"; apertando "interagir" (E), emite
## `abrir_pedido` com o conteúdo e anima a tampa. Não conhece o herói nem a tela (signal up):
## quem monta o jogo abre a tela do baú e chama `fechar_tampa` ao fechar.

## Emitido quando o herói aperta E perto do baú.
signal abrir_pedido(itens: Array[Item])
## O herói chegou perto do baú (true) ou se afastou (false): o botão E do toque só aparece perto.
signal perto_mudou(perto: bool)

## Pastas cujos .tres de Item formam o conteúdo (o baú nunca esvazia: dá cópias).
@export var pastas: PackedStringArray = ["res://data/armas/", "res://data/armaduras/", "res://data/municoes/", "res://data/itens/"]

var _itens: Array[Item] = []
var _corpos_perto: int = 0
var _aberto: bool = false

@onready var _aviso: Label = $Aviso
@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_aviso.hide()
	_sprite.play(&"fechado")
	_sprite.animation_finished.connect(_ao_terminar_animacao)
	body_entered.connect(func(_corpo: Node2D) -> void: _mudar_perto(1))
	body_exited.connect(func(_corpo: Node2D) -> void: _mudar_perto(-1))
	_itens = carregar_itens(pastas)


func _unhandled_input(evento: InputEvent) -> void:
	if _corpos_perto > 0 and evento.is_action_pressed("interagir"):
		abrir_tampa()
		abrir_pedido.emit(_itens)
		get_viewport().set_input_as_handled()


func itens() -> Array[Item]:
	return _itens


## Todos os Item (.tres) das `pastas`, na ordem dos arquivos.
static func carregar_itens(lista_pastas: PackedStringArray) -> Array[Item]:
	var achados: Array[Item] = []
	for pasta in lista_pastas:
		for recurso in Recursos.da_pasta(pasta):
			if recurso is Item:
				achados.append(recurso)
	return achados


## Abre a tampa (quem monta o jogo chama ao abrir a tela, ou o próprio E).
func abrir_tampa() -> void:
	if _aberto:
		return
	_aberto = true
	_sprite.play(&"abrir")


## Fecha a tampa ao sair da tela do arsenal.
func fechar_tampa() -> void:
	if not _aberto:
		_sprite.play(&"fechado")
		return
	_aberto = false
	_sprite.play(&"fechar")


func _ao_terminar_animacao() -> void:
	if _sprite.animation == &"abrir":
		_sprite.play(&"aberto")
	elif _sprite.animation == &"fechar":
		_sprite.play(&"fechado")


func _mudar_perto(quanto: int) -> void:
	var estava_perto := _corpos_perto > 0
	_corpos_perto += quanto
	_aviso.visible = _corpos_perto > 0
	if (_corpos_perto > 0) != estava_perto:
		perto_mudou.emit(_corpos_perto > 0)
