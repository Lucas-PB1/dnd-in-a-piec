class_name HitboxComponent
extends Area2D
## Área que entrega um Golpe enquanto está ligada. Cada HurtboxComponent recebe o golpe
## no máximo uma vez por ligar(). Quem foi atingido resolve o ataque contra a própria CA.
## Coloque um CollisionShape2D como filho e ajuste a máscara (ex.: hurtbox_inimigo).

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


func desligar() -> void:
	_ligada = false


func esta_ligada() -> bool:
	return _ligada


func _physics_process(_delta: float) -> void:
	if not _ligada:
		return
	for area in get_overlapping_areas():
		var alvo := area as HurtboxComponent
		if alvo and alvo not in _atingidos:
			_atingidos.append(alvo)
			alvo.receber_golpe(_golpe, global_position)
