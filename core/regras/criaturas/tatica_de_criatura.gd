class_name TaticaDeCriatura
extends RefCounted
## Orquestra cobertura, flanqueio e estratégia (timers + “quer agora?”).
## Regras puras: `Abrigo`, `Flanqueio`, `EstrategiaDeMonstro`. A feature liga estados e movimento.
## Política (ADR): clã Goblin e Gray Ooze ligam as três; chefes ficam de fora até fatia própria.

const MASCARA_MUNDO := 1
## Cobertura: janela do tiro do herói (s), passo e alcance da busca (px), intervalo entre buscas (s),
## distância mínima do alvo para valer se esconder (px).
const JANELA_DISPARO := 3.0
const PASSO_ABRIGO := 16.0
const ALCANCE_ABRIGO_PX := 192.0
const INTERVALO_ABRIGO := 2.0
const DISTANCIA_MINIMA_ABRIGO := 96.0
## Estratégia: intervalo entre afastamentos (s), folga além do “perto” (px), espaço atrás (px),
## distância segura ferido (px), alcance de aliado “por perto” (px).
const INTERVALO_AFASTAR := 1.5
const FOLGA_DISTANCIA_PX := 64.0
const ESPACO_ATRAS_PX := 24.0
const DISTANCIA_SEGURA_FERIDO_PX := 256.0
const ALCANCE_ALIADO_PX := 256.0
const MOTIVO_DISTANCIA := &"distancia"
const MOTIVO_FERIDO := &"ferido"
## Flanqueio: intervalo (s), alcance (px), fração do alcance corpo a corpo onde para no flanco.
const INTERVALO_FLANCO := 6.0
const ALCANCE_FLANCO_PX := 256.0
const FRACAO_ALCANCE_FLANCO := 0.6

## Vale manter distância (dano à distância >= corpo a corpo).
var prefere_distancia: bool = false

var _origem_disparo: Vector2 = Vector2.ZERO
var _tempo_desde_disparo: float = INF
var _tempo_desde_abrigo: float = INF
var _x_abrigo: float = 0.0
var _tempo_desde_afastar: float = INF
var _motivo_afastar: StringName = MOTIVO_DISTANCIA
var _ja_recuou_ferido: bool = false
var _tempo_desde_flanco: float = INF
var _x_flanco: float = 0.0


func _init(criatura: CriaturaRPG) -> void:
	prefere_distancia = EstrategiaDeMonstro.prefere_distancia(
		criatura.dano_medio(criatura.golpe()),
		criatura.dano_medio_a_distancia(),
	)


func passar_tempo(delta: float) -> void:
	_tempo_desde_disparo += delta
	_tempo_desde_abrigo += delta
	_tempo_desde_afastar += delta
	_tempo_desde_flanco += delta


## O herói atirou ou arremessou de `origem`.
func perceber_disparo(origem: Vector2) -> void:
	_origem_disparo = origem
	_tempo_desde_disparo = 0.0


func tempo_sem_disparo() -> float:
	return _tempo_desde_disparo


func origem_do_disparo() -> Vector2:
	return _origem_disparo


func x_do_abrigo() -> float:
	return _x_abrigo


func x_do_flanco() -> float:
	return _x_flanco


func motivo_afastar() -> StringName:
	return _motivo_afastar


## Parede entre o último disparo e o peito (`posicao` nos pés).
func protegido_do_disparo(
	espaco: PhysicsDirectSpaceState2D,
	posicao: Vector2,
	altura_peito: float,
) -> bool:
	return not SensorDeTerreno.linha_livre(
		espaco, _origem_disparo, posicao + Vector2(0.0, -altura_peito), MASCARA_MUNDO
	)


## True se deve entrar em cobertura; atualiza `x_do_abrigo`.
func quer_cobertura(
	espaco: PhysicsDirectSpaceState2D,
	posicao: Vector2,
	altura_peito: float,
	distancia_horizontal: float,
	ao_alcance: bool,
	percebido: bool,
) -> bool:
	if not percebido or _tempo_desde_disparo > JANELA_DISPARO or _tempo_desde_abrigo < INTERVALO_ABRIGO:
		return false
	if ao_alcance or distancia_horizontal < DISTANCIA_MINIMA_ABRIGO:
		return false
	_tempo_desde_abrigo = 0.0
	if protegido_do_disparo(espaco, posicao, altura_peito):
		_x_abrigo = posicao.x
		return true
	_x_abrigo = BuscaDeAbrigo.procurar(
		espaco, posicao, altura_peito, _origem_disparo,
		PASSO_ABRIGO, ceili(ALCANCE_ABRIGO_PX / PASSO_ABRIGO), MASCARA_MUNDO,
	)
	return not is_nan(_x_abrigo)


## True se deve flanquear; atualiza `x_do_flanco`. `aliados_engajados_x` = X dos aliados já no corpo a corpo.
func quer_flanquear(
	alvo_x: float,
	meu_x: float,
	distancia_horizontal: float,
	ao_alcance: bool,
	percebido: bool,
	vida: int,
	vida_maxima: int,
	alcance_corpo_px: float,
	meia_largura: float,
	aliados_engajados_x: Array[float],
) -> bool:
	if not percebido or ao_alcance or _tempo_desde_flanco < INTERVALO_FLANCO:
		return false
	if vida * 3 <= vida_maxima:
		return false
	if distancia_horizontal > ALCANCE_FLANCO_PX:
		return false
	var meu_lado := Flanqueio.lado(alvo_x, meu_x)
	for aliado_x in aliados_engajados_x:
		if Flanqueio.lado(alvo_x, aliado_x) == meu_lado:
			_tempo_desde_flanco = 0.0
			_x_flanco = alvo_x - meu_lado * (alcance_corpo_px * FRACAO_ALCANCE_FLANCO + meia_largura)
			return true
	return false


## True se deve afastar; atualiza motivo. `tem_ataque_distancia` = ainda tem flecha/arremesso.
func quer_afastar(
	percebido: bool,
	vida: int,
	vida_maxima: int,
	aliados_perto: int,
	tem_espaco_atras: bool,
	tem_ataque_distancia: bool,
	perto_do_alvo: bool,
	ao_alcance: bool,
) -> bool:
	if not percebido:
		return false
	if _quer_recuar_ferido(vida, vida_maxima, aliados_perto, tem_espaco_atras):
		return _comecar_a_afastar(MOTIVO_FERIDO)
	if _quer_manter_distancia(tem_ataque_distancia, perto_do_alvo, ao_alcance, tem_espaco_atras):
		return _comecar_a_afastar(MOTIVO_DISTANCIA)
	return false


## Já se afastou o bastante para o motivo atual?
func afastado_o_bastante(distancia_horizontal: float, perto_px: float) -> bool:
	if _motivo_afastar == MOTIVO_FERIDO:
		return distancia_horizontal >= DISTANCIA_SEGURA_FERIDO_PX
	return distancia_horizontal > perto_px + FOLGA_DISTANCIA_PX


## Aliados em pé no grupo (duck typing: `alvo_ao_alcance`, `vida_atual`, opcional `esta_caido`).
static func aliados_em_pe(arvore: SceneTree, eu: Node, grupo: StringName) -> Array[Node]:
	var lista: Array[Node] = []
	if arvore == null:
		return lista
	for no in arvore.get_nodes_in_group(grupo):
		if no == eu or not is_instance_valid(no) or no.is_queued_for_deletion():
			continue
		if not no.has_method(&"alvo_ao_alcance") or not no.has_method(&"vida_atual"):
			continue
		if no.has_method(&"esta_caido") and bool(no.call(&"esta_caido")):
			continue
		if int(no.call(&"vida_atual")) <= 0:
			continue
		lista.append(no)
	return lista


## Quantos aliados estão a até `ALCANCE_ALIADO_PX` de `meu_x`.
static func contar_aliados_perto(aliados: Array[Node], meu_x: float) -> int:
	var total := 0
	for aliado in aliados:
		if absf((aliado as Node2D).global_position.x - meu_x) <= ALCANCE_ALIADO_PX:
			total += 1
	return total


## X dos aliados já no corpo a corpo com o alvo.
static func xs_engajados(aliados: Array[Node]) -> Array[float]:
	var xs: Array[float] = []
	for aliado in aliados:
		if bool(aliado.call(&"alvo_ao_alcance")):
			xs.append((aliado as Node2D).global_position.x)
	return xs


func _comecar_a_afastar(motivo: StringName) -> bool:
	_motivo_afastar = motivo
	_tempo_desde_afastar = 0.0
	_ja_recuou_ferido = _ja_recuou_ferido or motivo == MOTIVO_FERIDO
	return true


func _quer_recuar_ferido(vida: int, vida_maxima: int, aliados_perto: int, tem_espaco_atras: bool) -> bool:
	if _ja_recuou_ferido or _tempo_desde_afastar < INTERVALO_AFASTAR:
		return false
	return EstrategiaDeMonstro.deve_recuar_ferido(vida, vida_maxima, aliados_perto) and tem_espaco_atras


func _quer_manter_distancia(
	tem_ataque_distancia: bool,
	perto_do_alvo: bool,
	ao_alcance: bool,
	tem_espaco_atras: bool,
) -> bool:
	return prefere_distancia and tem_ataque_distancia and _tempo_desde_afastar >= INTERVALO_AFASTAR \
		and perto_do_alvo and not ao_alcance and tem_espaco_atras
