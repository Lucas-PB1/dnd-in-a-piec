class_name TalentoRPG
extends Resource
## Um talento do livro (PHB 2024), só como documentação: nome, categoria, resumo e a situação dele
## no jogo. Quem lê é o Compêndio. Os arquivos em `data/talentos/` são gerados por
## `tools/gerar_compendio.gd`: edite a tabela de lá, não os `.tres`.

enum Categoria { ORIGEM, GERAL }
## PLANEJADO = já tem conta combinada em docs/talentos.md; EM_ESPERA = depende de algo que o jogo
## ainda não tem (magia, descanso, perícia...); FORA = não cabe no jogo hoje.
enum Situacao { PLANEJADO, EM_ESPERA, FORA }

## Só o que já funciona no jogo aparece no Compêndio; o resto fica guardado aqui como documentação.
@export var no_jogo: bool = false
@export var id: StringName
@export var nome: String
@export var categoria: Categoria = Categoria.GERAL
@export_multiline var resumo: String
@export var situacao: Situacao = Situacao.EM_ESPERA
## Por que está em espera (ou o que falta), em uma frase.
@export var motivo: String
## Atributos em que o talento deixa pôr o aumento (vazio = o talento não aumenta atributo).
@export var atributos: Array[StringName] = []
## Quantos pontos de atributo ele dá (1 na maioria; o Aumento de Valor de Habilidade dá 2).
@export var pontos_de_atributo: int = 0
## Pode ser escolhido mais de uma vez (só o Aumento de Valor de Habilidade).
@export var repetivel: bool = false


## O jogador pode escolher este talento no nível 4? Só os gerais já decididos como planejados.
func escolhivel() -> bool:
	return categoria == Categoria.GERAL and situacao == Situacao.PLANEJADO


static func nome_da_categoria(valor: Categoria) -> String:
	return "Talento de origem" if valor == Categoria.ORIGEM else "Talento geral"


static func nome_da_situacao(valor: Situacao) -> String:
	match valor:
		Situacao.PLANEJADO:
			return "Planejado"
		Situacao.EM_ESPERA:
			return "Em espera"
	return "Fora por enquanto"
