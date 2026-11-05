extends Node2D
## Cena principal: monta o jogo ligando a fase ao herói (só pelas APIs públicas deles).

@onready var _fase: Fase = $FaseTeste
@onready var _jogador: Jogador = $Jogador


func _ready() -> void:
	_jogador.posicionar_no_inicio(_fase.posicao_inicio())
	_jogador.definir_limites_camera(_fase.area_jogavel())
	_jogador.limite_queda = _fase.limite_queda()
