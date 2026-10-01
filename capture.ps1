# capture.ps1 - Captura visual das cenas-chave usando Movie Maker do Godot no Windows PowerShell
# Uso: .\capture.ps1 [-Target all|title|kakariko|battle|camp|showcase] [-Scenario <nome>]

param (
    [string]$Target = "all",
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

function Resolve-ScenePath([string]$Key) {
    switch ($Key.ToLower()) {
        "title" { return "scenes\main\main.tscn" }
        "kakariko" { return "scenes\world_3d\kakariko_3d.tscn" }
        "battle" { return "scenes\battle_3d\battle_3d.tscn" }
        "camp" { return "scenes\world_3d\camp_3d.tscn" }
        "showcase" { return "scenes\dev\toon_showcase.tscn" }
        default { return "" }
    }
}

function Capture-Scene([string]$SceneName) {
    $RelPath = Resolve-ScenePath $SceneName
    $FullPath = Join-Path $ScriptDir $RelPath

    if (-not (Test-Path $FullPath)) {
        Write-Host "[AVISO] Cena '$SceneName' ($RelPath) não encontrada. Pulando..."
        return
    }

    $OutDir = Join-Path $ScriptDir "captures\$SceneName"
    if (-not (Test-Path $OutDir)) {
        New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
    }

    Get-ChildItem -Path $OutDir -Filter "frame*" | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $OutDir -Filter "0*.png" | Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Host "==> Capturando cena '$SceneName' (150 quadros @ 30 FPS)..."

    $GodotArgs = @(
        "--path", "$ScriptDir",
        "--write-movie", "captures/$SceneName/frame.png",
        "--fixed-fps", "30",
        "--quit-after", "150",
        "res://$($RelPath.Replace('\', '/'))"
    )

    if ($Scenario -ne "") {
        $GodotArgs += @("--", "--scenario=$Scenario")
    }

    $Process = Start-Process -FilePath $GodotExe -ArgumentList $GodotArgs -Wait -NoNewWindow -PassThru

    $Frames = Get-ChildItem -Path $OutDir -Filter "frame*.png" | Sort-Object Name
    $Total = $Frames.Count

    if ($Total -eq 0) {
        Write-Warning "[ERRO] Nenhum quadro gerado para '$SceneName'!"
        return
    }

    $IdxStart = 0
    $IdxMid = [Math]::Floor($Total / 2)
    $IdxEnd = $Total - 1

    Copy-Item $Frames[$IdxStart].FullName (Join-Path $OutDir "01.png") -Force
    Copy-Item $Frames[$IdxMid].FullName (Join-Path $OutDir "02.png") -Force
    Copy-Item $Frames[$IdxEnd].FullName (Join-Path $OutDir "03.png") -Force

    # Remove intermediários
    Get-ChildItem -Path $OutDir -Filter "frame*" | Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Host "[OK] Captura '$SceneName' concluída: captures/$SceneName/01.png, 02.png, 03.png"
}

$Scenes = @()
if ($Target.ToLower() -eq "all") {
    $Scenes = @("title", "kakariko", "battle", "camp", "showcase")
} else {
    $Scenes = @($Target.ToLower())
}

$CapturesDir = Join-Path $ScriptDir "captures"
if (-not (Test-Path $CapturesDir)) {
    New-Item -ItemType Directory -Path $CapturesDir -Force | Out-Null
}

foreach ($s in $Scenes) {
    Capture-Scene $s
}

Write-Host "Todas as capturas solicitadas foram concluídas com sucesso!"
