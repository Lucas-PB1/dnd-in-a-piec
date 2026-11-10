class_name SaltadorDeMonstro
extends RefCounted
## O salto da perseguição de quem anda no chão (Goblin, Minotauro, Wight): sonda o terreno à frente, decide com a regra
## pura `SaltoDnd` (altura e distância vêm da Força) e dá o impulso. O dono chama `passar_tempo` a cada quadro de física,
## `planejar` ao andar, `iniciar` ao saltar e `correr_no_ar` enquanto está no ar.

## Passo da sondagem do chão (px), folga acima do degrau (px), espera entre saltos (s) e quanto o alvo precisa estar
## abaixo dos pés (px) para valer descer.
const PASSO_SONDA := 8.0
const FOLGA_TOPO_SALTO := 10.0
const INTERVALO_SALTO := 0.4
const DESNIVEL_ALVO_PX := 24.0

var _corpo: CharacterBody2D
var _forca: int
var _gravidade: float
var _mascara_chao: int
var _tempo_desde_salto: float = INF
var _velocidade_no_ar: float = 0.0


func _init(corpo: CharacterBody2D, forca: int, gravidade: float, mascara_chao: int = 1) -> void:
	_corpo = corpo
	_forca = forca
	_gravidade = gravidade
	_mascara_chao = mascara_chao


func passar_tempo(delta: float) -> void:
	_tempo_desde_salto += delta


## Diante de parede, degrau, vão ou queda (`bloqueado`), decide se vale saltar. `inicio_px` é onde a sondagem começa à
## frente do centro do corpo. Sem obstáculo, no ar ou em recarga, devolve um plano vazio. Sem `alvo`, sobe degrau e
## atravessa vão, mas não desce queda grande. `proibir_descer` força o mesmo (vantagem de terreno).
func planejar(alvo: Node2D, direcao: float, bloqueado: bool, inicio_px: float,
		proibir_descer: bool = false) -> SaltoDnd.Plano:
	if not _corpo.is_on_floor() or not bloqueado or _tempo_desde_salto < INTERVALO_SALTO:
		return SaltoDnd.Plano.new()
	var altura_max := SaltoDnd.altura_px(_forca)
	var distancia_max := SaltoDnd.distancia_px(_forca)
	var quantidade := ceili(distancia_max / PASSO_SONDA) + 1
	var perfil := SensorDeTerreno.perfil(_corpo.get_world_2d().direct_space_state, _corpo.global_position, direcao,
		inicio_px, PASSO_SONDA, quantidade, altura_max, SaltoDnd.queda_segura_px(), _mascara_chao)
	var alvo_embaixo := not proibir_descer and alvo != null \
		and alvo.global_position.y - _corpo.global_position.y >= DESNIVEL_ALVO_PX
	return SaltoDnd.planejar(perfil, PASSO_SONDA, inicio_px, altura_max, distancia_max, alvo_embaixo)


## Dá o impulso do plano: corre na `velocidade` e sobe o bastante para o degrau ou para cobrir o vão.
func iniciar(plano: SaltoDnd.Plano, direcao: float, velocidade: float, meia_largura_corpo: float) -> void:
	_tempo_desde_salto = 0.0
	var subida := 0.0
	if plano.tipo != SaltoDnd.Tipo.DESCER:
		subida = sqrt(2.0 * _gravidade * (maxf(plano.desnivel_px, 0.0) + FOLGA_TOPO_SALTO))
	if plano.tipo == SaltoDnd.Tipo.VAO and velocidade > 0.0:
		var tempo_no_ar := (plano.distancia_px + meia_largura_corpo) / velocidade
		subida = maxf(subida, _gravidade * tempo_no_ar / 2.0)
	_velocidade_no_ar = velocidade
	_corpo.velocity = Vector2(direcao * velocidade, -subida)


## No ar do salto: mantém a corrida (uma batida na parede zera o x).
func correr_no_ar(direcao: float) -> void:
	_corpo.velocity.x = direcao * _velocidade_no_ar
