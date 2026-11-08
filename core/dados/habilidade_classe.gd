class_name HabilidadeClasse
extends Resource
## Uma habilidade da classe, mostrada na árvore de habilidades (ex.: Segundo Fôlego do Guerreiro).
## É só descrição: a regra de verdade está no código e na ficha.

@export var id: StringName = &""
@export var nome: String = ""
## Nível da ficha a partir do qual a habilidade está liberada.
@export var nivel_minimo: int = 1
@export_multiline var descricao: String = ""
## Ação de entrada que usa a habilidade (ex.: &"folego"). Vazio = não tem tecla.
@export var acao: StringName = &""
## ids das habilidades de que esta depende (as linhas da árvore).
@export var requer: Array[StringName] = []
## Ainda não existe no jogo: aparece apagada com "Em breve".
@export var em_breve: bool = false


## Liberada para uma ficha desse nível? (Em breve nunca está.)
func liberada(nivel: int) -> bool:
	return not em_breve and nivel >= nivel_minimo
