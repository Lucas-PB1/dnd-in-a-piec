class_name DisparoDeCriatura
extends RefCounted
## Capacidade de disparo da ficha (`disparos`) e Sensibilidade à Luz Solar (`sensivel_ao_sol`).
## O dono monta o `Golpe` (autor, vantagem, Enfraquecido) e chama `atirar`; a IA de quando
## atirar (perto demais, chance, multiataque) fica na feature.

const CENA_FLECHA := preload("res://core/projeteis/flecha.tscn")
const MUNICAO_FLECHA := preload("res://data/municoes/flecha.tres")
## Chão sólido + pranchas (bloqueiam a linha de tiro).
const MASCARA_CHAO := 1 | (1 << 5)  # MontagemDeCriatura.mascara_do_chao()

var _criatura: CriaturaRPG
## Cópias do disparo da ficha. Menor que 0 = não acaba.
var _flechas: int = 0
## Fase de dia: quem é sensível ao sol ataca com desvantagem.
var luz_do_sol: bool = false


func _init(criatura: CriaturaRPG) -> void:
	_criatura = criatura
	_flechas = criatura.disparos


## A ficha tem ataque de disparo?
static func tem_disparo(criatura: CriaturaRPG) -> bool:
	return criatura.disparos != 0


## Sensibilidade à Luz Solar: desvantagem nos ataques enquanto estiver ao sol.
static func desvantagem_por_sol(criatura: CriaturaRPG, ao_sol: bool) -> bool:
	return criatura.sensivel_ao_sol and ao_sol


func desvantagem_solar() -> bool:
	return desvantagem_por_sol(_criatura, luz_do_sol)


func tem_flecha() -> bool:
	return _flechas < 0 or _flechas > 0


func flechas_restantes() -> int:
	return _flechas


## Dentro do alcance longo do disparo da ficha.
func no_alcance_longo(distancia_px: float) -> bool:
	return distancia_px <= EscalaDnd.pes_para_pixels(_criatura.disparo_longo_pes)


## Nada do mundo entre o peito de quem atira e o do alvo.
static func linha_de_tiro_livre(
	espaco: PhysicsDirectSpaceState2D,
	origem: Vector2,
	destino: Vector2,
) -> bool:
	return SensorDeTerreno.linha_livre(espaco, origem, destino, MASCARA_CHAO)


## True se tinha flecha e gastou uma (munição infinita não muda a conta).
func consumir_flecha() -> bool:
	if not tem_flecha():
		return false
	if _flechas > 0:
		_flechas -= 1
	return true


## Gasta munição (se acaba) e solta a flecha. False se não tinha flecha.
func atirar(
	pai: Node,
	golpe: Golpe,
	origem: Vector2,
	destino: Vector2,
	gravidade: float,
) -> bool:
	if not consumir_flecha():
		return false
	var flecha: Flecha = CENA_FLECHA.instantiate()
	pai.add_child(flecha)
	flecha.lancar(
		golpe,
		MUNICAO_FLECHA,
		origem,
		destino,
		EscalaDnd.pes_para_pixels(_criatura.disparo_normal_pes),
		EscalaDnd.pes_para_pixels(_criatura.disparo_longo_pes),
		gravidade,
	)
	return true
