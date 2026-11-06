class_name Recursos
extends RefCounted
## Carrega todos os Resources (.tres) de uma pasta, na ordem dos arquivos. Funciona também
## no jogo exportado (ResourceLoader.list_directory entende os arquivos remapeados).


static func da_pasta(pasta: String) -> Array[Resource]:
	var achados: Array[Resource] = []
	for arquivo in ResourceLoader.list_directory(pasta):
		if arquivo.ends_with(".tres"):
			achados.append(load(pasta.path_join(arquivo)))
	return achados
