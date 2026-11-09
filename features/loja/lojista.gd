class_name Lojista
extends Area2D
## Banca do lojista no início da fase. Com o herói perto, mostra "E: loja"; apertando "interagir" (E), emite
## `abrir_pedido`. Não conhece o herói nem a tela (signal up): quem monta o jogo abre a tela da loja.
## Detecta qualquer corpo na camada "jogador" (máscara).

## Emitido quando o herói aperta E perto da banca.
signal abrir_pedido
## O herói chegou perto (true) ou se afastou (false): o botão E do toque só aparece perto.
signal perto_mudou(perto: bool)

var _corpos_perto: int = 0

@onready var _aviso: Label = $Aviso


func _ready() -> void:
	_aviso.hide()
	body_entered.connect(func(_corpo: Node2D) -> void: _mudar_perto(1))
	body_exited.connect(func(_corpo: Node2D) -> void: _mudar_perto(-1))


func _unhandled_input(evento: InputEvent) -> void:
	if _corpos_perto > 0 and evento.is_action_pressed("interagir"):
		abrir_pedido.emit()
		get_viewport().set_input_as_handled()


func _mudar_perto(quanto: int) -> void:
	var estava_perto := _corpos_perto > 0
	_corpos_perto += quanto
	_aviso.visible = _corpos_perto > 0
	if (_corpos_perto > 0) != estava_perto:
		perto_mudou.emit(_corpos_perto > 0)
