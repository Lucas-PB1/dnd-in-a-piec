class_name EstadoOoze
extends Estado
## Base dos estados do Gray Ooze: guarda a referência a ele.

var ooze: GrayOoze


func configurar(dono: Node) -> void:
	ooze = dono as GrayOoze
