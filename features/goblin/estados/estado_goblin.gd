class_name EstadoGoblin
extends Estado
## Base dos estados do Goblin: guarda a referência a ele.

var goblin: Goblin


func configurar(dono: Node) -> void:
	goblin = dono as Goblin
