# Roda todos os testes de tests/teste_*.gd e o jogo headless; mostra erros e avisos.
# Uso (PowerShell, na raiz do projeto):  .\tests\rodar_testes.ps1            (3 testes ao mesmo tempo)
#                                         .\tests\rodar_testes.ps1 -Paralelo 1   (um de cada vez, como antes)
# Cada teste é um processo do Godot; em paralelo a suíte leva uma fração do tempo. A saída sai na ordem dos arquivos.
param([int]$Paralelo = 3)
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
    param($godot, $raiz, $arquivo)
    $saida = & $godot --headless --debug --path $raiz --script "res://tests/$arquivo" 2>&1 |
        Select-String "ok |PASSOU|FALHOU|ERRO|ERROR|WARNING" | ForEach-Object { $_.Line }
    [pscustomobject]@{ Arquivo = $arquivo; Saida = $saida; Codigo = $LASTEXITCODE }
}
$testes = Get-ChildItem (Join-Path $PSScriptRoot "teste_*.gd")
$jobs = @()
foreach ($teste in $testes) {
    while (@(Get-Job -State Running).Count -ge $Paralelo) { Start-Sleep -Milliseconds 200 }
    $jobs += Start-Job -ScriptBlock $trabalho -ArgumentList $godot, $raiz, $teste.Name
}
foreach ($job in $jobs) {
    $resultado = Receive-Job -Job $job -Wait
    Remove-Job -Job $job
    Write-Host "== $($resultado.Arquivo)"
    $resultado.Saida
    if ($resultado.Codigo -ne 0) { $falhou = $true }
}

if ($falhou) { Write-Host "RESULTADO: FALHOU"; exit 1 } else { Write-Host "RESULTADO: TUDO OK"; exit 0 }
