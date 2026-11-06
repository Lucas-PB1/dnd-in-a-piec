class_name Inventario
extends RefCounted
## Inventário: lista de itens + o que está equipado em cada espaço. Regra pura.
## Um item equipado continua na lista (marcado como equipado). Itens empilháveis iguais
## (ex.: Azagaia) ocupam 1 lugar com uma quantidade. Um item pode ocupar mais de um espaço
## (arma de Duas Mãos ocupa a mão secundária): equipar tira o que estiver no caminho.

## Emitido sempre que algo muda (adicionou, equipou, desequipou, jogou fora).
signal mudou

## Máximo de lugares na mochila (uma pilha ocupa 1).
var capacidade: int
var itens: Array[Item] = []

var _equipados: Dictionary[StringName, Item] = {}
## Desgaste de cada item (ex.: Corrosão): penalidade no ataque.
var _penalidades: Dictionary[Item, int] = {}
## Quantidade de cada pilha (itens fora daqui valem 1).
var _quantidades: Dictionary[Item, int] = {}


func _init(capacidade_maxima: int = 12) -> void:
	capacidade = capacidade_maxima


func esta_cheio() -> bool:
	return itens.size() >= capacidade


## Põe `quantidade` unidades do item. Empilhável igual a um que já está aqui soma na pilha.
func adicionar(item: Item, quantidade: int = 1) -> bool:
	if item == null or quantidade < 1 or (quantidade > 1 and not item.empilhavel):
		return false
	var pilha := _pilha_de(item)
	if pilha:
		_quantidades[pilha] = quantidade_de(pilha) + quantidade
	elif esta_cheio():
		return false
	else:
		itens.append(item)
		if quantidade > 1:
			_quantidades[item] = quantidade
	mudou.emit()
	return true


## Quantas unidades há no lugar do item (1 se não for pilha).
func quantidade_de(item: Item) -> int:
	return _quantidades.get(item, 1) if item in itens else 0


## Esvazia tudo (ex.: o herói recebe o pacote inicial).
func limpar() -> void:
	itens.clear()
	_equipados.clear()
	_penalidades.clear()
	_quantidades.clear()
	mudou.emit()


## Equipa no espaço do item. Tudo que ocupava algum dos espaços dele é desequipado
## (continua na lista): ex.: Espada Grande tira o escudo; escudo tira a Espada Grande.
func equipar(item: Item) -> bool:
	if item not in itens or not item.equipavel():
		return false
	for espaco in item.espacos_ocupados():
		var ocupante := _ocupante(espaco)
		if ocupante:
			_equipados.erase(ocupante.espaco)
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
	_penalidades.erase(item)
	_quantidades.erase(item)
	mudou.emit()
	return true


## Penalidade de desgaste do item (0 = intacto).
func penalidade(item: Item) -> int:
	return _penalidades.get(item, 0)


## Aumenta o desgaste do item em `quanto`. Se chegar ao `limite`, o item é destruído
## (sai do inventário) e a função devolve true.
func desgastar(item: Item, quanto: int, limite: int) -> bool:
	if item not in itens:
		return false
	_penalidades[item] = penalidade(item) + quanto
	if _penalidades[item] >= limite:
		descartar(item)
		return true
	mudou.emit()
	return false


## Item equipado no `espaco`, ou null.
func equipado(espaco: StringName) -> Item:
	return _equipados.get(espaco)


func esta_equipado(item: Item) -> bool:
	return item != null and _equipados.get(item.espaco) == item


## Nenhum item equipado ocupa o `espaco` (nem uma arma de Duas Mãos).
func livre(espaco: StringName) -> bool:
	return _ocupante(espaco) == null


func _ocupante(espaco: StringName) -> Item:
	for item: Item in _equipados.values():
		if espaco in item.espacos_ocupados():
			return item
	return null


## A pilha já guardada onde o `item` entra, ou null.
func _pilha_de(item: Item) -> Item:
	if not item.empilhavel:
		return null
	for guardado in itens:
		if guardado.empilha_com(item):
			return guardado
	return null
