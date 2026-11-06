class_name EstadoJogador
extends Estado
## Base dos estados do herói: guarda a referência ao Jogador e as regras comuns
## "apertou atacar -> Atacando" e "pulou ou saiu do chão -> NoAr".

## Abaixo desta velocidade horizontal (px/s) o herói é considerado parado.
const VELOCIDADE_PARADO := 1.0

var jogador: Jogador


func configurar(dono: Node) -> void:
	jogador = dono as Jogador


## Se apertou atacar, troca para Atacando e retorna true.
func _foi_atacar() -> bool:
	if jogador.pediu_ataque():
		trocar_para.emit(&"Atacando")
		return true
	return false


## Se apertou arremessar com uma arma que arremessa, troca para Arremessando.
func _foi_arremessar() -> bool:
	if jogador.pediu_arremesso():
		trocar_para.emit(&"Arremessando")
		return true
	return false


## Para estados no chão: se pulou ou perdeu o chão, troca para NoAr e retorna true.
func _foi_para_o_ar() -> bool:
	if jogador.tentar_pular() or not jogador.is_on_floor():
		trocar_para.emit(&"NoAr")
		return true
	return false
