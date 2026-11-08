class_name AntecedenteRPG
extends Resource
## Um antecedente do livro (PHB 2024), só como documentação: atributos que ele aumenta, talento
## de origem, perícias, ferramenta e o texto. Quem lê é o Compêndio; a ficha ainda não usa. Os
## arquivos em `data/antecedentes/` são gerados por `tools/gerar_compendio.gd`.

## Só o que já funciona no jogo aparece no Compêndio; o resto fica guardado aqui como documentação.
@export var no_jogo: bool = false
@export var id: StringName
@export var nome: String
@export_multiline var descricao: String
## Os três atributos entre os quais o livro deixa distribuir +2/+1 ou +1/+1/+1.
@export var atributos: Array[StringName] = []
## Id do talento de origem (casa com `TalentoRPG.id`).
@export var talento: StringName
@export var pericias: Array[StringName] = []
@export var ferramenta: String
## O que o livro dá de equipamento, em uma frase; o jogo só entrega o que já existe nele.
@export_multiline var equipamento: String
