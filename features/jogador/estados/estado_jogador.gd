class_name EstadoJogador
extends Estado
## Base dos estados do herói: guarda a referência ao Jogador e as regras comuns
## "apertou atacar -> Atacando" e "pulou ou saiu do chão -> NoAr".

## Abaixo desta velocidade horizontal (px/s) o herói é considerado parado.
const VELOCIDADE_PARADO := 1.0

var jogador: Jogador


func configurar(dono: Node) -> void:
	jogador = dono as Jogador


## Se apertou atacar: disparo vai para Arremessando; corpo a corpo para Atacando.
func _foi_atacar() -> bool:
	if not jogador.pediu_ataque():
		return false
	trocar_para.emit(&"Arremessando" if jogador.disparo_na_mao() else &"Atacando")
	return true


## Se apertou arremessar com arma de arremesso (não de disparo), troca para Arremessando.
func _foi_arremessar() -> bool:
	if jogador.pediu_arremesso():
		trocar_para.emit(&"Arremessando")
		return true
	return false


## Atleta: empurrando contra uma parede, troca para Escalando e retorna true.
func _foi_escalar() -> bool:
	if jogador.pode_escalar():
		trocar_para.emit(&"Escalando")
		return true
	return false


## Para estados no chão: se pulou ou perdeu o chão, troca para NoAr e retorna true.
func _foi_para_o_ar() -> bool:
	if jogador.tentar_pular() or not jogador.is_on_floor():
		trocar_para.emit(&"NoAr")
		return true
	return false
