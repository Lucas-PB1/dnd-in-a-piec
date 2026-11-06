class_name ArmaArremessada
extends CharacterBody2D
## Arma arremessada. Voa num arco, acerta com o Golpe e cai no chão. Perto dela, E recolhe.
## Não conhece o herói: emite sinais e quem monta o jogo guarda a arma de volta.

## Emitido quando o herói aperta E com a arma no chão.
signal recolhida(arma: Arma, penalidade: int)
## A arma não mágica chegou no limite de corrosão no voo e se desfez.
signal derreteu(texto: String)

## Gravidade do arco (px/s²).
const GRAVIDADE := 980.0
## Tempo para cruzar a distância longa (s). A normal fica no meio do caminho.
const TEMPO_DE_VOO := 0.45
## Impulso para cima no lançamento (px/s).
const IMPULSO := -90.0
const AVISO_PEGAR := "E: pegar"
const AVISO_CHEIA := "Mochila cheia"

var _arma: Arma
var _golpe: Golpe
var _penalidade: int = 0
var _origem_x: float = 0.0
var _normal_px: float = 1.0
var _longo_px: float = 1.0
var _voando: bool = false
var _perto: bool = false

@onready var _sprite: Sprite2D = $Sprite
@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _aviso: Label = $Aviso
@onready var _perto_area: Area2D = $Perto


func _ready() -> void:
	_aviso.hide()
	_perto_area.body_entered.connect(func(_corpo: Node2D) -> void: _perto = true)
	_perto_area.body_exited.connect(func(_corpo: Node2D) -> void: _perto = false)


## Começa o voo. Chamar depois de entrar na árvore (a posição já é a da mão).
func lancar(arma: Arma, golpe: Golpe, penalidade: int, direcao: int) -> void:
	_arma = arma
	_golpe = golpe
	_penalidade = penalidade
	_origem_x = global_position.x
	_normal_px = EscalaDnd.pes_para_pixels(arma.arremesso_normal_pes)
	_longo_px = EscalaDnd.pes_para_pixels(arma.arremesso_longo_pes)
	_preparar_sprite(arma, direcao)
	velocity = Vector2(direcao * _longo_px / TEMPO_DE_VOO, IMPULSO)
	_voando = true
	_hitbox.ligar(golpe)
	if not golpe.arma_corroida.is_connected(_ao_corroer):
		golpe.arma_corroida.connect(_ao_corroer)


func esta_no_chao() -> bool:
	return not _voando


func em_desvantagem() -> bool:
	return _golpe != null and _golpe.desvantagem


func _physics_process(delta: float) -> void:
	if not _voando:
		return
	velocity.y += GRAVIDADE * delta
	_aplicar_alcance()
	move_and_slide()
	_sprite.rotation += delta * 12.0
	if is_on_floor():
		_pousar()


func _unhandled_input(evento: InputEvent) -> void:
	if _voando or not _perto or not evento.is_action_pressed("interagir"):
		return
	recolhida.emit(_arma, _penalidade)
	get_viewport().set_input_as_handled()


## A mochila não coube: a arma fica no chão.
func avisar_cheia() -> void:
	_aviso.text = AVISO_CHEIA


func _preparar_sprite(arma: Arma, direcao: int) -> void:
	DesenhoArma.preparar(_sprite, arma)
	_sprite.scale = Vector2(direcao, 1.0)
	_sprite.rotation_degrees = DesenhoArma.rotacao(arma, 0.0)


## Além da distância normal, o ataque (já rolado no acerto) tem desvantagem.
## Além da longa, a arma só cai: não acerta mais.
func _aplicar_alcance() -> void:
	var dist := absf(global_position.x - _origem_x)
	if _golpe and dist > _normal_px:
		_golpe.desvantagem = true
	if dist >= _longo_px:
		_hitbox.desligar()
		velocity.x = 0.0


func _pousar() -> void:
	_voando = false
	velocity = Vector2.ZERO
	_hitbox.desligar()
	_sprite.rotation_degrees = 80.0
	_aviso.text = AVISO_PEGAR
	_aviso.show()


func _ao_corroer(quanto: int, limite: int) -> void:
	_penalidade += quanto
	if _penalidade >= limite and _arma:
		derreteu.emit("%s derreteu!" % _arma.nome)
		queue_free()
