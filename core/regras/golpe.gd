class_name Golpe
extends RefCounted
## Um ataque de D&D pronto para ser resolvido: nome, bônus para acertar, dados de dano
## (já com o modificador) e tipo de dano. Quem ataca monta; quem é atingido resolve contra
## a própria CA e resistências.

## Emitido por um alvo com Forma Corrosiva quando esta arma o atinge e causa dano.
## Quem montou o golpe (o dono da arma) decide o que acontece com ela.
## Quem emite é o alvo, de fora desta classe; por isso o aviso de "sinal não usado" é desligado.
@warning_ignore("unused_signal")
signal arma_corroida(penalidade: int, limite: int)

var nome: String
## Somado ao d20 (proficiência + modificador, ou o "+3" da ficha da criatura).
var bonus_ataque: int
var dano: Dado
var tipo_dano: StringName
## True se é uma arma não mágica (sofre Corrosão). Soco e ataques naturais = false.
var arma_corroivel: bool
## Desvantagem: rola 2d20 e fica com o menor (ex.: armadura sem treinamento).
var desvantagem: bool = false
## O acerto corrói a armadura não mágica do alvo (Pseudópode do Gray Ooze).
var corroi_armadura: bool = false


func _init(nome_golpe: String, bonus: int, dado_dano: Dado, tipo: StringName = TiposDano.CONTUNDENTE,
		corroivel: bool = false) -> void:
	nome = nome_golpe
	bonus_ataque = bonus
	dano = dado_dano
	tipo_dano = tipo
	arma_corroivel = corroivel
