class_name DadosDeVidaDoHeroi
extends RefCounted
## Durável: um dado de vida por nível, que voltam a cada fase. Uma ação bônus gasta um e cura o valor rolado.
## Regra pura: devolve o motivo de não poder, e quem usa mostra o aviso e aplica a cura.

var restantes: int = 0


func repor(ficha: Ficha) -> void:
	restantes = ficha.dados_de_vida() if ficha else 0


## Subiu de nível: ganha o dado novo, sem passar do total.
func ao_subir_de_nivel(ficha: Ficha, niveis: int) -> void:
	restantes = mini(restantes + niveis, ficha.dados_de_vida())


## "" se dá para gastar um dado agora; senão o aviso que o herói mostra.
func motivo_de_nao_poder(vida_cheia: bool, acao_bonus_livre: bool) -> String:
	if restantes <= 0:
		return "Sem dados de vida"
	if vida_cheia:
		return "Vida cheia"
	if not acao_bonus_livre:
		return "Ação bônus"
	return ""


## Gasta um dado e devolve quanto cura (o valor rolado).
func gastar(faces: int, rng: RandomNumberGenerator) -> int:
	restantes -= 1
	return rng.randi_range(1, faces)
