class_name Hud
extends CanvasLayer
## Informações na tela durante o jogo. Por enquanto: pontos de vida.


@onready var _vida: Label = %Vida


## Mostra a vida no formato "PV 12/12".
func mostrar_vida(atual: int, maxima: int) -> void:
	_vida.text = "PV %d/%d" % [atual, maxima]
