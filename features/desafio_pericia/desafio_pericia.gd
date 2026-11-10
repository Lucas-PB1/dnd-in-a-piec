class_name DesafioPericia
extends Node2D
## Obstáculo que pede um teste de perícia (E perto). Não conhece o herói: emite o pedido e a
## `main` rola; depois chama `concluir(passou)`. Sucesso remove o bloqueio uma vez.

## Herói apertou E perto: a main rola e devolve o resultado em `concluir`.
signal teste_pedido(desafio: DesafioPericia)
## Herói chegou perto (true) ou saiu (false): o botão de toque só aparece perto.
signal perto_mudou(perto: bool)
## Resultado já aplicado (para testes e feedback).
signal resolvido(passou: bool)

const TAMANHO_BLOCO := 32.0
## Segundos até poder tentar de novo depois de falhar.
const RECARGA_FALHA_S := 1.0

@export var pericia: StringName = Pericia.ATLETISMO
@export var cd: int = 12
@export var rotulo: String = "Empurrar"
@export_multiline var aviso_sucesso: String = "Conseguiu!"
@export_multiline var aviso_falha: String = "Não foi desta vez"

var _corpos_perto: int = 0
var _resolvido: bool = false
var _recarga: float = 0.0

@onready var _aviso: Label = $Aviso
@onready var _colisao: CollisionShape2D = $Bloqueio/Colisao
@onready var _visual: ColorRect = $Visual
@onready var _area: Area2D = $Area


func _ready() -> void:
	_aviso.hide()
	_aviso.text = "E: %s" % rotulo
	_area.body_entered.connect(func(_c: Node2D) -> void: _mudar_perto(1))
	_area.body_exited.connect(func(_c: Node2D) -> void: _mudar_perto(-1))


func _process(delta: float) -> void:
	_recarga = maxf(_recarga - delta, 0.0)


func _unhandled_input(evento: InputEvent) -> void:
	if _resolvido or _recarga > 0.0 or _corpos_perto <= 0:
		return
	if evento.is_action_pressed(&"interagir"):
		teste_pedido.emit(self)
		get_viewport().set_input_as_handled()


func pericia_do_teste() -> StringName:
	return pericia


func cd_do_teste() -> int:
	return cd


func esta_resolvido() -> bool:
	return _resolvido


## A main chama depois de `Jogador.rolar_teste_pericia`.
func concluir(passou: bool) -> void:
	if _resolvido:
		return
	if not passou:
		_recarga = RECARGA_FALHA_S
		resolvido.emit(false)
		return
	_resolvido = true
	_colisao.set_deferred(&"disabled", true)
	_visual.visible = false
	_aviso.hide()
	if _corpos_perto > 0:
		perto_mudou.emit(false)
		_corpos_perto = 0
	resolvido.emit(true)


func _mudar_perto(quanto: int) -> void:
	if _resolvido:
		return
	var estava := _corpos_perto > 0
	_corpos_perto += quanto
	_aviso.visible = _corpos_perto > 0
	if (_corpos_perto > 0) != estava:
		perto_mudou.emit(_corpos_perto > 0)
