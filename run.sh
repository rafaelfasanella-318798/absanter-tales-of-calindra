#!/usr/bin/env bash
# run.sh - Executa o jogo usando o Godot Linux no WSL
# NOTA: Requer WSLg (Windows 11) ou um servidor X configurado (DISPLAY) para exibir a janela gráfica.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="${SCRIPT_DIR}/tools/godot/godot"

if [[ ! -x "${GODOT_BIN}" ]]; then
    echo "Erro: Binário do Godot não encontrado em ${GODOT_BIN}" >&2
    exit 1
fi

echo "Iniciando Absanter – Tales of Calindra..."
"${GODOT_BIN}" --path "${SCRIPT_DIR}" "$@"
