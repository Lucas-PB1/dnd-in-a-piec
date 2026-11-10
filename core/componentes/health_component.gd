class_name HealthComponent
extends Node
## Pontos de vida de uma entidade: recebe dano, avisa quando muda e quando chega a zero.

## Emitido quando a vida (atual ou máxima) muda.
signal vida_mudou(atual: int, maxima: int)
## Emitido uma vez, quando a vida chega a zero.
signal morreu

var vida_maxima: int = 1
var vida_atual: int = 1


## Quanto do máximo foi drenado (Drenar Vida do Wight); volta com `restaurar_maximo` (descanso longo).
var maximo_drenado: int = 0


## Define a vida máxima e enche a vida.
func configurar(maxima: int) -> void:
	vida_maxima = maxima
	maximo_drenado = 0
	curar_tudo()


## Aumenta o máximo e os PV atuais pelo mesmo valor, como ao ganhar um nível.
func aumentar_maximo(novo_maximo: int) -> void:
	var aumento := maxi(novo_maximo - (vida_maxima + maximo_drenado), 0)
	vida_maxima = maxi(novo_maximo - maximo_drenado, 1)
	if not esta_morto():
		vida_atual = mini(vida_atual + aumento, vida_maxima)
	vida_mudou.emit(vida_atual, vida_maxima)


## Reduz o máximo de PV em `quantidade` (mínimo 1) e corta a vida atual se passar do novo máximo.
func reduzir_maximo(quantidade: int) -> void:
	if esta_morto() or quantidade <= 0:
		return
	var reducao := mini(quantidade, vida_maxima - 1)
	vida_maxima -= reducao
	maximo_drenado += reducao
	vida_atual = mini(vida_atual, vida_maxima)
	vida_mudou.emit(vida_atual, vida_maxima)


## Devolve o máximo drenado (sem curar: quem chama cura).
func restaurar_maximo() -> void:
	vida_maxima += maximo_drenado
	maximo_drenado = 0
	vida_mudou.emit(vida_atual, vida_maxima)


func curar_tudo() -> void:
	vida_atual = vida_maxima
	vida_mudou.emit(vida_atual, vida_maxima)


## Sobe a vida em `quantidade`, sem passar do máximo. Devolve o quanto de fato subiu.
## Morto não cura. Com a vida cheia, devolve 0.
func curar(quantidade: int) -> int:
	if esta_morto() or quantidade <= 0:
		return 0
	var antes := vida_atual
	vida_atual = mini(vida_atual + quantidade, vida_maxima)
	var ganho := vida_atual - antes
	if ganho > 0:
		vida_mudou.emit(vida_atual, vida_maxima)
	return ganho


## Tira `quantidade` de vida (nunca abaixo de zero). Ao zerar, emite `morreu`.
func receber_dano(quantidade: int) -> void:
	if esta_morto() or quantidade <= 0:
		return
	vida_atual = maxi(vida_atual - quantidade, 0)
	vida_mudou.emit(vida_atual, vida_maxima)
	if esta_morto():
		morreu.emit()


func esta_morto() -> bool:
	return vida_atual <= 0
