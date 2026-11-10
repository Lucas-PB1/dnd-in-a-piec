class_name Sons
extends Node
## Efeitos sonoros do jogo. Escuta o que acontece (golpes resolvidos, o herói pulando, morrendo,
## usando habilidades, os botões dos menus) e toca o som certo; não muda regra nenhuma. Cada
## efeito tem algumas variações e um leve sorteio de tom, para não soar repetido. Sons de monstro
## usam `tocar_em` (volume pela distância ao herói).

const RPG := "res://assets/audio/kenney_rpg/OGG/"
const SINTETIZADO := "res://assets/audio/sintetizados/"
const INTERFACE_KENNEY := "res://assets/audio/kenney_interface/Audio/"
const VOZES := "res://assets/audio/vozes_monstros/"
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
	&"pegar_item": [RPG + "handleCoins.ogg", RPG + "handleCoins2.ogg"],
	&"equipar": [RPG + "metalClick.ogg", RPG + "metalLatch.ogg", RPG + "clothBelt.ogg"],
	&"clique": [INTERFACE_KENNEY + "click_001.ogg", INTERFACE_KENNEY + "click_002.ogg"],
	&"abrir_tela": [INTERFACE_KENNEY + "open_001.ogg"],
	&"fechar_tela": [INTERFACE_KENNEY + "close_001.ogg"],
	&"confirmar": [INTERFACE_KENNEY + "confirmation_001.ogg"],
	&"golpe_monstro": [SINTETIZADO + "golpe_monstro.wav"],
	&"aviso_goblin": [VOZES + "goblin_aviso_1.wav", VOZES + "goblin_aviso_2.wav", VOZES + "goblin_aviso_3.wav"],
	&"ataque_goblin": [VOZES + "goblin_ataque_1.wav", VOZES + "goblin_ataque_2.wav", VOZES + "goblin_ataque_3.wav"],
	&"aviso_morto": [VOZES + "morto_aviso_1.wav", VOZES + "morto_aviso_2.wav"],
	&"ataque_morto": [VOZES + "morto_ataque_1.wav", VOZES + "morto_ataque_2.wav", VOZES + "morto_ataque_3.wav"],
	&"aviso_growl": [VOZES + "growl_1.ogg", VOZES + "growl_2.ogg", VOZES + "growl_3.ogg"],
	&"ataque_growl": [VOZES + "growl_3.ogg", VOZES + "growl_4.ogg", VOZES + "growl_5.ogg"],
	&"rugido": [SINTETIZADO + "rugido.wav"],
	&"rugido_morte": [SINTETIZADO + "rugido_morte.wav"],
	&"tremor": [SINTETIZADO + "tremor.wav"],
}
## Nome da ficha -> [som do aviso, som do ataque, tom base]. Minions; chefes ficam no rugido.
const VOZ_DA_CRIATURA := {
	"Goblin Minion": [&"aviso_goblin", &"ataque_goblin", 1.0],
	"Goblin Warrior": [&"aviso_goblin", &"ataque_goblin", 1.0],
	"Kobold Warrior": [&"aviso_goblin", &"ataque_goblin", 1.28],
	"Hobgoblin Warrior": [&"aviso_goblin", &"ataque_goblin", 0.88],
	"Bugbear Warrior": [&"aviso_growl", &"ataque_growl", 0.85],
	"Gray Ooze": [&"aviso_growl", &"ataque_growl", 1.2],
	"Skeleton": [&"aviso_morto", &"ataque_morto", 1.18],
	"Zombie": [&"aviso_morto", &"ataque_morto", 0.92],
}
## Sons que saem no barramento da interface; o resto vai para os efeitos.
const DA_INTERFACE: Array[StringName] = [&"clique", &"abrir_tela", &"fechar_tela", &"confirmar"]
## Volume (dB) de cada som que não toca no volume padrão.
const VOLUMES := {
	&"golpe_monstro": -3.0, &"tremor": -2.0, &"passo": -9.0, &"pulo": -8.0, &"pouso": -5.0,
	&"golpe": -4.0, &"golpe_pesado": -2.0, &"clique": -4.0, &"pegar_item": -4.0, &"equipar": -3.0,
	&"aviso_goblin": -2.0, &"ataque_goblin": -1.0, &"aviso_morto": -2.0, &"ataque_morto": -1.0,
	&"aviso_growl": -3.0, &"ataque_growl": -2.0,
}
## Sorteio do tom (1 = o original): cada vez soa um pouco diferente.
const VARIACAO_DE_TOM := 0.07
const VOZES_POR_BARRAMENTO := 8
## Passos: tempo entre um e outro andando e correndo (s) e a velocidade a partir da qual conta como andando (px/s).
const INTERVALO_PASSO_ANDANDO := 0.34
const INTERVALO_PASSO_CORRENDO := 0.22
const VELOCIDADE_MINIMA_PASSO := 40.0
const CAMADA_HURTBOX_JOGADOR := 8
## Mixagem por distância (só sons de monstro): cheio até N ladrilhos, some aos M.
const DISTANCIA_CHEIA_PX := EscalaDnd.PIXELS_POR_LADRILHO * 6.0
const DISTANCIA_MUDA_PX := EscalaDnd.PIXELS_POR_LADRILHO * 20.0
## Abaixo disto o som nem toca (economiza voz e evita estalo no -infinito).
const ATENUACAO_MUDA_DB := -40.0
## Sinais que só os chefes têm: o rugido ao despertar e o tremor do chão.
const SINAL_DESPERTAR := &"despertou"
const SINAL_TREMOR := &"abalou_o_chao"
const SINAL_AVISO := &"avisou_ataque"

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
	for hitbox in get_tree().root.find_children("*", "HitboxComponent", true, false):
		_escutar_hitbox(hitbox as HitboxComponent)
	for no in get_tree().root.find_children("*", "", true, false):
		_escutar_chefe(no)
		_escutar_aviso_de_criatura(no)
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
	jogador.aparou.connect(tocar.bind(&"critico"))
	jogador.surto_ativo_mudou.connect(_ao_mudar_surto)
	jogador.folego_mudou.connect(_ao_mudar_folego)
	jogador.progressao_mudou.connect(_ao_mudar_progressao)
	jogador.inventario.item_obtido.connect(_ao_obter_item)
	jogador.inventario.item_equipado.connect(_ao_equipar_item)


## O abrir e fechar das telas de `interface` (pausa, inventário, opções...) soam.
func ligar_telas(interface: Node) -> void:
	for tela in interface.get_children():
		if tela is Control:
			(tela as Control).visibility_changed.connect(_ao_mudar_tela.bind(tela))


## Toca um som do catálogo. `volume_extra` em dB soma ao volume do som. `tom` multiplica o pitch.
func tocar(nome: StringName, volume_extra: float = 0.0, tom: float = 1.0) -> void:
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
	voz.pitch_scale = tom * (1.0 + randf_range(-VARIACAO_DE_TOM, VARIACAO_DE_TOM))
	voz.play()
	tocados[nome] = tocados.get(nome, 0) + 1


## Som de monstro: volume cai com a distância até o herói (UI e herói usam `tocar` sem isto).
func tocar_em(nome: StringName, origem: Vector2, tom: float = 1.0) -> void:
	var extra := atenuacao_por_distancia(origem)
	if extra <= ATENUACAO_MUDA_DB:
		return
	tocar(nome, extra, tom)


## Quanto baixar (dB) um som em `origem` por causa da distância ao herói. 0 = cheio.
func atenuacao_por_distancia(origem: Vector2) -> float:
	if _jogador == null or not is_instance_valid(_jogador):
		return 0.0
	var distancia := origem.distance_to(_jogador.global_position)
	if distancia <= DISTANCIA_CHEIA_PX:
		return 0.0
	if distancia >= DISTANCIA_MUDA_PX:
		return ATENUACAO_MUDA_DB
	var t := (distancia - DISTANCIA_CHEIA_PX) / (DISTANCIA_MUDA_PX - DISTANCIA_CHEIA_PX)
	return linear_to_db(lerpf(1.0, 0.01, t))


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
	elif no is HitboxComponent:
		_escutar_hitbox(no as HitboxComponent)
	_escutar_chefe(no)
	_escutar_aviso_de_criatura(no)


func _escutar_defesa(defesa: DefesaComponent) -> void:
	# `bind` cria Callable novo a cada chamada: `is_connected` com outro bind nunca acha o antigo.
	if _sinal_ja_tem(defesa.golpe_resolvido, _ao_resolver_golpe):
		return
	defesa.golpe_resolvido.connect(_ao_resolver_golpe.bind(defesa))


func _escutar_dissolver(dissolver: DissolverComponent) -> void:
	if not dissolver.morrendo.is_connected(_ao_morrer_criatura):
		dissolver.morrendo.connect(_ao_morrer_criatura)


func _escutar_botao(botao: BaseButton) -> void:
	if not botao.pressed.is_connected(_ao_clicar_botao):
		botao.pressed.connect(_ao_clicar_botao)


## Golpe de criatura: a área que atinge a hurtbox do herói soa quando liga (o golpe em si).
func _escutar_hitbox(hitbox: HitboxComponent) -> void:
	if (hitbox.collision_mask & CAMADA_HURTBOX_JOGADOR) == 0:
		return
	if _sinal_ja_tem(hitbox.ligada, _ao_ligar_golpe_de_criatura):
		return
	hitbox.ligada.connect(_ao_ligar_golpe_de_criatura.bind(hitbox))


## Minions com `avisou_ataque`: voz no brilho amarelo.
func _escutar_aviso_de_criatura(no: Node) -> void:
	if not no.has_signal(SINAL_AVISO):
		return
	for info in no.get_signal_connection_list(SINAL_AVISO):
		var ligado: Callable = info["callable"]
		if ligado.get_object() == self and ligado.get_method() == &"_ao_aviso_de_criatura":
			return
	no.connect(SINAL_AVISO, _ao_aviso_de_criatura.bind(no))


## Chefes (têm o sinal do tremor): rugem ao despertar, tremem o chão e rugem ao morrer.
func _escutar_chefe(no: Node) -> void:
	if not no.has_signal(SINAL_TREMOR):
		return
	if no.has_signal(SINAL_DESPERTAR) and not _ja_escuta(no, SINAL_DESPERTAR, &"_ao_despertar_chefe"):
		no.connect(SINAL_DESPERTAR, _ao_despertar_chefe.bind(no))
	if not _ja_escuta(no, SINAL_TREMOR, &"_ao_tremer"):
		no.connect(SINAL_TREMOR, _ao_tremer.bind(no))
	if no.has_signal(&"morreu") and not _ja_escuta(no, &"morreu", &"_ao_morrer_chefe"):
		no.connect(&"morreu", _ao_morrer_chefe.bind(no))


func _ja_escuta(no: Node, sinal: StringName, metodo: StringName) -> bool:
	for info in no.get_signal_connection_list(sinal):
		var ligado: Callable = info["callable"]
		if ligado.get_object() == self and ligado.get_method() == metodo:
			return true
	return false


## True se este nó já escuta o sinal com este método (ignora argumentos de `bind`).
func _sinal_ja_tem(sinal: Signal, metodo: Callable) -> bool:
	var nome := metodo.get_method()
	for info in sinal.get_connections():
		var ligado: Callable = info["callable"]
		if ligado.get_object() == self and ligado.get_method() == nome:
			return true
	return false


func _ao_clicar_botao() -> void:
	tocar(&"clique")


func _ao_despertar_chefe(chefe: Node) -> void:
	tocar_em(&"rugido", _posicao_do_no(chefe))


func _ao_morrer_chefe(chefe: Node) -> void:
	tocar_em(&"rugido_morte", _posicao_do_no(chefe))


func _ao_ligar_golpe_de_criatura(_golpe: Golpe, hitbox: HitboxComponent) -> void:
	var origem := _posicao_do_no(hitbox)
	var voz := _voz_da_ficha(_ficha_do_no(hitbox))
	if voz.is_empty():
		tocar_em(&"golpe_monstro", origem)
		return
	tocar_em(voz[1], origem, float(voz[2]))


func _ao_aviso_de_criatura(criatura: Node) -> void:
	var voz := _voz_da_ficha(_ficha_do_no(criatura))
	if voz.is_empty():
		return
	tocar_em(voz[0], _posicao_do_no(criatura), float(voz[2]))


## Sobe na árvore até achar um nó com `criatura` (ficha).
func _ficha_do_no(no: Node) -> CriaturaRPG:
	var atual: Node = no
	while atual != null:
		var ficha: Variant = atual.get("criatura")
		if ficha is CriaturaRPG:
			return ficha as CriaturaRPG
		atual = atual.get_parent()
	return null


func _voz_da_ficha(ficha: CriaturaRPG) -> Array:
	if ficha == null or not VOZ_DA_CRIATURA.has(ficha.nome):
		return []
	return VOZ_DA_CRIATURA[ficha.nome]


func _posicao_do_no(no: Node) -> Vector2:
	if no is Node2D:
		return (no as Node2D).global_position
	return _jogador.global_position if _jogador != null else Vector2.ZERO


func _ao_tremer(_forca: float, _duracao: float, chefe: Node) -> void:
	tocar_em(&"tremor", _posicao_do_no(chefe))


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


func _ao_morrer_criatura(onde: Vector2) -> void:
	tocar_em(&"estouro", onde)


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


func _ao_obter_item(_item: Item) -> void:
	tocar(&"pegar_item")


func _ao_equipar_item(_item: Item) -> void:
	tocar(&"equipar")
