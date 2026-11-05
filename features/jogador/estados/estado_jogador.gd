class_name EstadoJogador
extends Estado
## Base dos estados do herói: guarda a referência ao Jogador e a regra comum
## "pulou ou saiu do chão -> NoAr" dos estados que estão no chão.

## Abaixo desta velocidade horizontal (px/s) o herói é considerado parado.
const VELOCIDADE_PARADO := 1.0

var jogador: Jogador


func configurar(dono: Node) -> void:
	jogador = dono as Jogador


## Para estados no chão: se pulou ou perdeu o chão, troca para NoAr e retorna true.
func _foi_para_o_ar() -> bool:
	if jogador.tentar_pular() or not jogador.is_on_floor():
		trocar_para.emit(&"NoAr")
		return true
	return false
