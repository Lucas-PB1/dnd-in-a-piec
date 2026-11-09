class_name AgarraoDoHeroi
extends RefCounted
## O herói agarrado por um monstro (condição Agarrado do livro): não sai do lugar até escapar. A cada rodada ele tenta
## escapar com um teste de Força ou Destreza (o melhor bônus) contra a CD de quem agarrou; apertar pular adianta a tentativa
## se já passou meia rodada. Solta também se quem agarrou sumiu ou ficou longe. Regra pura: o herói faz o teste e o aviso.

## Pular antecipa a tentativa depois desta fração da rodada.
const FRACAO_PARA_ANTECIPAR := 0.5

var _autor_id: int = 0
var _cd: int = 0
var _tempo: float = 0.0


func esta_agarrado() -> bool:
	return _autor_id != 0


func autor_id() -> int:
	return _autor_id


func agarrar(autor: int, cd_do_escape: int) -> void:
	_autor_id = autor
	_cd = cd_do_escape
	_tempo = 0.0


func soltar() -> void:
	_autor_id = 0
	_tempo = 0.0


## Passa o tempo. True quando chegou a hora de tentar escapar (a rodada acabou).
func passar(delta: float) -> bool:
	if not esta_agarrado():
		return false
	_tempo += delta
	return _tempo >= EscalaDnd.RODADA_SEGUNDOS


## Apertou pular: tenta já, se passou tempo bastante desde a última tentativa.
func pode_antecipar() -> bool:
	return esta_agarrado() and _tempo >= EscalaDnd.RODADA_SEGUNDOS * FRACAO_PARA_ANTECIPAR


## Rola o teste de escape (d20 + bônus contra a CD). Passou: solta e devolve true. Falhou: recomeça a contagem.
func tentar_escapar(bonus: int, rng: RandomNumberGenerator) -> bool:
	_tempo = 0.0
	if Combate.passou_salvaguarda(bonus, _cd, rng):
		soltar()
		return true
	return false
