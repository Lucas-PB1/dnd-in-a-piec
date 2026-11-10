class_name SubclasseRPG
extends Resource
## Especialização de classe no nível 3 (ex.: Campeão do Guerreiro). Texto e flags de regra;
## a `Ficha` guarda só o `id`. Arquivos em `data/subclasses/`.

## Só o que já funciona no jogo aparece na tela de escolha e no Compêndio.
@export var no_jogo: bool = false
@export var id: StringName
@export var nome: String
@export_multiline var descricao: String
## Id da classe-mãe (ex.: &"guerreiro"). Vazio = serve a qualquer classe.
@export var classe_pai: StringName = &"guerreiro"
@export var nivel_minimo: int = 3
## Regra de casa: “vantagem em iniciativa” vira +proficiência (não empilha com Alerta).
@export var iniciativa_com_proficiencia: bool = false
## 0 = crítico só no 20 (padrão). Campeão = 19.
@export var limiar_critico: int = 0
## Perícias em que a subclasse dá vantagem no teste.
@export var pericias_com_vantagem: Array[StringName] = []
## Fração do deslocamento liberada após um crítico (0 = nenhum). Campeão = 0,5.
@export var fracao_movimento_pos_critico: float = 0.0


## Pode ser escolhida agora nesta ficha?
func escolhivel_para(ficha: Ficha) -> bool:
	if not no_jogo or ficha == null or ficha.nivel < nivel_minimo:
		return false
	if classe_pai.is_empty() or ficha.classe == null:
		return true
	return ficha.classe.nome.to_lower().replace(" ", "_") == String(classe_pai)
