class_name BlocoQuebravel
extends StaticBody2D
## Bloco de pedra rachado, marcado para quebrar: sólido como o chão até o Minotauro (investida ou glaive) acertá-lo; então
## solta pedaços e some. Os pés ficam na origem, como nas criaturas: o bloco ocupa 32 px acima dela.

## Emitido quando o bloco quebra (a cena, a fase ou um teste pode reagir).
signal quebrado

const TAMANHO := 32.0
## Quanto tempo os pedaços ficam no ar antes de o nó sumir (s).
const TEMPO_DOS_PEDACOS := 0.9

var _quebrado: bool = false

@onready var _visual: Node2D = $Visual
@onready var _colisao: CollisionShape2D = $Colisao
@onready var _pedacos: CPUParticles2D = $Pedacos


func esta_quebrado() -> bool:
	return _quebrado


## Quebra uma vez só: tira do grupo (ninguém mais conta com ele), solta os pedaços e libera o caminho.
func quebrar() -> void:
	if _quebrado:
		return
	_quebrado = true
	remove_from_group(&"quebravel")
	_colisao.set_deferred(&"disabled", true)
	_visual.visible = false
	_pedacos.restart()
	_pedacos.emitting = true
	quebrado.emit()
	await get_tree().create_timer(TEMPO_DOS_PEDACOS).timeout
	queue_free()
