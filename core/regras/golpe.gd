class_name Golpe
extends RefCounted
## Um ataque de D&D pronto para ser resolvido: nome, bônus para acertar e dados de dano
## (já com o modificador). Quem ataca monta; quem é atingido resolve contra a própria CA.

var nome: String
## Somado ao d20 (proficiência + modificador, ou o "+3" da ficha da criatura).
var bonus_ataque: int
var dano: Dado


func _init(nome_golpe: String, bonus: int, dado_dano: Dado) -> void:
	nome = nome_golpe
	bonus_ataque = bonus
	dano = dado_dano
