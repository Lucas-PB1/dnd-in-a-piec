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
## Empunhadura Dupla: a segunda arma na outra mão não precisa ser Leve (o herói liga ao ter o talento).
var segunda_arma_livre: bool = false
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


## Primeiro item com esse nome, ou null (a munição é achada pelo nome).
func item_chamado(nome: String) -> Item:
	for item in itens:
		if item.nome == nome:
			return item
	return null


## Esvazia tudo (ex.: o herói recebe o pacote inicial).
func limpar() -> void:
	itens.clear()
	_equipados.clear()
	_penalidades.clear()
	_quantidades.clear()
	mudou.emit()


## Equipa no espaço do item. A 2ª arma leve vai para a mão secundária (tira o escudo).
## Tudo que ocupava algum dos espaços dele é desequipado (continua na lista):
## ex.: Espada Grande tira o escudo; escudo tira a Espada Grande.
func equipar(item: Item) -> bool:
	if item not in itens or not item.equipavel():
		return false
	var destino := _destino_ao_equipar(item)
	for espaco in _espacos_do_destino(item, destino):
		var ocupante := _ocupante(espaco)
		if ocupante and ocupante != item:
			_equipados.erase(espaco_de(ocupante))
	var atual := espaco_de(item)
	if atual != &"" and atual != destino:
		_equipados.erase(atual)
	_equipados[destino] = item
	mudou.emit()
	return true


func desequipar(espaco: StringName) -> bool:
	if not _equipados.has(espaco):
		return false
	_equipados.erase(espaco)
	_promover_segunda_arma(espaco)
	mudou.emit()
	return true


## Saiu a arma da mão principal e há uma arma na outra mão: ela passa a ser a principal (escudo fica onde está).
func _promover_segunda_arma(espaco_liberado: StringName) -> void:
	if espaco_liberado != Item.ESPACO_MAO or _equipados.has(Item.ESPACO_MAO):
		return
	var segunda: Item = _equipados.get(Item.ESPACO_MAO_SECUNDARIA)
	if segunda is Arma:
		_equipados.erase(Item.ESPACO_MAO_SECUNDARIA)
		_equipados[Item.ESPACO_MAO] = segunda

## Joga o item fora (some do inventário). Se estava equipado, desequipa antes.
func descartar(item: Item) -> bool:
	if item not in itens:
		return false
	var espaco := espaco_de(item)
	if espaco != &"":
		_equipados.erase(espaco)
	_promover_segunda_arma(espaco)
	itens.erase(item)
	_penalidades.erase(item)
	_quantidades.erase(item)
	mudou.emit()
	return true


## Tira 1 unidade (arremesso). Pilha com mais de 1 devolve uma cópia; a última sai do inventário.
func extrair_uma(item: Item) -> Item:
	if item not in itens:
		return null
	if quantidade_de(item) > 1:
		_quantidades[item] = quantidade_de(item) - 1
		if quantidade_de(item) == 1:
			_quantidades.erase(item)
		mudou.emit()
		return item.duplicate() as Item
	descartar(item)
	return item


## Guarda o item e, se o desgaste trazido for maior, fica com ele (ex.: arma recolhida do chão).
func adicionar_com_desgaste(item: Item, penalidade_item: int, quantidade: int = 1) -> bool:
	if not adicionar(item, quantidade):
		return false
	var guardado := item if item in itens else _pilha_de(item)
	if guardado and penalidade_item > penalidade(guardado):
		_penalidades[guardado] = penalidade_item
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


## Itens equipados na ordem em que foram equipados (sem repetir o que ocupa dois espaços).
func equipados_em_ordem() -> Array[Item]:
	var lista: Array[Item] = []
	for item in _equipados.values():
		if item not in lista:
			lista.append(item)
	return lista


## Item equipado no `espaco`, ou null.
func equipado(espaco: StringName) -> Item:
	return _equipados.get(espaco)


func esta_equipado(item: Item) -> bool:
	return espaco_de(item) != &""


## Espaço em que o item está equipado, ou vazio. A 2ª arma não usa o espaço do próprio item.
func espaco_de(item: Item) -> StringName:
	if item == null:
		return &""
	for espaco in _equipados:
		if _equipados[espaco] == item:
			return espaco
	return &""


## Nenhum item equipado ocupa o `espaco` (nem uma arma de Duas Mãos).
func livre(espaco: StringName) -> bool:
	return _ocupante(espaco) == null


func _ocupante(espaco: StringName) -> Item:
	if _equipados.has(espaco):
		return _equipados[espaco]
	for item: Item in _equipados.values():
		if espaco in item.espacos_extras():
			return item
	return null


## 2ª arma leve: a principal já é leve e a outra mão está livre ou com escudo.
func _destino_ao_equipar(item: Item) -> StringName:
	var arma := item as Arma
	if arma and _cabe_na_outra_mao(arma):
		return Item.ESPACO_MAO_SECUNDARIA
	return item.espaco


func _cabe_na_outra_mao(arma: Arma) -> bool:
	if (not arma.leve and not segunda_arma_livre) or arma.duas_maos or arma.disparavel() or espaco_de(arma) == Item.ESPACO_MAO:
		return false
	var principal := _equipados.get(Item.ESPACO_MAO) as Arma
	if principal == null or not principal.leve or principal.duas_maos or principal.disparavel():
		return false
	var secundaria: Item = _equipados.get(Item.ESPACO_MAO_SECUNDARIA)
	return secundaria == null or secundaria is Armadura


## Espaços que ficam ocupados ao equipar em `destino`. Na mão secundária, só ela.
func _espacos_do_destino(item: Item, destino: StringName) -> Array[StringName]:
	var espacos: Array[StringName] = [destino]
	if destino == item.espaco:
		espacos.append_array(item.espacos_extras())
	return espacos


## A pilha já guardada onde o `item` entra, ou null.
func _pilha_de(item: Item) -> Item:
	if not item.empilhavel:
		return null
	for guardado in itens:
		if guardado.empilha_com(item):
			return guardado
	return null
