class_name Wight
extends CharacterBody2D
## Corpo Seco / Wight (D&D 2024, ND 3), o chefe da cripta. Ataques Múltiplos: dois ataques por ação, cada um a Espada Necrótica,
## o Arco Necrótico (flecha) ou o Drenar Vida (salvaguarda de Constituição; quem falha perde também o máximo de PV, até o
## descanso longo). Resistente a dano necrótico; Sensibilidade à Luz Solar vem da ficha.
## Números na ficha (CriaturaRPG). Comportamento nos estados (estados/). Não conhece o herói: recebe um alvo por
## definir_alvo() e a Percepção passiva por definir_percepcao_passiva().

## Emitido quando termina de morrer (antes de sumir).
signal morreu
## A vida mudou (a main mostra a barra do chefe).
signal vida_mudou(atual: int, maxima: int)
## Percebeu o herói pela primeira vez: a main faz surgirem os acompanhantes da fase (a "invocação" é só de cena).
signal despertou

const CENA_FLECHA := preload("res://core/projeteis/flecha.tscn")
const FLECHA := preload("res://data/municoes/flecha.tres")
## Camada "mundo" do chão.
const MASCARA_MUNDO := 1
const FOLGA_PE := 6.0
const PROFUNDIDADE_BEIRA := 20.0
## Quanto à frente da borda do corpo (px) o raio procura chão antes de descer do penhasco.
const DISTANCIA_BEIRA := 40.0
## Quanto tempo o sprite fica vermelho ao levar dano (s).
const TEMPO_PISCAR_DANO := 0.12
## Ataques Múltiplos do livro: dois ataques por ação.
const ATAQUES_POR_ACAO := 2

## Bloco de estatísticas. Padrão: data/wight.tres.
@export var criatura: CriaturaRPG
## Altura (px) da área do golpe e metade da largura do corpo (px): o golpe começa na borda do corpo.
@export var altura_golpe: float = 56.0
@export var meia_largura_corpo: float = 14.0
## Janela em que a espada e o Drenar Vida acertam (s desde o início da animação, 12 quadros por segundo).
@export var inicio_acerto: float = 0.33
@export var fim_acerto: float = 0.46
## Quando a flecha sai do arco (s desde o início da animação).
@export var momento_soltura: float = 0.5
## Altura (px) da mão de onde sai a flecha, e do peito do herói onde ele mira.
@export var altura_mao: float = 40.0
@export var altura_alvo: float = 36.0
## Chance (0 a 1) de cada ataque de perto ser o Drenar Vida em vez da espada.
@export var chance_drenar: float = 0.5
## Chance (0 a 1) de, com o herói longe, preferir o arco a se aproximar; e a distância mínima (px) para valer o arco.
@export var chance_atirar: float = 0.85
@export var distancia_minima_tiro: float = 128.0
## Empurrar (maestria): velocidade com que o empurrão o desloca (px/s).
@export var velocidade_empurrao: float = 320.0
@export var cor_dano: Color = Color(1.0, 0.45, 0.45)
@export var cor_aviso: Color = Color(0.6, 1.0, 0.7)

var alvo: Node2D
## Para onde olha: 1 = direita, -1 = esquerda.
var direcao_olhar: int = -1

var _rng := RandomNumberGenerator.new()
var _gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _tempo_desde_ataque: float = INF
var _empurrao_restante: float = 0.0
var _despertou: bool = false
var _luz_do_sol: bool = false
var _prefere_atirar: bool = true
var _saltador: SaltadorDeMonstro

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _dissolver: DissolverComponent = $Dissolver
@onready var _vida: HealthComponent = $Vida
@onready var _defesa: DefesaComponent = $Defesa
@onready var _texto: TextoFlutuanteComponent = $Texto
@onready var _golpe: HitboxComponent = $Golpe
@onready var _forma_golpe: CollisionShape2D = $Golpe/Forma
@onready var _maquina: MaquinaEstados = $MaquinaEstados
@onready var _condicoes: CondicoesComponent = $Condicoes


func _ready() -> void:
	if criatura == null:
		criatura = CriaturaRPG.new()  # cena aberta sozinha (F6) continua funcionando
	_saltador = SaltadorDeMonstro.new(self, criatura.atributos.get(Atributos.FORCA, Atributos.VALOR_MEDIO) as int, _gravidade)
	_vida.configurar(criatura.vida_maxima(_rng))
	_vida.vida_mudou.connect(vida_mudou.emit)
	_defesa.classe_armadura = criatura.classe_armadura
	_defesa.resistencias = criatura.resistencias
	_defesa.imunidades = criatura.imunidades_dano
	_condicoes.imunidades = criatura.imunidades_condicoes
	_condicoes.tamanho = criatura.tamanho
	_defesa.golpe_resolvido.connect(_ao_resolver_golpe)
	_vida.morreu.connect(_ao_morrer)
	_dissolver.terminou.connect(terminar_de_morrer)
	_preparar_condicoes()
	_preparar_area()
	_maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	_tempo_desde_ataque += delta
	_saltador.passar_tempo(delta)
	if not is_on_floor():
		velocity.y += _gravidade * delta
	_maquina.processar_fisica(delta)
	_aplicar_empurrao(delta)
	move_and_slide()
	_sprite.scale.x = direcao_olhar  # a arte olha para a direita
	_golpe.scale.x = direcao_olhar


# --- API pública ------------------------------------------------------------------

func definir_alvo(novo_alvo: Node2D) -> void:
	alvo = novo_alvo


## O Wight não se esconde: não rola Furtividade, então não usa a Percepção do herói.
func definir_percepcao_passiva(_valor: int) -> void:
	pass


## Fase de dia: a Sensibilidade à Luz Solar dá desvantagem nos ataques dele.
func definir_luz_do_sol(ao_sol: bool) -> void:
	_luz_do_sol = ao_sol


func vida_atual() -> int:
	return _vida.vida_atual


func vida_maxima() -> int:
	return _vida.vida_maxima


func nome_estado() -> StringName:
	return _maquina.nome_estado_atual()


# --- Ferramentas dos estados ----------------------------------------------------

func alvo_percebido() -> bool:
	return alvo != null and _distancia_horizontal() <= EscalaDnd.pes_para_pixels(criatura.percepcao_pes)


func alvo_ao_alcance() -> bool:
	return alvo != null and _distancia_horizontal() <= meia_largura_corpo + _alcance_px() \
		and absf(alvo.global_position.y - global_position.y) <= altura_golpe


func pode_atacar() -> bool:
	return _tempo_desde_ataque >= EscalaDnd.intervalo_ataque(criatura.iniciativa)


## O herói está longe, a vontade do momento é atirar e não há parede no caminho da flecha.
func quer_atirar() -> bool:
	return _prefere_atirar and alvo != null and _distancia_horizontal() >= distancia_minima_tiro \
		and _distancia_horizontal() <= EscalaDnd.pes_para_pixels(criatura.disparo_longo_pes) and _linha_de_tiro_livre()


## Primeira vez que percebe o herói: avisa a main (uma vez só).
func despertar() -> void:
	if _despertou:
		return
	_despertou = true
	despertou.emit()


func virar_para_alvo() -> void:
	if alvo:
		direcao_olhar = 1 if alvo.global_position.x > global_position.x else -1


func andar_para_alvo() -> void:
	virar_para_alvo()
	if not _tem_chao_na(float(direcao_olhar)):
		parar()
		return
	velocity.x = direcao_olhar * EscalaDnd.deslocamento_para_velocidade(criatura.deslocamento_pes)


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


func tocar(animacao: StringName) -> void:
	if _sprite.animation == animacao and _sprite.is_playing():
		return
	_sprite.animation = animacao
	_sprite.play()


func animacao_terminou() -> bool:
	return not _sprite.is_playing()


func iniciar_ataque(animacao: StringName) -> void:
	_tempo_desde_ataque = 0.0
	_prefere_atirar = _rng.randf() < chance_atirar
	virar_para_alvo()
	parar()
	_sprite.animation = animacao
	_sprite.frame = 0
	_sprite.play()


## Sorteia se o próximo ataque de perto é o Drenar Vida (senão, a espada).
func sortear_drenar() -> bool:
	return criatura.drenar_cd > 0 and _rng.randf() < chance_drenar


func ligar_golpe(drenar: bool) -> void:
	_golpe.ligar(_golpe_do_drenar() if drenar else _golpe_da_espada())


func desligar_golpe() -> void:
	_golpe.desligar()


## Aviso antes do ataque: para, olha o herói e brilha (dá tempo de esquivar).
func tempo_aviso() -> float:
	return criatura.aviso_ataque


func preparar_aviso() -> void:
	parar()
	virar_para_alvo()
	tocar(&"parado")
	_sprite.modulate = cor_aviso


func encerrar_aviso() -> void:
	_sprite.modulate = Color.WHITE


## Solta uma flecha na direção do alvo (mira no peito dele).
func atirar() -> void:
	if alvo == null:
		return
	var flecha: Flecha = CENA_FLECHA.instantiate()
	add_child(flecha)
	var mao := global_position + Vector2(direcao_olhar * meia_largura_corpo, -altura_mao)
	var destino := alvo.global_position + Vector2(0.0, -altura_alvo)
	flecha.lancar(_golpe_do_disparo(), FLECHA, mao, destino,
		EscalaDnd.pes_para_pixels(criatura.disparo_normal_pes),
		EscalaDnd.pes_para_pixels(criatura.disparo_longo_pes), _gravidade)


func esta_caido() -> bool:
	return _condicoes.esta_caido()


## Deitado (Caído): o corpo gira e fica no chão; de pé, volta ao normal.
func deitar(deitado: bool) -> void:
	_sprite.rotation_degrees = -90.0 * direcao_olhar if deitado else 0.0


func dissolver() -> void:
	_dissolver.dissolver()


func terminar_de_morrer() -> void:
	morreu.emit()
	queue_free()


# --- Interno --------------------------------------------------------------------

func _golpe_da_espada() -> Golpe:
	return _com_autor(criatura.golpe())


func _golpe_do_drenar() -> Golpe:
	return _com_autor(criatura.golpe_drenar())


func _golpe_do_disparo() -> Golpe:
	var golpe := _com_autor(criatura.golpe_disparo())
	golpe.corpo_a_corpo = false
	return golpe


func _com_autor(golpe: Golpe) -> Golpe:
	golpe.autor_id = get_instance_id()
	golpe.desvantagem = _condicoes.consumir_desvantagem() or (criatura.sensivel_ao_sol and _luz_do_sol)
	return golpe


func _alcance_px() -> float:
	return EscalaDnd.pes_para_pixels(criatura.ataque_alcance_pes)


func _distancia_horizontal() -> float:
	return absf(alvo.global_position.x - global_position.x)


func _linha_de_tiro_livre() -> bool:
	return SensorDeTerreno.linha_livre(get_world_2d().direct_space_state,
		global_position + Vector2(0.0, -altura_mao), alvo.global_position + Vector2(0.0, -altura_alvo), MASCARA_MUNDO)


func _tem_chao_na(direcao: float) -> bool:
	var origem := global_position + Vector2(direcao * (meia_largura_corpo + DISTANCIA_BEIRA), -FOLGA_PE)
	var consulta := PhysicsRayQueryParameters2D.create(origem, origem + Vector2(0.0, PROFUNDIDADE_BEIRA + FOLGA_PE))
	consulta.collision_mask = MASCARA_MUNDO
	return not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


## O golpe cobre do centro do corpo até o alcance.
func _preparar_area() -> void:
	var comprimento := meia_largura_corpo + _alcance_px()
	(_forma_golpe.shape as RectangleShape2D).size = Vector2(comprimento, altura_golpe)
	_forma_golpe.position = Vector2(comprimento / 2.0, -altura_golpe / 2.0)


func _ao_resolver_golpe(resultado: Combate.Resultado, _origem: Vector2) -> void:
	_texto.mostrar_resultado(resultado)
	if _vida.esta_morto():
		return
	if _condicoes.esta_caido() and nome_estado() != &"Caido":
		_maquina.trocar(&"Caido")
	elif resultado.acertou:
		_piscar_dano()


## Chefe não se assusta com golpe: só pisca (não interrompe o que está fazendo).
func _piscar_dano() -> void:
	_sprite.modulate = cor_dano
	await get_tree().create_timer(TEMPO_PISCAR_DANO).timeout
	if is_inside_tree() and not _vida.esta_morto():
		_sprite.modulate = Color.WHITE


func _preparar_condicoes() -> void:
	for atributo in Atributos.TODOS:
		_condicoes.bonus_salvaguardas[atributo] = criatura.bonus_salvaguarda(atributo)
	_condicoes.aviso.connect(func(texto: String) -> void: _texto.mostrar(texto, TextoFlutuanteComponent.COR_CONDICAO))
	_condicoes.empurrado.connect(func(deslocamento: Vector2) -> void: _empurrao_restante = deslocamento.x)


func _aplicar_empurrao(delta: float) -> void:
	if is_zero_approx(_empurrao_restante):
		return
	var passo := signf(_empurrao_restante) * minf(absf(_empurrao_restante), velocidade_empurrao * delta)
	velocity.x = passo / delta
	_empurrao_restante -= passo


func _ao_morrer() -> void:
	_defesa.invulneravel = true
	desligar_golpe()
	_sprite.modulate = Color.WHITE
	_maquina.trocar(&"Morrendo")
