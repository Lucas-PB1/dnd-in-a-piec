extends SceneTree
## Monta o SpriteFrames dos monstros a partir das folhas do SpriteCook (8 quadros lado a lado).
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/gerar_monstros_spritecook.gd
## Para cada criatura grava `<nome>_sc_frames.tres` e imprime o tamanho do corpo no 1º quadro
## parado (para escolher `scale` e `offset` do sprite na cena: pés em (0,0), meio do corpo em x = 0).
## A morte não tem animação: é por código (DissolverComponent).

const LADO_QUADRO := {"minion": 88, "warrior": 76, "ooze": 78}
const QUADROS := 8
## criatura -> pasta, prefixo dos arquivos, animações (nome -> [arquivo, fps, repete]).
const CRIATURAS := {
	"minion": {
		"pasta": "res://features/humanoides/sprites/",
		"animacoes": {
			"parado": ["minion_parado_sc", 8.0, true],
			"correr": ["minion_andar_sc", 12.0, true],
			"atacar": ["minion_golpe_sc", 20.0, false],
			"arremessar": ["minion_arremesso_sc", 20.0, false],
			"dano": ["minion_dano_sc", 16.0, false],
		},
	},
	"warrior": {
		"pasta": "res://features/humanoides/sprites/",
		"animacoes": {
			"parado": ["warrior_parado_sc", 8.0, true],
			"correr": ["warrior_andar_sc", 12.0, true],
			"atacar": ["warrior_golpe_sc", 20.0, false],
			"disparar": ["warrior_arco_sc", 16.0, false],
			"dano": ["warrior_dano_sc", 16.0, false],
		},
	},
	"ooze": {
		"pasta": "res://features/gray_ooze/sprites/",
		"animacoes": {
			"parado": ["ooze_parado_sc", 8.0, true],
			"andar": ["ooze_deslizar_sc", 10.0, true],
			"atacar": ["ooze_pseudopode2_sc", 16.0, false],
			"dano": ["ooze_dano_sc", 16.0, false],
		},
	},
}


func _initialize() -> void:
	for nome: String in CRIATURAS:
		_montar(nome, CRIATURAS[nome])
	quit()


func _montar(nome: String, dados: Dictionary) -> void:
	var lado: int = LADO_QUADRO[nome]
	var quadros := SpriteFrames.new()
	quadros.remove_animation(&"default")
	var animacoes: Dictionary = dados["animacoes"]
	for animacao: String in animacoes:
		var d: Array = animacoes[animacao]
		var tira: Texture2D = load(dados["pasta"] + d[0] + ".png")
		quadros.add_animation(animacao)
		quadros.set_animation_speed(animacao, d[1])
		quadros.set_animation_loop(animacao, d[2])
		for i in QUADROS:
			var quadro := AtlasTexture.new()
			quadro.atlas = tira
			quadro.region = Rect2(Vector2(i * lado, 0), Vector2(lado, lado))
			quadros.add_frame(animacao, quadro)
	ResourceSaver.save(quadros, dados["pasta"] + "%s_sc_frames.tres" % nome)
	_imprimir_corpo(nome, dados, lado)


## Caixa do corpo no 1º quadro parado e o `offset` que põe os pés na origem e o corpo no meio.
func _imprimir_corpo(nome: String, dados: Dictionary, lado: int) -> void:
	var caminho := ProjectSettings.globalize_path(dados["pasta"] + dados["animacoes"]["parado"][0] + ".png")
	var corpo := Image.load_from_file(caminho).get_region(Rect2i(0, 0, lado, lado)).get_used_rect()
	var meio_x := corpo.position.x + corpo.size.x / 2.0
	var pes_y := corpo.end.y
	print("%s: corpo %s, offset = (%s, %s)" % [nome, corpo, lado / 2.0 - meio_x, lado / 2.0 - pes_y])
