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


func equipavel() -> bool:
	return espaco != &""
