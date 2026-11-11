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
## Medidas da arte dos efeitos (Kenney via tools/montar_efeitos_golpe.gd): raio do arco
## (metade da célula 64) com centro no meio do quadro; rastro 64 px; impacto 48 px.
const RAIO_DO_ARCO := 28.0
const CENTRO_DO_ARCO := Vector2.ZERO
const COMPRIMENTO_DO_RASTRO := 64.0
const TAMANHO_DO_IMPACTO := 48.0
## O impacto cresce com a arma, entre estes limites.
const ESCALA_IMPACTO := Vector2(0.8, 1.4)
## Golpe extra de duas armas, cruzado (X): poses da 2ª arma [tempo, ângulo, mão x, mão y,
## acerta]. A principal faz o espelho (de baixo para cima), e as duas se cruzam no meio.
const POSES_CRUZADO := [[0.0, -70, -2, -4, false], [0.06, -100, -4, -6, true],
	[0.15, 60, 8, 2, false], [0.28, 35, 0, 0, false]]
## Carregando o arremesso: a mão sobe e recua (braço armado acima do ombro) e a arma vai
## de quase deitada a apontando para cima. Tudo à vista, para o jogador ver a força subir.
const ANGULOS_CARGA := Vector2(-15.0, -60.0)
const RECUO_CARGA := Vector2(-13.0, -7.0)
## Disparo: quadros da carga (preparo, sobe, mira, puxa, puxa, cheio), depois soltura e volta.
const PASSOS_DA_CARGA := 6
const QUADRO_SOLTURA := 6
const QUADRO_VOLTA := 7
## Fora do tiro: a arma de disparo fica baixa e relaxada na mão (no lugar do ícone).
const QUADRO_DESCANSO := 8
## Fração do gesto depois de soltar em que a soltura vira a volta.
const FIM_DA_SOLTURA := 0.45

var _arma: Arma
var _golpe: Golpe
var _tempo: float = 0.0
var _golpeando: bool = false
var _direcao: int = 1
var _golpe_secundario: bool = false
var _mao: Vector2 = Vector2.ZERO
## Arma principal no golpe cruzado (null fora dele) e a soma dos ângulos do espelho.
var _cruzada: Arma
var _soma_cruzado: float = 0.0
## Carga (0 a 1 no arremesso; no disparo, a força, que pode parar antes de 1).
## Negativo = não está carregando.
var _carga: float = -1.0
## Mira da carga (graus; positivo = para cima, além do ângulo da força).
var _mira: float = 0.0
## Soltura do disparo: mostra o último quadro em vez de inclinar a arma.
var _soltando: bool = false
## Quanto do gesto depois da soltura já passou (0 a 1).
var _progresso_soltura: float = 0.0
## A arma na mão é de disparo (quadros próprios; a empunhadura fica na mão).
var _disparando: bool = false
## A arma carregada não aponta para trás do corpo nem para dentro do chão.
const LIMITE_MIRA_VISUAL := Vector2(-100.0, 45.0)

@onready var _espada: Sprite2D = $Espada
@onready var _espada_cruzada: Sprite2D = $EspadaCruzada
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
	_disparando = not arma.quadros_disparo.is_empty()
	if _carga >= 0.0 and _disparando:
		_mostrar_disparo(arma)
		return
	if _disparando and arma.quadros_disparo.size() > QUADRO_DESCANSO:
		_mostrar_descanso(arma)
		return
	if _carga >= 0.0:
		position = mao + RECUO_CARGA * _carga
		var angulo_carga := clampf(lerpf(ANGULOS_CARGA.x, ANGULOS_CARGA.y, _carga) - _mira, LIMITE_MIRA_VISUAL.x, LIMITE_MIRA_VISUAL.y)
		_espada.rotation_degrees = DesenhoArma.rotacao(arma, angulo_carga)
		return
	_espada.rotation_degrees = DesenhoArma.rotacao(arma, DesenhoArma.angulo_sem_tocar_chao(angulo, mao.y, arma, FOLGA_DO_CHAO))


## Começa um golpe com a `arma`. `secundaria` = o 2º golpe, da arma da outra mão: com a
## `principal`, as duas cruzam em X (a área de acerto segue a da outra mão).
## Quem for atingido resolve o `golpe` contra a própria CA.
func golpear(arma: Arma, golpe: Golpe, secundaria: bool = false, principal: Arma = null) -> void:
	_arma = _versao_cruzada(arma) if principal else arma
	_cruzada = principal
	DesenhoArma.preparar(_espada_cruzada, principal)
	_golpe = golpe
	_tempo = 0.0
	_golpeando = true
	_golpe_secundario = secundaria
	DesenhoArma.preparar(_espada, arma)
	_efeito.modulate = arma.cor_corte
	_efeito.hide()
	_aplicar_pose()


## Pose de carregar. `fracao` 0 a 1 (no disparo, a força); negativo = volta ao repouso.
## `mira` gira o quadro (graus, positivo = para cima). `soltando` mostra a soltura e depois a
## volta, conforme o `progresso` do gesto depois de soltar (0 a 1).
func carregar_arremesso(fracao: float, mira: float = 0.0, soltando: bool = false, progresso: float = 0.0) -> void:
	_carga = fracao
	_mira = mira
	_soltando = soltando and fracao >= 0.0
	_progresso_soltura = progresso


## A mão saiu do lugar da animação (golpe ou carga do arremesso): a camada da mão não deve
## cobrir a arma. No disparo a mão segura a empunhadura parada: a camada fica por cima.
func mao_fora_do_lugar() -> bool:
	return _golpeando or (_carga >= 0.0 and not _disparando)


## No golpe de corte (da mão ou o extra das duas armas; não nas armas desenhadas quadro a quadro), o corpo do
## herói faz o movimento: a mão sobe e desce no desenho, e a arma vai presa a ela.
func corpo_acompanha() -> bool:
	var da_vez := _cruzada != null or not _golpe_secundario
	return _golpeando and da_vez and _arma != null and _arma.efeito == Arma.EFEITO_CORTE and _arma.quadros.is_empty()


## O golpe extra das duas armas (cruzado) tem o corpo próprio, `corte_duplo`.
func golpe_cruzado() -> bool:
	return _golpeando and _cruzada != null


## Quadro do corpo no instante do golpe: os quadros antes de `quadro_do_acerto` (a preparação) cobrem o tempo
## até a arma começar a acertar; dali em diante, o resto cobre o golpe e a volta.
func quadro_do_corpo(quadros: int, quadro_do_acerto: int) -> int:
	var inicio := _inicio_do_acerto()
	if _tempo < inicio:
		return int(_tempo / maxf(inicio, 0.001) * quadro_do_acerto)
	var resto := (_tempo - inicio) / maxf(_arma.duracao() - inicio, 0.001)
	return mini(quadro_do_acerto + int(resto * (quadros - quadro_do_acerto)), quadros - 1)


func _inicio_do_acerto() -> float:
	for pose in _arma.poses:
		if pose.acerta:
			return pose.tempo
	return _arma.duracao() * 0.5


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
	position = _mao if corpo_acompanha() else _mao + pose.mao  # com o corpo animado, a mão do desenho já se move
	if _arma.quadros.is_empty():
		_espada.rotation_degrees = DesenhoArma.rotacao(_arma, pose.angulo)
	else:
		_mostrar_quadro(_arma.indice_da_pose(_tempo))
	if _cruzada:
		_espada_cruzada.rotation_degrees = DesenhoArma.rotacao(_cruzada, _soma_cruzado - pose.angulo)
	var comprimento := _arma.comprimento * pose.escala + FOLGA_PONTA
	var retangulo := _forma.shape as RectangleShape2D
	retangulo.size = Vector2(comprimento, ESPESSURA_ACERTO)
	_forma.rotation_degrees = pose.angulo
	_forma.position = Vector2.from_angle(deg_to_rad(pose.angulo)) * comprimento / 2.0


## Cópia da arma da outra mão com o movimento cruzado (e o passo para chegar a 5 pés).
func _versao_cruzada(arma: Arma) -> Arma:
	var versao := arma.duplicate() as Arma
	versao.quadros = []
	versao.poses = []
	for p: Array in POSES_CRUZADO:
		versao.poses.append(PoseGolpe.criar(p[0], p[1], Vector2(p[2], p[3]), 1.0, p[4]))
	versao.passo = maxf(EscalaDnd.PONTA_5_PES - versao.alcance_da_ponta(), 0.0)
	versao.efeito = Arma.EFEITO_CORTE
	var acerto := versao.poses.filter(func(pose: PoseGolpe) -> bool: return pose.acerta)[0] as PoseGolpe
	_soma_cruzado = acerto.angulo + versao.poses[versao.poses.find(acerto) + 1].angulo
	return versao


## A força escolhe o quadro (cheio só se a carga chega lá). A mira gira em volta da mão.
func _mostrar_disparo(arma: Arma) -> void:
	var indice := mini(int(_carga * PASSOS_DA_CARGA), PASSOS_DA_CARGA - 1)
	if _soltando:
		indice = QUADRO_SOLTURA if _progresso_soltura < FIM_DA_SOLTURA else QUADRO_VOLTA
	indice = mini(indice, arma.quadros_disparo.size() - 1)
	_espada.texture = arma.quadros_disparo[indice]
	_espada.offset = -arma.pegada_quadros
	_espada.rotation_degrees = -_mira


## Arma de disparo parada: o quadro de descanso (já desenhado baixo e sem tocar o chão).
func _mostrar_descanso(arma: Arma) -> void:
	_espada.texture = arma.quadros_disparo[QUADRO_DESCANSO]
	_espada.offset = -arma.pegada_quadros
	_espada.rotation = 0.0


## Arma flexível (mangual, chicote): mostra o quadro desenhado da pose, sem girar.
func _mostrar_quadro(indice: int) -> void:
	_espada.texture = _arma.quadros[mini(indice, _arma.quadros.size() - 1)]
	_espada.offset = -_arma.pegada_quadros
	_espada.rotation = 0.0


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
	_cruzada = null
	_espada_cruzada.hide()
	_hitbox.desligar()
