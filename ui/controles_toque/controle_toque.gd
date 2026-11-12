class_name ControleToque
extends Control
## Base dos controles de toque (botão e analógico): modo de edição do layout e contorno de destaque.

const SEM_DEDO := -1
const CONTORNO := 1.5
## Contorno do selecionado na edição.
const CONTORNO_DESTAQUE := 2.5
const COR_DESTAQUE := Color(1.0, 0.85, 0.3, 0.95)
const SEGMENTOS_ARCO := 40

## Modo de edição do layout: não aperta nada (quem arrasta é o ControlesToque).
var editando: bool = false:
	set(valor):
		editando = valor
		soltar()
## Selecionado na edição: ganha um contorno de destaque.
var destacado: bool = false:
	set(valor):
		destacado = valor
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


## Solta o dedo e as ações. Cada controle implementa o seu.
func soltar() -> void:
	pass


func _raio() -> float:
	return minf(size.x, size.y) / 2.0


func _desenhar_destaque(centro: Vector2) -> void:
	if not destacado:
		return
	draw_arc(centro, _raio() + CONTORNO_DESTAQUE, 0.0, TAU, SEGMENTOS_ARCO, COR_DESTAQUE, CONTORNO_DESTAQUE, true)
