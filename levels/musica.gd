class_name Musica
extends Node
## Música de fundo + ambiente por tema: toca uma faixa em loop (recomeça sozinha) e troca de
## uma para outra com transição suave. A fase escolhe música e ambiente; telas (título, derrota,
## vitória) tocam só a música e calamos o ambiente. Fica no barramento "Musica".

const TITULO := "res://assets/audio/musica/shakkar.ogg"
const EXPLORACAO := "res://assets/audio/musica/exploracao.mp3"
const TAVERNA := "res://assets/audio/musica/old_tower_inn.mp3"
const BATALHA := "res://assets/audio/musica/batalha_medieval.mp3"
const MASMORRA := "res://assets/audio/musica/masmorra_dungeon002.ogg"
const CAVERNA := "res://assets/audio/musica/caverna_escura.ogg"
const CRIPTA := "res://assets/audio/musica/sussurros_nevoa.ogg"
const CHEFE := "res://assets/audio/musica/chefe_batalha_rpg.ogg"
const DERROTA := "res://assets/audio/musica/derrota.ogg"
const AMBIENTE_FLORESTA := "res://assets/audio/sintetizados/ambiente_floresta.wav"
const AMBIENTE_RUINAS := "res://assets/audio/sintetizados/ambiente_ruinas.wav"
const AMBIENTE_SUBTERRANEO := "res://assets/audio/sintetizados/ambiente_subterraneo.wav"
const AMBIENTE_COVIL := "res://assets/audio/sintetizados/ambiente_covil.wav"
## Faixa de cada fase (1 = Clareira ... 10 = Covil). Batalha só na Ruína e Fortaleza (4–5).
## Fases dos chefes (6 e 10) tocam a música de chefe. Fase sem faixa mantém a que está tocando.
const FAIXAS_DAS_FASES := {
	1: TITULO, 2: EXPLORACAO, 3: TAVERNA, 4: BATALHA, 5: BATALHA,
	6: CHEFE, 7: MASMORRA, 8: CAVERNA, 9: CRIPTA, 10: CHEFE,
}
## Ambiente por tema da campanha (4 temas): Floresta 1–3, Ruínas 4–6, Subterrâneo 7–9, Covil 10.
const AMBIENTES_DAS_FASES := {
	1: AMBIENTE_FLORESTA, 2: AMBIENTE_FLORESTA, 3: AMBIENTE_FLORESTA,
	4: AMBIENTE_RUINAS, 5: AMBIENTE_RUINAS, 6: AMBIENTE_RUINAS,
	7: AMBIENTE_SUBTERRANEO, 8: AMBIENTE_SUBTERRANEO, 9: AMBIENTE_SUBTERRANEO,
	10: AMBIENTE_COVIL,
}
const TEMPO_DA_TROCA := 1.4
## Ao sair, quanto esperar (ms) para o motor de áudio soltar as faixas, ou ele reclama de recursos abertos.
const ESPERA_DO_MOTOR_DE_AUDIO_MS := 80
## Volume (dB) de uma faixa silenciada e da faixa tocando.
const VOLUME_MUDO := -60.0
const VOLUME_TOCANDO := 0.0
## Ambiente fica abaixo da música para não competir.
const VOLUME_AMBIENTE := -14.0

## Caminho da faixa que está tocando agora (vazio = nenhuma).
var faixa_atual: String = ""
## Caminho do ambiente atual (vazio = calado).
var ambiente_atual: String = ""

var _jogador_atual: AudioStreamPlayer
var _jogador_outro: AudioStreamPlayer
var _ambiente_atual: AudioStreamPlayer
var _ambiente_outro: AudioStreamPlayer
var _transicoes: Array[Tween] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # a música continua nos menus pausados
	_jogador_atual = _criar_jogador(&"musica")
	_jogador_outro = _criar_jogador(&"musica")
	_ambiente_atual = _criar_jogador(&"ambiente")
	_ambiente_outro = _criar_jogador(&"ambiente")


## Toca a faixa em loop com transição suave. A mesma faixa que já toca não recomeça.
## Telas (título, derrota, vitória) usam isto e o ambiente some.
func tocar(caminho: String) -> void:
	_trocar_musica(caminho)
	tocar_ambiente("")


## A faixa e o ambiente da fase `indice` (1 a 10), se houver.
func tocar_da_fase(indice: int) -> void:
	if FAIXAS_DAS_FASES.has(indice):
		_trocar_musica(FAIXAS_DAS_FASES[indice])
	tocar_ambiente(AMBIENTES_DAS_FASES.get(indice, ""))


## Loop baixo do tema. Vazio = some com transição.
func tocar_ambiente(caminho: String) -> void:
	if caminho == ambiente_atual:
		return
	ambiente_atual = caminho
	var anterior := _ambiente_atual
	_ambiente_atual = _ambiente_outro
	_ambiente_outro = anterior
	if caminho.is_empty():
		_desvanecer(_ambiente_outro)
		return
	var faixa := load(caminho) as AudioStream
	if faixa == null:
		return
	_ambiente_atual.stream = faixa
	_ambiente_atual.volume_db = VOLUME_MUDO
	_ambiente_atual.play()
	_nova_transicao().tween_property(_ambiente_atual, "volume_db", VOLUME_AMBIENTE, TEMPO_DA_TROCA)
	_desvanecer(_ambiente_outro)


func parar() -> void:
	tocar("")


## Ao sair, para as vozes e solta as faixas (senão o motor reclama de recursos de áudio abertos).
func _exit_tree() -> void:
	for transicao in _transicoes:
		if transicao.is_valid():
			transicao.kill()
	_transicoes.clear()
	for jogador in [_jogador_atual, _jogador_outro, _ambiente_atual, _ambiente_outro]:
		if jogador != null:
			jogador.stop()
			jogador.stream = null
	OS.delay_msec(ESPERA_DO_MOTOR_DE_AUDIO_MS)  # o servidor de áudio solta a faixa no próximo ciclo de mixagem


func esta_tocando() -> bool:
	return _jogador_atual.playing


func ambiente_esta_tocando() -> bool:
	return _ambiente_atual != null and _ambiente_atual.playing and not ambiente_atual.is_empty()


func _trocar_musica(caminho: String) -> void:
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


## Cada transição fica guardada para poder ser cancelada ao sair do jogo.
func _nova_transicao() -> Tween:
	var transicao := create_tween()
	_transicoes.append(transicao)
	return transicao


func _criar_jogador(camada: StringName) -> AudioStreamPlayer:
	var jogador := AudioStreamPlayer.new()
	jogador.bus = OpcoesSom.MUSICA
	jogador.finished.connect(_ao_terminar.bind(jogador, camada))
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
func _ao_terminar(jogador: AudioStreamPlayer, camada: StringName) -> void:
	if camada == &"musica" and jogador == _jogador_atual and not faixa_atual.is_empty():
		jogador.play()
	elif camada == &"ambiente" and jogador == _ambiente_atual and not ambiente_atual.is_empty():
		jogador.play()
