class_name Sons
extends Node
## Efeitos sonoros do jogo. Escuta o que acontece (golpes resolvidos, o herói pulando, morrendo,
## usando habilidades, os botões dos menus) e toca o som certo; não muda regra nenhuma. Cada
## efeito tem algumas variações e um leve sorteio de tom, para não soar repetido. Monstros novos
## ganham os sons sem mudar nada neles (como o Impacto).

const RPG := "res://assets/audio/kenney_rpg/OGG/"
const SINTETIZADO := "res://assets/audio/sintetizados/"
const INTERFACE_KENNEY := "res://assets/audio/kenney_interface/Audio/"
## Nome do som -> caminhos dos arquivos (um é sorteado a cada vez).
const SONS := {
	&"golpe": [SINTETIZADO + "whoosh_1.wav", SINTETIZADO + "whoosh_2.wav", RPG + "knifeSlice.ogg", RPG + "knifeSlice2.ogg"],
	&"golpe_pesado": [SINTETIZADO + "whoosh_pesado.wav"],
	&"acerto": [SINTETIZADO + "acerto_1.wav", SINTETIZADO + "acerto_2.wav", RPG + "chop.ogg"],
	&"critico": [SINTETIZADO + "acerto_critico.wav"],
	&"apanhar": [SINTETIZADO + "apanhar.wav"],
	&"morte_heroi": [SINTETIZADO + "morte_heroi.wav"],
	&"estouro": [SINTETIZADO + "estouro.wav"],
	&"pulo": [RPG + "cloth1.ogg", RPG + "cloth2.ogg", RPG + "cloth3.ogg"],
	&"pouso": [SINTETIZADO + "pouso.wav"],
	&"passo": [RPG + "footstep00.ogg", RPG + "footstep01.ogg", RPG + "footstep02.ogg", RPG + "footstep03.ogg", RPG + "footstep04.ogg"],
	&"arremesso": [RPG + "drawKnife1.ogg", RPG + "drawKnife2.ogg", RPG + "drawKnife3.ogg"],
	&"tiro": [SINTETIZADO + "tiro_arco.wav"],
	&"surto_ativar": [SINTETIZADO + "surto_ativar.wav"],
	&"surto_golpe": [SINTETIZADO + "surto_golpe.wav"],
	&"folego": [SINTETIZADO + "folego.wav"],
	&"nivel": [SINTETIZADO + "nivel.wav"],
	&"bau": [RPG + "creak1.ogg", RPG + "creak2.ogg"],
	&"clique": [INTERFACE_KENNEY + "click_001.ogg", INTERFACE_KENNEY + "click_002.ogg"],
	&"abrir_tela": [INTERFACE_KENNEY + "open_001.ogg"],
	&"fechar_tela": [INTERFACE_KENNEY + "close_001.ogg"],
	&"confirmar": [INTERFACE_KENNEY + "confirmation_001.ogg"],
}
## Sons que saem no barramento da interface; o resto vai para os efeitos.
const DA_INTERFACE: Array[StringName] = [&"clique", &"abrir_tela", &"fechar_tela", &"confirmar"]
## Volume (dB) de cada som que não toca no volume padrão.
const VOLUMES := {&"passo": -9.0, &"pulo": -8.0, &"pouso": -5.0, &"golpe": -4.0, &"golpe_pesado": -2.0, &"clique": -4.0}
## Sorteio do tom (1 = o original): cada vez soa um pouco diferente.
const VARIACAO_DE_TOM := 0.07
const VOZES_POR_BARRAMENTO := 8
## Passos: tempo entre um e outro andando e correndo (s) e a velocidade a partir da qual conta como andando (px/s).
const INTERVALO_PASSO_ANDANDO := 0.34
const INTERVALO_PASSO_CORRENDO := 0.22
const VELOCIDADE_MINIMA_PASSO := 40.0
const CAMADA_HURTBOX_JOGADOR := 8

## Sons já tocados nesta sessão (para os testes): nome -> quantas vezes.
var tocados: Dictionary[StringName, int] = {}

var _vozes: Dictionary[StringName, Array] = {}
var _proxima_voz: Dictionary[StringName, int] = {}
var _cache: Dictionary[String, AudioStream] = {}
var _jogador: Jogador
var _tempo_passo: float = 0.0
var _ultimo_folego: int = -1
var _ultimo_nivel: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # os cliques dos menus tocam com o jogo pausado
	for barramento in [OpcoesSom.EFEITOS, OpcoesSom.INTERFACE]:
		var vozes: Array[AudioStreamPlayer] = []
		for i in VOZES_POR_BARRAMENTO:
			var voz := AudioStreamPlayer.new()
			voz.bus = barramento
			add_child(voz)
			vozes.append(voz)
		_vozes[barramento] = vozes
		_proxima_voz[barramento] = 0
	for defesa in get_tree().root.find_children("*", "DefesaComponent", true, false):
		_escutar_defesa(defesa as DefesaComponent)
	for dissolver in get_tree().root.find_children("*", "DissolverComponent", true, false):
		_escutar_dissolver(dissolver as DissolverComponent)
	for botao in get_tree().root.find_children("*", "BaseButton", true, false):
		_escutar_botao(botao as BaseButton)
	get_tree().node_added.connect(_ao_nascer_no)


## Ao sair, para as vozes e solta os sons (senão o motor reclama de recursos de áudio abertos).
func _exit_tree() -> void:
	for barramento in _vozes:
		for voz: AudioStreamPlayer in _vozes[barramento]:
			voz.stop()
			voz.stream = null
	_cache.clear()


func _process(delta: float) -> void:
	if _jogador == null or not is_instance_valid(_jogador):
		return
	_tempo_passo -= delta
	var andando := _jogador.is_on_floor() and absf(_jogador.velocity.x) > VELOCIDADE_MINIMA_PASSO and not get_tree().paused
	if andando and _tempo_passo <= 0.0:
		_tempo_passo = INTERVALO_PASSO_CORRENDO if _jogador.esta_correndo() else INTERVALO_PASSO_ANDANDO
		tocar(&"passo")


## Liga os sons do herói (pulo, golpe, habilidades, morte...). A main chama depois de montar tudo.
func ligar_jogador(jogador: Jogador) -> void:
	_jogador = jogador
	_ultimo_nivel = jogador.ficha.nivel if jogador.ficha else 0
	_ultimo_folego = jogador.usos_folego()
	jogador.pulou.connect(tocar.bind(&"pulo"))
	jogador.aterrissou.connect(tocar.bind(&"pouso"))
	jogador.golpe_iniciado.connect(_ao_golpear)
	jogador.arma_arremessada.connect(_ao_arremessar)
	jogador.comecou_a_morrer.connect(tocar.bind(&"morte_heroi"))
	jogador.surto_ativo_mudou.connect(_ao_mudar_surto)
	jogador.folego_mudou.connect(_ao_mudar_folego)
	jogador.progressao_mudou.connect(_ao_mudar_progressao)


## O abrir e fechar das telas de `interface` (pausa, inventário, opções...) soam.
func ligar_telas(interface: Node) -> void:
	for tela in interface.get_children():
		if tela is Control:
			(tela as Control).visibility_changed.connect(_ao_mudar_tela.bind(tela))


## Toca um som do catálogo. `volume_extra` em dB soma ao volume do som.
func tocar(nome: StringName, volume_extra: float = 0.0) -> void:
	if not SONS.has(nome):
		return
	var caminhos: Array = SONS[nome]
	var faixa := _carregar(caminhos[randi() % caminhos.size()])
	if faixa == null:
		return
	var barramento := OpcoesSom.INTERFACE if nome in DA_INTERFACE else OpcoesSom.EFEITOS
	var voz := _voz_livre(barramento)
	voz.stream = faixa
	voz.volume_db = VOLUMES.get(nome, 0.0) + volume_extra
	voz.pitch_scale = 1.0 + randf_range(-VARIACAO_DE_TOM, VARIACAO_DE_TOM)
	voz.play()
	tocados[nome] = tocados.get(nome, 0) + 1


func _carregar(caminho: String) -> AudioStream:
	if not _cache.has(caminho):
		_cache[caminho] = load(caminho) as AudioStream
	return _cache[caminho]


## Uma voz que não está tocando; se todas estiverem, reaproveita a mais antiga (rodízio).
func _voz_livre(barramento: StringName) -> AudioStreamPlayer:
	var vozes: Array = _vozes[barramento]
	for voz: AudioStreamPlayer in vozes:
		if not voz.playing:
			return voz
	var indice: int = _proxima_voz[barramento]
	_proxima_voz[barramento] = (indice + 1) % vozes.size()
	return vozes[indice]


func _ao_nascer_no(no: Node) -> void:
	if no is DefesaComponent:
		_escutar_defesa(no as DefesaComponent)
	elif no is DissolverComponent:
		_escutar_dissolver(no as DissolverComponent)
	elif no is BaseButton:
		_escutar_botao(no as BaseButton)


func _escutar_defesa(defesa: DefesaComponent) -> void:
	if not defesa.golpe_resolvido.is_connected(_ao_resolver_golpe):
		defesa.golpe_resolvido.connect(_ao_resolver_golpe.bind(defesa))


func _escutar_dissolver(dissolver: DissolverComponent) -> void:
	if not dissolver.morrendo.is_connected(_ao_morrer_criatura):
		dissolver.morrendo.connect(_ao_morrer_criatura)


func _escutar_botao(botao: BaseButton) -> void:
	if not botao.pressed.is_connected(tocar.bind(&"clique")):
		botao.pressed.connect(tocar.bind(&"clique"))


func _ao_resolver_golpe(resultado: Combate.Resultado, _origem: Vector2, defesa: DefesaComponent) -> void:
	if not resultado.acertou and not resultado.raspao:
		return
	if (defesa.hurtbox.collision_layer & CAMADA_HURTBOX_JOGADOR) != 0:
		tocar(&"apanhar")
	elif resultado.critico:
		tocar(&"critico")
	else:
		tocar(&"acerto")


func _ao_golpear(arma: Arma, _extra: bool) -> void:
	tocar(&"golpe_pesado" if arma != null and arma.pesada else &"golpe")


func _ao_arremessar(_arma: Arma, _golpe: Golpe, _penalidade: int, _origem: Vector2, _direcao: int, _forca: float, _mira: float, municao: Municao, _ignora: bool, _destreza: int) -> void:
	tocar(&"tiro" if municao != null else &"arremesso")


func _ao_morrer_criatura(_onde: Vector2) -> void:
	tocar(&"estouro")


## O Surto acendeu (ativação) ou o segundo golpe saiu (acabou).
func _ao_mudar_surto(ativo: bool) -> void:
	tocar(&"surto_ativar" if ativo else &"surto_golpe")


## Só soa quando um uso é gasto (o descanso, que devolve usos, é silencioso).
func _ao_mudar_folego(restantes: int, _total: int) -> void:
	if _ultimo_folego >= 0 and restantes < _ultimo_folego:
		tocar(&"folego")
	_ultimo_folego = restantes


func _ao_mudar_progressao(nivel: int, _experiencia: int, _proximo: int) -> void:
	if _ultimo_nivel > 0 and nivel > _ultimo_nivel:
		tocar(&"nivel")
	_ultimo_nivel = nivel


func _ao_mudar_tela(tela: Control) -> void:
	tocar(&"abrir_tela" if tela.visible else &"fechar_tela")
