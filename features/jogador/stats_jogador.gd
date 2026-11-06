class_name StatsJogador
extends Resource
## Números de "sensação" do herói. Edite em data/jogador_padrao.tres (Inspector).
## O jogo só LÊ este recurso; nunca altera em tempo de jogo.
## A velocidade NÃO fica aqui: vem do deslocamento de D&D da ficha (EscalaDnd).

@export_group("Andar e correr")
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

@export_group("Ataque")
## Apertar atacar um pouco antes de poder golpear de novo também vale (s).
@export var tempo_buffer_ataque: float = 0.2

@export_group("Levar dano")
## Depois de levar um golpe, fica invencível (piscando) por este tempo (s).
@export var tempo_invencibilidade: float = 1.0
## Empurrão ao levar um golpe (px/s): x = para longe de quem bateu, y = para cima (negativo).
@export var recuo_dano: Vector2 = Vector2(150.0, -180.0)
## Tempo sem controle depois do golpe (s).
@export var tempo_recuo: float = 0.3


# A gravidade e a força do pulo saem da altura e do tempo desejados:
# você ajusta "quão alto" e "quão rápido", e a física se ajusta sozinha.
func gravidade() -> float:
	return 2.0 * altura_pulo / (tempo_ate_topo * tempo_ate_topo)


func forca_pulo() -> float:
	return 2.0 * altura_pulo / tempo_ate_topo
