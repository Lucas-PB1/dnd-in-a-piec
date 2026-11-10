extends EstadoJogador
## K em duas fases. CARREGANDO: a força sobe (toque = alcance normal; segurar = o teto da
## pessoa) e W/S miram. No arremesso o teto é o alcance longo em 0,6 s e a arma inclina.
## No disparo a força é a velocidade (a da arma no máximo), a Destreza limita o teto e o
## tempo, e a arma troca de quadro. W não pula. Sem mexer na mira, o arremesso cai no chão
## na distância da força e o disparo sai reto (e cai pelo peso da munição). SOLTANDO:
## arremesso solta a arma; disparo gasta munição, mostra a soltura e a arma fica. No chão
## o herói freia.

enum Etapa { CARREGANDO, SOLTANDO }

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
	if jogador.disparo_na_mao():
		jogador.carregar_arremesso(_carga, _mira, true, _tempo / DURACAO_SOLTURA)
	if jogador.quer_disparo_extra():
		jogador.lancar_arma(_carga, _mira, true)
		_tempo = 0.0
		return
	_tempo += delta
	if _tempo >= DURACAO_SOLTURA:
		trocar_para.emit(_proximo_estado())


func _carregar(delta: float) -> void:
	_apontar_mira(delta)
	var teto := jogador.teto_da_carga()
	var tempo := jogador.tempo_ate_teto()
	if jogador.segurando_arremesso():
		_carga = minf(_carga + teto / tempo * delta, teto)
		jogador.carregar_arremesso(_carga, _mira)
		return
	jogador.lancar_arma(_carga, _mira)
	_etapa = Etapa.SOLTANDO
	if jogador.disparo_na_mao():
		jogador.carregar_arremesso(_carga, _mira, true)


## W (ou "mirar_cima": o analógico para cima) sobe a mira, S desce. Sem eles, o tiro
## sai reto e o arremesso cai no chão.
func _apontar_mira(delta: float) -> void:
	if Input.is_action_pressed(&"pular") or Input.is_action_pressed(&"mirar_cima"):
		_mira = minf(_mira + VELOCIDADE_MIRA * delta, MIRA_CIMA)
	if Input.is_action_pressed(&"mover_baixo"):
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
