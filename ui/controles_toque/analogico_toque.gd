class_name AnalogicoToque
extends Control
## Analógico virtual: o dedo arrasta o pino dentro do círculo. Para o lado anda; até a
## borda corre ("correr"); para cima mira para cima no tiro ("mirar_cima", não pula); para
## baixo abaixa ("mover_baixo"). Aperta as ações do InputMap, como as teclas.

const SEM_DEDO := -1
const CONTORNO := 1.5
## Contorno do selecionado na edição.
const CONTORNO_DESTAQUE := 2.5
const COR_DESTAQUE := Color(1.0, 0.85, 0.3, 0.95)
## O toque que começa até esta fração além do círculo ainda pega o analógico.
const FOLGA_TOQUE := 1.3
## Tamanho do pino, em fração do raio.
const RAIO_PINO := 0.42

const ACAO_DIREITA := &"mover_direita"
const ACAO_ESQUERDA := &"mover_esquerda"
const ACAO_CORRER := &"correr"
const ACAO_CIMA := &"mirar_cima"
const ACAO_BAIXO := &"mover_baixo"

## Menos que isto (fração do raio) não anda.
@export var zona_morta: float = 0.25
## A partir daqui (fração do raio, na horizontal) corre.
@export var zona_corrida: float = 0.85
## Inclinação vertical (fração do raio) que mira para cima ou abaixa.
@export var limiar_vertical: float = 0.55
@export var cor_base: Color = Color(1.0, 1.0, 1.0, 0.16)
@export var cor_contorno: Color = Color(1.0, 1.0, 1.0, 0.5)
@export var cor_pino: Color = Color(1.0, 1.0, 1.0, 0.55)
@export var cor_corrida: Color = Color(1.0, 0.85, 0.45, 0.7)

var _dedo: int = SEM_DEDO
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
## Onde está o pino (comprimento até 1).
var _vetor: Vector2 = Vector2.ZERO
var _apertadas: Dictionary[StringName, bool] = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch:
		var toque := evento as InputEventScreenTouch
		if toque.pressed and _dedo == SEM_DEDO and not editando and is_visible_in_tree() and not get_tree().paused and _pega(toque.position):
			_dedo = toque.index
			_mover_pino(toque.position)
			get_viewport().set_input_as_handled()
		elif not toque.pressed and toque.index == _dedo:
			soltar()
	elif evento is InputEventScreenDrag:
		var arrasto := evento as InputEventScreenDrag
		if arrasto.index == _dedo:
			_mover_pino(arrasto.position)
			get_viewport().set_input_as_handled()


## Vetor do pino (-1 a 1 em cada eixo; comprimento até 1). Para testes e para quem desenha.
func vetor() -> Vector2:
	return _vetor


## Solta o pino e todas as ações.
func soltar() -> void:
	_dedo = SEM_DEDO
	_vetor = Vector2.ZERO
	_aplicar()


func _notification(qual: int) -> void:
	if qual == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		soltar()


func _raio() -> float:
	return minf(size.x, size.y) / 2.0


func _centro() -> Vector2:
	return global_position + size / 2.0


func _pega(ponto: Vector2) -> bool:
	return ponto.distance_to(_centro()) <= _raio() * FOLGA_TOQUE


func _mover_pino(ponto: Vector2) -> void:
	_vetor = ((ponto - _centro()) / _raio()).limit_length(1.0)
	_aplicar()


func _aplicar() -> void:
	_definir(ACAO_DIREITA, _vetor.x > zona_morta)
	_definir(ACAO_ESQUERDA, _vetor.x < -zona_morta)
	_definir(ACAO_CORRER, absf(_vetor.x) >= zona_corrida)
	_definir(ACAO_CIMA, _vetor.y < -limiar_vertical)
	_definir(ACAO_BAIXO, _vetor.y > limiar_vertical)
	queue_redraw()


func _definir(acao: StringName, ligada: bool) -> void:
	if ligada == _apertadas.get(acao, false):
		return
	_apertadas[acao] = ligada
	if ligada:
		Input.action_press(acao)
	else:
		Input.action_release(acao)


func _draw() -> void:
	var centro := size / 2.0
	draw_circle(centro, _raio(), cor_base)
	var borda := cor_corrida if _apertadas.get(ACAO_CORRER, false) else cor_contorno
	draw_arc(centro, _raio() - CONTORNO / 2.0, 0.0, TAU, 40, borda, CONTORNO, true)
	draw_circle(centro + _vetor * _raio() * (1.0 - RAIO_PINO), _raio() * RAIO_PINO, cor_pino)
	if destacado:
		draw_arc(centro, _raio() + CONTORNO_DESTAQUE, 0.0, TAU, 40, COR_DESTAQUE, CONTORNO_DESTAQUE, true)
