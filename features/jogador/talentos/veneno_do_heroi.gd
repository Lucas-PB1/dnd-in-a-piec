class_name VenenoDoHeroi
extends RefCounted
## Veneno da arma do herói. Potente (Envenenador): doses por fase, salvaguarda de Constituição do alvo, 2d8.
## Básico (item Veneno Básico): +1d4, só em arma cortante ou perfurante. Dura 15 s ou até o primeiro acerto.
## Regra pura: o herói cuida do item da mochila, da ação bônus e dos avisos.

const POTENTE := &"potente"
const BASICO := &"basico"
const DURACAO := 15.0
const NOME_ITEM_BASICO := "Veneno Básico"

var doses: int = 0
## Qual veneno está na arma agora (&"" = nenhum).
var na_arma: StringName = &""
var _tempo: float = 0.0


func repor(ficha: Ficha) -> void:
	doses = ficha.doses_de_veneno() if ficha else 0
	apagar()


## Qual veneno dá para passar agora? O potente primeiro; o básico só em arma cortante ou perfurante e com o item.
func tipo_disponivel(arma: Arma, tem_item_basico: bool) -> StringName:
	if doses > 0:
		return POTENTE
	var serve := arma.tipo_dano == TiposDano.CORTANTE or arma.tipo_dano == TiposDano.PERFURANTE
	return BASICO if serve and tem_item_basico else &""


## Passa o veneno na arma. O potente gasta uma dose; o básico, o frasco (quem chama tira da mochila).
func aplicar(tipo: StringName) -> void:
	if tipo == POTENTE:
		doses -= 1
	na_arma = tipo
	_tempo = DURACAO


func apagar() -> void:
	na_arma = &""
	_tempo = 0.0


## Passa o tempo; true se o veneno secou agora.
func passar(delta: float) -> bool:
	if _tempo <= 0.0:
		return false
	_tempo -= delta
	if _tempo > 0.0:
		return false
	apagar()
	return true


## Liga o veneno da arma no golpe.
func aplicar_ao_golpe(golpe: Golpe, ficha: Ficha) -> void:
	if na_arma == POTENTE:
		golpe.efeitos.append(EfeitosDeTalento.VenenoPotente.new(ficha.cd_veneno()))
	elif na_arma == BASICO:
		golpe.efeitos.append(EfeitosDeTalento.VenenoBasico.new())
