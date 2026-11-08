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


static func nome_da_categoria(valor: Categoria) -> String:
	return "Talento de origem" if valor == Categoria.ORIGEM else "Talento geral"


static func nome_da_situacao(valor: Situacao) -> String:
	match valor:
		Situacao.PLANEJADO:
			return "Planejado"
		Situacao.EM_ESPERA:
			return "Em espera"
	return "Fora por enquanto"
