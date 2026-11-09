# Roda todos os testes de tests/teste_*.gd e o jogo headless; mostra erros e avisos.
# Uso (PowerShell, na raiz do projeto):  .\tests\rodar_testes.ps1            (3 testes ao mesmo tempo)
#                                         .\tests\rodar_testes.ps1 -Paralelo 1   (um de cada vez, como antes)
# Cada teste é um processo do Godot com limite de tempo (-LimiteSegundos, padrão 120): passou disso, é morto e reprova.
# Em paralelo a suíte leva uma fração do tempo. A saída sai na ordem dos arquivos.
param([int]$Paralelo = 3, [int]$LimiteSegundos = 120)
$ErrorActionPreference = "Continue"
$godot = $env:GODOT_EDITOR_PATH
$raiz = Split-Path -Parent $PSScriptRoot
$falhou = $false

Write-Host "== Importando assets"
& $godot --headless --path $raiz --import 2>&1 | Select-String "ERROR|WARNING"

Write-Host "== Rodando o jogo por 3 s (procurando erros e avisos)"
# --debug: igual ao editor, mostra os avisos de GDScript (ex.: UNUSED_SIGNAL).
$log = & $godot --headless --debug --path $raiz --quit-after 180 2>&1 | Select-String "ERROR|WARNING"
if ($log) { $log; $falhou = $true } else { Write-Host "   sem erros nem avisos" }

# Um teste por processo, no máximo $Paralelo ao mesmo tempo. Cada trabalho devolve a saída filtrada e o código de saída.
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
        $saida = $texto -split "`r?`n" | Where-Object { $_ -match "ok |PASSOU|FALHOU|ERRO|ERROR|WARNING" }
    } else {
        taskkill /PID $processo.Id /T /F | Out-Null  # mata o processo e os filhos: um teste travado não pode acumular
        $codigo = 1
        $saida = @("ERRO - TRAVOU: passou de $limite s e foi encerrado")
    }
    [pscustomobject]@{ Arquivo = $arquivo; Saida = $saida; Codigo = $codigo }
}
$testes = Get-ChildItem (Join-Path $PSScriptRoot "teste_*.gd")
$jobs = @()
foreach ($teste in $testes) {
    while (@(Get-Job -State Running).Count -ge $Paralelo) { Start-Sleep -Milliseconds 200 }
    Write-Host "   iniciando $($teste.Name)"
    $jobs += Start-Job -ScriptBlock $trabalho -ArgumentList $godot, $raiz, $teste.Name, $LimiteSegundos
}
foreach ($job in $jobs) {
    $resultado = Receive-Job -Job $job -Wait
    Remove-Job -Job $job
    Write-Host "== $($resultado.Arquivo)"
    $resultado.Saida
    if ($resultado.Codigo -ne 0) { $falhou = $true }
}

if ($falhou) { Write-Host "RESULTADO: FALHOU"; exit 1 } else { Write-Host "RESULTADO: TUDO OK"; exit 0 }
