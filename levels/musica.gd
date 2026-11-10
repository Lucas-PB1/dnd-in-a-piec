class_name Musica
extends Node
## Música de fundo: toca uma faixa em loop (recomeça sozinha) e troca de uma para outra com transição suave
## (a antiga some enquanto a nova sobe). Escolhe a faixa pela tela ou pela fase. Fica no
## barramento "Musica", cujo volume vem das Opções.

const TITULO := "res://assets/audio/musica/shakkar.ogg"
const TAVERNA := "res://assets/audio/musica/old_tower_inn.mp3"
const BATALHA := "res://assets/audio/musica/batalha_medieval.mp3"
const MASMORRA := "res://assets/audio/musica/masmorra_dungeon002.ogg"
const CAVERNA := "res://assets/audio/musica/caverna_escura.ogg"
const CHEFE := "res://assets/audio/musica/chefe_batalha_rpg.ogg"
## Faixa de cada fase (1 = Clareira ... 10 = Covil). As fases dos chefes (6 e 10) tocam a música de chefe.
## Fase sem faixa mantém a que está tocando.
const FAIXAS_DAS_FASES := {
	1: TITULO, 2: TITULO, 3: TAVERNA, 4: BATALHA, 5: BATALHA,
	6: CHEFE, 7: MASMORRA, 8: CAVERNA, 9: MASMORRA, 10: CHEFE,
}
const TEMPO_DA_TROCA := 1.4
## Ao sair, quanto esperar (ms) para o motor de áudio soltar as faixas, ou ele reclama de recursos abertos.
const ESPERA_DO_MOTOR_DE_AUDIO_MS := 80
## Volume (dB) de uma faixa silenciada e da faixa tocando.
const VOLUME_MUDO := -60.0
const VOLUME_TOCANDO := 0.0

## Caminho da faixa que está tocando agora (vazio = nenhuma).
var faixa_atual: String = ""

var _jogador_atual: AudioStreamPlayer
var _jogador_outro: AudioStreamPlayer
var _transicoes: Array[Tween] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # a música continua nos menus pausados
	_jogador_atual = _criar_jogador()
	_jogador_outro = _criar_jogador()


## Toca a faixa em loop com transição suave. A mesma faixa que já toca não recomeça.
func tocar(caminho: String) -> void:
	if caminho == faixa_atual:
		return
	faixa_atual = caminho
	var anterior := _jogador_atual
	_jogador_atual = _jogador_outro
	_jogador_outro = anterior
	if caminho.is_empty():
		_desvanecer(_jogador_outro)
		return
	var faixa := load(caminho) as AudioStream
	if faixa == null:
		return
	_jogador_atual.stream = faixa
	_jogador_atual.volume_db = VOLUME_MUDO
	_jogador_atual.play()
	_nova_transicao().tween_property(_jogador_atual, "volume_db", VOLUME_TOCANDO, TEMPO_DA_TROCA)
	_desvanecer(_jogador_outro)


## A faixa da fase `indice` (1 a 10), se houver.
func tocar_da_fase(indice: int) -> void:
	if FAIXAS_DAS_FASES.has(indice):
		tocar(FAIXAS_DAS_FASES[indice])


func parar() -> void:
	tocar("")


## Ao sair, para as vozes e solta as faixas (senão o motor reclama de recursos de áudio abertos).
func _exit_tree() -> void:
	for transicao in _transicoes:
		if transicao.is_valid():
			transicao.kill()
	_transicoes.clear()
	for jogador in [_jogador_atual, _jogador_outro]:
		if jogador != null:
			jogador.stop()
			jogador.stream = null
	OS.delay_msec(ESPERA_DO_MOTOR_DE_AUDIO_MS)  # o servidor de áudio solta a faixa no próximo ciclo de mixagem


func esta_tocando() -> bool:
	return _jogador_atual.playing


## Cada transição fica guardada para poder ser cancelada ao sair do jogo.
func _nova_transicao() -> Tween:
	var transicao := create_tween()
	_transicoes.append(transicao)
	return transicao


func _criar_jogador() -> AudioStreamPlayer:
	var jogador := AudioStreamPlayer.new()
	jogador.bus = OpcoesSom.MUSICA
	jogador.finished.connect(_ao_terminar.bind(jogador))
	jogador.volume_db = VOLUME_MUDO
	add_child(jogador)
	return jogador


func _desvanecer(jogador: AudioStreamPlayer) -> void:
	if not jogador.playing:
		return
	var transicao := _nova_transicao()
	transicao.tween_property(jogador, "volume_db", VOLUME_MUDO, TEMPO_DA_TROCA)
	transicao.tween_callback(jogador.stop)


## A faixa que está tocando recomeça quando termina (loop por código: marcar `loop` no arquivo deixa
## recursos de áudio abertos ao sair do jogo). A que está sumindo não recomeça.
func _ao_terminar(jogador: AudioStreamPlayer) -> void:
	if jogador == _jogador_atual and not faixa_atual.is_empty():
		jogador.play()
