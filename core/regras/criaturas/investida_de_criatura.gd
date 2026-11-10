class_name InvestidaDeCriatura
extends RefCounted
## Capacidade de chifrada/investida da ficha (`chifrada_*`).
## Recarga X-6, janela de distância e carreira; a feature anima, move e quebra blocos.

## Faces do dado da recarga (1d6 do "Recarga 5–6").
const FACES_RECARGA := 6

var _criatura: CriaturaRPG
var _pronta: bool = true
var _tempo_recarga: float = 0.0


func _init(criatura: CriaturaRPG) -> void:
	_criatura = criatura


## A ficha tem ataque de chifrada/cabeçada?
static func tem_chifrada(criatura: CriaturaRPG) -> bool:
	return not criatura.chifrada_dano.is_empty()


func pronta() -> bool:
	return _pronta


## Só para testes / forçar estado da recarga.
func definir_pronta(valor: bool) -> void:
	_pronta = valor
	if valor:
		_tempo_recarga = 0.0


func alcance_chifrada_px() -> float:
	return EscalaDnd.pes_para_pixels(_criatura.chifrada_alcance_pes)


func carreira_px() -> float:
	return EscalaDnd.pes_para_pixels(_criatura.chifrada_carreira_pes)


## Correu o bastante em linha reta para o bônus / derrubada da ficha.
func carreira_completa(corrida_px: float) -> bool:
	return corrida_px >= carreira_px()


## Distância mínima (px) para valer a carreira antes do acerto.
func distancia_minima_px(meia_largura: float) -> float:
	return meia_largura + alcance_chifrada_px() + carreira_px()


## Recarga X-6: no começo de cada rodada rola 1d6. Sem recarga na ficha (`<= 0`), fica sempre pronta.
func passar_tempo(delta: float, rng: RandomNumberGenerator) -> void:
	if _pronta or _criatura.chifrada_recarga <= 0:
		return
	_tempo_recarga += delta
	if _tempo_recarga < EscalaDnd.RODADA_SEGUNDOS:
		return
	_tempo_recarga -= EscalaDnd.RODADA_SEGUNDOS
	_pronta = rng.randi_range(1, FACES_RECARGA) >= _criatura.chifrada_recarga


## Gasta a chifrada (sem efeito se a ficha não tem recarga).
func consumir() -> void:
	if _criatura.chifrada_recarga <= 0:
		return
	_pronta = false
	_tempo_recarga = 0.0


## Chifrada pronta, distância na janela, mesma altura e chão à frente.
func quer_investir(
	distancia: float,
	meia_largura: float,
	distancia_maxima_extra: float,
	desnivel_y: float,
	desnivel_maximo: float,
	no_chao: bool,
	tem_chao_a_frente: bool,
) -> bool:
	if not _pronta or not no_chao:
		return false
	var minima := distancia_minima_px(meia_largura)
	return distancia >= minima and distancia <= distancia_maxima_extra + minima \
		and desnivel_y <= desnivel_maximo and tem_chao_a_frente


## Golpe da ficha; com carreira soma o dano extra e derruba.
func golpe(com_carreira: bool) -> Golpe:
	return _criatura.golpe_chifrada(com_carreira)
