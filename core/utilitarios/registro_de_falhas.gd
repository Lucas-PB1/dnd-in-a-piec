class_name RegistroDeFalhas
extends RefCounted
## Caixa-preta do jogo, para achar o que fecha o jogo no celular (onde não há console).
## - Marca os passos importantes (fase, tela aberta, nível, escolha) num arquivo curto.
## - Uma "sessão aberta" fica gravada enquanto o jogo está em primeiro plano; fechar direito, ou
##   ir para o segundo plano, apaga a marca. Se o jogo abrir e a marca ainda estiver lá, o jogo
##   anterior caiu: o relatório junta os últimos passos e o fim do log do Godot daquela vez.
## Não é autoload: a main chama iniciar() no começo e marcar() nos passos (como Comandos).

## Onde ficam os arquivos. Os testes trocam a pasta, para não mexer no registro de verdade.
static var pasta: String = "user://"
## Desligado no modo headless (testes e ferramentas abrem a main o tempo todo e dariam falsos avisos de queda).
static var ligado: bool = DisplayServer.get_name() != "headless"
const ARQUIVO_PASSOS := "ultimos_passos.txt"
const ARQUIVO_SESSAO := "sessao_aberta.txt"
## Pasta onde o Godot grava os logs (debug/file_logging); o da vez anterior é o mais novo depois do atual.
const PASTA_LOGS := "user://logs"
const LOG_ATUAL := "godot.log"
## Passos guardados (os mais antigos saem) e linhas do log do Godot que vão para o relatório.
const MAXIMO_PASSOS := 40
const LINHAS_DO_LOG := 60

## Passos desta sessão, do mais antigo ao mais novo.
static var _passos: PackedStringArray = []
## Relatório da queda anterior, montado no iniciar() (vazio = a última vez fechou direito).
static var _relatorio: String = ""


## Começo do jogo: vê se a vez anterior caiu, guarda o relatório e abre uma sessão nova.
static func iniciar() -> void:
	_relatorio = ""
	if not ligado:
		return
	if FileAccess.file_exists(_caminho(ARQUIVO_SESSAO)):
		_relatorio = _montar_relatorio(_ler(_caminho(ARQUIVO_PASSOS)), _fim_do_log_anterior())
	_passos.clear()
	_gravar(_caminho(ARQUIVO_PASSOS), "")
	abrir_sessao()


## O jogo anterior caiu (a sessão ficou aberta)?
static func houve_falha() -> bool:
	return not _relatorio.is_empty()


static func relatorio() -> String:
	return _relatorio


## O jogador já viu (ou copiou) o relatório: não mostra de novo.
static func descartar_relatorio() -> void:
	_relatorio = ""


## Anota um passo ("Fase 6 Labirinto", "Tela: Talento", "Nível 8"). Grava na hora: se o jogo cair
## logo depois, o passo já está no arquivo.
static func marcar(passo: String) -> void:
	if not ligado:
		return
	_passos.append("%s  %s" % [Time.get_time_string_from_system(), passo])
	if _passos.size() > MAXIMO_PASSOS:
		_passos = _passos.slice(_passos.size() - MAXIMO_PASSOS)
	_gravar(_caminho(ARQUIVO_PASSOS), "\n".join(_passos))


## Jogo em primeiro plano: se cair agora, conta como queda.
static func abrir_sessao() -> void:
	if not ligado:
		return
	_gravar(_caminho(ARQUIVO_SESSAO), Time.get_datetime_string_from_system())


## Fechou direito ou foi para o segundo plano (o celular pode matar o app lá sem ser queda).
static func fechar_sessao() -> void:
	if not ligado:
		return
	if FileAccess.file_exists(_caminho(ARQUIVO_SESSAO)):
		DirAccess.remove_absolute(_caminho(ARQUIVO_SESSAO))


## O texto que o jogador copia e manda: versão, aparelho, últimos passos e o fim do log.
static func _montar_relatorio(passos: String, log_anterior: String) -> String:
	var partes: PackedStringArray = [
		"DnD in a Piece · %s %s · %s · %s" % [OS.get_name(), OS.get_version(), OS.get_model_name(),
			Time.get_datetime_string_from_system()],
		"", "Últimos passos:", passos if not passos.is_empty() else "(nenhum)",
		"", "Fim do log do Godot:", log_anterior if not log_anterior.is_empty() else "(log não encontrado)",
	]
	return "\n".join(partes)


## As últimas linhas do log da vez anterior: o arquivo de log mais novo que não é o desta vez.
static func _fim_do_log_anterior() -> String:
	var dir := DirAccess.open(PASTA_LOGS)
	if dir == null:
		return ""
	var anteriores: PackedStringArray = []
	for nome in dir.get_files():
		if nome.ends_with(".log") and nome != LOG_ATUAL:
			anteriores.append(nome)
	if anteriores.is_empty():
		return ""
	anteriores.sort()  # godot<data e hora>.log: em ordem de nome = em ordem de tempo
	var linhas := _ler(PASTA_LOGS.path_join(anteriores[-1])).split("\n")
	return "\n".join(linhas.slice(maxi(linhas.size() - LINHAS_DO_LOG, 0)))


static func _caminho(arquivo: String) -> String:
	return pasta.path_join(arquivo)


static func _ler(caminho: String) -> String:
	return FileAccess.get_file_as_string(caminho) if FileAccess.file_exists(caminho) else ""


static func _gravar(caminho: String, texto: String) -> void:
	var arquivo := FileAccess.open(caminho, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(texto)
		arquivo.close()
