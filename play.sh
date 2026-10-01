#!/usr/bin/env bash
# play.sh - Abre o jogo em uma cena ou atalho especificado
# Atalhos: title, kakariko, battle, camp, showcase

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="${SCRIPT_DIR}/tools/godot/godot"

if [[ ! -x "${GODOT_BIN}" ]]; then
    echo "Erro: Binário do Godot não encontrado em ${GODOT_BIN}" >&2
    exit 1
fi

TARGET="res://scenes/main/main.tscn"
EXTRA_ARGS=()
USER_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        title)
            TARGET="res://scenes/main/main.tscn"
            shift
            ;;
        kakariko)
            TARGET="res://scenes/world_3d/kakariko_3d.tscn"
            shift
            ;;
        battle)
            TARGET="res://scenes/battle_3d/battle_3d.tscn"
            shift
            ;;
        camp)
            TARGET="res://scenes/world_3d/camp_3d.tscn"
            shift
            ;;
        showcase)
            TARGET="res://scenes/dev/toon_showcase.tscn"
            shift
            ;;
        res://*.tscn)
            TARGET="$1"
            shift
            ;;
        --speed|-Speed)
            EXTRA_ARGS+=("--time-scale" "$2")
            shift 2
            ;;
        --colisoes|-Colisoes)
            EXTRA_ARGS+=("--debug-collisions")
            shift
            ;;
        --nav|-Nav)
            EXTRA_ARGS+=("--debug-navigation")
            shift
            ;;
        --fps|-Fps)
            EXTRA_ARGS+=("--print-fps")
            shift
            ;;
        --editor|-Editor)
            EXTRA_ARGS+=("--editor")
            shift
            ;;
        --scenario|-Scenario)
            USER_ARGS+=("--scenario=$2")
            shift 2
            ;;
        *)
            EXTRA_ARGS+=("$1")
            shift
            ;;
    esac
done

CMD=("${GODOT_BIN}" "--path" "${SCRIPT_DIR}")

if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
    CMD+=("${EXTRA_ARGS[@]}")
fi

CMD+=("${TARGET}")

if [[ ${#USER_ARGS[@]} -gt 0 ]]; then
    CMD+=("--" "${USER_ARGS[@]}")
fi

echo "Executando cena: ${TARGET}"
exec "${CMD[@]}"
