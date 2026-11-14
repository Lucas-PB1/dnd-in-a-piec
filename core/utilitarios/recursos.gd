class_name Recursos
extends RefCounted
## Carrega todos os Resources (.tres) de uma pasta, na ordem dos arquivos. Funciona também
## no jogo exportado (ResourceLoader.list_directory entende os arquivos remapeados).
## Cada pasta é lida uma vez só e guardada: no jogo exportado, listar a pasta dentro do .pck é
## lento, e há regras consultadas todo quadro (o estilo de luta mexe na velocidade do herói).
## Antes da memória o jogo exportado caía para ~5 FPS nas fases.

## Pasta -> os Resources dela, na ordem dos arquivos.
static var _lidas: Dictionary[String, Array] = {}


static func da_pasta(pasta: String) -> Array[Resource]:
	if not _lidas.has(pasta):
		var lidos: Array[Resource] = []
		for arquivo in ResourceLoader.list_directory(pasta):
			if arquivo.ends_with(".tres"):
				lidos.append(load(pasta.path_join(arquivo)))
		_lidas[pasta] = lidos
	var copia: Array[Resource] = []
	copia.assign(_lidas[pasta])  # quem recebe pode mexer na lista sem estragar a guardada
	return copia


## Esquece o que leu (ferramenta que grava .tres novos e quer relê-los na mesma execução).
static func esquecer() -> void:
	_lidas.clear()
