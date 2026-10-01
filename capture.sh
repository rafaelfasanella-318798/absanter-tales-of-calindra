#!/usr/bin/env bash
# capture.sh - Captura visual das cenas-chave usando Movie Maker do Godot
# Uso: ./capture.sh [all|title|kakariko|battle|camp|showcase] [--scenario <nome>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="${SCRIPT_DIR}/tools/godot/godot"

if [[ ! -x "${GODOT_BIN}" ]]; then
    echo "Erro: Binário do Godot não encontrado em ${GODOT_BIN}" >&2
    exit 1
fi

TARGET="all"
SCENARIO=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        all|title|kakariko|battle|camp|showcase)
            TARGET="$1"
            shift
            ;;
        --scenario|-Scenario)
            SCENARIO="$2"
            shift 2
            ;;
        *)
            echo "Argumento desconhecido: $1" >&2
            echo "Uso: ./capture.sh [all|title|kakariko|battle|camp|showcase] [--scenario <nome>]" >&2
            exit 1
            ;;
    esac
done

resolve_scene_path() {
    local key="$1"
    case "$key" in
        title) echo "scenes/main/main.tscn" ;;
        kakariko) echo "scenes/world_3d/kakariko_3d.tscn" ;;
        battle) echo "scenes/battle_3d/battle_3d.tscn" ;;
        camp) echo "scenes/world_3d/camp_3d.tscn" ;;
        showcase) echo "scenes/dev/toon_showcase.tscn" ;;
        *) echo "" ;;
    esac
}

capture_scene() {
    local name="$1"
    local rel_path
    rel_path="$(resolve_scene_path "$name")"

    if [[ -z "${rel_path}" || ! -f "${SCRIPT_DIR}/${rel_path}" ]]; then
        echo "[AVISO] Cena '${name}' (${rel_path}) não encontrada. Pulando..."
        return 0
    fi

    local out_dir="${SCRIPT_DIR}/captures/${name}"
    mkdir -p "${out_dir}"
    rm -f "${out_dir}"/frame*.png "${out_dir}"/frame.wav "${out_dir}"/0*.png

    echo "==> Capturando cena '${name}' (150 quadros @ 30 FPS)..."

    local cmd=("${GODOT_BIN}" "--path" "${SCRIPT_DIR}" "--write-movie" "captures/${name}/frame.png" "--fixed-fps" "30" "--quit-after" "150" "res://${rel_path}")
    if [[ -n "${SCENARIO}" ]]; then
        cmd+=("--" "--scenario=${SCENARIO}")
    fi

    "${cmd[@]}" >/dev/null 2>&1 || true

    local frames=()
    while IFS= read -r f; do
        [[ -n "$f" ]] && frames+=("$f")
    done < <(find "${out_dir}" -maxdepth 1 -name "frame*.png" | sort)

    local total=${#frames[@]}
    if [[ ${total} -eq 0 ]]; then
        echo "[ERRO] Nenhum quadro gerado para '${name}'!" >&2
        return 1
    fi

    local idx_start=0
    local idx_mid=$(( total / 2 ))
    local idx_end=$(( total - 1 ))

    cp "${frames[$idx_start]}" "${out_dir}/01.png"
    cp "${frames[$idx_mid]}" "${out_dir}/02.png"
    cp "${frames[$idx_end]}" "${out_dir}/03.png"

    # Remove quadros intermediários e áudio
    rm -f "${out_dir}"/frame*.png "${out_dir}"/frame.wav

    echo "[OK] Captura '${name}' concluída: captures/${name}/{01,02,03}.png"
}

SCENES=()
if [[ "${TARGET}" == "all" ]]; then
    SCENES=("title" "kakariko" "battle" "camp" "showcase")
else
    SCENES=("${TARGET}")
fi

mkdir -p "${SCRIPT_DIR}/captures"

for s in "${SCENES[@]}"; do
    capture_scene "$s"
done

echo "Todas as capturas solicitadas foram concluídas com sucesso!"
