# test.ps1 - Executa testes automatizados com GUT no Windows PowerShell
param (
    [string]$File = "",
    [string]$Name = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$GodotExe = Join-Path $ScriptDir "tools\godot-win\Godot_v4.7.2-stable_win64_console.exe"

if (-not (Test-Path $GodotExe)) {
    $GodotExe = Join-Path $ScriptDir "tools\godot-win\Godot_v4.7.2-stable_win64.exe"
}

if (-not (Test-Path $GodotExe)) {
    Write-Error "Godot Windows executável não encontrado em $GodotExe"
    exit 1
}

$Arguments = @("--path", "$ScriptDir", "--headless", "-s", "addons/gut/gut_cmdln.gd", "-gconfig=.gutconfig.json", "-gexit")

if ($File -ne "") {
    $Arguments += "-gtest=$File"
}

if ($Name -ne "") {
    $Arguments += "-gunit_test_name=$Name"
}

Write-Host "Executando testes GUT..."
& $GodotExe $Arguments
exit $LASTEXITCODE
