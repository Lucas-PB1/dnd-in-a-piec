class_name Estado
extends Node
## Base de um estado da MaquinaEstados. Cada estado = um comportamento.
## Para trocar de estado, emita `trocar_para` com o nome do nó do próximo estado.

## Pede à máquina para trocar para outro estado (nome do nó, ex.: &"NoAr").
## Quem emite são as subclasses; por isso o aviso de "sinal não usado" é desligado aqui.
@warning_ignore("unused_signal")
signal trocar_para(nome_estado: StringName)


## Recebe quem a máquina controla (o "dono"). Sobrescreva para guardar com o tipo certo.
func configurar(_dono: Node) -> void:
	pass


## Chamado quando a máquina entra neste estado.
func entrar() -> void:
	pass


## Chamado quando a máquina sai deste estado.
func sair() -> void:
	pass


## Chamado a cada passo de física enquanto este estado está ativo.
func processar_fisica(_delta: float) -> void:
	pass
