class_name HitboxComponent
extends Area2D
## Área que causa dano enquanto está ligada. Cada HurtboxComponent é atingido
## no máximo uma vez por golpe (até ligar() de novo).
## Coloque um CollisionShape2D como filho e ajuste a máscara (ex.: hurtbox_inimigo).

## Emitido a cada alvo atingido.
signal acertou(alvo: HurtboxComponent)

var _dano: int = 0
var _ligada: bool = false
var _atingidos: Array[HurtboxComponent] = []


func _ready() -> void:
	monitorable = false  # ninguém precisa detectar o golpe; ele é quem detecta


## Liga a área com o dano do golpe atual e esquece quem foi atingido no golpe anterior.
func ligar(dano: int) -> void:
	_dano = dano
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
			alvo.receber_golpe(_dano, global_position)
			acertou.emit(alvo)
