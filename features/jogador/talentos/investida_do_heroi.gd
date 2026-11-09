class_name InvestidaDoHeroi
extends RefCounted
## Investida: o modo escolhido (empurrão ou dano extra) e quanto o herói correu em linha reta. O golpe feito
## depois de 10 pés de corrida leva o efeito, uma vez por rodada. Regra pura.

const DISTANCIA_PES := 10.0
## true = empurra 10 pés; false = soma 1d8 de dano.
var empurra: bool = false
## Quanto já correu em linha reta (px).
var corrida_px: float = 0.0


func alternar() -> void:
	empurra = not empurra


## Mede a corrida: soma enquanto corre para onde olha; zera quando para, anda devagar ou vira.
func medir(correndo: bool, velocidade_x: float, direcao_olhar: int, delta: float) -> void:
	if correndo and velocidade_x != 0.0 and signf(velocidade_x) == direcao_olhar:
		corrida_px += absf(velocidade_x) * delta
	else:
		corrida_px = 0.0


func carregada() -> bool:
	return corrida_px >= EscalaDnd.pes_para_pixels(DISTANCIA_PES)


## Liga o efeito escolhido no golpe (o herói confere o talento e a recarga antes).
func aplicar(golpe: Golpe) -> void:
	golpe.efeitos.append(EfeitosDeTalento.Investida.new(empurra))
