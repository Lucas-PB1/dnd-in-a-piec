class_name ToqueDuplo
extends RefCounted
## Detecta "dois toques rápidos na mesma direção" (ex.: para correr ou dar dash).
## Uso: chame registrar() todo quadro com a direção que acabou de ser apertada (-1, 1 ou 0).

## Tempo máximo entre os dois toques (segundos).
var janela: float

var _ultima_direcao: int = 0
var _tempo_desde_toque: float = INF


func _init(janela_segundos: float = 0.25) -> void:
	janela = janela_segundos


## Retorna true no quadro em que o segundo toque acontece.
func registrar(direcao_apertada: int, delta: float) -> bool:
	_tempo_desde_toque += delta
	if direcao_apertada == 0:
		return false

	var foi_duplo := direcao_apertada == _ultima_direcao and _tempo_desde_toque <= janela
	# Depois de um toque duplo, zera: o 3º toque começa uma contagem nova.
	_ultima_direcao = 0 if foi_duplo else direcao_apertada
	_tempo_desde_toque = 0.0
	return foi_duplo
