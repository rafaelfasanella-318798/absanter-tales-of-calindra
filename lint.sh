#!/usr/bin/env bash
# lint.sh - Executa linting e checagem de formatação GDScript com gdtoolkit

set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"

if ! command -v gdlint &>/dev/null; then
    echo "Erro: gdlint não encontrado em PATH. Instale com 'pip3 install --user gdtoolkit'." >&2
    exit 1
fi

echo "==> Executando gdlint..."
gdlint scripts/ scenes/ tests/

echo "==> Verificando formatação com gdformat..."
gdformat --check scripts/ scenes/ tests/

echo "==> Tudo certo! Código aprovado no lint."
