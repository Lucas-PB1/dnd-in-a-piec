class_name Arma
extends Resource
## Dados de uma arma corpo a corpo (equipamento). Uma arma nova = um .tres novo em data/.
## Os tempos contam a partir do início do golpe.

@export var nome: String = "Espada"
## Dano por acerto.
@export var dano: int = 3
## Imagem da arma, desenhada apontando para a DIREITA com o cabo na origem.
@export var textura: Texture2D
## Cor do arco de corte.
@export var cor_corte: Color = Color(0.85, 0.95, 1.0, 0.9)

@export_group("Área do golpe")
## Até onde o golpe alcança à frente do herói (px).
@export var alcance: float = 44.0
## Altura da área do golpe (px).
@export var altura: float = 40.0

@export_group("Tempos (s)")
## Duração total do golpe (o herói não pode golpear de novo antes disso).
@export var duracao: float = 0.32
## Quando o corte começa a acertar.
@export var inicio_acerto: float = 0.06
## Quando o corte para de acertar.
@export var fim_acerto: float = 0.16

@export_group("Movimento da arma (graus)")
## Ângulo da arma no começo do golpe (negativo = levantada para trás).
@export var angulo_inicial: float = -110.0
## Ângulo da arma no fim do golpe (positivo = abaixada à frente).
@export var angulo_final: float = 35.0
