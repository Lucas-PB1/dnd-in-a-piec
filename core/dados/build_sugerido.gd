class_name BuildSugerido
extends Resource
## Uma distribuição de atributos pronta para escolher na criação (ex.: Guerreiro de armadura
## pesada). Os valores seguem a compra de pontos (8 a 15, até 27 pontos).

@export var nome: String = ""
## Atributo -> valor.
@export var atributos: Dictionary[StringName, int] = {}
