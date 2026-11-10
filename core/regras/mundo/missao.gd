class_name Missao
extends RefCounted
## A missão da fase: um título ("Limpe a clareira"), o que fazer e quanto já foi feito: "derrote todos os
## inimigos" ou, na fase de chefe, "derrote o <chefe>". Regra pura: a main conta as mortes e mostra o texto na HUD.

var titulo: String
var total: int
var feitos: int = 0
## Nome do chefe a derrotar (vazio = missão comum de limpar a fase).
var chefe: String = ""


func _init(titulo_da_missao: String = "", inimigos: int = 0, nome_do_chefe: String = "") -> void:
	titulo = titulo_da_missao
	chefe = nome_do_chefe
	total = maxi(inimigos, 0)


## Há missão a mostrar (fase sem inimigos, como a de teste, não tem).
func existe() -> bool:
	return total > 0


## Um inimigo da cota morreu.
func registrar_morte() -> void:
	feitos = mini(feitos + 1, total)


func cumprida() -> bool:
	return existe() and feitos >= total


## "Limpe a clareira: derrote todos os inimigos" (sem contar: as emboscadas são secretas), ou "Limpe a clareira: cumprida! Vá até a porta." no fim.
func texto() -> String:
	var nome := titulo if titulo != "" else "Missão"
	if cumprida():
		return "%s: cumprida! Vá até a porta." % nome
	if chefe != "":
		return "%s: derrote o %s" % [nome, chefe]
	return "%s: derrote todos os inimigos" % nome
