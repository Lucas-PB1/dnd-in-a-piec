extends EstadoJogador
## K em duas fases. CARREGANDO: a arma vai para trás, a força sobe (toque = alcance normal;
## até TEMPO_CARGA = longo) e W/S miram para cima ou para baixo. W não pula neste estado.
## Sem mexer na mira, o voo cai no chão na distância da força. SOLTANDO: arremesso solta a
## arma; disparo gasta munição e a arma fica. No chão o herói freia; no ar continua caindo.

enum Etapa { CARREGANDO, SOLTANDO }

## Segurando K por este tempo (s), a força chega ao máximo (alcance longo).
const TEMPO_CARGA := 0.6
## Tempo do gesto depois de soltar (s). O intervalo até o próximo ataque é o da iniciativa.
const DURACAO_SOLTURA := 0.2
## Graus por segundo ao mirar com W (cima) ou S (baixo) enquanto segura o K.
const VELOCIDADE_MIRA := 140.0
## Limite da mira (graus somados ao arco; positivo = para cima).
const MIRA_CIMA := 70.0
const MIRA_BAIXO := 40.0

var _etapa: Etapa = Etapa.CARREGANDO
var _carga: float = 0.0
var _tempo: float = 0.0
## Graus a mais para cima. 0 = o arco que cai no chão na distância da força.
var _mira: float = 0.0


func entrar() -> void:
	_etapa = Etapa.CARREGANDO
	_carga = 0.0
	_tempo = 0.0
	_mira = 0.0
	jogador.carregar_arremesso(0.0)


func sair() -> void:
	jogador.carregar_arremesso(-1.0)  # apanhou no meio da carga: a pose volta ao normal


func processar_fisica(delta: float) -> void:
	jogador.anular_buffer_pulo()
	_mover(delta)
	if _etapa == Etapa.CARREGANDO:
		_carregar(delta)
		return
	if jogador.quer_disparo_extra():
		jogador.lancar_arma(_carga / TEMPO_CARGA, _mira, true)
		_tempo = 0.0
		return
	_tempo += delta
	if _tempo >= DURACAO_SOLTURA:
		trocar_para.emit(_proximo_estado())


func _carregar(delta: float) -> void:
	_apontar_mira(delta)
	if jogador.segurando_arremesso():
		_carga = minf(_carga + delta, TEMPO_CARGA)
		jogador.carregar_arremesso(_carga / TEMPO_CARGA, _mira)
		return
	jogador.lancar_arma(_carga / TEMPO_CARGA, _mira)
	_etapa = Etapa.SOLTANDO


## W sobe a mira, S desce. Sem os dois, o tiro fica no arco que cai no chão.
func _apontar_mira(delta: float) -> void:
	if Input.is_action_pressed("pular"):
		_mira = minf(_mira + VELOCIDADE_MIRA * delta, MIRA_CIMA)
	if Input.is_action_pressed("mover_baixo"):
		_mira = maxf(_mira - VELOCIDADE_MIRA * delta, -MIRA_BAIXO)


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
