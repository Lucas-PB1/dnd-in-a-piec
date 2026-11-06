class_name ClasseRPG
extends Resource
## Dados de uma classe de D&D (ex.: data/classe_guerreiro.tres).

@export var nome: String = "Guerreiro"
## Faces do dado de vida (Guerreiro = d10). No nível 1 a vida usa o valor máximo dele.
@export var dado_vida: int = 10
## Distribuição sugerida na compra de pontos (atributo -> valor, total 27 pontos).
@export var atributos_sugeridos: Dictionary[StringName, int] = {}
## Salvaguardas em que a classe é proficiente (Guerreiro: Força e Constituição).
@export var salvaguardas_proficientes: Array[StringName] = []
## Categorias de arma em que é proficiente (Proficiencias: simples, marcial).
@export var proficiencias_armas: Array[StringName] = []
## Treinamento de armaduras (Proficiencias: leve, media, pesada, escudo).
@export var treinamento_armaduras: Array[StringName] = []
## Pacotes de equipamento inicial à escolha na criação (Guerreiro: A ou B do livro).
@export var pacotes_iniciais: Array[PacoteInicial] = []
## Maestria em Armas: quantos tipos de arma a classe domina no nível 1 (Guerreiro: 3).
@export var quantidade_maestrias: int = 0
## Second Wind: usos por luta. 0 = a classe não tem o poder. Guerreiro nível 1 = 2.
@export var usos_segundo_folego: int = 0

## Cura do Second Wind no nível 1: 1d10 + nível (o +1). De 2 a 11.
const DADO_SEGUNDO_FOLEGO := "1d10+1"


## Rolagem da cura do Second Wind. Quem chama confere se ainda há usos.
func cura_do_folego(rng: RandomNumberGenerator) -> int:
	return Dado.de_texto(DADO_SEGUNDO_FOLEGO).rolar(rng)
