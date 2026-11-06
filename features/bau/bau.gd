class_name Bau
extends Area2D
## Baú do arsenal. Com o herói perto, mostra "E: abrir"; apertando "interagir" (E), emite
## `abrir_pedido` com o conteúdo. Não conhece o herói nem a tela (signal up): quem monta o
## jogo abre a tela do baú. Detecta qualquer corpo na camada "jogador" (máscara).

## Emitido quando o herói aperta E perto do baú.
signal abrir_pedido(itens: Array[Item])

## Pastas cujos .tres de Item formam o conteúdo (o baú nunca esvazia: dá cópias).
@export var pastas: PackedStringArray = ["res://data/armas/", "res://data/armaduras/", "res://data/municoes/"]

var _itens: Array[Item] = []
var _corpos_perto: int = 0

@onready var _aviso: Label = $Aviso


func _ready() -> void:
	_aviso.hide()
	body_entered.connect(func(_corpo: Node2D) -> void: _mudar_perto(1))
	body_exited.connect(func(_corpo: Node2D) -> void: _mudar_perto(-1))
	_itens = carregar_itens(pastas)


func _unhandled_input(evento: InputEvent) -> void:
	if _corpos_perto > 0 and evento.is_action_pressed("interagir"):
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


func _mudar_perto(quanto: int) -> void:
	_corpos_perto += quanto
	_aviso.visible = _corpos_perto > 0
