class_name Inventario
extends RefCounted
## Inventário: lista de itens + o que está equipado em cada espaço. Regra pura.
## Um item equipado continua na lista (marcado como equipado).

## Emitido sempre que algo muda (adicionou, equipou, desequipou, jogou fora).
signal mudou

## Máximo de itens carregados.
var capacidade: int
var itens: Array[Item] = []

var _equipados: Dictionary[StringName, Item] = {}


func _init(capacidade_maxima: int = 12) -> void:
	capacidade = capacidade_maxima


func esta_cheio() -> bool:
	return itens.size() >= capacidade


func adicionar(item: Item) -> bool:
	if item == null or esta_cheio():
		return false
	itens.append(item)
	mudou.emit()
	return true


## Equipa no espaço do item (troca o que estava lá; o antigo continua na lista).
func equipar(item: Item) -> bool:
	if item not in itens or not item.equipavel():
		return false
	_equipados[item.espaco] = item
	mudou.emit()
	return true


func desequipar(espaco: StringName) -> bool:
	if not _equipados.has(espaco):
		return false
	_equipados.erase(espaco)
	mudou.emit()
	return true


## Joga o item fora (some do inventário). Se estava equipado, desequipa antes.
func descartar(item: Item) -> bool:
	if item not in itens:
		return false
	if esta_equipado(item):
		_equipados.erase(item.espaco)
	itens.erase(item)
	mudou.emit()
	return true


## Item equipado no `espaco`, ou null.
func equipado(espaco: StringName) -> Item:
	return _equipados.get(espaco)


func esta_equipado(item: Item) -> bool:
	return item != null and _equipados.get(item.espaco) == item
