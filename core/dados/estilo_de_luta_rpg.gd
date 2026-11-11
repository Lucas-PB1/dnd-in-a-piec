class_name EstiloDeLutaRPG
extends Resource
## Talento de Estilo de Luta (PHB 2024 / Northlands / Grim Hollow). Escolha do Guerreiro no nível 1.
## Arquivos em `data/estilos/`. A `Ficha` guarda o `id`.

## Qual regra aplicar no combate (side-scroller; ver ADR).
enum Efeito {
	DEFESA,
	DUELISMO,
	ARQUEARIA,
	ARREMESSO,
	DUAS_ARMAS,
	ARMAS_GRANDES,
	DESARMADO,
	LUTA_CEGAS,
	GLIMA,
	SELVAGERIA,
	ESCARAMUCADOR,
	PELOS_PES,
	ARTILHEIRO,
	DISPARO_DUPLO,
	RAJADA,
	COMBATENTE_MOVEL,
	OPORTUNISTA,
	DEFESA_CHAO,
}

@export var no_jogo: bool = true
@export var id: StringName
@export var nome: String
@export_multiline var descricao: String
## Livro de origem (ex.: "PHB 2024", "Northlands", "Grim Hollow").
@export var fonte: String = "PHB 2024"
@export var efeito: Efeito = Efeito.DEFESA


## Pasta dos Resources de estilo.
const PASTA := "res://data/estilos"


## Todos os estilos jogáveis, na ordem dos arquivos.
static func todos() -> Array[EstiloDeLutaRPG]:
	var lista: Array[EstiloDeLutaRPG] = []
	for recurso in Recursos.da_pasta(PASTA):
		if recurso is EstiloDeLutaRPG and (recurso as EstiloDeLutaRPG).no_jogo:
			lista.append(recurso as EstiloDeLutaRPG)
	return lista


## Resource pelo id, ou null.
static func por_id(id_estilo: StringName) -> EstiloDeLutaRPG:
	for estilo in todos():
		if estilo.id == id_estilo:
			return estilo
	return null
