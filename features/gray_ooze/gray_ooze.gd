class_name GrayOoze
extends CharacterBody2D
## Gray Ooze (D&D 5e): gosma lenta que persegue o alvo que percebe e ataca com o Pseudópode
## no ritmo da iniciativa. Números em data/gray_ooze.tres (CriaturaRPG). Comportamento nos
## estados (estados/). Não conhece o herói: recebe um alvo qualquer por definir_alvo().

## Emitido quando termina de morrer (antes de sumir).
signal morreu
## Emitido no brilho do aviso antes do Pseudópode (Sons toca a voz da espécie).
signal avisou_ataque

## Igual à beira do goblin; extrair se uma terceira criatura precisar.
const DISTANCIA_BEIRA := 14.0
const FOLGA_PE := 6.0
const PROFUNDIDADE_BEIRA := 20.0
const MASCARA_MUNDO := 1
const GRUPO_ALIADOS := &"monstros"
const CHEGOU_ANDAR := 6.0
const MOTIVO_FERIDO := TaticaDeCriatura.MOTIVO_FERIDO

## Bloco de estatísticas. Padrão: data/gray_ooze.tres.
@export var criatura: CriaturaRPG
## Altura do corpo usada na área do Pseudópode (px).
@export var altura_pseudopode: float = 24.0
## Metade da largura do corpo (px): o Pseudópode começa a partir daqui.
@export var meia_largura_corpo: float = 20.0
## Altura do peito (px acima dos pés) para cobertura e linha atrás ao recuar.
@export var altura_peito: float = 20.0
## Empurrar (maestria): velocidade com que o empurrão o desloca (px/s).
@export var velocidade_empurrao: float = 320.0
## Achatamento do sprite enquanto está Caído (multiplica a escala da cena).
@export var escala_caido: Vector2 = Vector2(1.25, 0.55)
## Cor do brilho do aviso antes do Pseudópode.
@export var cor_aviso: Color = Color(1.0, 0.9, 0.35)

## Alvo perseguido (ex.: o herói). Sem alvo, fica parado.
var alvo: Node2D
## Para onde olha: 1 = direita, -1 = esquerda.
var direcao_olhar: int = -1

var _rng := RandomNumberGenerator.new()
var _tempo_desde_ataque: float = INF
var _gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")
## Quanto ainda falta do empurrão (px, com sinal).
var _empurrao_restante: float = 0.0
var _saltador: SaltadorDeMonstro
## Cobertura, flanqueio e estratégia.
var _tatica: TaticaDeCriatura
var _posicao_sprite: Vector2
## Escala do sprite na cena (a arte do Ooze é ampliada 2x): Caído achata a partir dela.
var _escala_sprite: Vector2

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _tremor: TremorComponent = $Tremor
@onready var _dissolver: DissolverComponent = $Dissolver
@onready var _vida: HealthComponent = $Vida
@onready var _defesa: DefesaComponent = $Defesa
@onready var _texto: TextoFlutuanteComponent = $Texto
@onready var _pseudopode: HitboxComponent = $Pseudopode
@onready var _forma_pseudopode: CollisionShape2D = $Pseudopode/Forma
@onready var _maquina: MaquinaEstados = $MaquinaEstados
@onready var _condicoes: CondicoesComponent = $Condicoes


func _ready() -> void:
	if criatura == null:
		criatura = CriaturaRPG.new()  # cena aberta sozinha (F6) continua funcionando
	_saltador = MontagemDeCriatura.criar_saltador(self, criatura, _gravidade)
	MontagemDeCriatura.aplicar_ficha(criatura, _vida, _defesa, _condicoes, _rng, _texto)
	MontagemDeCriatura.ligar_sinais_padrao(
		_defesa, _vida, _dissolver, _ao_resolver_golpe, _ao_morrer, terminar_de_morrer
	)
	_tatica = TaticaDeCriatura.new(criatura)
	_preparar_condicoes()
	_posicao_sprite = _sprite.position
	_escala_sprite = _sprite.scale
	_preparar_pseudopode()
	_maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	_tempo_desde_ataque += delta
	_saltador.passar_tempo(delta)
	_tatica.passar_tempo(delta)
	if not is_on_floor():
		velocity.y += _gravidade * delta
	_maquina.processar_fisica(delta)
	_aplicar_empurrao(delta)
	move_and_slide()
	_sprite.flip_h = direcao_olhar < 0  # a arte do SpriteCook olha para a direita
	_pseudopode.scale.x = direcao_olhar


# --- API pública ------------------------------------------------------------------

func definir_alvo(novo_alvo: Node2D) -> void:
	alvo = novo_alvo


func vida_atual() -> int:
	return _vida.vida_atual


func nome_estado() -> StringName:
	return _maquina.nome_estado_atual()


# --- Ferramentas dos estados ----------------------------------------------------

func alvo_percebido() -> bool:
	return alvo != null and _distancia_horizontal() <= EscalaDnd.pes_para_pixels(criatura.percepcao_pes)


## True se o alvo está dentro do alcance do Pseudópode.
func alvo_ao_alcance() -> bool:
	return alvo != null and _distancia_horizontal() <= meia_largura_corpo + _alcance_px()


## Ritmo pela iniciativa da ficha (Gray Ooze: -2 -> um ataque a cada 1,2 s).
func pode_atacar() -> bool:
	return _tempo_desde_ataque >= EscalaDnd.intervalo_ataque(criatura.iniciativa)


func virar_para_alvo() -> void:
	if alvo:
		direcao_olhar = 1 if alvo.global_position.x > global_position.x else -1


## Anda na direção do alvo no deslocamento da ficha (pés por rodada -> px/s), menos a
## Lentidão (maestria), se estiver Lento.
func andar_para_alvo() -> void:
	virar_para_alvo()
	if not _tem_chao_na(float(direcao_olhar)):
		parar()
		return
	velocity.x = direcao_olhar * MontagemDeCriatura.velocidade_andar(criatura, _condicoes)


func parar() -> void:
	velocity.x = 0.0


## O herói atirou ou arremessou: passa a procurar abrigo.
func perceber_disparo(origem: Vector2) -> void:
	_tatica.perceber_disparo(origem)


func tempo_sem_disparo() -> float:
	return _tatica.tempo_sem_disparo()


func quer_cobertura() -> bool:
	if alvo == null:
		return false
	return _tatica.quer_cobertura(
		get_world_2d().direct_space_state, global_position, altura_peito,
		_distancia_horizontal(), alvo_ao_alcance(), alvo_percebido(),
	)


func protegido_do_disparo() -> bool:
	return _tatica.protegido_do_disparo(get_world_2d().direct_space_state, global_position, altura_peito)


func x_do_abrigo() -> float:
	return _tatica.x_do_abrigo()


func quer_flanquear() -> bool:
	if alvo == null:
		return false
	return _tatica.quer_flanquear(
		alvo.global_position.x, global_position.x, _distancia_horizontal(),
		alvo_ao_alcance(), alvo_percebido(), _vida.vida_atual, _vida.vida_maxima,
		_alcance_px(), meia_largura_corpo,
		TaticaDeCriatura.xs_engajados(TaticaDeCriatura.aliados_em_pe(get_tree(), self, GRUPO_ALIADOS)),
	)


func x_do_flanco() -> float:
	return _tatica.x_do_flanco()


func quer_afastar() -> bool:
	if alvo == null:
		return false
	virar_para_alvo()
	var aliados := TaticaDeCriatura.aliados_em_pe(get_tree(), self, GRUPO_ALIADOS)
	return _tatica.quer_afastar(
		alvo_percebido(), _vida.vida_atual, _vida.vida_maxima,
		TaticaDeCriatura.contar_aliados_perto(aliados, global_position.x),
		_tem_espaco_atras(), false, false, alvo_ao_alcance(),
	)


func motivo_afastar() -> StringName:
	return _tatica.motivo_afastar()


func afastado_o_bastante() -> bool:
	return _tatica.afastado_o_bastante(_distancia_horizontal(), 0.0)


## Anda até `x` (ou corre em Disparada). True ao chegar / parede / beira.
func andar_ate(x: float, correndo: bool = false) -> bool:
	var falta := x - global_position.x
	if absf(falta) <= CHEGOU_ANDAR:
		parar()
		return true
	direcao_olhar = 1 if falta > 0.0 else -1
	if is_on_wall() or not _tem_chao_na(float(direcao_olhar)):
		parar()
		return true
	var base := MontagemDeCriatura.deslocamento_efetivo_pes(criatura, _condicoes)
	var fracao := EscalaDnd.MULTIPLICADOR_DISPARADA if correndo else 1.0
	velocity.x = direcao_olhar * EscalaDnd.deslocamento_para_velocidade(base * fracao)
	return false


## Recua de costas (Disparada), olhando para o alvo.
func recuar() -> void:
	if not _tem_chao_na(-float(direcao_olhar)):
		parar()
		return
	var base := MontagemDeCriatura.deslocamento_efetivo_pes(criatura, _condicoes)
	velocity.x = -direcao_olhar * EscalaDnd.deslocamento_para_velocidade(base * EscalaDnd.MULTIPLICADOR_DISPARADA)


## Diante de parede, degrau, vão ou queda que vale transpor, planeja o salto (regra em `SaltoDnd`; plano vazio se não há).
func planejar_salto() -> SaltoDnd.Plano:
	virar_para_alvo()
	var direcao := float(direcao_olhar)
	var bloqueado := is_on_wall() or not _tem_chao_na(direcao)
	return _saltador.planejar(alvo, direcao, bloqueado, meia_largura_corpo + DISTANCIA_BEIRA)


func iniciar_salto(plano: SaltoDnd.Plano) -> void:
	_saltador.iniciar(plano, float(direcao_olhar), MontagemDeCriatura.velocidade_andar(criatura, _condicoes), meia_largura_corpo)


func correr_no_ar() -> void:
	_saltador.correr_no_ar(float(direcao_olhar))


## False na beira: o próximo passo não tem chão. Empurrão ainda pode derrubar.
func _tem_chao_na(direcao: float) -> bool:
	var mundo := get_world_2d()
	if mundo == null:
		return true
	var origem := global_position + Vector2(direcao * DISTANCIA_BEIRA, -FOLGA_PE)
	var consulta := PhysicsRayQueryParameters2D.create(origem, origem + Vector2(0.0, PROFUNDIDADE_BEIRA + FOLGA_PE))
	consulta.collision_mask = MASCARA_MUNDO
	return not mundo.direct_space_state.intersect_ray(consulta).is_empty()


## Toca a animação desde o primeiro quadro (se já estiver tocando ela, não reinicia).
func tocar(animacao: StringName) -> void:
	if _sprite.animation == animacao and _sprite.is_playing():
		return
	_sprite.animation = animacao  # trocar a animação volta para o quadro 0
	_sprite.play()


func animacao_terminou() -> bool:
	return not _sprite.is_playing()


## Levou dano: o sprite treme por `duracao` s.
func tremer(duracao: float) -> void:
	_tremor.tremer(duracao)


func parar_tremor() -> void:
	_tremor.parar()


## Aviso antes do Pseudópode: quanto dura (s), vindo da ficha.
func tempo_aviso() -> float:
	return criatura.aviso_ataque


## Começa o aviso: para, olha para o alvo e brilha.
func preparar_aviso() -> void:
	parar()
	virar_para_alvo()
	tocar(&"parado")
	_sprite.modulate = cor_aviso
	avisou_ataque.emit()


func encerrar_aviso() -> void:
	_sprite.modulate = Color.WHITE


func iniciar_ataque() -> void:
	_tempo_desde_ataque = 0.0
	virar_para_alvo()
	parar()
	tocar(&"atacar")


## Enfraquecido (maestria): este ataque sai com desvantagem e a condição se gasta.
func ligar_pseudopode() -> void:
	var golpe := criatura.golpe()
	golpe.autor_id = get_instance_id()
	golpe.desvantagem = _condicoes.consumir_desvantagem()
	_pseudopode.ligar(golpe)


func desligar_pseudopode() -> void:
	_pseudopode.desligar()


func esta_caido() -> bool:
	return _condicoes.esta_caido()


## Deitado (Caído) achata o sprite no chão; de pé, volta ao normal.
func deitar(deitado: bool) -> void:
	_sprite.scale = _escala_sprite * escala_caido if deitado else _escala_sprite
	_sprite.position = Vector2(_posicao_sprite.x, _posicao_sprite.y * escala_caido.y) if deitado else _posicao_sprite


## Morte por código: pisca, some em fumaça e, ao acabar, sai do jogo.
func dissolver() -> void:
	_dissolver.dissolver()


## Sai do jogo depois de dissolver.
func terminar_de_morrer() -> void:
	morreu.emit()
	queue_free()


# --- Interno --------------------------------------------------------------------

func _alcance_px() -> float:
	return EscalaDnd.pes_para_pixels(criatura.ataque_alcance_pes)


func _distancia_horizontal() -> float:
	return absf(alvo.global_position.x - global_position.x)


func _tem_espaco_atras() -> bool:
	var costas := -float(direcao_olhar)
	var peito := global_position + Vector2(0.0, -altura_peito)
	return _tem_chao_na(costas) and SensorDeTerreno.linha_livre(
		get_world_2d().direct_space_state, peito,
		peito + Vector2(costas * TaticaDeCriatura.ESPACO_ATRAS_PX, 0.0), MASCARA_MUNDO,
	)


## Área do Pseudópode: começa na borda do corpo e vai até o alcance da ficha (5 pés).
func _preparar_pseudopode() -> void:
	var retangulo := _forma_pseudopode.shape as RectangleShape2D
	retangulo.size = Vector2(_alcance_px(), altura_pseudopode)
	_forma_pseudopode.position = Vector2(meia_largura_corpo + _alcance_px() / 2.0, -altura_pseudopode / 2.0)


func _ao_resolver_golpe(resultado: Combate.Resultado, _origem: Vector2) -> void:
	_texto.mostrar_resultado(resultado)
	_corroer_arma_se_preciso(resultado)
	if _vida.esta_morto():
		return
	if _condicoes.esta_caido():
		if nome_estado() != &"Caido":
			_maquina.trocar(&"Caido")
	elif resultado.acertou:
		_maquina.trocar(&"LevandoDano")


## A ficha diz as salvaguardas (Derrubar pede CON); avisos e empurrão vêm das condições.
func _preparar_condicoes() -> void:
	MontagemDeCriatura.preparar_condicoes(
		criatura, _condicoes, _texto,
		func(deslocamento: Vector2) -> void: _empurrao_restante = deslocamento.x
	)


## Empurrar: desliza o que falta do empurrão (com colisão), por cima do que o estado mandou.
func _aplicar_empurrao(delta: float) -> void:
	_empurrao_restante = MontagemDeCriatura.aplicar_empurrao(
		self, _empurrao_restante, velocidade_empurrao, delta
	)


## Forma Corrosiva: arma não mágica que CAUSA DANO no Ooze leva penalidade cumulativa no
## ataque e é destruída no limite. Quem decide o que fazer com a arma é o dono dela.
func _corroer_arma_se_preciso(resultado: Combate.Resultado) -> void:
	if criatura.corrosao_por_toque <= 0 or resultado.dano <= 0 or not resultado.golpe.arma_corroivel:
		return
	resultado.golpe.arma_corroida.emit(criatura.corrosao_por_toque, criatura.corrosao_limite)


func _ao_morrer() -> void:
	_defesa.invulneravel = true
	desligar_pseudopode()
	_maquina.trocar(&"Morrendo")
