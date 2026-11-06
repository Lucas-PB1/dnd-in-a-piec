class_name PacoteInicial
extends Resource
## Equipamento inicial de uma classe, como no livro (ex.: Guerreiro A: Cota de Malha,
## Espada Grande, Mangual e 8 Azagaias). O herói recebe cópias e já veste o que está em `equipar`.

@export var nome: String = "Pacote"
## Item -> quantidade (empilháveis, como a Azagaia, entram numa pilha só).
@export var itens: Dictionary[Item, int] = {}
## Itens que já começam equipados (precisam estar em `itens`).
@export var equipar: Array[Item] = []


## Arma que começa na mão, ou null.
func arma() -> Arma:
	for item in equipar:
		if item is Arma:
			return item
	return null


## Armadura que começa vestida (não o escudo), ou null.
func armadura() -> Armadura:
	for item in equipar:
		if item is Armadura and not (item as Armadura).e_escudo():
			return item
	return null


## "Cota de Malha, Espada Grande, Mangual, 8× Azagaia"
func texto_itens() -> String:
	var partes: PackedStringArray = []
	for item in itens:
		partes.append(("%d× %s" % [itens[item], item.nome]) if itens[item] > 1 else item.nome)
	return ", ".join(partes)
