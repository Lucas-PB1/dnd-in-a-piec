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
## Com a lâmina mais para trás que isto (graus; -90 = para cima), o golpe ainda está sendo
## armado atrás da cabeça e não acerta: só acerta quem está à frente.
const ANGULO_ATRAS := -100.0
## Medidas da arte dos efeitos (tools/gerar_arte_provisoria.gd): raio do arco e onde fica o
## centro dele no quadro; comprimento do rastro; tamanho do impacto.
const RAIO_DO_ARCO := 22.0
const CENTRO_DO_ARCO := Vector2(9.6, 0.0)
const COMPRIMENTO_DO_RASTRO := 48.0
const TAMANHO_DO_IMPACTO := 40.0
## O impacto cresce com a arma, entre estes limites.
const ESCALA_IMPACTO := Vector2(0.8, 1.4)

var _arma: Arma
var _golpe: Golpe
var _tempo: float = 0.0
var _golpeando: bool = false
var _direcao: int = 1
var _golpe_secundario: bool = false
var _mao: Vector2 = Vector2.ZERO

@onready var _espada: Sprite2D = $Espada
@onready var _efeito: AnimatedSprite2D = $Efeito
@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _forma: CollisionShape2D = $Hitbox/Forma


func _ready() -> void:
	_espada.hide()
	_efeito.hide()
	_efeito.animation_finished.connect(_efeito.hide)


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
	_efeito.modulate = arma.cor_corte
	_efeito.hide()
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
		_efeito.hide()


func _physics_process(delta: float) -> void:
	if not _golpeando:
		return
	_tempo += delta
	_aplicar_pose()
	_atualizar_acerto()
	if _tempo >= _arma.duracao():
		_terminar()


## Espelha a arma, o efeito e a área do golpe. Ao trocar de lado, não deixa a
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
		_mostrar_efeito_do_inicio()
	elif not acertando and _hitbox.esta_ligada():
		_hitbox.desligar()
		if _arma.efeito == Arma.EFEITO_IMPACTO:
			_mostrar_impacto()


## Começo do trecho que acerta: arco nos cortes (gira junto, com centro na mão e raio do
## tamanho da arma), rastro nas estocadas (da mão até a ponta, na direção do golpe).
func _mostrar_efeito_do_inicio() -> void:
	var inicio := _arma.pose_em(_tempo)
	var fim := _arma.pose_em(_arma.fim_do_acerto())
	var alcance := _arma.comprimento * maxf(inicio.escala, fim.escala)
	match _arma.efeito:
		Arma.EFEITO_CORTE:
			_tocar_efeito(Arma.EFEITO_CORTE, Vector2.ZERO, (inicio.angulo + fim.angulo) / 2.0,
				Vector2.ONE * alcance / RAIO_DO_ARCO, CENTRO_DO_ARCO)
		Arma.EFEITO_RASTRO:
			_tocar_efeito(Arma.EFEITO_RASTRO, Vector2.ZERO, fim.angulo,
				Vector2(alcance / COMPRIMENTO_DO_RASTRO, 1.0), Vector2(COMPRIMENTO_DO_RASTRO / 2.0, 0.0))


## Fim do trecho que acerta de um contundente: impacto onde a cabeça da arma parou.
func _mostrar_impacto() -> void:
	var pose := _arma.pose_em(_tempo)
	var ponta := Vector2.from_angle(deg_to_rad(pose.angulo)) * _arma.comprimento * pose.escala
	var tamanho := clampf(_arma.comprimento / TAMANHO_DO_IMPACTO, ESCALA_IMPACTO.x, ESCALA_IMPACTO.y)
	_tocar_efeito(Arma.EFEITO_IMPACTO, ponta, 0.0, Vector2.ONE * tamanho, Vector2.ZERO)


## Toca a `animacao` do efeito em `posicao` (relativa à mão), girada `angulo` graus.
## `deslocamento` põe o ponto certo da arte na origem (centro do arco, começo do rastro).
## O efeito some sozinho quando a animação acaba (pode passar do fim do golpe).
func _tocar_efeito(animacao: StringName, posicao: Vector2, angulo: float, escala: Vector2, deslocamento: Vector2) -> void:
	_efeito.position = posicao
	_efeito.rotation_degrees = angulo
	_efeito.scale = escala
	_efeito.offset = deslocamento
	_efeito.reset_physics_interpolation()  # não "arrastar" da posição do efeito anterior
	_efeito.show()
	_efeito.play(animacao)


## Fim do golpe: a arma volta para o repouso no próximo seguir_mao().
func _terminar() -> void:
	_golpeando = false
	_golpe_secundario = false
	_hitbox.desligar()
