# Roda todos os testes de tests/teste_*.gd e o jogo headless; mostra erros e avisos.
# Uso (PowerShell, na raiz do projeto):  .\tests\rodar_testes.ps1            (3 testes ao mesmo tempo)
#                                         .\tests\rodar_testes.ps1 -Paralelo 1   (um de cada vez, como antes)
# Cada teste e um processo do Godot com limite de tempo (-LimiteSegundos, padrao 120): passou disso, e morto e reprova.
# Em paralelo a suite leva uma fracao do tempo. A saida sai na ordem dos arquivos.
# Cada teste imprime >> OK ou >> FALHOU; no fim lista todas as falhas (nunca falha em silencio).
param([int]$Paralelo = 3, [int]$LimiteSegundos = 120)
$ErrorActionPreference = "Continue"
$godot = $env:GODOT_EDITOR_PATH
$raiz = Split-Path -Parent $PSScriptRoot
$falhou = $false
$falhas = New-Object System.Collections.Generic.List[string]

function Test-LinhaRelevante {
	param([string]$linha)
	if ($linha -match "ObjectDB instances were leaked") { return $false }
	if ($linha -match "resources still in use at exit") { return $false }
	return $linha -match "ok |PASSOU|FALHOU|ERRO|ERROR|WARNING|SCRIPT ERROR|Parse Error|Failed to"
}

Write-Host "== Importando assets"
$logImport = & $godot --headless --path $raiz --import 2>&1 | Where-Object { Test-LinhaRelevante "$_" }
if ($logImport) {
	$logImport
	Write-Host "AVISO: import imprimiu ERROR/WARNING (conferir acima)."
}

Write-Host "== Rodando o jogo por 3 s (procurando erros e avisos)"
$log = & $godot --headless --debug --path $raiz --quit-after 180 2>&1 | Where-Object { Test-LinhaRelevante "$_" }
if ($log) {
	$log
	$falhou = $true
	[void]$falhas.Add("jogo headless 3s")
	Write-Host ">> FALHOU: jogo headless (ha ERROR/WARNING acima)"
} else {
	Write-Host "   sem erros nem avisos"
}

$trabalho = {
	param($godot, $raiz, $arquivo, $limite)
	$info = New-Object System.Diagnostics.ProcessStartInfo
	$info.FileName = $godot
	$info.Arguments = "--headless --debug --path `"$raiz`" --script res://tests/$arquivo"
	$info.RedirectStandardOutput = $true
	$info.RedirectStandardError = $true
	$info.UseShellExecute = $false
	$info.CreateNoWindow = $true
	$processo = [System.Diagnostics.Process]::Start($info)
	$lendo = $processo.StandardOutput.ReadToEndAsync()
	$lendoErro = $processo.StandardError.ReadToEndAsync()
	if ($processo.WaitForExit($limite * 1000)) {
		$codigo = $processo.ExitCode
		$texto = $lendo.Result + "`n" + $lendoErro.Result
		$linhas = $texto -split "`r?`n"
		$saida = @()
		foreach ($linha in $linhas) {
			if ($linha -match "ObjectDB instances were leaked") { continue }
			if ($linha -match "resources still in use at exit") { continue }
			if ($linha -match "ok |PASSOU|FALHOU|ERRO|ERROR|WARNING|SCRIPT ERROR|Parse Error|Failed to") {
				$saida += $linha
			}
		}
		$rastro = @($linhas | Where-Object { $_.Trim() -ne "" } | Select-Object -Last 25)
	} else {
		taskkill /PID $processo.Id /T /F | Out-Null
		$codigo = 1
		$saida = @("ERRO - TRAVOU: passou de $limite s e foi encerrado")
		$rastro = @()
	}
	$junto = $saida -join "`n"
	$passouTexto = $junto -match "(?m)^PASSOU:"
	$falhouTexto = ($junto -match "(?m)^FALHOU:") -or ($junto -match "(?m)^\s*ERRO -")
	[pscustomobject]@{
		Arquivo = $arquivo
		Saida = $saida
		Rastro = $rastro
		Codigo = $codigo
		PassouTexto = $passouTexto
		FalhouTexto = $falhouTexto
	}
}

$testes = Get-ChildItem (Join-Path $PSScriptRoot "teste_*.gd")
$jobs = @()
foreach ($teste in $testes) {
	while (@(Get-Job -State Running).Count -ge $Paralelo) { Start-Sleep -Milliseconds 200 }
	Write-Host "   iniciando $($teste.Name)"
	$jobs += Start-Job -ScriptBlock $trabalho -ArgumentList $godot, $raiz, $teste.Name, $LimiteSegundos
}

function Test-ResultadoFalhou($resultado) {
	if ($resultado.Codigo -ne 0) { return "codigo de saida $($resultado.Codigo)" }
	if ($resultado.FalhouTexto) { return "imprimiu FALHOU/ERRO" }
	if (-not $resultado.PassouTexto) { return "nao imprimiu PASSOU (provavel crash ou script incompleto)" }
	return $null
}

foreach ($job in $jobs) {
	$resultado = Receive-Job -Job $job -Wait
	Remove-Job -Job $job
	Write-Host ""
	Write-Host "== $($resultado.Arquivo)"
	if ($resultado.Saida -and @($resultado.Saida).Count -gt 0) {
		$resultado.Saida
	} else {
		Write-Host "   (nenhuma linha ok/PASSOU/FALHOU/ERRO filtrada)"
	}

	$motivo = Test-ResultadoFalhou $resultado
	# Flake sob carga paralela: uma segunda tentativa sozinha antes de reprovar de verdade.
	if ($motivo) {
		Write-Host ">> tentativa 1 falhou ($motivo); repetindo sozinho..."
		$retryJob = Start-Job -ScriptBlock $trabalho -ArgumentList $godot, $raiz, $resultado.Arquivo, $LimiteSegundos
		$resultado = Receive-Job -Job $retryJob -Wait
		Remove-Job -Job $retryJob
		if ($resultado.Saida -and @($resultado.Saida).Count -gt 0) { $resultado.Saida }
		$motivo = Test-ResultadoFalhou $resultado
	}

	if ($motivo) {
		$falhou = $true
		[void]$falhas.Add("$($resultado.Arquivo) ($motivo)")
		Write-Host ">> FALHOU: $($resultado.Arquivo) - $motivo"
		if (-not $resultado.Saida -or @($resultado.Saida).Count -eq 0) {
			Write-Host "   --- ultimas linhas brutas ---"
			$resultado.Rastro
			Write-Host "   --- fim ---"
		}
	} else {
		Write-Host ">> OK: $($resultado.Arquivo)"
	}
}

Write-Host ""
if ($falhou) {
	$n = $falhas.Count
	Write-Host "RESULTADO: FALHOU - $n falhas:"
	foreach ($f in $falhas) { Write-Host "  - $f" }
	exit 1
}

Write-Host "RESULTADO: TUDO OK"
exit 0
