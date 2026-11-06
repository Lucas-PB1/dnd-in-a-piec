# Gera as regras do Cursor (.cursor/rules/*.mdc) a partir das skills do projeto
# (.claude/skills/*/SKILL.md). As skills são a fonte da verdade: edite o SKILL.md e rode
# este script de novo; nunca edite os .mdc gerados à mão.
#   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Jogos\rpg\tools\gerar_regras_cursor.ps1
#
# Cada skill vira uma regra com o mesmo texto e um modo de ativação do Cursor:
#   sempre = alwaysApply (entra em toda conversa)
#   globs  = entra quando um arquivo que casa com os padrões está no contexto
#   pedido = o agente decide pela descrição (ou o usuário chama com @nome)

$raiz = Split-Path -Parent $PSScriptRoot
$origem = Join-Path $raiz ".claude\skills"
$destino = Join-Path $raiz ".cursor\rules"
$utf8 = New-Object System.Text.UTF8Encoding($false)

# skill -> [modo, globs]
$ativacao = [ordered]@{
	"godot-estrutura-pastas"    = @("sempre", "")
	"godot-estilo-gdscript"     = @("globs", "**/*.gd")
	"godot-cenas-e-sinais"      = @("globs", "**/*.tscn,**/*.gd")
	"godot-componentes-e-dados" = @("globs", "core/**,data/**,features/**")
	"godot-maquina-de-estados"  = @("globs", "**/estados/**")
	"revisar-codigo"            = @("pedido", "")
}

New-Item -ItemType Directory -Force $destino | Out-Null

foreach ($nome in $ativacao.Keys) {
	$arquivo = Join-Path $origem "$nome\SKILL.md"
	if (-not (Test-Path $arquivo)) {
		Write-Host "Falta $arquivo" -ForegroundColor Yellow
		continue
	}
	$texto = [System.IO.File]::ReadAllText($arquivo, $utf8)
	# Separa o cabeçalho (--- ... ---) do corpo e pega a descrição.
	$partes = [regex]::Match($texto, '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n(.*)$')
	$cabecalho = $partes.Groups[1].Value
	$corpo = $partes.Groups[2].Value.TrimStart()
	$descricao = [regex]::Match($cabecalho, '(?m)^description:\s*(.+)$').Groups[1].Value.Trim()
	$modo = $ativacao[$nome][0]
	$globs = $ativacao[$nome][1]
	$sempre = if ($modo -eq "sempre") { "true" } else { "false" }
	$aviso = "<!-- Gerado de .claude/skills/$nome/SKILL.md por tools/gerar_regras_cursor.ps1. Edite a skill, não este arquivo. -->"
	$mdc = "---`ndescription: $descricao`nglobs: $globs`nalwaysApply: $sempre`n---`n$aviso`n`n$corpo"
	[System.IO.File]::WriteAllText((Join-Path $destino "$nome.mdc"), $mdc.Replace("`r`n", "`n"), $utf8)
	Write-Host "  $nome.mdc ($modo)"
}
Write-Host "Regras do Cursor geradas em $destino"
