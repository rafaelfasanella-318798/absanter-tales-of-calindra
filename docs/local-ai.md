# Guia de IA Local para Desenvolvimento · Absanter

Instruções para configuração e integração de modelos locais (Ollama, OpenCode, Cline).

---

## 1. Topologia de Hardware e Runtime

- **CPU**: AMD Ryzen 7 9800X3D (8C/16T)
- **GPU**: NVIDIA RTX 3070 8 GB VRAM
- **Configuração Recomendada**:
  - Ollama instalado diretamente no **Windows host** (acesso à VRAM direta sem overhead).
  - Comunicação WSL ↔ Windows via `http://localhost:11434` (com `networkingMode=mirrored` no `.wslconfig`).

---

## 2. Modelos Recomendados

1. **Qwen3-Coder-30B-A3B (Q4_K_M)**:
   - Papel: Geração de código complexo, dados estruturados e refatorações.
   - MoE com 3B ativos.
2. **Qwen2.5-Coder-7B (Q4_K_M)**:
   - Papel: Edições rápidas em tempo real e autocomplete (via Continue.dev).

---

## 3. Comandos de Setup (no Host Windows)

```powershell
# Baixar modelos principais
ollama pull qwen3-coder:30b
ollama pull qwen2.5-coder:7b
```

---

## 4. Integração com Agentes no WSL

- **OpenCode CLI**:
  ```bash
  opencode --model ollama/qwen3-coder:30b
  ```
- **Context Window (`num_ctx`)**:
  - Recomenda-se ajustar `num_ctx: 32768` no Modelfile para leitura de múltiplos arquivos.
