extends EstadoJogador
## Arremesso em duas fases. CARREGANDO: enquanto K está apertado, a arma vai para trás e a
## força sobe (toque rápido = alcance normal; segurando até TEMPO_CARGA = alcance longo).
## SOLTANDO: ao soltar K, a arma sai da mão e o herói termina o gesto. No chão o herói
## freia; no ar continua caindo.

enum Etapa { CARREGANDO, SOLTANDO }

## Segurando K por este tempo (s), a força chega ao máximo (alcance longo).
const TEMPO_CARGA := 0.6
## Tempo do gesto depois de soltar (s). O intervalo até o próximo ataque é o da iniciativa.
const DURACAO_SOLTURA := 0.2

var _etapa: Etapa = Etapa.CARREGANDO
var _carga: float = 0.0
var _tempo: float = 0.0


func entrar() -> void:
	_etapa = Etapa.CARREGANDO
	_carga = 0.0
	_tempo = 0.0
	jogador.carregar_arremesso(0.0)


func sair() -> void:
	jogador.carregar_arremesso(-1.0)  # apanhou no meio da carga: a pose volta ao normal


func processar_fisica(delta: float) -> void:
	_mover(delta)
	if _etapa == Etapa.CARREGANDO:
		_carregar(delta)
		return
	_tempo += delta
	if _tempo >= DURACAO_SOLTURA:
		trocar_para.emit(_proximo_estado())


func _carregar(delta: float) -> void:
	if jogador.segurando_arremesso():
		_carga = minf(_carga + delta, TEMPO_CARGA)
		jogador.carregar_arremesso(_carga / TEMPO_CARGA)
		return
	jogador.lancar_arma(_carga / TEMPO_CARGA)
	_etapa = Etapa.SOLTANDO


func _mover(delta: float) -> void:
	if jogador.is_on_floor():
		jogador.mover_horizontal(0.0, jogador.velocidade_andar(), delta, false)
	else:
		jogador.aplicar_gravidade(delta)
		jogador.cortar_pulo_se_soltou()
		jogador.mover_horizontal(jogador.direcao(), jogador.velocidade_andar(), delta, false)


func _proximo_estado() -> StringName:
	if not jogador.is_on_floor():
		return &"NoAr"
	return &"Andando" if jogador.direcao() != 0.0 else &"Parado"
