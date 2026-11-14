extends TesteBase
## Caixa-preta (RegistroDeFalhas): uma sessão que ficou aberta vira relatório na abertura seguinte,
## com os últimos passos; fechar direito não dá aviso; a main mostra o relatório por cima do título.
## godot --headless --debug --path . --script res://tests/campanha/teste_registro_de_falhas.gd

const PASTA_TESTE := "user://registro_teste"


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var pasta_real := RegistroDeFalhas.pasta
	DirAccess.make_dir_recursive_absolute(PASTA_TESTE)
	RegistroDeFalhas.pasta = PASTA_TESTE  # nunca o registro de verdade
	RegistroDeFalhas.ligado = true
	RegistroDeFalhas.fechar_sessao()
	_testar_regra()
	await _testar_tela_na_main()
	RegistroDeFalhas.fechar_sessao()
	RegistroDeFalhas.ligado = false
	RegistroDeFalhas.pasta = pasta_real
	print("PASSOU: caixa-preta" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _testar_regra() -> void:
	RegistroDeFalhas.iniciar()
	_checar(not RegistroDeFalhas.houve_falha(), "na primeira abertura não há queda")
	RegistroDeFalhas.marcar("Fase 6 Labirinto (nível 8)")
	RegistroDeFalhas.marcar("Tela: TelaTalento aberta")
	# O jogo "cai": ninguém fecha a sessão. Na abertura seguinte:
	RegistroDeFalhas.iniciar()
	var relatorio := RegistroDeFalhas.relatorio()
	_checar(RegistroDeFalhas.houve_falha(), "a sessão que ficou aberta conta como queda")
	_checar(relatorio.contains("Fase 6 Labirinto (nível 8)") and relatorio.contains("TelaTalento aberta"),
		"o relatório traz os últimos passos antes da queda")
	RegistroDeFalhas.descartar_relatorio()
	_checar(not RegistroDeFalhas.houve_falha(), "depois de visto, o relatório não volta")
	RegistroDeFalhas.fechar_sessao()  # fechou direito (ou foi para o segundo plano)
	RegistroDeFalhas.iniciar()
	_checar(not RegistroDeFalhas.houve_falha(), "fechar direito não dá aviso de queda")
	for i in RegistroDeFalhas.MAXIMO_PASSOS + 10:
		RegistroDeFalhas.marcar("passo %d" % i)
	RegistroDeFalhas.iniciar()
	var linhas := RegistroDeFalhas.relatorio().split("\n")
	_checar(RegistroDeFalhas.relatorio().contains("passo %d" % (RegistroDeFalhas.MAXIMO_PASSOS + 9))
		and not RegistroDeFalhas.relatorio().contains("passo 0\n") and linhas.size() < RegistroDeFalhas.MAXIMO_PASSOS + RegistroDeFalhas.LINHAS_DO_LOG + 12,
		"guarda só os passos mais recentes")


## Com uma queda anterior, o título aparece com o relatório por cima; Fechar o tira.
func _testar_tela_na_main() -> void:
	RegistroDeFalhas.fechar_sessao()
	RegistroDeFalhas.iniciar()
	RegistroDeFalhas.marcar("Nível 8 (XP 7200)")  # e "cai" de novo
	var main: Main = load("res://levels/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var tela := main.get_node_or_null("Interface/TelaRelatorioFalha") as TelaRelatorioFalha
	_checar(tela != null and tela.visible, "com uma queda anterior, o relatório aparece por cima do título")
	if tela == null:
		main.free()
		return
	var texto := (tela.find_child("Relatorio", true, false) as TextEdit).text
	_checar(texto.contains("Nível 8 (XP 7200)"), "a tela mostra os passos de antes da queda")
	(tela.find_child("Fechar", true, false) as Button).pressed.emit()
	await process_frame
	_checar(main.get_node_or_null("Interface/TelaRelatorioFalha") == null or tela.is_queued_for_deletion(), "Fechar tira o relatório")
	_checar(not RegistroDeFalhas.houve_falha(), "e ele não volta nesta sessão")
	main.free()
	await process_frame
