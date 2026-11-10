class_name MatilhaDeCriatura
extends RefCounted
## Capacidade de Táticas de Matilha da ficha (`taticas_de_matilha`).
## Usa a regra pura `TaticasDeMatilha` e aliados do grupo (duck typing via `TaticaDeCriatura`).

const GRUPO_PADRAO := &"monstros"

var _criatura: CriaturaRPG


func _init(criatura: CriaturaRPG) -> void:
	_criatura = criatura


static func tem_matilha(criatura: CriaturaRPG) -> bool:
	return criatura.taticas_de_matilha


func tem() -> bool:
	return tem_matilha(_criatura)


## Vantagem se há aliado em pé a até 5 pés do alvo.
func vale(
	alvo: Node2D,
	arvore: SceneTree,
	eu: Node,
	grupo: StringName = GRUPO_PADRAO,
) -> bool:
	if not tem() or alvo == null or arvore == null:
		return false
	var posicoes: Array[Vector2] = []
	for no in TaticaDeCriatura.aliados_em_pe(arvore, eu, grupo):
		posicoes.append((no as Node2D).global_position)
	return TaticasDeMatilha.vale(alvo.global_position, posicoes)
