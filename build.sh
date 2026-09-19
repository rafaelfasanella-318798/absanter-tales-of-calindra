#!/usr/bin/env bash
# build.sh - Exporta o jogo para Windows, Linux e Web

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="${SCRIPT_DIR}/tools/godot/godot"

if [[ ! -x "${GODOT_BIN}" ]]; then
    echo "Erro: Binário do Godot não encontrado em ${GODOT_BIN}" >&2
    exit 1
fi

mkdir -p export/windows export/linux export/web

PLATFORMS=("${@:-linux windows web}")

for target in ${PLATFORMS}; do
    case "${target,,}" in
        linux)
            echo "==> Exportando Linux/X11..."
            "${GODOT_BIN}" --path "${SCRIPT_DIR}" --headless --export-release "Linux" export/linux/absanter.x86_64
            ;;
        windows)
            echo "==> Exportando Windows Desktop..."
            "${GODOT_BIN}" --path "${SCRIPT_DIR}" --headless --export-release "Windows Desktop" export/windows/absanter.exe
            ;;
        web)
            echo "==> Exportando Web..."
            "${GODOT_BIN}" --path "${SCRIPT_DIR}" --headless --export-release "Web" export/web/index.html
            ;;
        *)
            echo "Aviso: Plataforma desconhecida '${target}'. Ignorando."
            ;;
    esac
done

echo "==> Exportação concluída com sucesso!"
