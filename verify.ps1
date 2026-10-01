# verify.ps1 - Valida integridade em clone/worktree limpo no Windows PowerShell
param (
    [string]$Ref = "HEAD",
    [switch]$SkipLint
)

$ErrorActionPreference = "Stop"
$StartTime = Get-Date

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$GodotExe = Join-Path $ScriptDir "tools\godot-win\Godot_v4.7.2-stable_win64_console.exe"

if (-not (Test-Path $GodotExe)) {
    $GodotExe = Join-Path $ScriptDir "tools\godot-win\Godot_v4.7.2-stable_win64.exe"
}

if (-not (Test-Path $GodotExe)) {
    Write-Error "Godot Windows executável não encontrado em $GodotExe"
    exit 1
}

$TmpGuid = [System.Guid]::NewGuid().ToString("N")
$TmpDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "absanter_verify_$TmpGuid")

Write-Host "=========================================================="
Write-Host "==> absanter verify: Verificando ref '$Ref' em worktree limpa"
Write-Host "=========================================================="

try {
    # 1. Cria worktree limpa
    Write-Host "==> [1/5] Criando worktree limpa a partir de '$Ref'..."
    git -C "$ScriptDir" -c core.hooksPath=/dev/null worktree add --detach "$TmpDir" "$Ref"
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao criar worktree do git."
    }

    # 2. Executa Godot --import
    Write-Host "==> [2/5] Executando Godot --import..."
    & $GodotExe --path "$TmpDir" --headless --import
    
    # 3. Lint
    if (-not $SkipLint) {
        Write-Host "==> [3/5] Verificando lint (gdlint e gdformat)..."
        $gdlint = Get-Command "gdlint" -ErrorAction SilentlyContinue
        $gdformat = Get-Command "gdformat" -ErrorAction SilentlyContinue
        if (-not $gdlint -or -not $gdformat) {
            Write-Error "gdlint ou gdformat não encontrados. Instale com: pip install gdtoolkit"
            exit 1
        }
        & gdlint "$TmpDir\scripts" "$TmpDir\scenes" "$TmpDir\tests"
        if ($LASTEXITCODE -ne 0) { throw "Falha no gdlint." }
        & gdformat --check "$TmpDir\scripts" "$TmpDir\scenes" "$TmpDir\tests"
        if ($LASTEXITCODE -ne 0) { throw "Falha no gdformat." }
    } else {
        Write-Host "==> [3/5] Lint pulado (-SkipLint)."
    }

    # 4. GUT tests
    Write-Host "==> [4/5] Executando testes GUT..."
    $GutLog = Join-Path $TmpDir "gut_output.log"
    & $GodotExe --path "$TmpDir" --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit *>&1 | Tee-Object -FilePath $GutLog
    if ($LASTEXITCODE -ne 0) {
        throw "Falha na execução dos testes GUT (código $LASTEXITCODE)."
    }

    $LogContent = Get-Content $GutLog -Raw
    if ($LogContent -notmatch "All tests passed!") {
        throw "Nem todos os testes passaram!"
    }

    # 5. Smoke tests
    Write-Host "==> [5/5] Smoke test das cenas principais..."
    $MainScenes = @(
        "res://scenes/main/main.tscn",
        "res://scenes/world_3d/kakariko_3d.tscn",
        "res://scenes/battle_3d/battle_3d.tscn",
        "res://scenes/world_3d/camp_3d.tscn"
    )

    foreach ($Scene in $MainScenes) {
        Write-Host "    - Verificando cena: $Scene"
        $SceneLog = Join-Path $TmpDir "scene_smoke.log"
        & $GodotExe --path "$TmpDir" --headless "$Scene" --quit-after 180 *>&1 | Out-File -FilePath $SceneLog
        if ($LASTEXITCODE -ne 0) {
            Get-Content $SceneLog | Write-Error
            throw "Falha ao rodar cena $Scene (código $LASTEXITCODE)"
        }
        $SceneContent = Get-Content $SceneLog -Raw
        if ($SceneContent -match "(SCRIPT ERROR|Parse Error)") {
            Get-Content $SceneLog | Write-Error
            throw "Erro de script detectado na cena $Scene"
        }
    }

    $EndTime = Get-Date
    $Duration = [math]::Round(($EndTime - $StartTime).TotalSeconds)

    Write-Host "=========================================================="
    Write-Host "RESUMO DA VERIFICAÇÃO"
    Write-Host "=========================================================="
    Write-Host "Ref verificada:     $Ref"
    Write-Host "Cenas testadas:     $($MainScenes.Count) cenas OK"
    Write-Host "Tempo total:        ${Duration}s"
    if ($SkipLint) {
        Write-Host "Status:             verificação parcial: não apta para push"
        exit 0
    } else {
        Write-Host "Status:             SUCESSO - Apta para push!"
        exit 0
    }
}
finally {
    Write-Host "==> Limpando worktree temporária..."
    git -C "$ScriptDir" worktree remove --force "$TmpDir" 2>$null
    if (Test-Path "$TmpDir") {
        Remove-Item -Recurse -Force "$TmpDir" -ErrorAction SilentlyContinue
    }
    git -C "$ScriptDir" worktree prune 2>$null
}
