# Confere os pedidos do SpriteCook de docs/spritecook/prompts.json e gera docs/spritecook/prompts.md.
#   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Jogos\rpg\tools\conferir_prompts_spritecook.ps1
# Confere, sem gastar crédito: estrutura, quadros (cada fase do texto cobre de 1 a N sem buracos),
# frases obrigatórias, negativo, tamanho e o CUSTO de cada rodada pelas regras reais de preço.
# Sai com código 1 se algo estiver errado. O arquivo .md é gerado: edite o .json.

$raiz = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
$json = Join-Path $raiz "docs\spritecook\prompts.json"
$destino = Join-Path $raiz "docs\spritecook\prompts.md"
$dados = [System.IO.File]::ReadAllText($json, $utf8) | ConvertFrom-Json

$falhas = New-Object System.Collections.Generic.List[string]
function Falha($id, $texto) { $script:falhas.Add("[$id] $texto") }

$custos = $dados.regras_de_custo
$presets = @("idle", "walk", "jump", "run", "attack", "hurt", "death")
$vistas = @("front_idle", "front_walk", "front_run")
$tipos = @("custom", "preset", "personagem", "efeito")
$ids = @{}

foreach ($item in $dados.itens) {
	$id = $item.id
	if ($ids.ContainsKey($id)) { Falha $id "id repetido" }
	$ids[$id] = $true
	if ($tipos -notcontains $item.tipo) { Falha $id "tipo desconhecido: $($item.tipo)" }
	if (-not $item.titulo) { Falha $id "sem título" }
	if (-not $item.conferir -or $item.conferir.Count -eq 0) { Falha $id "sem lista 'conferir' (o que olhar no resultado)" }

	if ($item.tipo -eq "custom") {
		$p = [string]$item.prompt
		$n = [int]$item.frames
		if ($n -lt 2 -or $n -gt 16 -or $n % 2 -ne 0) { Falha $id "quadros deve ser par de 2 a 16 (é $n)" }
		if ($vistas -notcontains $item.source_view) { Falha $id "source_view inválido: $($item.source_view)" }
		if ($p.Length -lt 250 -or $p.Length -gt 1200) { Falha $id "prompt com $($p.Length) caracteres (esperado 250 a 1200)" }
		if ($p -notmatch "side view facing right") { Falha $id "falta a frase 'side view facing right'" }
		if ($p -notmatch "same camera angle") { Falha $id "falta a frase 'same camera angle'" }
		if ($p -match "empty hands") { Falha $id "usa 'empty hands' (no teste, isso virou soco)" }
		if (-not $item.negativo) { Falha $id "sem lista de proibições (vira a frase final do pedido)" }
		$final = $p + " Strictly avoid: " + $item.negativo + "."
		if ($final.Length -gt 3000) { Falha $id "pedido final com $($final.Length) caracteres (o SpriteCook aceita no máximo 3000)" }
		# Fases "Frames a-b:" cobrem 1..N em ordem, sem buraco nem sobreposição.
		$achados = [regex]::Matches($p, "Frames?\s+(\d+)(?:-(\d+))?:")
		if ($achados.Count -eq 0) { Falha $id "sem fases por quadro ('Frames 1-2: ...')" }
		else {
			$proximo = 1
			foreach ($m in $achados) {
				$ini = [int]$m.Groups[1].Value
				$fim = if ($m.Groups[2].Success) { [int]$m.Groups[2].Value } else { $ini }
				if ($ini -ne $proximo) { Falha $id "fases fora de ordem ou com buraco: esperava começar em $proximo e começa em $ini" }
				if ($fim -lt $ini) { Falha $id "fase com fim menor que o início: $($m.Value)" }
				$proximo = $fim + 1
			}
			if ($proximo - 1 -ne $n) { Falha $id "as fases cobrem $($proximo - 1) quadros, mas o pedido tem $n" }
		}
	}
	elseif ($item.tipo -eq "preset") {
		if ($presets -notcontains $item.preset) { Falha $id "preset inexistente: $($item.preset)" }
	}
	elseif ($item.tipo -eq "personagem") {
		$p = [string]$item.prompt
		if ($p.Length -lt 100 -or $p.Length -gt 600) { Falha $id "prompt do personagem com $($p.Length) caracteres (esperado 100 a 600)" }
		if ($p -notmatch "side profile facing right") { Falha $id "falta 'side profile facing right'" }
		if ($p -notmatch "clean dark outline") { Falha $id "falta 'clean dark outline' (o mesmo traço do herói)" }
		if ($p -notmatch "cute chibi proportions") { Falha $id "falta 'cute chibi proportions' (mesma proporção do herói)" }
	}
	elseif ($item.tipo -eq "efeito") {
		if (-not $item.prompt_imagem -or -not $item.prompt) { Falha $id "efeito precisa de prompt_imagem e prompt (animação)" }
		if ($item.prompt_imagem -notmatch "transparent background") { Falha $id "prompt_imagem sem 'transparent background'" }
		if ($item.prompt_imagem -notmatch "pixel art") { Falha $id "prompt_imagem sem 'pixel art'" }
		if (-not $item.negativo) { Falha $id "sem negativo" }
		$n = [int]$item.frames
		if ($n -lt 2 -or $n -gt 16 -or $n % 2 -ne 0) { Falha $id "quadros deve ser par de 2 a 16 (é $n)" }
	}
}

# Custo por rodada (animações: 20 a primeira, 14 as outras, +12 uma vez se houver pose de andar).
$resumo = @()
$porPrioridade = @{}
foreach ($nome in $dados.rodadas.PSObject.Properties.Name) {
	$doGrupo = @($dados.itens | Where-Object { $_.rodada -eq $nome })
	$anims = @($doGrupo | Where-Object { $_.tipo -eq "custom" -or $_.tipo -eq "preset" })
	$bases = @($doGrupo | Where-Object { $_.tipo -eq "personagem" })
	$custo = 0
	if ($anims.Count -gt 0) { $custo += $custos.primeira_animacao_da_rodada + $custos.animacao_extra_na_rodada * ($anims.Count - 1) }
	if (@($anims | Where-Object { $_.prep }).Count -gt 0) { $custo += $custos.preparo_de_pose_andar_ou_correr }
	$custo += $custos.personagem_base * $bases.Count
	$prio = if ($doGrupo.Count -gt 0) { [int]($doGrupo | Select-Object -First 1).prioridade } else { 0 }
	$resumo += [pscustomobject]@{ Rodada = $nome; Itens = $doGrupo.Count; Custo = $custo; Prioridade = $prio }
	if (-not $porPrioridade.ContainsKey($prio)) { $porPrioridade[$prio] = 0 }
	$porPrioridade[$prio] += $custo
}
$efeitos = @($dados.itens | Where-Object { $_.tipo -eq "efeito" })
$custoEfeito = $custos.imagem_pixel_engine + $custos.animar_imagem
foreach ($e in $efeitos) {
	$prio = [int]$e.prioridade
	if (-not $porPrioridade.ContainsKey($prio)) { $porPrioridade[$prio] = 0 }
	$porPrioridade[$prio] += $custoEfeito
}

# O que o plano (docs/plano_animacoes.md) espera.
$esperado = @{ heroi_essencial = 48; goblin_minion = 114; goblin_warrior = 114; gray_ooze = 88; heroi_extras = 48 }
foreach ($linha in $resumo) {
	if ($esperado.ContainsKey($linha.Rodada) -and $esperado[$linha.Rodada] -ne $linha.Custo) {
		Falha $linha.Rodada "custo calculado $($linha.Custo), mas o plano espera $($esperado[$linha.Rodada])"
	}
}
$efeitosPrio2 = @($efeitos | Where-Object { $_.prioridade -eq 2 }).Count
$efeitosPrio3 = @($efeitos | Where-Object { $_.prioridade -eq 3 }).Count
if ($efeitosPrio2 -ne 11) { Falha "efeitos" "esperava 11 efeitos de combate (prioridade 2), há $efeitosPrio2" }
if ($efeitosPrio3 -ne 5) { Falha "efeitos" "esperava 5 efeitos de mapa (prioridade 3), há $efeitosPrio3" }

# --- Documento gerado ---
$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine("# Pedidos do SpriteCook (gerado)")
[void]$md.AppendLine("")
[void]$md.AppendLine("Gerado de ``docs/spritecook/prompts.json`` por ``tools/conferir_prompts_spritecook.ps1``. **Edite o .json, não este arquivo.**")
[void]$md.AppendLine("Cada pedido está em inglês (é o que o motor entende melhor). Os campos 'Conferir' são para olhar o resultado antes de integrar.")
[void]$md.AppendLine("")
[void]$md.AppendLine("## Como pedir")
[void]$md.AppendLine("")
[void]$md.AppendLine("- **Animações do herói:** ``generate_character_animations`` com o personagem ``b484dd94-593b-4f7b-a97a-0786ac93147d``, ``perspective=platformer``, ``custom_animations`` com ``label``, ``prompt``, ``source_view`` e ``output_frames``, e ``negative_prompt`` quando a ferramenta aceitar. Os itens da mesma rodada vão **juntos numa chamada** (20 + 14 + 14...).")
[void]$md.AppendLine("- **Monstros:** primeiro ``generate_character`` (12) com o prompt da base; só anime se a base ficar boa. Presets (parado, andar, dano, morte) usam ``animation_ids``; os golpes usam ``custom_animations``.")
[void]$md.AppendLine("- **Efeitos:** ``generate_game_art`` com ``model=pixel-engine-image-v1`` (64x64, 6 créditos), depois ``animate_game_art`` (20).")
[void]$md.AppendLine("- Antes de gerar: ``get_credit_balance``. Depois de gerar: salvar o ``asset_id`` no ``spritecook-assets.json``.")
[void]$md.AppendLine("")
[void]$md.AppendLine("## Custo por rodada (calculado)")
[void]$md.AppendLine("")
[void]$md.AppendLine("| Rodada | Itens | Custo | Prioridade |")
[void]$md.AppendLine("|---|---|---|---|")
foreach ($linha in $resumo) { [void]$md.AppendLine("| $($linha.Rodada) | $($linha.Itens) | $($linha.Custo) | $($linha.Prioridade) |") }
[void]$md.AppendLine("| efeitos (16 x $custoEfeito) | $($efeitos.Count) | $($efeitos.Count * $custoEfeito) | 2 e 3 |")
[void]$md.AppendLine("")
[void]$md.AppendLine("Prioridade 0 = opcional (extras do herói e Gray Ooze, que já tem arte CC0).")
[void]$md.AppendLine("")

$grupos = @($dados.itens | Group-Object { if ($_.rodada) { $_.rodada } else { $_.grupo } })
foreach ($g in $grupos) {
	[void]$md.AppendLine("## $($g.Name)")
	[void]$md.AppendLine("")
	if ($dados.rodadas.PSObject.Properties.Name -contains $g.Name) { [void]$md.AppendLine("_$($dados.rodadas.($g.Name).descricao)_"); [void]$md.AppendLine("") }
	foreach ($item in $g.Group) {
		[void]$md.AppendLine("### $($item.id): $($item.titulo)")
		[void]$md.AppendLine("")
		$quadros = if ($item.frames) { "$($item.frames) quadros" } else { "imagem" }
		$ferr = switch ($item.tipo) { "custom" { "animação personalizada" } "preset" { "preset '$($item.preset)'" } "personagem" { "personagem base" } default { "efeito (imagem + animação)" } }
		[void]$md.AppendLine("- Tipo: $ferr, $quadros, prioridade $($item.prioridade).")
		if ($item.tipo -eq "efeito") {
			[void]$md.AppendLine("")
			[void]$md.AppendLine("Imagem (``pixel-engine-image-v1``, 64x64):")
			[void]$md.AppendLine("")
			[void]$md.AppendLine('```'); [void]$md.AppendLine($item.prompt_imagem); [void]$md.AppendLine('```')
			[void]$md.AppendLine("")
			[void]$md.AppendLine("Animação:")
		}
		[void]$md.AppendLine("")
		if ($item.tipo -eq "custom") {
			[void]$md.AppendLine("**Enviar assim** (as proibições vão dentro do texto, porque ``custom_animations`` ignora ``negative_prompt``):")
			[void]$md.AppendLine("")
			[void]$md.AppendLine('```'); [void]$md.AppendLine($item.prompt + " Strictly avoid: " + $item.negativo + "."); [void]$md.AppendLine('```')
		} else {
			[void]$md.AppendLine('```'); [void]$md.AppendLine($item.prompt); [void]$md.AppendLine('```')
		}
		if ($item.negativo -and $item.tipo -ne "custom") {
			[void]$md.AppendLine("")
			[void]$md.AppendLine("Negativo:")
			[void]$md.AppendLine("")
			[void]$md.AppendLine('```'); [void]$md.AppendLine($item.negativo); [void]$md.AppendLine('```')
		}
		[void]$md.AppendLine("")
		[void]$md.AppendLine("Conferir no resultado:")
		[void]$md.AppendLine("")
		foreach ($c in $item.conferir) { [void]$md.AppendLine("- [ ] $c") }
		if ($item.alerta) { [void]$md.AppendLine(""); [void]$md.AppendLine("> $($item.alerta)") }
		[void]$md.AppendLine("")
	}
}
[System.IO.File]::WriteAllText($destino, $md.ToString().Replace("`r`n", "`n"), $utf8)

Write-Host "Itens conferidos: $($dados.itens.Count)"
$resumo | Format-Table -AutoSize | Out-String | Write-Host
foreach ($k in ($porPrioridade.Keys | Sort-Object)) { Write-Host ("Prioridade {0}: {1} créditos" -f $k, $porPrioridade[$k]) }
Write-Host "Documento: $destino"
if ($falhas.Count -gt 0) {
	Write-Host "`nFALHAS ($($falhas.Count)):" -ForegroundColor Red
	$falhas | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
	exit 1
}
Write-Host "`nTUDO CONFERIDO" -ForegroundColor Green
