#!/usr/bin/env bash
# test.sh - Executa testes automatizados com GUT em modo headless

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="${SCRIPT_DIR}/tools/godot/godot"

if [[ ! -x "${GODOT_BIN}" ]]; then
    echo "Erro: Binário do Godot não encontrado em ${GODOT_BIN}" >&2
    exit 1
fi

echo "Executando testes GUT..."
"${GODOT_BIN}" --path "${SCRIPT_DIR}" --headless -s addons/gut/gut_cmdln.gd -gexit "$@"
