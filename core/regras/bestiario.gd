class_name Bestiario
extends RefCounted
## Registro do bestiário: quantas vezes o herói derrotou cada criatura. Uma criatura só mostra
## a ficha completa depois da primeira derrota. Regra pura: o save guarda o que está aqui.

## Nome da criatura -> quantas vezes foi derrotada.
var derrotados: Dictionary[String, int] = {}


func registrar_derrota(nome: String) -> void:
	derrotados[nome] = quantidade(nome) + 1


func quantidade(nome: String) -> int:
	return derrotados.get(nome, 0)


func foi_derrotada(nome: String) -> bool:
	return quantidade(nome) > 0


## Quantas criaturas diferentes já foram derrotadas.
func conhecidas() -> int:
	return derrotados.size()


func para_dicionario() -> Dictionary:
	return derrotados.duplicate()


## Põe de volta o que foi salvo (ignora valores que não são número positivo).
func carregar(dados: Dictionary) -> void:
	derrotados.clear()
	for nome in dados:
		var vezes := int(dados[nome])
		if vezes > 0:
			derrotados[str(nome)] = vezes
