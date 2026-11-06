class_name AtaqueJogador
extends Node2D
## Arma na mão do herói. Fora do golpe, a arma equipada fica na mão, no ângulo de
## descanso da animação. No golpe, toca as poses da Arma (cada arma tem o seu movimento),
## a área de acerto acompanha a arma (da pegada até a ponta) e liga só nos trechos que
## acertam. O dono chama seguir_mao() todo quadro e golpear() para golpear (call down).

## Em repouso, a ponta da arma fica pelo menos isto (px) acima do chão (os pés).
const FOLGA_DO_CHAO := 2.0
## Grossura da área de acerto em volta da arma (px).
const ESPESSURA_ACERTO := 14.0
## A área passa um pouco da ponta (px): o golpe "pega" quem está encostando nela.
const FOLGA_PONTA := 6.0
## Abaixo deste giro (graus) no trecho que acerta, é estocada: sem o arco de corte.
const GIRO_MINIMO_CORTE := 60.0
## Tamanho do arco de corte para uma arma deste comprimento (px); escala com a arma.
const COMPRIMENTO_DO_CORTE := 40.0
## Com a lâmina mais para trás que isto (graus; -90 = para cima), o golpe ainda está sendo
## armado atrás da cabeça e não acerta: só acerta quem está à frente.
const ANGULO_ATRAS := -100.0
## O arco de corte aparece a esta fração do comprimento da arma, e nunca menor que ESCALA_MINIMA_CORTE.
const POSICAO_DO_CORTE := 0.6
const ESCALA_MINIMA_CORTE := 0.6

var _arma: Arma
var _golpe: Golpe
var _tempo: float = 0.0
var _golpeando: bool = false
var _direcao: int = 1
var _golpe_secundario: bool = false
var _mao: Vector2 = Vector2.ZERO

@onready var _espada: Sprite2D = $Espada
@onready var _corte: AnimatedSprite2D = $Corte
@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _forma: CollisionShape2D = $Hitbox/Forma


func _ready() -> void:
	_espada.hide()
	_corte.hide()


## Coloca a arma na `mao` (pixels, relativo aos pés, já espelhado) virada para `direcao`.
## Fora do golpe, mostra a `arma` em repouso no `angulo` (graus), menos inclinada se for
## comprida demais e a ponta fosse entrar no chão. Arma sem imagem (soco) some.
func seguir_mao(mao: Vector2, angulo: float, direcao: int, arma: Arma) -> void:
	_mao = mao
	_virar(direcao)
	if _golpeando:
		return
	position = mao
	_espada.position = Vector2.ZERO
	_espada.scale = Vector2.ONE
	DesenhoArma.preparar(_espada, arma)
	_espada.rotation_degrees = DesenhoArma.rotacao(arma, _angulo_sem_tocar_chao(angulo, mao.y, arma))


## Começa um golpe com a `arma`. `secundaria` = o 2º golpe, da arma da outra mão.
## Quem for atingido resolve o `golpe` contra a própria CA.
func golpear(arma: Arma, golpe: Golpe, secundaria: bool = false) -> void:
	_arma = arma
	_golpe = golpe
	_tempo = 0.0
	_golpeando = true
	_golpe_secundario = secundaria
	DesenhoArma.preparar(_espada, arma)
	_corte.modulate = arma.cor_corte
	_corte.hide()
	_aplicar_pose()


func esta_golpeando() -> bool:
	return _golpeando


## O golpe atual é o da arma da outra mão (o sprite de trás deve sumir para não duplicar).
func golpe_da_secundaria() -> bool:
	return _golpeando and _golpe_secundario


## Velocidade (px/s; positivo = para a frente) do passo do golpe, como uma estocada de
## esgrima: avança até o fim do trecho que acerta e volta na recuperação (golpear várias
## vezes não faz o herói sair andando). 0 fora do golpe ou se a arma não precisa de passo.
func velocidade_do_passo() -> float:
	if not _golpeando or _arma.passo <= 0.0:
		return 0.0
	var fim_ida := _arma.fim_do_acerto()
	if _tempo < fim_ida:
		return _arma.passo / fim_ida
	return -_arma.passo / maxf(_arma.duracao() - fim_ida, 0.001)


## Interrompe o golpe no meio (ex.: o herói apanhou).
func cancelar() -> void:
	if _golpeando:
		_terminar()


func _physics_process(delta: float) -> void:
	if not _golpeando:
		return
	_tempo += delta
	_aplicar_pose()
	_atualizar_acerto()
	if _tempo >= _arma.duracao():
		_terminar()


## Espelha a arma, o corte e a área do golpe. Ao trocar de lado, não deixa a
## interpolação "arrastar" a espada pelo meio do corpo.
func _virar(direcao: int) -> void:
	if direcao == _direcao:
		return
	_direcao = direcao
	scale.x = direcao
	reset_physics_interpolation()


## Põe a arma e a área de acerto na pose do instante atual.
func _aplicar_pose() -> void:
	var pose := _arma.pose_em(_tempo)
	position = _mao + pose.mao
	if _arma.quadros.is_empty():
		_espada.rotation_degrees = DesenhoArma.rotacao(_arma, pose.angulo)
	else:
		_mostrar_quadro(_arma.indice_da_pose(_tempo))
	var comprimento := _arma.comprimento * pose.escala + FOLGA_PONTA
	var retangulo := _forma.shape as RectangleShape2D
	retangulo.size = Vector2(comprimento, ESPESSURA_ACERTO)
	_forma.rotation_degrees = pose.angulo
	_forma.position = Vector2.from_angle(deg_to_rad(pose.angulo)) * comprimento / 2.0


## Arma flexível (mangual, chicote): mostra o quadro desenhado da pose, sem girar.
func _mostrar_quadro(indice: int) -> void:
	_espada.texture = _arma.quadros[mini(indice, _arma.quadros.size() - 1)]
	_espada.offset = -_arma.pegada_quadros
	_espada.rotation = 0.0


## Limita o ângulo para baixo: a ponta não passa dos pés. `altura_mao` = y da mão
## (negativo = acima dos pés).
func _angulo_sem_tocar_chao(angulo: float, altura_mao: float, arma: Arma) -> float:
	if arma.comprimento <= 0.0:
		return angulo
	var seno_maximo := clampf((-altura_mao - FOLGA_DO_CHAO) / arma.comprimento, -1.0, 1.0)
	return minf(angulo, rad_to_deg(asin(seno_maximo)))


func _atualizar_acerto() -> void:
	var acertando := _arma.acertando(_tempo) and _arma.pose_em(_tempo).angulo > ANGULO_ATRAS
	if acertando and not _hitbox.esta_ligada():
		_hitbox.ligar(_golpe)
		_mostrar_corte()
	elif not acertando and _hitbox.esta_ligada():
		_hitbox.desligar()


## Arco de corte no meio do giro do trecho que acerta, do tamanho da arma.
## Estocada (quase sem giro) não mostra arco.
func _mostrar_corte() -> void:
	var inicio := _arma.pose_em(_tempo)
	var fim := _arma.pose_em(_arma.fim_do_acerto())
	if absf(fim.angulo - inicio.angulo) < GIRO_MINIMO_CORTE:
		return
	var meio := deg_to_rad((inicio.angulo + fim.angulo) / 2.0)
	_corte.position = Vector2.from_angle(meio) * _arma.comprimento * POSICAO_DO_CORTE
	_corte.scale = Vector2.ONE * maxf(_arma.comprimento / COMPRIMENTO_DO_CORTE, ESCALA_MINIMA_CORTE)
	_corte.show()
	_corte.play(&"corte")


## Fim do golpe: a arma volta para o repouso no próximo seguir_mao().
func _terminar() -> void:
	_golpeando = false
	_golpe_secundario = false
	_hitbox.desligar()
	_corte.hide()
