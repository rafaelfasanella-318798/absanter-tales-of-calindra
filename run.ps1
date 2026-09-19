# run.ps1 - Abre o projeto no Godot Windows para edicao visual e jogo nativo
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$GodotExe = Join-Path $ScriptDir "tools\godot-win\Godot_v4.7.2-stable_win64.exe"

if (-not (Test-Path $GodotExe)) {
    Write-Error "Godot Windows executavel nao encontrado em: $GodotExe"
    exit 1
}

Write-Host "Iniciando Godot Windows: $GodotExe"
Start-Process -FilePath $GodotExe -ArgumentList "--path `"$ScriptDir`""
