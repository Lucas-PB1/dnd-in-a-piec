class_name Jogador
extends CharacterBody2D
## Herói de ação lateral. Este script guarda as "ferramentas de física" (gravidade, pulo,
## movimento) e repassa o comportamento para a MaquinaEstados (estados em estados/).
## Visual e câmera são filhos: o Jogador chama funções deles (call down).

## Emitido no quadro em que o pulo começa.
signal pulou
## Emitido no quadro em que toca o chão depois de estar no ar.
signal aterrissou
## Emitido quando volta para o início (ex.: caiu num buraco).
signal reapareceu
## Emitido quando a vida muda (ex.: ao criar o personagem).
signal vida_mudou(atual: int, maxima: int)

## Números de balanceamento (velocidades, pulo). Padrão: data/jogador_padrao.tres.
@export var stats: StatsJogador
## Itens com que o herói começa (ficam no inventário, sem equipar).
@export var itens_iniciais: Array[Item] = []
## Golpe usado quando não há arma na mão (soco de D&D). Padrão: data/ataque_desarmado.tres.
@export var ataque_desarmado: Arma
## Classe de D&D (dado de vida, atributos sugeridos). Padrão: data/classe_guerreiro.tres.
@export var classe: ClasseRPG
## Se cair abaixo desta altura (Y), volta para o início.
@export var limite_queda: float = 600.0

## Para onde o herói está olhando: 1 = direita, -1 = esquerda.
var direcao_olhar: int = 1
var posicao_inicial: Vector2
## Ficha de D&D (atributos). Começa com a sugestão da classe; a tela de criação troca.
var ficha: Ficha
## Itens carregados e equipados.
var inventario := Inventario.new()

var _rng := RandomNumberGenerator.new()
var _contador_coyote: float = 0.0
var _contador_buffer: float = 0.0
var _pedido_corrida: int = 0
var _estava_no_chao: bool = true
var _toque_duplo: ToqueDuplo

@onready var _maquina: MaquinaEstados = $MaquinaEstados
@onready var _animacao: AnimacaoJogador = $Sprite
@onready var _camera: CameraJogador = $Camera
@onready var _ataque: AtaqueJogador = $Ataque
@onready var _vida: HealthComponent = $Vida


func _ready() -> void:
	# Valores padrão seguros: a cena aberta sozinha (F6) continua funcionando.
	if stats == null:
		stats = StatsJogador.new()
	if ataque_desarmado == null:
		ataque_desarmado = Arma.new()
	for item in itens_iniciais:
		inventario.adicionar(item)
	if classe == null:
		classe = ClasseRPG.new()
	posicao_inicial = global_position
	_toque_duplo = ToqueDuplo.new(stats.janela_toque_duplo)
	aterrissou.connect(_animacao.tocar_aterrissagem)
	_vida.vida_mudou.connect(vida_mudou.emit)
	configurar_ficha(Ficha.new(classe, classe.atributos_sugeridos))
	_maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	_atualizar_contadores(delta)
	_maquina.processar_fisica(delta)
	move_and_slide()
	_checar_aterrissagem()
	_animacao.atualizar(_maquina.nome_estado_atual(), velocity, direcao_olhar, stats)
	_ataque.seguir_mao(_animacao.ponto_da_mao(), _animacao.angulo_descanso(), direcao_olhar, arma_atual())
	_camera.olhar_para(direcao_olhar)
	if global_position.y > limite_queda:
		reaparecer()


# --- API pública (para a fase/main e para os testes) ----------------------------

## Define onde o herói começa e o coloca lá.
func posicionar_no_inicio(posicao: Vector2) -> void:
	posicao_inicial = posicao
	global_position = posicao
	reset_physics_interpolation()


## Troca a ficha de D&D (ex.: vinda da tela de criação) e recalcula a vida.
func configurar_ficha(nova: Ficha) -> void:
	ficha = nova
	classe = nova.classe
	_vida.configurar(ficha.vida_maxima())


func vida_atual() -> int:
	return _vida.vida_atual


func vida_maxima() -> int:
	return _vida.vida_maxima


## Impede a câmera de mostrar fora da `area` da fase (pixels).
func definir_limites_camera(area: Rect2) -> void:
	_camera.definir_limites(area)


## Volta para o início da fase.
func reaparecer() -> void:
	posicionar_no_inicio(posicao_inicial)
	velocity = Vector2.ZERO
	_maquina.trocar(&"NoAr")
	reapareceu.emit()


func nome_estado() -> StringName:
	return _maquina.nome_estado_atual()


func esta_correndo() -> bool:
	return nome_estado() == &"Correndo"


# --- Ferramentas de física (usadas pelos estados) -------------------------------

## Direção segurada: -1 (esquerda) a 1 (direita).
func direcao() -> float:
	return Input.get_axis("mover_esquerda", "mover_direita")


## Direção do toque duplo neste quadro (-1 ou 1), ou 0 se não houve.
func pediu_corrida() -> int:
	return _pedido_corrida


func pediu_ataque() -> bool:
	return Input.is_action_just_pressed("atacar")


## Arma na mão, ou o ataque desarmado se a mão estiver vazia.
func arma_atual() -> Arma:
	var na_mao := inventario.equipado(Item.ESPACO_MAO) as Arma
	return na_mao if na_mao else ataque_desarmado


## Começa um golpe com a arma atual, para o lado em que o herói olha.
## O dano é rolado no início de cada golpe (dados da arma + modificador da ficha).
func iniciar_golpe() -> void:
	var arma := arma_atual()
	_ataque.golpear(arma, ficha.rolar_dano(arma, _rng))


func esta_golpeando() -> bool:
	return _ataque.esta_golpeando()


func aplicar_gravidade(delta: float) -> void:
	var g := stats.gravidade() if velocity.y < 0.0 else stats.gravidade() * stats.multiplicador_queda
	velocity.y = minf(velocity.y + g * delta, stats.velocidade_max_queda)


## Pula se o botão foi apertado há pouco (buffer) e ainda está no chão ou no coyote time.
func tentar_pular() -> bool:
	if _contador_buffer <= 0.0 or _contador_coyote <= 0.0:
		return false
	velocity.y = -stats.forca_pulo()
	_contador_buffer = 0.0
	_contador_coyote = 0.0
	pulou.emit()
	return true


## Pulo de altura variável: soltou o botão subindo -> corta a subida.
func cortar_pulo_se_soltou() -> void:
	if Input.is_action_just_released("pular") and velocity.y < 0.0:
		velocity.y *= stats.corte_pulo


## Acelera até `dir * maxima` (px/s). Com `virar`, o herói olha para o lado do movimento.
func mover_horizontal(dir: float, maxima: float, delta: float, virar: bool = true) -> void:
	velocity.x = move_toward(velocity.x, dir * maxima, _taxa_aceleracao(dir) * delta)
	if virar and dir != 0.0:
		direcao_olhar = 1 if dir > 0.0 else -1


# --- Interno --------------------------------------------------------------------

func _atualizar_contadores(delta: float) -> void:
	# Coyote time: um tempinho de "graça" depois de sair da beirada.
	_contador_coyote = stats.tempo_coyote if is_on_floor() else _contador_coyote - delta
	# Buffer: guarda o aperto do botão de pulo por um instante.
	_contador_buffer = stats.tempo_buffer if Input.is_action_just_pressed("pular") else _contador_buffer - delta
	# Toque duplo para correr.
	_toque_duplo.janela = stats.janela_toque_duplo
	var apertada := _direcao_apertada_agora()
	_pedido_corrida = apertada if _toque_duplo.registrar(apertada, delta) else 0


func _direcao_apertada_agora() -> int:
	if Input.is_action_just_pressed("mover_direita"):
		return 1
	if Input.is_action_just_pressed("mover_esquerda"):
		return -1
	return 0


func _taxa_aceleracao(dir: float) -> float:
	if not is_on_floor():
		return stats.aceleracao_no_ar
	return stats.aceleracao if dir != 0.0 else stats.desaceleracao


func _checar_aterrissagem() -> void:
	if is_on_floor() and not _estava_no_chao:
		aterrissou.emit()
	_estava_no_chao = is_on_floor()
