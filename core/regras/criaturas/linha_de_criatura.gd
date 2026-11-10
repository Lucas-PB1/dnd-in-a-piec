class_name LinhaDeCriatura
extends RefCounted
## Capacidade de salvaguarda em área da ficha (`linha_*`): Borrifo, Sopro etc.
## Recarga X-6, dimensões e golpe; hitbox/VFX e estados ficam na feature.

## Faces do dado da recarga (1d6 do "Recarga 5–6").
const FACES_RECARGA := 6

var _criatura: CriaturaRPG
var _pronta: bool = true
var _tempo_recarga: float = 0.0


func _init(criatura: CriaturaRPG) -> void:
	_criatura = criatura


## A ficha tem salvaguarda em linha/cone?
static func tem_linha(criatura: CriaturaRPG) -> bool:
	return criatura.linha_cd > 0


func tem() -> bool:
	return tem_linha(_criatura)


func pronta() -> bool:
	return _pronta


## Só para testes / forçar estado da recarga.
func definir_pronta(valor: bool) -> void:
	_pronta = valor
	if valor:
		_tempo_recarga = 0.0


func comprimento_px() -> float:
	return EscalaDnd.pes_para_pixels(_criatura.linha_comprimento_pes)


func largura_px() -> float:
	return EscalaDnd.pes_para_pixels(_criatura.linha_largura_pes)


func tamanho_hitbox_px() -> Vector2:
	return Vector2(comprimento_px(), largura_px())


## Centro da hitbox no eixo X, a partir da borda do corpo.
func offset_x_centro(meia_largura: float) -> float:
	return meia_largura + comprimento_px() / 2.0


## Recarga X-6: no começo de cada rodada rola 1d6. Sem recarga na ficha (`<= 0`), fica sempre pronta.
## `fator_rodada` < 1 encurta a rodada (fúria da Quimera).
func passar_tempo(delta: float, rng: RandomNumberGenerator, fator_rodada: float = 1.0) -> void:
	if _pronta or _criatura.linha_recarga <= 0:
		return
	_tempo_recarga += delta
	var rodada := EscalaDnd.RODADA_SEGUNDOS * fator_rodada
	if _tempo_recarga < rodada:
		return
	_tempo_recarga -= rodada
	_pronta = rng.randi_range(1, FACES_RECARGA) >= _criatura.linha_recarga


## Gasta a linha (sem efeito se a ficha não tem recarga).
func consumir() -> void:
	if _criatura.linha_recarga <= 0:
		return
	_pronta = false
	_tempo_recarga = 0.0


## Alvo à frente, dentro do comprimento e do desnível máximo (feature decide a altura).
func alvo_na_area(
	distancia_horizontal: float,
	meia_largura: float,
	desnivel_y: float,
	desnivel_maximo: float,
) -> bool:
	return distancia_horizontal <= meia_largura + comprimento_px() and desnivel_y <= desnivel_maximo


## Golpe de salvaguarda da ficha (sem rolagem de acerto).
func golpe() -> Golpe:
	return _criatura.golpe_linha()
