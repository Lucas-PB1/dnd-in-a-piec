class_name EstilosDoHeroi
extends RefCounted
## Estado de combate dos estilos que precisam de janela/turno (Selvageria, Oportunista,
## Escaramuçador, Combatente Móvel). Regra pura; o herói liga.

## Janela do Oportunista depois de levar dano (s).
const JANELA_OPORTUNISTA := 1.5
## Quanto o Escaramuçador / Combatente Móvel soma ao deslocamento (pés).
const PES_EXTRA_MOVEL := 10.0
## Distância “bem perto” para Pelos Pés / artilheiro (pés).
const PES_PERTO := 5.0


var selvageria_ativa: bool = false
var oportunista_restante: float = 0.0
var moveu_neste_turno: bool = false
var deslocamento_extra_pes: float = 0.0
## Rajada: true = abre mão da vantagem por 2º alvo; false = mantém vantagem.
var rajada_ligada: bool = false
## Disparo Duplo: o 1º tiro liberou um 2º imediato.
var disparo_duplo_pendente: bool = false
var _pixels_movidos: float = 0.0


func alternar_rajada() -> bool:
	rajada_ligada = not rajada_ligada
	return rajada_ligada


func resetar_turno() -> void:
	selvageria_ativa = false
	moveu_neste_turno = false
	deslocamento_extra_pes = 0.0
	_pixels_movidos = 0.0


func ao_levar_dano() -> void:
	oportunista_restante = JANELA_OPORTUNISTA


func passar(delta: float) -> void:
	if oportunista_restante > 0.0:
		oportunista_restante = maxf(oportunista_restante - delta, 0.0)


func registrar_movimento(pixels: float) -> void:
	_pixels_movidos += absf(pixels)
	if _pixels_movidos >= EscalaDnd.pes_para_pixels(PES_EXTRA_MOVEL * 0.45):
		moveu_neste_turno = true


func ativar_selvageria() -> void:
	selvageria_ativa = true


func consumir_oportunista() -> bool:
	if oportunista_restante <= 0.0:
		return false
	oportunista_restante = 0.0
	return true


func ativar_movimento_extra() -> void:
	deslocamento_extra_pes = PES_EXTRA_MOVEL


func tem_oportunista() -> bool:
	return oportunista_restante > 0.0
