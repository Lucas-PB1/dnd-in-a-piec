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
## Armaduras iniciais à escolha na criação (Guerreiro: Cota de Malha ou Couro Batido).
@export var armaduras_iniciais: Array[Armadura] = []
