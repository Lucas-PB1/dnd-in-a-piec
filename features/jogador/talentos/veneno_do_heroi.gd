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


## Arma cortante ou perfurante (o Veneno Básico do livro só cola nela).
static func arma_serve_basico(arma: Arma) -> bool:
	return arma != null and (arma.tipo_dano == TiposDano.CORTANTE or arma.tipo_dano == TiposDano.PERFURANTE)


## Qual veneno dá para passar agora? O potente primeiro; o básico só em arma cortante ou perfurante e com o item.
func tipo_disponivel(arma: Arma, tem_item_basico: bool) -> StringName:
	if doses > 0:
		return POTENTE
	return BASICO if arma_serve_basico(arma) and tem_item_basico else &""


## HUD/toque: há dose, veneno na arma, ou frasco + arma que aceita o básico.
func visivel_na_ui(arma: Arma, tem_item_basico: bool) -> bool:
	if na_arma != &"" or doses > 0:
		return true
	return tem_item_basico and arma_serve_basico(arma)


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
