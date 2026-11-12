class_name BotaoToque
extends ControleToque
## Botão redondo na tela de toque: o dedo em cima aperta a `acao` do InputMap, como a tecla
## (segurar = segurar; dois toques rápidos = toque duplo). Os eventos também chegam às telas
## que escutam `_unhandled_input`. Vários dedos ao mesmo tempo: cada
## botão guarda o dedo que o apertou. Com o jogo pausado não aperta (há um menu por cima),
## mas solta sempre, para nada ficar preso.

## Grossura do brilho em volta do botão aceso.
const CONTORNO_BRILHO := 4.0
const TAMANHO_TEXTO_MINIMO := 11
const TAMANHO_TEXTO_MAXIMO := 18
## O texto cresce com o botão: fração do raio.
const TEXTO_POR_RAIO := 0.42
## Contorno escuro da letra, para ler sobre qualquer fundo.
const CONTORNO_TEXTO := 3
const COR_CONTORNO_TEXTO := Color(0.1, 0.06, 0.04, 0.85)
## Tamanho da seta desenhada, em fração do raio.
const TAMANHO_SETA := 0.45

## Estado da habilidade no botão: NORMAL (pronta), ACESO (ativa agora: Surto armado, Mente Tática ligada)
## e DESLIGADO (não dá para usar agora: Mente Tática desligada, Surto já usado, sem Fôlego).
enum EstadoBotao { NORMAL, ACESO, DESLIGADO }

## Ação apertada (ex.: &"pular").
@export var acao: StringName
## Texto no meio (vazio = só a seta, se houver).
@export var texto: String = ""
## Seta desenhada no meio (Vector2.ZERO = nenhuma), ex.: Vector2.LEFT.
@export var seta: Vector2 = Vector2.ZERO
@export var cor: Color = Color(1.0, 1.0, 1.0, 0.28)
@export var cor_apertado: Color = Color(1.0, 0.92, 0.6, 0.5)
@export var cor_contorno: Color = Color(1.0, 1.0, 1.0, 0.55)
@export var cor_texto: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var cor_aceso: Color = Color(1.0, 0.82, 0.3, 0.62)
@export var cor_contorno_aceso: Color = Color(1.0, 0.9, 0.5, 1.0)
@export var cor_desligado: Color = Color(0.85, 0.28, 0.28, 0.3)
@export var cor_contorno_desligado: Color = Color(0.9, 0.4, 0.4, 0.55)

var _dedo: int = SEM_DEDO
## Ver EstadoBotao. A interface muda quando a habilidade liga, desliga ou fica indisponível.
var estado: EstadoBotao = EstadoBotao.NORMAL:
	set(valor):
		if estado != valor:
			estado = valor
			queue_redraw()


func _input(evento: InputEvent) -> void:
	var toque := evento as InputEventScreenTouch
	if toque == null:
		return
	if toque.pressed and _dedo == SEM_DEDO and acao != &"" and not editando and is_visible_in_tree() and not get_tree().paused and _contem(toque.position):
		_dedo = toque.index
		_enviar_acao(true)
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif not toque.pressed and toque.index == _dedo:
		soltar()


func esta_apertado() -> bool:
	return _dedo != SEM_DEDO


## Troca o que o botão faz (ex.: o de ataque vira "Abrir" perto de um baú). Solta a ação antes.
func trocar_funcao(nova_acao: StringName, novo_texto: String) -> void:
	if nova_acao == acao and novo_texto == texto:
		return
	soltar()
	acao = nova_acao
	texto = novo_texto
	queue_redraw()


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


func _contem(ponto: Vector2) -> bool:
	return ponto.distance_to(global_position + size / 2.0) <= _raio()


func _draw() -> void:
	var centro := size / 2.0
	draw_circle(centro, _raio(), cor_apertado if esta_apertado() else _cor_do_estado())
	if estado == EstadoBotao.ACESO:
		draw_arc(centro, _raio() + CONTORNO_BRILHO / 2.0, 0.0, TAU, 32, Color(cor_contorno_aceso, 0.45), CONTORNO_BRILHO, true)
	draw_arc(centro, _raio() - CONTORNO / 2.0, 0.0, TAU, 32, _cor_do_contorno(), CONTORNO, true)
	if seta != Vector2.ZERO:
		_desenhar_seta(centro)
	_desenhar_destaque(centro)
	if texto != "":
		var fonte := get_theme_default_font()
		var tamanho := _tamanho_texto()
		var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_CENTER, -1, tamanho).x
		var base := centro + Vector2(-largura / 2.0, tamanho / 3.0)
		draw_string_outline(fonte, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, CONTORNO_TEXTO, COR_CONTORNO_TEXTO)
		draw_string(fonte, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor_texto)


func _tamanho_texto() -> int:
	return clampi(int(_raio() * TEXTO_POR_RAIO), TAMANHO_TEXTO_MINIMO, TAMANHO_TEXTO_MAXIMO)


func _cor_do_estado() -> Color:
	match estado:
		EstadoBotao.ACESO:
			return cor_aceso
		EstadoBotao.DESLIGADO:
			return cor_desligado
	return cor


func _cor_do_contorno() -> Color:
	match estado:
		EstadoBotao.ACESO:
			return cor_contorno_aceso
		EstadoBotao.DESLIGADO:
			return cor_contorno_desligado
	return cor_contorno


func _desenhar_seta(centro: Vector2) -> void:
	var frente := seta.normalized() * _raio() * TAMANHO_SETA
	var lado := frente.orthogonal() * 0.8
	draw_colored_polygon(PackedVector2Array([centro + frente, centro - frente * 0.6 + lado, centro - frente * 0.6 - lado]), cor_texto)
