extends EstadoJogador
## Derrubado (Chifrada do Minotauro): é lançado para longe, fica deitado sem controle e depois se levanta.

## Tempo deitado (s) e tempo para ficar de pé de novo (s). O deitado é o Caído do D&D (meia rodada).
const TEMPO_DEITADO := CondicoesComponent.DURACAO_CAIDO
const TEMPO_PARA_LEVANTAR := 0.3
## Quanto o lançamento passa do recuo de um golpe comum.
const FORCA_DO_LANCAMENTO := 1.4

var _tempo: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	var lado := signf(jogador.global_position.x - jogador.origem_ultimo_golpe.x)
	if lado == 0.0:
		lado = -jogador.direcao_olhar
	jogador.velocity = Vector2(lado * jogador.stats.recuo_dano.x * FORCA_DO_LANCAMENTO, jogador.stats.recuo_dano.y)
	jogador.deitar(true)


func sair() -> void:
	jogador.deitar(false)


func processar_fisica(delta: float) -> void:
	_tempo += delta
	jogador.aplicar_gravidade(delta)
	jogador.mover_horizontal(0.0, jogador.velocidade_andar(), delta, false)
	var deitado := _tempo_deitado()
	if _tempo >= deitado:
		jogador.deitar(false)
	if _tempo < deitado + TEMPO_PARA_LEVANTAR:
		return
	if not jogador.is_on_floor():
		trocar_para.emit(&"NoAr")
	else:
		trocar_para.emit(&"Andando" if jogador.direcao() != 0.0 else &"Parado")


## Defesa no Chão: levantar custa só ~5 pés (metade do tempo deitado padrão).
func _tempo_deitado() -> float:
	if jogador.ficha != null and jogador.ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.DEFESA_CHAO):
		return TEMPO_DEITADO * 0.5
	return TEMPO_DEITADO
