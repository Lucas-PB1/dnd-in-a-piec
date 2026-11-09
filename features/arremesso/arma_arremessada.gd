class_name ArmaArremessada
extends CharacterBody2D
## Arma arremessada ou munição disparada. Arremesso: voa num arco até a distância da força
## (0 = alcance normal, 1 = longo); `mira` soma graus para cima. Disparo: sai na velocidade
## da arma (pelo alcance longo do livro), na direção da mira, e cai pelo peso da munição.
## Além do alcance normal o ataque tem desvantagem; no longo o voo perde o acerto e cai.
## Arremesso: acerta UM alvo e cai ali (ponta finca; o resto gira e deita). E recolhe.
## Disparo (`municao`): a imagem da munição voa de ponta, acerta um alvo e some. Não se pega.
## Não conhece o herói: emite sinais e quem monta o jogo guarda a arma de volta.

## Emitido quando o herói aperta E com a arma no chão.
signal recolhida(arma: Arma, penalidade: int)
## A arma não mágica chegou no limite de corrosão no voo e se desfez.
signal derreteu(texto: String)
## O herói chegou perto da arma caída (true) ou se afastou (false): o botão E do toque só aparece perto.
signal perto_mudou(perto: bool)

## Gravidade do arco (px/s²). A munição multiplica pelo peso dela.
const GRAVIDADE := 980.0
## Disparo: carga mínima (toque) sai com esta fração da velocidade da arma.
const FRACAO_MINIMA_DISPARO := 0.55
## Destreza muda a velocidade do tiro em até ±25%.
const DESTREZA_VELOCIDADE_MINIMA := 0.75
const DESTREZA_VELOCIDADE_MAXIMA := 1.25
## Tempo de voo do arremesso até o alcance normal e até o longo (s): longe sobe mais alto.
const TEMPO_NORMAL := 0.35
const TEMPO_LONGO := 0.8
## Altura da mão acima do chão no lançamento (px), para o arco cair na distância certa.
const ALTURA_DA_MAO := 30.0
## Giro das armas que rodam (rad/s).
const GIRO := 14.0
## Quanto a ponta entra no chão ao fincar (px).
const FINCADA := 4.0
## Área de acerto: no mínimo isto (px), ou metade da arma.
const RAIO_ACERTO_MINIMO := 8.0
const AVISO_PEGAR := "E: pegar"
const AVISO_CHEIA := "Mochila cheia"
## O tiro que atravessa some depois deste tempo (s) se não pousar em nenhum chão.
const TEMPO_MAXIMO_ATRAVESSANDO := 5.0
## Um chão é a superfície que aponta para cima (normal.y abaixo disto); paredes e quinas são ignoradas.
const NORMAL_MINIMA_DO_CHAO := -0.5
const CAMADA_MUNDO := 1

var _arma: Arma
var _golpe: Golpe
var _penalidade: int = 0
var _origem_x: float = 0.0
var _normal_px: float = 1.0
var _longo_px: float = 1.0
var _voando: bool = false
var _perto: bool = false
var _direcao: int = 1
var _municao: Municao
## Destreza de quem disparou. 14 é o tempo escrito na munição; maior deixa o tiro mais reto.
var _destreza: int = Ficha.DESTREZA_REFERENCIA
## Multiplica a gravidade (o peso da munição; arremesso = 1).
var _peso: float = 1.0
var _ignora_longo: bool = false
## Atirador de Elite: a flecha ignora as laterais do cenário e atravessa as criaturas (cada uma é atingida uma vez).
var _ignora_cobertura: bool = false
var _tempo_atravessando: float = 0.0
## Ângulo absoluto do voo (graus a partir da horizontal; positivo = para cima).
const MIRA_MINIMA := -50.0
const MIRA_MAXIMA := 85.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _aviso: Label = $Aviso
@onready var _perto_area: Area2D = $Perto
@onready var _forma_acerto: CollisionShape2D = $Hitbox/Forma


func _ready() -> void:
	_aviso.hide()
	_perto_area.body_entered.connect(func(_corpo: Node2D) -> void: _definir_perto(true))
	_perto_area.body_exited.connect(func(_corpo: Node2D) -> void: _definir_perto(false))
	_hitbox.alvo_atingido.connect(func(_alvo: HurtboxComponent) -> void: _ao_acertar())


func _exit_tree() -> void:
	if _perto:
		_definir_perto(false)  # a arma some (recolhida ou derretida): o botão E apaga


func _definir_perto(perto: bool) -> void:
	if _perto == perto:
		return
	_perto = perto
	perto_mudou.emit(perto)


## Começa o voo. Chamar depois de entrar na árvore (a posição já é a da mão). `forca` de 0
## (alcance normal) a 1 (alcance longo). `mira` soma graus para cima (0 = cai no chão).
## `municao` preenchida = disparo que some ao acertar ou ao cair.
func lancar(arma: Arma, golpe: Golpe, penalidade: int, direcao: int, forca: float = 0.0, mira: float = 0.0, municao: Municao = null, ignora_alcance_longo: bool = false, destreza: int = Ficha.DESTREZA_REFERENCIA) -> void:
	_arma = arma
	_golpe = golpe
	_penalidade = penalidade
	_municao = municao
	_destreza = maxi(destreza, 1)
	_ignora_longo = ignora_alcance_longo
	_ignora_cobertura = ignora_alcance_longo and municao != null
	_origem_x = global_position.x
	var normal_pes := arma.disparo_normal_pes if municao else arma.arremesso_normal_pes
	var longo_pes := arma.disparo_longo_pes if municao else arma.arremesso_longo_pes
	_normal_px = EscalaDnd.pes_para_pixels(normal_pes)
	_longo_px = EscalaDnd.pes_para_pixels(longo_pes)
	_direcao = direcao
	if municao:
		_peso = municao.peso
		_preparar_municao(municao)
	else:
		_preparar_sprite(arma, direcao)
	velocity = _velocidade_inicial(forca, mira)
	_voando = true
	_hitbox.ligar(golpe)
	if municao == null and not golpe.arma_corroida.is_connected(_ao_corroer):
		golpe.arma_corroida.connect(_ao_corroer)


func esta_no_chao() -> bool:
	return not _voando


func em_desvantagem() -> bool:
	return _golpe != null and _golpe.desvantagem


func _physics_process(delta: float) -> void:
	if not _voando:
		return
	velocity.y += GRAVIDADE * _peso * delta
	_aplicar_alcance()
	# Aponta ANTES de mover: ao bater no chão a velocidade para baixo zera, e a lança
	# deitaria em vez de fincar.
	if _municao:
		_apontar_municao(velocity)
	elif _arma.arremesso_de_ponta:
		_apontar(velocity)
	else:
		_sprite.rotation += GIRO * delta * _direcao
	if _ignora_cobertura:
		_mover_atravessando(delta)
		return
	move_and_slide()
	if is_on_floor():
		if _municao:
			queue_free()
		else:
			_pousar()


func _unhandled_input(evento: InputEvent) -> void:
	if _municao or _voando or not _perto or not evento.is_action_pressed("interagir"):
		return
	recolhida.emit(_arma, _penalidade)
	get_viewport().set_input_as_handled()


## A mochila não coube: a arma fica no chão.
func avisar_cheia() -> void:
	_aviso.text = AVISO_CHEIA


## De ponta: a origem fica na PONTA (é ela que bate e finca no chão). Girando: no centro.
func _preparar_sprite(arma: Arma, direcao: int) -> void:
	DesenhoArma.preparar(_sprite, arma)
	if arma.textura == null:
		return
	_sprite.scale = Vector2(direcao, 1.0)
	if arma.arremesso_de_ponta:
		_sprite.offset = -(arma.pegada + Vector2.from_angle(deg_to_rad(arma.angulo_arte)) * arma.comprimento)
		_apontar(velocity)
	else:
		_sprite.offset = -arma.textura.get_size() / 2.0
	var raio := RAIO_ACERTO_MINIMO if arma.arremesso_de_ponta else maxf(RAIO_ACERTO_MINIMO, arma.comprimento / 2.0)
	(_forma_acerto.shape as RectangleShape2D).size = Vector2.ONE * raio * 2.0
	_forma_acerto.position = Vector2.ZERO


## Gira a arma de ponta para onde ela está indo. Espelhada (scale.x = -1), o giro inverte.
func _apontar(rumo: Vector2) -> void:
	var angulo := rad_to_deg(Vector2(rumo.x * _direcao, rumo.y).angle())
	_sprite.rotation_degrees = DesenhoArma.rotacao(_arma, angulo) * _direcao


## A munição aponta para onde vai. A arte pode já estar inclinada (`angulo_arte`).
func _preparar_municao(municao: Municao) -> void:
	_sprite.centered = true
	_sprite.texture = municao.textura
	_sprite.offset = Vector2.ZERO
	_sprite.visible = municao.textura != null
	(_forma_acerto.shape as RectangleShape2D).size = Vector2.ONE * RAIO_ACERTO_MINIMO * 2.0
	_forma_acerto.position = Vector2.ZERO
	_aviso.hide()


func _apontar_municao(rumo: Vector2) -> void:
	if rumo.length_squared() <= 0.0 or _municao == null:
		return
	_sprite.rotation_degrees = rad_to_deg(rumo.angle()) - _municao.angulo_arte


## Arremesso: a força escolhe a distância no chão e `mira` (graus, positivo = cima) gira
## esse arco (mira 0 cai na distância da força). Disparo: ver _velocidade_disparo.
func _velocidade_inicial(forca: float, mira: float) -> Vector2:
	if _municao:
		return _velocidade_disparo(forca, mira)
	var distancia := lerpf(_normal_px, _longo_px, forca)
	var base := _velocidade_para(distancia, _tempo_de_voo(forca))
	if is_zero_approx(mira):
		return base
	var angulo := atan2(-base.y, absf(base.x)) + deg_to_rad(mira)
	angulo = clampf(angulo, deg_to_rad(MIRA_MINIMA), deg_to_rad(MIRA_MAXIMA))
	return Vector2(cos(angulo) * _direcao, -sin(angulo)) * base.length()


## Disparo: cada arma tem a sua velocidade de saída, a que alcançaria o alcance LONGO do
## livro num tiro a 45° (v = raiz de g x longo). Arco longo sai mais rápido e reto que a
## funda. A carga vai de FRACAO_MINIMA_DISPARO a 1, a Destreza muda um pouco, a munição
## soma o impulso dela e cai pelo peso dela. `mira` = graus acima da horizontal (0 = reto).
## O alcance do livro continua valendo: além do normal desvantagem, no longo o tiro cai.
func _velocidade_disparo(forca: float, mira: float) -> Vector2:
	var saida := EscalaDnd.velocidade_para_alcance(_longo_px, GRAVIDADE) * _municao.impulso
	saida *= lerpf(FRACAO_MINIMA_DISPARO, 1.0, clampf(forca, 0.0, 1.0))
	var destreza := float(_destreza) / float(Ficha.DESTREZA_REFERENCIA)
	saida *= clampf(destreza, DESTREZA_VELOCIDADE_MINIMA, DESTREZA_VELOCIDADE_MAXIMA)
	var angulo := deg_to_rad(clampf(mira, MIRA_MINIMA, MIRA_MAXIMA))
	return Vector2(cos(angulo) * _direcao, -sin(angulo)) * saida


## Arremesso: tempo de voo pela força (longe sobe mais alto).
func _tempo_de_voo(forca: float) -> float:
	return lerpf(TEMPO_NORMAL, TEMPO_LONGO, clampf(forca, 0.0, 1.0))


## Velocidade inicial para cair a `distancia` (px) à frente em `tempo` (s), saindo da mão.
func _velocidade_para(distancia: float, tempo: float) -> Vector2:
	var subida := (ALTURA_DA_MAO - 0.5 * GRAVIDADE * tempo * tempo) / tempo
	return Vector2(_direcao * distancia / tempo, subida)


## Acertou: o arremesso cai ali; a munição some.
func _ao_acertar() -> void:
	if _municao and _ignora_cobertura:
		return  # o tiro do Atirador de Elite segue e pode acertar quem está atrás
	_hitbox.desligar()
	if _municao:
		queue_free()
		return
	velocity.x = 0.0


## Atirador de Elite: voa sem parar nas paredes e degraus do cenário nem nas criaturas; só o chão (superfície
## que aponta para cima) o faz sumir. Some também depois de um tempo, para não voar para sempre.
func _mover_atravessando(delta: float) -> void:
	_tempo_atravessando += delta
	var destino := global_position + velocity * delta
	var consulta := PhysicsRayQueryParameters2D.create(global_position, destino, CAMADA_MUNDO)
	var achado := get_world_2d().direct_space_state.intersect_ray(consulta)
	if _tempo_atravessando >= TEMPO_MAXIMO_ATRAVESSANDO or (not achado.is_empty() and (achado["normal"] as Vector2).y < NORMAL_MINIMA_DO_CHAO):
		queue_free()
		return
	global_position = destino

## Passou do alcance longo: perde o acerto e cai, sem atravessar.
func _cair_sem_acertar() -> void:
	velocity.x = 0.0
	_hitbox.desligar()


## Além da distância normal, o ataque (rolado no acerto) tem desvantagem. Além da longa, só cai.
## Atirador de Elite tira a desvantagem do alcance longo; o tiro ainda não passa do longo.
func _aplicar_alcance() -> void:
	var dist := absf(global_position.x - _origem_x)
	if _golpe and dist > _normal_px and not _ignora_longo:
		_golpe.desvantagem = true
	if dist >= _longo_px:
		_cair_sem_acertar()


func _pousar() -> void:
	_voando = false
	velocity = Vector2.ZERO
	_hitbox.desligar()
	if _arma.arremesso_de_ponta:
		_sprite.position = Vector2(_direcao * FINCADA, FINCADA)  # a ponta entra um pouco no chão
	else:
		_sprite.rotation_degrees = DesenhoArma.rotacao(_arma, 0.0) * _direcao  # deitada
	_aviso.text = AVISO_PEGAR
	_aviso.show()


func _ao_corroer(quanto: int, limite: int) -> void:
	_penalidade += quanto
	if _penalidade >= limite and _arma:
		derreteu.emit("%s derreteu!" % _arma.nome)
		queue_free()
