class_name HitboxComponent
extends Area2D
## Área que entrega um Golpe enquanto está ligada. Como no D&D, um ataque tem UM alvo: o
## golpe vai para o mais perto de quem ataca entre os que tocam a área. Maestria Trespassar:
## se o golpe acertou o 1º, um 2º alvo perto dele recebe `golpe.trespassar`. Cada
## HurtboxComponent recebe no máximo um golpe por ligar(). Quem foi atingido resolve o
## ataque contra a própria CA. Coloque um CollisionShape2D como filho e ajuste a máscara.

## Trespassar: o 2º alvo tem de estar a até 5 pés do 1º. Medido entre os centros: 5 pés de
## espaço + 5 pés do tamanho de uma criatura Média = 10 pés (px).
const DISTANCIA_TRESPASSAR := 10.0 * EscalaDnd.PIXELS_POR_LADRILHO / EscalaDnd.PES_POR_LADRILHO

## Emitido quando o golpe é entregue a um alvo (ex.: a arma arremessada cai ali).
signal alvo_atingido(alvo: HurtboxComponent)
## Emitido quando a área liga com um golpe novo (o som do golpe das criaturas escuta isto).
signal ligada(golpe: Golpe)

## Golpe de área (sopro, linha de ácido): entrega a TODOS que tocam a área, não só ao mais perto.
@export var atinge_todos: bool = false
## Hurtbox do próprio dono, que a área nunca atinge (para áreas que pegam também as criaturas aliadas).
@export var ignorar: HurtboxComponent

var _golpe: Golpe
var _ligada: bool = false
var _atingidos: Array[HurtboxComponent] = []


func _ready() -> void:
	monitorable = false  # ninguém precisa detectar o golpe; ele é quem detecta


## Liga a área com o `golpe` atual e esquece quem foi atingido no golpe anterior.
func ligar(golpe: Golpe) -> void:
	_golpe = golpe
	_ligada = true
	_atingidos.clear()
	ligada.emit(golpe)


func desligar() -> void:
	_ligada = false


func esta_ligada() -> bool:
	return _ligada


func _physics_process(_delta: float) -> void:
	if not _ligada:
		return
	var candidatos := _alvos_novos()
	if candidatos.is_empty():
		return
	if atinge_todos:
		for alvo in candidatos:
			_entregar(alvo, _golpe)
	elif _atingidos.is_empty():
		_entregar(candidatos[0], _golpe)
	elif _atingidos.size() == 1 and _golpe.trespassar and _golpe.acertou_algum:
		_tentar_trespassar(candidatos)


## Hurtboxes tocando a área que ainda não receberam nada, da mais perto à mais longe.
func _alvos_novos() -> Array[HurtboxComponent]:
	var alvos: Array[HurtboxComponent] = []
	for area in get_overlapping_areas():
		var alvo := area as HurtboxComponent
		if alvo and alvo != ignorar and alvo not in _atingidos:
			alvos.append(alvo)
	alvos.sort_custom(func(a: HurtboxComponent, b: HurtboxComponent) -> bool:
		return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
	return alvos


func _tentar_trespassar(candidatos: Array[HurtboxComponent]) -> void:
	var primeiro := _atingidos[0]
	for alvo in candidatos:
		if alvo.global_position.distance_to(primeiro.global_position) <= DISTANCIA_TRESPASSAR:
			_entregar(alvo, _golpe.trespassar)
			return


func _entregar(alvo: HurtboxComponent, golpe: Golpe) -> void:
	_atingidos.append(alvo)
	alvo.receber_golpe(golpe, global_position)
	alvo_atingido.emit(alvo)
