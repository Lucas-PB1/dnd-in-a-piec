class_name HealthComponent
extends Node
## Pontos de vida de uma entidade. Por enquanto só guarda e avisa a vida;
## dano e morte entram com o primeiro inimigo que machuca o herói.

## Emitido quando a vida (atual ou máxima) muda.
signal vida_mudou(atual: int, maxima: int)

var vida_maxima: int = 1
var vida_atual: int = 1


## Define a vida máxima e enche a vida.
func configurar(maxima: int) -> void:
	vida_maxima = maxima
	vida_atual = maxima
	vida_mudou.emit(vida_atual, vida_maxima)
