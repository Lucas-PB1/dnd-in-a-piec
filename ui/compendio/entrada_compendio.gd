class_name EntradaCompendio
extends RefCounted
## Uma página do Compêndio: nome na lista, uma linha de tipo e o texto. Montada por `Compendio`.

var nome: String
var tipo: String
var texto: String


func _init(nome_: String, tipo_: String, texto_: String) -> void:
	nome = nome_
	tipo = tipo_
	texto = texto_
