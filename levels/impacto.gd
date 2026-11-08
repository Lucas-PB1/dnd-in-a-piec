class_name Impacto
extends Node2D
## Sensação dos golpes ("juice"), tudo por código: quando um golpe ACERTA, o jogo dá uma pausa
## curtinha, a câmera treme e saem faíscas; ao pousar e ao correr, o herói levanta poeira.
## Escuta o sinal `golpe_resolvido` de toda DefesaComponent (as que já existem e as que nascem
## depois), então monstros novos ganham o efeito sem mudar nada neles. Não muda regra nenhuma.

## Camada da hurtbox do herói (4 = hurtbox_jogador, valor 8). O resto é inimigo ou boneco.
const CAMADA_HURTBOX_JOGADOR := 8
## Pausa no impacto (s, em tempo real), tremor (px) e faíscas por tipo de acerto.
const PAUSA_ACERTO := 0.05
const PAUSA_CRITICO := 0.11
const PAUSA_SOFRIDO := 0.07
const PAUSA_MORTE := 0.1
const TREMOR_ACERTO := Vector2(1.5, 0.12)
const TREMOR_CRITICO := Vector2(4.0, 0.22)
const TREMOR_SOFRIDO := Vector2(3.0, 0.2)
const TREMOR_MORTE := Vector2(3.5, 0.25)
const FAISCAS_ACERTO := 6
const FAISCAS_CRITICO := 14
const FAISCAS_SOFRIDO := 9
## Durante a pausa o tempo do jogo anda a esta fração (quase parado).
const ESCALA_NA_PAUSA := 0.04
const COR_FAISCA := Color(1.0, 0.95, 0.7)
const COR_FAISCA_CRITICO := Color(1.0, 0.8, 0.25)
const COR_FAISCA_SOFRIDA := Color(1.0, 0.4, 0.35)
const COR_POEIRA := Color(0.82, 0.76, 0.66, 0.85)
## Poeira: um sopro a cada tanto de tempo correndo (s) e o tamanho dele.
const INTERVALO_POEIRA := 0.11
const POEIRA_CORRIDA := 3
const POEIRA_POUSO := 8
const LADO_PARTICULA := 4

var _pausas_ativas: int = 0
var _tempo_poeira: float = 0.0
var _jogador: Jogador
## Quadradinho branco das partículas (sem textura elas saem com 1 px, quase invisíveis).
var _quadradinho: ImageTexture


func _ready() -> void:
	var imagem := Image.create(LADO_PARTICULA, LADO_PARTICULA, false, Image.FORMAT_RGBA8)
	imagem.fill(Color.WHITE)
	_quadradinho = ImageTexture.create_from_image(imagem)
	z_index = 20  # por cima de tudo, menos da interface
	for defesa in get_tree().root.find_children("*", "DefesaComponent", true, false):
		_escutar(defesa as DefesaComponent)
	for dissolver in get_tree().root.find_children("*", "DissolverComponent", true, false):
		_escutar_morte(dissolver as DissolverComponent)
	get_tree().node_added.connect(_ao_nascer_no)
	var herois := get_tree().root.find_children("*", "Jogador", true, false)
	if not herois.is_empty():
		_jogador = herois[0] as Jogador
		_jogador.aterrissou.connect(_ao_aterrissar)


func _exit_tree() -> void:
	Engine.time_scale = 1.0  # nunca deixa o jogo lento por engano


func _process(delta: float) -> void:
	if _jogador == null or not is_instance_valid(_jogador):
		return
	_tempo_poeira -= delta
	if _tempo_poeira <= 0.0 and _jogador.esta_correndo() and _jogador.is_on_floor():
		_tempo_poeira = INTERVALO_POEIRA
		_poeira(_jogador.global_position + Vector2(-_jogador.direcao_olhar * 8.0, -1.0), POEIRA_CORRIDA, Vector2(-_jogador.direcao_olhar, -0.2))


func _ao_nascer_no(no: Node) -> void:
	if no is DissolverComponent:
		_escutar_morte(no as DissolverComponent)
	if no is DefesaComponent:
		_escutar(no as DefesaComponent)


func _escutar_morte(dissolver: DissolverComponent) -> void:
	if not dissolver.morrendo.is_connected(_ao_morrer_criatura):
		dissolver.morrendo.connect(_ao_morrer_criatura)


## Uma criatura morrendo ao morrer: pausa e tremor um pouco mais fortes que num acerto comum.
func _ao_morrer_criatura(_onde: Vector2) -> void:
	_pausar(PAUSA_MORTE)
	var camera := get_viewport().get_camera_2d()
	if camera is CameraJogador:
		(camera as CameraJogador).tremer(TREMOR_MORTE.x, TREMOR_MORTE.y)


func _escutar(defesa: DefesaComponent) -> void:
	if not defesa.golpe_resolvido.is_connected(_ao_resolver_golpe):
		defesa.golpe_resolvido.connect(_ao_resolver_golpe.bind(defesa))


func _ao_resolver_golpe(resultado: Combate.Resultado, _origem: Vector2, defesa: DefesaComponent) -> void:
	if not resultado.acertou and not resultado.raspao:
		return
	var no_heroi := (defesa.hurtbox.collision_layer & CAMADA_HURTBOX_JOGADOR) != 0
	var onde := defesa.hurtbox.global_position
	if no_heroi:
		_impactar(onde, PAUSA_SOFRIDO, TREMOR_SOFRIDO, FAISCAS_SOFRIDO, COR_FAISCA_SOFRIDA)
	elif resultado.critico:
		_impactar(onde, PAUSA_CRITICO, TREMOR_CRITICO, FAISCAS_CRITICO, COR_FAISCA_CRITICO)
	else:
		_impactar(onde, PAUSA_ACERTO, TREMOR_ACERTO, FAISCAS_ACERTO, COR_FAISCA)


func _impactar(onde: Vector2, pausa: float, tremor: Vector2, faiscas: int, cor: Color) -> void:
	_pausar(pausa)
	var camera := get_viewport().get_camera_2d()
	if camera is CameraJogador:
		(camera as CameraJogador).tremer(tremor.x, tremor.y)
	_soltar(onde, faiscas, cor, Vector2.UP, 180.0, 120.0, 0.3, 0.6)


func _ao_aterrissar() -> void:
	if _jogador:
		_poeira(_jogador.global_position + Vector2(0.0, -1.0), POEIRA_POUSO, Vector2.UP)


## Quase para o tempo por `segundos` reais. Pausas que se sobrepõem se juntam.
func _pausar(segundos: float) -> void:
	_pausas_ativas += 1
	Engine.time_scale = ESCALA_NA_PAUSA
	await get_tree().create_timer(segundos, true, false, true).timeout  # ignora a escala do tempo
	_pausas_ativas -= 1
	if _pausas_ativas <= 0:
		_pausas_ativas = 0
		Engine.time_scale = 1.0


func _poeira(onde: Vector2, quantidade: int, direcao: Vector2) -> void:
	_soltar(onde, quantidade, COR_POEIRA, direcao, 40.0, 25.0, 0.35, 0.9, 40.0)


## Solta um sopro de quadradinhos que sobem e somem. `velocidade` e `espalhar` em px/s.
func _soltar(onde: Vector2, quantidade: int, cor: Color, direcao: Vector2, velocidade: float, espalhar: float, vida: float, tamanho: float, gravidade: float = 400.0) -> void:
	var sopro := CPUParticles2D.new()
	sopro.position = onde
	sopro.one_shot = true
	sopro.explosiveness = 1.0
	sopro.amount = quantidade
	sopro.lifetime = vida
	sopro.direction = direcao
	sopro.spread = 70.0
	sopro.initial_velocity_min = maxf(velocidade - espalhar, 0.0)
	sopro.initial_velocity_max = velocidade + espalhar
	sopro.gravity = Vector2(0.0, gravidade)
	sopro.scale_amount_min = tamanho * 0.6
	sopro.scale_amount_max = tamanho
	sopro.color = cor
	sopro.texture = _quadradinho
	sopro.emitting = true
	add_child(sopro)
	get_tree().create_timer(vida + 0.2, true, false, true).timeout.connect(sopro.queue_free)
