#!/usr/bin/env bash
# verify.sh - Valida a integridade de uma ref (padrão HEAD) em clone/worktree limpo
# Conforme especificação G0-01 do docs/ARCHITECTURE.md

set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"

START_TIME=$(date +%s)
REF="HEAD"
SKIP_LINT=false

# Argument parsing
for arg in "$@"; do
    case "$arg" in
        --skip-lint)
            SKIP_LINT=true
            ;;
        *)
            REF="$arg"
            ;;
    esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="${REPO_DIR}/tools/godot/godot"

if [[ ! -x "${GODOT_BIN}" ]]; then
    echo "Erro: Binário do Godot não encontrado em ${GODOT_BIN}" >&2
    exit 1
fi

TMP_DIR="$(mktemp -d /tmp/absanter_verify_XXXXXX)"

cleanup() {
    local exit_code=$?
    echo "==> Limpando worktree temporária em ${TMP_DIR}..."
    git -C "${REPO_DIR}" worktree remove --force "${TMP_DIR}" 2>/dev/null || true
    rm -rf "${TMP_DIR}"
    git -C "${REPO_DIR}" worktree prune 2>/dev/null || true
    exit "${exit_code}"
}
trap cleanup EXIT INT TERM

echo "=========================================================="
echo "==> absanter verify: Verificando ref '${REF}' em worktree limpa"
echo "=========================================================="

# 1. Cria worktree limpa
echo "==> [1/5] Criando worktree limpa a partir de '${REF}'..."
git -C "${REPO_DIR}" -c core.hooksPath=/dev/null worktree add --detach "${TMP_DIR}" "${REF}"

# 2. Executa Godot --import
echo "==> [2/5] Executando Godot --import..."
"${GODOT_BIN}" --path "${TMP_DIR}" --headless --import

# 3. Executa Lint
if [[ "${SKIP_LINT}" = false ]]; then
    echo "==> [3/5] Verificando lint (gdlint e gdformat)..."
    if ! command -v gdlint &>/dev/null || ! command -v gdformat &>/dev/null; then
        echo "Erro: gdlint ou gdformat não encontrados em PATH." >&2
        echo "Instale com: pip install gdtoolkit" >&2
        exit 1
    fi
    gdlint "${TMP_DIR}/scripts" "${TMP_DIR}/scenes" "${TMP_DIR}/tests"
    gdformat --check "${TMP_DIR}/scripts" "${TMP_DIR}/scenes" "${TMP_DIR}/tests"
else
    echo "==> [3/5] Lint pulado (--skip-lint)."
fi

# 4. Executa testes GUT
echo "==> [4/5] Executando suíte de testes GUT com .gutconfig.json..."
GUT_LOG="${TMP_DIR}/gut_output.log"
set +e
"${GODOT_BIN}" --path "${TMP_DIR}" --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit 2>&1 | tee "${GUT_LOG}"
GUT_EXIT=${PIPESTATUS[0]}
set -e

if [[ ${GUT_EXIT} -ne 0 ]]; then
    echo "Erro: Falha na execução da suíte de testes GUT (código de saída ${GUT_EXIT})." >&2
    exit 1
fi

TOTAL_TESTS=$(grep -E "^Tests[[:space:]]+[0-9]+" "${GUT_LOG}" | awk '{print $2}' || echo "0")
PASSING_TESTS=$(grep -E "^Passing Tests[[:space:]]+[0-9]+" "${GUT_LOG}" | awk '{print $3}' || echo "0")

if [[ "${TOTAL_TESTS}" == "0" || "${PASSING_TESTS}" != "${TOTAL_TESTS}" ]]; then
    echo "Erro: Testes falharam ou nenhum teste foi executado (${PASSING_TESTS}/${TOTAL_TESTS} passaram)." >&2
    exit 1
fi

# 5. Smoke das cenas principais
echo "==> [5/5] Smoke test das cenas principais (--quit-after 180)..."
MAIN_SCENES=(
    "res://scenes/main/main.tscn"
    "res://scenes/world_3d/kakariko_3d.tscn"
    "res://scenes/battle_3d/battle_3d.tscn"
    "res://scenes/world_3d/camp_3d.tscn"
)

for scene in "${MAIN_SCENES[@]}"; do
    echo "    - Verificando cena: ${scene}"
    SCENE_LOG="${TMP_DIR}/scene_smoke.log"
    set +e
    "${GODOT_BIN}" --path "${TMP_DIR}" --headless "${scene}" --quit-after 180 > "${SCENE_LOG}" 2>&1
    SCENE_EXIT=$?
    set -e

    if [[ ${SCENE_EXIT} -ne 0 ]]; then
        echo "Erro: Falha ao carregar ${scene} (código ${SCENE_EXIT})." >&2
        cat "${SCENE_LOG}" >&2
        exit 1
    fi

    if grep -E -i "(SCRIPT ERROR|Parse Error)" "${SCENE_LOG}" > /dev/null; then
        echo "Erro: Erro de script detectado ao carregar ${scene}:" >&2
        grep -E -i -C 2 "(SCRIPT ERROR|Parse Error)" "${SCENE_LOG}" >&2
        exit 1
    fi
done

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "=========================================================="
echo "RESUMO DA VERIFICAÇÃO"
echo "=========================================================="
echo "Ref verificada:     ${REF}"
echo "Testes executados:  ${PASSING_TESTS}/${TOTAL_TESTS} passaram"
echo "Cenas testadas:     ${#MAIN_SCENES[@]} cenas OK"
echo "Tempo total:        ${DURATION}s"
if [[ "${SKIP_LINT}" = true ]]; then
    echo "Status:             verificação parcial: não apta para push"
    exit 0
else
    echo "Status:             SUCESSO - Apta para push!"
fi
echo "=========================================================="
