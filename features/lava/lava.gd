class_name Lava
extends Area2D
## Poça de lava: quem fica em cima leva 1d6 de fogo a cada rodada. Não é chão sólido — só zona de dano.
## Não conhece o herói: acha `Defesa` no corpo e chama `receber_ambiente`.

## Largura da poça em ladrilhos (32 px). O gerador da fase define.
@export var largura_ladrilhos: int = 3
## Dados de dano por tique (notação D&D).
@export var dados_dano: String = "1d6"

const CAMADA_JOGADOR := 2
const COR_LAVA := Color(0.85, 0.25, 0.08, 0.85)
const COR_BORDA := Color(1.0, 0.55, 0.12, 0.95)
const ALTURA_VISUAL_PX := 16.0

var _tempo: float = 0.0
var _corpos: Array[Node2D] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = CAMADA_JOGADOR
	monitorable = false
	monitoring = true
	_garantir_forma()
	_garantir_visual()
	if not body_entered.is_connected(_ao_entrar):
		body_entered.connect(_ao_entrar)
	if not body_exited.is_connected(_ao_sair):
		body_exited.connect(_ao_sair)


func _physics_process(delta: float) -> void:
	if _corpos.is_empty():
		_tempo = 0.0
		return
	_tempo += delta
	if _tempo < EscalaDnd.RODADA_SEGUNDOS:
		return
	_tempo = 0.0
	aplicar_tique()


## Ajusta a largura depois de instanciar (o gerador chama antes de entrar na árvore).
func configurar(ladrilhos: int) -> void:
	largura_ladrilhos = maxi(ladrilhos, 1)


func _ao_entrar(corpo: Node2D) -> void:
	if corpo in _corpos:
		return
	_corpos.append(corpo)
	_queimar(corpo)
	_tempo = 0.0


func _ao_sair(corpo: Node2D) -> void:
	_corpos.erase(corpo)


## Aplica o tique de dano em quem está na poça (também usado pelos testes).
func aplicar_tique() -> void:
	for corpo in _corpos.duplicate():
		if is_instance_valid(corpo):
			_queimar(corpo)


func _queimar(corpo: Node2D) -> void:
	var defesa := corpo.get_node_or_null("Defesa") as DefesaComponent
	if defesa == null:
		return
	var dado := Dado.de_texto(dados_dano)
	if dado == null:
		return
	var golpe := Golpe.new("Lava", 0, dado, TiposDano.FOGO)
	golpe.corpo_a_corpo = false
	defesa.receber_ambiente(golpe, global_position)


func _largura_px() -> float:
	return float(largura_ladrilhos) * EscalaDnd.PIXELS_POR_LADRILHO


func _garantir_forma() -> void:
	var forma := get_node_or_null("Forma") as CollisionShape2D
	if forma == null:
		forma = CollisionShape2D.new()
		forma.name = "Forma"
		add_child(forma)
	var ret := forma.shape as RectangleShape2D
	if ret == null:
		ret = RectangleShape2D.new()
		forma.shape = ret
	var largura := _largura_px()
	ret.size = Vector2(largura, EscalaDnd.PIXELS_POR_LADRILHO)
	forma.position = Vector2(largura / 2.0, -EscalaDnd.PIXELS_POR_LADRILHO / 2.0)


func _garantir_visual() -> void:
	var largura := _largura_px()
	var borda := get_node_or_null("Borda") as ColorRect
	if borda == null:
		borda = ColorRect.new()
		borda.name = "Borda"
		borda.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(borda)
	borda.color = COR_BORDA
	borda.size = Vector2(largura, ALTURA_VISUAL_PX + 4.0)
	borda.position = Vector2(0.0, -ALTURA_VISUAL_PX - 2.0)
	var visual := get_node_or_null("Visual") as ColorRect
	if visual == null:
		visual = ColorRect.new()
		visual.name = "Visual"
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(visual)
	visual.color = COR_LAVA
	visual.size = Vector2(largura - 4.0, ALTURA_VISUAL_PX)
	visual.position = Vector2(2.0, -ALTURA_VISUAL_PX)
