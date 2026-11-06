class_name Item
extends Resource
## Um item que pode ficar no inventário. Itens equipáveis dizem em qual espaço vão.

## Espaço "mão" (armas).
const ESPACO_MAO := &"mao"
## Espaço "corpo" (armaduras).
const ESPACO_CORPO := &"corpo"
## Espaço "mão secundária" (escudos).
const ESPACO_MAO_SECUNDARIA := &"mao_secundaria"

@export var nome: String = "Item"
@export_multiline var descricao: String = ""
## Imagem mostrada no inventário.
@export var icone: Texture2D
## Onde se equipa (ex.: &"mao"). Vazio = não dá para equipar.
@export var espaco: StringName = &""

## Empilhável: várias unidades ocupam 1 lugar na mochila (ex.: Azagaia ×8).
@export var empilhavel: bool = false


func equipavel() -> bool:
	return espaco != &""


## Mesmo item empilhável (cópias do mesmo .tres têm o mesmo nome).
func empilha_com(outro: Item) -> bool:
	return empilhavel and outro != null and outro.empilhavel and outro.nome == nome


## Outros espaços que o item ocupa além do seu (ex.: arma de Duas Mãos ocupa a mão secundária).
func espacos_extras() -> Array[StringName]:
	return []


## Todos os espaços que o item ocupa quando equipado.
func espacos_ocupados() -> Array[StringName]:
	var todos: Array[StringName] = [espaco]
	todos.append_array(espacos_extras())
	return todos
