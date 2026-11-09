class_name Missao
extends RefCounted
## A missão da fase: um título ("Limpe a clareira"), o que fazer e quanto já foi feito. Hoje só "derrote todos os
## inimigos"; os chefes ganham o seu tipo depois. Regra pura: a main conta as mortes e mostra o texto na HUD.

var titulo: String
var total: int
var feitos: int = 0


func _init(titulo_da_missao: String = "", inimigos: int = 0) -> void:
	titulo = titulo_da_missao
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
	return "%s: derrote todos os inimigos" % nome
