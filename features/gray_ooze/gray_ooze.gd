class_name GrayOoze
extends CharacterBody2D
## Gray Ooze (D&D 5e): gosma lenta que persegue o alvo que percebe e ataca com o Pseudópode
## no ritmo da iniciativa. Números em data/gray_ooze.tres (CriaturaRPG). Comportamento nos
## estados (estados/). Não conhece o herói: recebe um alvo qualquer por definir_alvo().

## Emitido quando termina de morrer (antes de sumir).
signal morreu

## Igual à beira do goblin; extrair se uma terceira criatura precisar.
const DISTANCIA_BEIRA := 14.0
const FOLGA_PE := 6.0
const PROFUNDIDADE_BEIRA := 20.0
const MASCARA_MUNDO := 1

## Bloco de estatísticas. Padrão: data/gray_ooze.tres.
@export var criatura: CriaturaRPG
## Altura do corpo usada na área do Pseudópode (px).
@export var altura_pseudopode: float = 24.0
## Metade da largura do corpo (px): o Pseudópode começa a partir daqui.
@export var meia_largura_corpo: float = 20.0
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
	_saltador = SaltadorDeMonstro.new(self, criatura.atributos.get(Atributos.FORCA, Atributos.VALOR_MEDIO) as int, _gravidade)
	_vida.configurar(criatura.vida_maxima(_rng))
	_defesa.classe_armadura = criatura.classe_armadura
	_defesa.resistencias = criatura.resistencias
	_defesa.imunidades = criatura.imunidades_dano
	_condicoes.imunidades = criatura.imunidades_condicoes
	_defesa.golpe_resolvido.connect(_ao_resolver_golpe)
	_vida.morreu.connect(_ao_morrer)
	_dissolver.terminou.connect(terminar_de_morrer)
	_preparar_condicoes()
	_posicao_sprite = _sprite.position
	_escala_sprite = _sprite.scale
	_preparar_pseudopode()
	_maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	_tempo_desde_ataque += delta
	_saltador.passar_tempo(delta)
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
	var pes := maxf(criatura.deslocamento_pes - _condicoes.reducao_deslocamento_pes(), 0.0)
	velocity.x = direcao_olhar * EscalaDnd.deslocamento_para_velocidade(pes)


func parar() -> void:
	velocity.x = 0.0


## Diante de parede, degrau, vão ou queda que vale transpor, planeja o salto (regra em `SaltoDnd`; plano vazio se não há).
func planejar_salto() -> SaltoDnd.Plano:
	virar_para_alvo()
	var direcao := float(direcao_olhar)
	var bloqueado := is_on_wall() or not _tem_chao_na(direcao)
	return _saltador.planejar(alvo, direcao, bloqueado, meia_largura_corpo + DISTANCIA_BEIRA)


func iniciar_salto(plano: SaltoDnd.Plano) -> void:
	_saltador.iniciar(plano, float(direcao_olhar), EscalaDnd.deslocamento_para_velocidade(criatura.deslocamento_pes), meia_largura_corpo)


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
	for atributo in Atributos.TODOS:
		_condicoes.bonus_salvaguardas[atributo] = criatura.bonus_salvaguarda(atributo)
	_condicoes.aviso.connect(func(texto: String) -> void: _texto.mostrar(texto, TextoFlutuanteComponent.COR_CONDICAO))
	_condicoes.empurrado.connect(func(deslocamento: Vector2) -> void: _empurrao_restante = deslocamento.x)


## Empurrar: desliza o que falta do empurrão (com colisão), por cima do que o estado mandou.
func _aplicar_empurrao(delta: float) -> void:
	if is_zero_approx(_empurrao_restante):
		return
	var passo := signf(_empurrao_restante) * minf(absf(_empurrao_restante), velocidade_empurrao * delta)
	velocity.x = passo / delta
	_empurrao_restante -= passo


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
