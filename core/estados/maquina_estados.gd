class_name MaquinaEstados
extends Node
## Máquina de estados genérica. Os estados são os nós-filhos (que estendem Estado).
## O dono chama iniciar(self) no _ready e processar_fisica(delta) no _physics_process.

## Emitido a cada troca de estado (nomes dos nós).
signal estado_mudou(anterior: StringName, novo: StringName)

## Estado em que a máquina começa. Se vazio, usa o primeiro filho.
@export var estado_inicial: Estado

var estado_atual: Estado

var _estados: Dictionary[StringName, Estado] = {}


## Liga os estados ao dono e entra no estado inicial.
func iniciar(dono: Node) -> void:
	for filho in get_children():
		var estado := filho as Estado
		if estado == null:
			continue
		_estados[estado.name] = estado
		estado.configurar(dono)
		estado.trocar_para.connect(trocar)
	estado_atual = estado_inicial if estado_inicial else _estados.values()[0]
	estado_atual.entrar()


func processar_fisica(delta: float) -> void:
	if estado_atual:
		estado_atual.processar_fisica(delta)


## Sai do estado atual e entra no estado `nome`.
func trocar(nome: StringName) -> void:
	var novo: Estado = _estados.get(nome)
	if novo == null:
		push_error("MaquinaEstados: estado '%s' não existe." % nome)
		return
	if novo == estado_atual:
		return
	var anterior := estado_atual
	anterior.sair()
	estado_atual = novo
	novo.entrar()
	estado_mudou.emit(anterior.name, novo.name)


func nome_estado_atual() -> StringName:
	return estado_atual.name if estado_atual else &""
