class_name StatsJogador
extends Resource
## Números de balanceamento do herói. Edite em data/jogador_padrao.tres (Inspector).
## O jogo só LÊ este recurso; nunca altera em tempo de jogo.

@export_group("Andar e correr")
## Velocidade máxima andando (pixels por segundo).
@export var velocidade: float = 160.0
## Velocidade máxima correndo (px/s). Corre com dois toques rápidos na direção.
@export var velocidade_corrida: float = 290.0
## Tempo máximo entre os dois toques para começar a correr (s).
@export var janela_toque_duplo: float = 0.25
## Quão rápido chega na velocidade máxima no chão (px/s²).
@export var aceleracao: float = 1400.0
## Quão rápido para no chão ao soltar (px/s²).
@export var desaceleracao: float = 1800.0
## Controle no ar (px/s²). Menor = menos controle durante o pulo.
@export var aceleracao_no_ar: float = 1100.0

@export_group("Pulo")
## Altura máxima do pulo segurando o botão (pixels). 32 px = 1 ladrilho.
@export var altura_pulo: float = 104.0
## Tempo até chegar no topo do pulo (segundos). Menor = pulo mais "rápido".
@export var tempo_ate_topo: float = 0.38
## Gravidade extra na queda. Maior que 1 = cai mais rápido do que sobe (pulo mais firme).
@export var multiplicador_queda: float = 1.6
## Ao soltar o botão subindo, a velocidade vertical é multiplicada por isto (pulo curto).
@export_range(0.0, 1.0) var corte_pulo: float = 0.45
## Velocidade máxima de queda (px/s).
@export var velocidade_max_queda: float = 700.0
## Tempo depois de sair da beirada em que ainda dá para pular (s).
@export var tempo_coyote: float = 0.1
## Apertar pular um pouco antes de tocar o chão também vale (s).
@export var tempo_buffer: float = 0.12


# A gravidade e a força do pulo saem da altura e do tempo desejados:
# você ajusta "quão alto" e "quão rápido", e a física se ajusta sozinha.
func gravidade() -> float:
	return 2.0 * altura_pulo / (tempo_ate_topo * tempo_ate_topo)


func forca_pulo() -> float:
	return 2.0 * altura_pulo / tempo_ate_topo
