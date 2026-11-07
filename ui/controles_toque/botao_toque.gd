class_name BotaoToque
extends Control
## Botão redondo na tela de toque: o dedo em cima aperta a `acao` do InputMap, como a tecla
## (segurar = segurar; dois toques rápidos = toque duplo). Os eventos também chegam às telas
## que escutam `_unhandled_input`. Vários dedos ao mesmo tempo: cada
## botão guarda o dedo que o apertou. Com o jogo pausado não aperta (há um menu por cima),
## mas solta sempre, para nada ficar preso.

const SEM_DEDO := -1
## Grossura do contorno e tamanho da letra (px da tela de 360 de altura).
const CONTORNO := 1.5
## Contorno do selecionado na edição.
const CONTORNO_DESTAQUE := 2.5
const COR_DESTAQUE := Color(1.0, 0.85, 0.3, 0.95)
const TAMANHO_TEXTO := 9
## Tamanho da seta desenhada, em fração do raio.
const TAMANHO_SETA := 0.45

## Ação apertada (ex.: &"pular").
@export var acao: StringName
## Texto no meio (vazio = só a seta, se houver).
@export var texto: String = ""
## Seta desenhada no meio (Vector2.ZERO = nenhuma), ex.: Vector2.LEFT.
@export var seta: Vector2 = Vector2.ZERO
@export var cor: Color = Color(1.0, 1.0, 1.0, 0.22)
@export var cor_apertado: Color = Color(1.0, 0.92, 0.6, 0.5)
@export var cor_contorno: Color = Color(1.0, 1.0, 1.0, 0.55)
@export var cor_texto: Color = Color(1.0, 1.0, 1.0, 0.9)

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


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(evento: InputEvent) -> void:
	var toque := evento as InputEventScreenTouch
	if toque == null:
		return
	if toque.pressed and _dedo == SEM_DEDO and not editando and is_visible_in_tree() and not get_tree().paused and _contem(toque.position):
		_dedo = toque.index
		_enviar_acao(true)
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif not toque.pressed and toque.index == _dedo:
		soltar()


func esta_apertado() -> bool:
	return _dedo != SEM_DEDO


## Solta a ação (o dedo saiu, ou o botão sumiu).
func soltar() -> void:
	if _dedo == SEM_DEDO:
		return
	_dedo = SEM_DEDO
	_enviar_acao(false)
	queue_redraw()


func _enviar_acao(apertada: bool) -> void:
	if apertada:
		Input.action_press(acao)
	else:
		Input.action_release(acao)
	call_deferred("_propagar_evento_acao", apertada)


func _propagar_evento_acao(apertada: bool) -> void:
	var evento := InputEventAction.new()
	evento.action = acao
	evento.pressed = apertada
	evento.strength = 1.0 if apertada else 0.0
	Input.parse_input_event(evento)


func _notification(qual: int) -> void:
	if qual == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		soltar()


func _raio() -> float:
	return minf(size.x, size.y) / 2.0


func _contem(ponto: Vector2) -> bool:
	return ponto.distance_to(global_position + size / 2.0) <= _raio()


func _draw() -> void:
	var centro := size / 2.0
	draw_circle(centro, _raio(), cor_apertado if esta_apertado() else cor)
	draw_arc(centro, _raio() - CONTORNO / 2.0, 0.0, TAU, 32, cor_contorno, CONTORNO, true)
	if seta != Vector2.ZERO:
		_desenhar_seta(centro)
	if destacado:
		draw_arc(centro, _raio() + CONTORNO_DESTAQUE, 0.0, TAU, 32, COR_DESTAQUE, CONTORNO_DESTAQUE, true)
	if texto != "":
		var fonte := get_theme_default_font()
		var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_CENTER, -1, TAMANHO_TEXTO).x
		var base := centro + Vector2(-largura / 2.0, TAMANHO_TEXTO / 3.0)
		draw_string(fonte, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANHO_TEXTO, cor_texto)


func _desenhar_seta(centro: Vector2) -> void:
	var frente := seta.normalized() * _raio() * TAMANHO_SETA
	var lado := frente.orthogonal() * 0.8
	draw_colored_polygon(PackedVector2Array([centro + frente, centro - frente * 0.6 + lado, centro - frente * 0.6 - lado]), cor_texto)
