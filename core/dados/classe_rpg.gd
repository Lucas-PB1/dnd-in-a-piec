class_name ClasseRPG
extends Resource
## Dados de uma classe de D&D (ex.: data/classe_guerreiro.tres).

@export var nome: String = "Guerreiro"
## Faces do dado de vida (Guerreiro = d10). No nível 1 a vida usa o valor máximo dele.
@export var dado_vida: int = 10
## Distribuição sugerida na compra de pontos (atributo -> valor, total 27 pontos).
@export var atributos_sugeridos: Dictionary[StringName, int] = {}
## Distribuições prontas à escolha na criação (Guerreiro: armadura média, pesada e leve).
@export var builds_sugeridos: Array[BuildSugerido] = []
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
## Perícias que a classe pode escolher (ids de Pericia). Guerreiro: 9.
@export var pericias_escolhiveis: Array[StringName] = []
## Quantas perícias a classe escolhe no nível 1 (Guerreiro: 2).
@export var quantidade_pericias: int = 0
## As que já vêm marcadas na criação (dá para trocar).
@export var pericias_sugeridas: Array[StringName] = []
## Second Wind: usos por luta. 0 = a classe não tem o poder. Guerreiro nível 1 = 2.
@export var usos_segundo_folego: int = 0
## Habilidades mostradas na árvore de habilidades (só descrição; as regras estão no código).
@export var habilidades: Array[HabilidadeClasse] = []

## Cura do Second Wind: 1d10 + nível. Quem chama confere se ainda há usos.
const DADO_SEGUNDO_FOLEGO := "1d10+1"  # rolagem de referência no nível 1.


func cura_do_folego(rng: RandomNumberGenerator, nivel: int = 1) -> int:
	return Dado.new(1, 10, nivel).rolar(rng)
