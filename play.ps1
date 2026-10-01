# play.ps1 - Executa o jogo em uma cena ou atalho especificado no Windows PowerShell
param (
    [string]$Target = "title",
    [double]$Speed = 1.0,
    [switch]$Colisoes,
    [switch]$Nav,
    [switch]$Fps,
    [switch]$Editor,
    [string]$Scenario = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$GodotExe = Join-Path $ScriptDir "tools\godot-win\Godot_v4.7.2-stable_win64.exe"

if (-not (Test-Path $GodotExe)) {
    $GodotExe = Join-Path $ScriptDir "tools\godot-win\Godot_v4.7.2-stable_win64_console.exe"
}

if (-not (Test-Path $GodotExe)) {
    Write-Error "Godot Windows executável não encontrado em $GodotExe"
    exit 1
}

$ScenePath = $Target
switch ($Target.ToLower()) {
    "title" { $ScenePath = "res://scenes/main/main.tscn" }
    "kakariko" { $ScenePath = "res://scenes/world_3d/kakariko_3d.tscn" }
    "battle" { $ScenePath = "res://scenes/battle_3d/battle_3d.tscn" }
    "camp" { $ScenePath = "res://scenes/world_3d/camp_3d.tscn" }
    "showcase" { $ScenePath = "res://scenes/dev/toon_showcase.tscn" }
}

$GodotArgs = @("--path", "$ScriptDir")

if ($Editor) {
    $GodotArgs += "--editor"
}
if ($Speed -ne 1.0) {
    $GodotArgs += @("--time-scale", "$Speed")
}
if ($Colisoes) {
    $GodotArgs += "--debug-collisions"
}
if ($Nav) {
    $GodotArgs += "--debug-navigation"
}
if ($Fps) {
    $GodotArgs += "--print-fps"
}

$GodotArgs += $ScenePath

if ($Scenario -ne "") {
    $GodotArgs += @("--", "--scenario=$Scenario")
}

Write-Host "Iniciando cena: $ScenePath"
Start-Process -FilePath $GodotExe -ArgumentList $GodotArgs
