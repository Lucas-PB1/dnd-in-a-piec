# Roda todos os testes de tests/teste_*.gd e o jogo headless; mostra erros e avisos.
# Uso (PowerShell, na raiz do projeto):  .\tests\rodar_testes.ps1
$ErrorActionPreference = "Continue"
$godot = $env:GODOT_EDITOR_PATH
$raiz = Split-Path -Parent $PSScriptRoot
$falhou = $false

Write-Host "== Importando assets"
& $godot --headless --path $raiz --import 2>&1 | Select-String "ERROR|WARNING"

Write-Host "== Rodando o jogo por 3 s (procurando erros e avisos)"
$log = & $godot --headless --path $raiz --quit-after 180 2>&1 | Select-String "ERROR|WARNING"
if ($log) { $log; $falhou = $true } else { Write-Host "   sem erros nem avisos" }

foreach ($teste in Get-ChildItem (Join-Path $PSScriptRoot "teste_*.gd")) {
    Write-Host "== $($teste.Name)"
    & $godot --headless --path $raiz --script "res://tests/$($teste.Name)" 2>&1 |
        Select-String "ok |PASSOU|FALHOU|ERRO|ERROR|WARNING"
    if ($LASTEXITCODE -ne 0) { $falhou = $true }
}

if ($falhou) { Write-Host "RESULTADO: FALHOU"; exit 1 } else { Write-Host "RESULTADO: TUDO OK"; exit 0 }
