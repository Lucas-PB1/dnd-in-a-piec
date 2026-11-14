extends TesteBase
## Recursos.da_pasta lê cada pasta uma vez só: no jogo exportado, listar a pasta no .pck a cada
## consulta derrubava as fases para ~5 FPS (o estilo de luta é consultado todo quadro).
## godot --headless --debug --path . --script res://tests/regras/teste_recursos.gd

const PASTA_ESTILOS := "res://data/estilos"
## Consultas seguidas que precisam caber num quadro folgado (ms).
const CONSULTAS := 2000
const LIMITE_MS := 50


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	Recursos.esquecer()
	var primeira := Recursos.da_pasta(PASTA_ESTILOS)
	var segunda := Recursos.da_pasta(PASTA_ESTILOS)
	_checar(not primeira.is_empty() and primeira.size() == segunda.size(), "a pasta de estilos tem arquivos e volta igual")
	_checar(primeira[0] == segunda[0], "a segunda leitura devolve os mesmos Resources (guardados)")
	primeira.clear()
	_checar(Recursos.da_pasta(PASTA_ESTILOS).size() == segunda.size(), "mexer na lista recebida não estraga a guardada")

	var classe := load("res://data/classe_guerreiro.tres") as ClasseRPG
	var ficha := Ficha.new(classe, {})
	ficha.estilos = [&"defesa"]
	var inicio := Time.get_ticks_msec()
	for i in CONSULTAS:
		ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.ESCARAMUCADOR)
	var gasto := Time.get_ticks_msec() - inicio
	_checar(gasto < LIMITE_MS, "%d consultas de estilo levam %d ms (limite %d)" % [CONSULTAS, gasto, LIMITE_MS])

	print("PASSOU: recursos guardados" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)
