# Gera o que o Cursor usa (.cursor/) a partir das fontes da verdade do projeto. Nunca edite os
# arquivos gerados à mão: edite a fonte e rode este script de novo.
#   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Jogos\rpg\tools\gerar_regras_cursor.ps1
#
#   .claude/skills/*/SKILL.md  -> .cursor/rules/<skill>.mdc        (regras de código)
#   docs/decisoes/*.md         -> .cursor/rules/decisoes-<tema>.mdc (decisões, por pasta mexida)
#   .claude/commands/*.md      -> .cursor/commands/*.md            (comandos /nome)
#
# Modos de ativação das regras no Cursor:
#   sempre = alwaysApply (entra em toda conversa)
#   globs  = entra quando um arquivo que casa com os padrões está no contexto
#   pedido = o agente decide pela descrição (ou o usuário chama com @nome)
# Os agentes de .claude/agents/ não têm equivalente em arquivo no Cursor (lá são "modos" na interface).

$raiz = Split-Path -Parent $PSScriptRoot
$regras = Join-Path $raiz ".cursor\rules"
$comandosCursor = Join-Path $raiz ".cursor\commands"
$utf8 = New-Object System.Text.UTF8Encoding($false)

# skill -> [modo, globs]
$skills = [ordered]@{
	"godot-estrutura-pastas"    = @("sempre", "")
	"godot-estilo-gdscript"     = @("globs", "**/*.gd")
	"godot-cenas-e-sinais"      = @("globs", "**/*.tscn,**/*.gd")
	"godot-componentes-e-dados" = @("globs", "core/**,data/**,features/**")
	"godot-maquina-de-estados"  = @("globs", "**/estados/**")
	"revisar-codigo"            = @("pedido", "")
}

# documento de decisões -> [globs, descrição]
$decisoes = [ordered]@{
	"base"          = @("project.godot,levels/**,assets/tiles/**,core/componentes/**", "Decisões da base técnica: motor, resolução e tela larga, pixel art, fase, câmera, camadas de física, componentes de combate, nome do jogo.")
	"heroi"         = @("features/jogador/**,data/jogador_padrao.tres,data/classe_guerreiro.tres", "Decisões do herói: estados, pulo, corrida, ataque, apanhar, Second Wind, arma na mão, pose de mira, escudo, armadura visível.")
	"regras_dnd"    = @("core/regras/**,core/dados/classe_rpg.gd,core/componentes/condicoes_component.gd,core/componentes/defesa_component.gd", "Decisões das regras de D&D 5e no código: vida, dano, combate, vantagem, salvaguarda, escala, tipos de dano, proficiências, maestrias, condições, talentos, regras da casa.")
	"armas_e_itens" = @("tools/gerar_armas.gd,tools/gerar_armaduras.gd,data/armas/**,data/armaduras/**,data/municoes/**,data/pacotes/**,core/dados/arma.gd,core/dados/armadura.gd,core/dados/item.gd,core/dados/municao.gd,core/regras/inventario.gd,core/regras/equipamento.gd,features/jogador/ataque_jogador.gd,features/arremesso/**,features/bau/**,ui/inventario/**,ui/bau/**", "Decisões de armas, armaduras, itens e inventário: tabelas geradas, golpe por arma, área de acerto, arremesso, disparo e força do tiro, corrosão, pacotes, baú.")
	"criaturas"     = @("features/gray_ooze/**,features/goblin/**,features/boneco_treino/**,core/dados/criatura_rpg.gd,data/gray_ooze.tres,data/goblin_minion.tres", "Decisões das criaturas: ficha do livro (CriaturaRPG), Gray Ooze, Goblin Minion, monstros no jogo, arena (Trazer).")
	"interface"     = @("ui/**,core/utilitarios/comandos.gd,core/utilitarios/opcoes_toque.gd", "Decisões de telas, HUD, ações de input e celular: título, criação, inventário, comandos, controles de toque e ajuste do layout.")
}

New-Item -ItemType Directory -Force $regras | Out-Null
New-Item -ItemType Directory -Force $comandosCursor | Out-Null

function Ler($arquivo) { return [System.IO.File]::ReadAllText($arquivo, $utf8) }
function Gravar($arquivo, $texto) { [System.IO.File]::WriteAllText($arquivo, $texto.Replace("`r`n", "`n"), $utf8) }

# Separa o cabeçalho (--- ... ---) do corpo. Devolve @(cabecalho, corpo).
function Separar($texto) {
	$partes = [regex]::Match($texto, '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n(.*)$')
	if (-not $partes.Success) { return @("", $texto) }
	return @($partes.Groups[1].Value, $partes.Groups[2].Value.TrimStart())
}

function Regra($nome, $descricao, $globs, $sempre, $corpo, $fonte) {
	$aviso = "<!-- Gerado de $fonte por tools/gerar_regras_cursor.ps1. Edite a fonte, não este arquivo. -->"
	$mdc = "---`ndescription: $descricao`nglobs: $globs`nalwaysApply: $sempre`n---`n$aviso`n`n$corpo"
	Gravar (Join-Path $regras "$nome.mdc") $mdc
}

Write-Host "Skills -> regras:"
foreach ($nome in $skills.Keys) {
	$arquivo = Join-Path $raiz ".claude\skills\$nome\SKILL.md"
	if (-not (Test-Path $arquivo)) { Write-Host "  falta $arquivo" -ForegroundColor Yellow; continue }
	$cabecalho, $corpo = Separar (Ler $arquivo)
	$descricao = [regex]::Match($cabecalho, '(?m)^description:\s*(.+)$').Groups[1].Value.Trim()
	$modo, $globs = $skills[$nome]
	$sempre = if ($modo -eq "sempre") { "true" } else { "false" }
	Regra $nome $descricao $globs $sempre $corpo ".claude/skills/$nome/SKILL.md"
	Write-Host "  $nome.mdc ($modo)"
}

Write-Host "Decisões -> regras:"
foreach ($tema in $decisoes.Keys) {
	$fonte = "docs/decisoes/$tema.md"
	if (-not (Test-Path (Join-Path $raiz $fonte))) { Write-Host "  falta $fonte" -ForegroundColor Yellow; continue }
	$globs, $descricao = $decisoes[$tema]
	$corpo = "Antes de mudar algo deste tema, siga as decisões já tomadas (e atualize o documento se uma decisão mudar):`n`n@$fonte`n"
	$nome = "decisoes-" + $tema.Replace("_", "-")
	Regra $nome $descricao $globs "false" $corpo $fonte
	Write-Host "  $nome.mdc (globs)"
}

Write-Host "Comandos:"
foreach ($arquivo in Get-ChildItem (Join-Path $raiz ".claude\commands\*.md")) {
	$cabecalho, $corpo = Separar (Ler $arquivo.FullName)
	$descricao = [regex]::Match($cabecalho, '(?m)^description:\s*(.+)$').Groups[1].Value.Trim()
	# O Cursor não troca $ARGUMENTS: o que o usuário escrever depois do comando vem junto da mensagem.
	$corpo = $corpo.Replace('$ARGUMENTS', '<o que o usuário escreveu depois do comando>')
	$aviso = "<!-- Gerado de .claude/commands/$($arquivo.Name) por tools/gerar_regras_cursor.ps1. Edite a fonte, não este arquivo. -->"
	Gravar (Join-Path $comandosCursor $arquivo.Name) "$aviso`n# $descricao`n`n$corpo"
	Write-Host "  /$($arquivo.BaseName)"
}

Write-Host "Pronto: $regras e $comandosCursor"
