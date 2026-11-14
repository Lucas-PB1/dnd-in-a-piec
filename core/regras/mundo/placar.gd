class_name Placar
extends RefCounted
## Conta abates e tempo da fase/run. O timer só avança enquanto há inimigos da cota vivos
## (a main decide quando chamar `avancar`). Recordes locais em `user://placar.cfg`.

const CAMINHO_PADRAO := "user://placar.cfg"
const SECAO_MELHOR := "melhor"
const CHAVE_RUN := "run"

## Caminho do arquivo (testes trocam para não sujar o placar real).
var caminho: String = CAMINHO_PADRAO
var kills_fase: int = 0
var kills_run: int = 0
var tempo_fase_s: float = 0.0
var tempo_run_s: float = 0.0
var fase_atual: int = 1
## Quantas vezes o herói caiu nesta run (a vitória mostra quantas foram até zerar).
## Os abates acima são de inimigos; queda é a do herói ("Você caiu!").
var quedas_run: int = 0
## Melhor tempo por índice de fase (1…N), em segundos.
var _melhores_fase: Dictionary = {}
var melhor_run_s: float = 0.0


## Zera a run e recarrega os recordes do disco.
func iniciar_run() -> void:
	kills_run = 0
	tempo_run_s = 0.0
	quedas_run = 0
	carregar()


## Nova fase: zera abates/tempo da fase (a run continua).
func iniciar_fase(indice: int) -> void:
	fase_atual = maxi(indice, 1)
	kills_fase = 0
	tempo_fase_s = 0.0


## Soma tempo só quando a main diz que o cronômetro está ativo.
func avancar(delta: float) -> void:
	if delta <= 0.0:
		return
	tempo_fase_s += delta
	tempo_run_s += delta


func registrar_morte() -> void:
	kills_fase += 1
	kills_run += 1


## O herói caiu (tela "Você caiu!").
func registrar_queda() -> void:
	quedas_run += 1


## Frase da vitória: quantas vezes caiu até zerar.
func texto_quedas_ate_zerar() -> String:
	match quedas_run:
		0:
			return "Zerou sem cair nenhuma vez!"
		1:
			return "Caiu 1 vez até zerar."
	return "Caiu %d vezes até zerar." % quedas_run


## Linha curta da HUD: abates da fase + tempos.
func texto_hud() -> String:
	return "Abates %d · Fase %s · Run %s" % [
		kills_fase, formatar_tempo(tempo_fase_s), formatar_tempo(tempo_run_s)]


## Resumo de fim (porta, vitória ou derrota).
## `incluir_quedas` = false na vitória, que já abre com a frase de texto_quedas_ate_zerar().
func texto_resumo(incluir_recorde: bool = true, incluir_quedas: bool = true) -> String:
	var linhas: PackedStringArray = [
		"Abates: %d nesta fase · %d na run" % [kills_fase, kills_run],
		"Tempo: fase %s · run %s" % [formatar_tempo(tempo_fase_s), formatar_tempo(tempo_run_s)],
	]
	if incluir_quedas:
		linhas.append("Quedas na run: %d" % quedas_run)
	if incluir_recorde:
		var melhor := melhor_da_fase(fase_atual)
		if melhor > 0.0:
			linhas.append("Recorde da fase: %s" % formatar_tempo(melhor))
		if melhor_run_s > 0.0:
			linhas.append("Melhor run: %s" % formatar_tempo(melhor_run_s))
	return "\n".join(linhas)


## Fecha a fase: se `gravar`, atualiza o recorde da fase (e da run se `run_completa`).
## Devolve se bateu o recorde da fase.
func fechar_fase(gravar: bool = true, run_completa: bool = false) -> bool:
	var novo_recorde := false
	if gravar:
		novo_recorde = _tentar_recorde_fase(fase_atual, tempo_fase_s)
		if run_completa:
			_tentar_recorde_run(tempo_run_s)
		if novo_recorde or run_completa:
			salvar()
	return novo_recorde


func melhor_da_fase(indice: int) -> float:
	return float(_melhores_fase.get(indice, 0.0))


func carregar() -> void:
	_melhores_fase.clear()
	melhor_run_s = 0.0
	var arquivo := ConfigFile.new()
	if arquivo.load(caminho) != OK:
		return
	for chave in arquivo.get_section_keys(SECAO_MELHOR):
		var valor := float(arquivo.get_value(SECAO_MELHOR, chave, 0.0))
		if chave == CHAVE_RUN:
			melhor_run_s = valor
			continue
		if chave.begins_with("fase_"):
			_melhores_fase[int(chave.trim_prefix("fase_"))] = valor


func salvar() -> void:
	var arquivo := ConfigFile.new()
	arquivo.load(caminho)  # mantém chaves antigas se houver
	for indice in _melhores_fase.keys():
		arquivo.set_value(SECAO_MELHOR, "fase_%d" % int(indice), float(_melhores_fase[indice]))
	if melhor_run_s > 0.0:
		arquivo.set_value(SECAO_MELHOR, CHAVE_RUN, melhor_run_s)
	arquivo.save(caminho)


static func formatar_tempo(segundos: float) -> String:
	var total := maxi(int(floor(segundos)), 0)
	var minutos := int(floor(float(total) / 60.0))
	var segs := total - minutos * 60
	return "%d:%02d" % [minutos, segs]


func _tentar_recorde_fase(indice: int, tempo: float) -> bool:
	if tempo <= 0.0:
		return false
	var atual := melhor_da_fase(indice)
	if atual > 0.0 and tempo >= atual:
		return false
	_melhores_fase[indice] = tempo
	return true


func _tentar_recorde_run(tempo: float) -> void:
	if tempo <= 0.0:
		return
	if melhor_run_s > 0.0 and tempo >= melhor_run_s:
		return
	melhor_run_s = tempo
