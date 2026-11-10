extends EstadoQuimera
## Ataques Múltiplos (corpo a corpo): depois do aviso, Cabeçada (derruba), Mordida e Garra numa só animação, cada golpe na sua
## janela. Se o Sopro de Fogo está pronto e o herói no cone, ele toma o lugar da Garra.

var _tempo: float = 0.0
var _comecou: bool = false
var _golpe_ligado: StringName = &""


func entrar() -> void:
	_comecou = false
	_tempo = 0.0
	_golpe_ligado = &""
	iniciar_aviso()


func sair() -> void:
	quimera.encerrar_aviso()
	quimera.desligar_golpe()


func processar_fisica(delta: float) -> void:
	quimera.parar()
	if not _comecou:
		if avisando(delta):
			return
		_comecou = true
		quimera.iniciar_ataque(&"ataque")
		return
	_tempo += delta
	# Sopro no lugar da Garra: troca antes de ligar a janela da Garra.
	if _tempo >= quimera.inicio_garra and quimera.quer_soprar():
		quimera.desligar_golpe()
		_golpe_ligado = &""
		quimera.combo_em_andamento = true
		trocar_para.emit(&"Soprando")
		return
	_atualizar_janela()
	if quimera.animacao_terminou():
		trocar_para.emit(&"Perseguindo")


## Liga o golpe da janela atual (e desliga o anterior): cada ataque do combo vale só uma vez.
## Com Sopro pronto, a janela da Garra não abre (o estado troca para Soprando).
func _atualizar_janela() -> void:
	var ativo := quimera.ataque_na_janela(_tempo)
	if ativo == Quimera.ATAQUE_GARRA and quimera.quer_soprar():
		ativo = &""
	if ativo == _golpe_ligado:
		return
	quimera.desligar_golpe()
	_golpe_ligado = ativo
	if ativo != &"":
		quimera.ligar_golpe(ativo)
