# Gemma 4 26B Remote - Servidor LLM Isolado para Claude Code

**Projeto isolado para expor modelo Gemma 4 26B A4B no waphixai para uso no Claude Code (laptopdev)**

---

## 📋 Objetivo

Criar um **servidor LLM isolado** no waphixai (192.168.1.130) que exponha o modelo **Gemma 4 26B A4B** via API OpenAI-compatible, permitindo que o Claude Code no laptopdev o utilize como backend local, **sem afetar** os projetos existentes (waphix-ai-os, waphix-ao-os-v0.5).

---

## 🏗️ Arquitetura

### Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                    LAPTOPDEV (192.168.1.x)                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Claude Code (IDE)                           │  │
│  │  - Configuração: endpoint customizado                     │  │
│  │  - Modelo: gemma-4-26b-a4b-q4kxl                         │  │
│  │  - API: http://192.168.1.130:8090/v1                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              │ SSH / HTTP                       │
│                              ▼                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │
┌─────────────────────────────────────────────────────────────────┐
│                    WAPHIXAI (192.168.1.130)                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         SERVIDOR ISOLADO (Este projeto)                  │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  llama-server (porta 8090)                        │  │  │
│  │  │  - Backend: Vulkan (ROCm bloqueado)              │  │  │
│  │  │  - Modelo: gemma-4-26b-a4b-q4kxl                  │  │  │
│  │  │  - NGL: 14 (6.8 GB VRAM)                         │  │  │
│  │  │  - API: OpenAI-compatible                         │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  Scripts de gestão (start/stop/status)           │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  Logs isolados em ./logs/                         │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         PROJETOS EXISTENTES (NÃO AFETADOS)               │  │
│  │  - waphix-ai-os (Hermes, portas 3010/4000)             │  │
│  │  - waphix-ao-os-v0.5 (modelbench, porta 7331)          │  │
│  │  - PM2 (não usado por este projeto)                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         RECURSOS COMPARTILHADOS (READ-ONLY)             │  │
│  │  - Modelo: /home/mike/waphix-ao-os-v0.5/models/        │  │
│  │  - Backend: /home/mike/waphix-ao-os-v0.5/runtimes/     │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Isolamento Garantido

| Aspecto | Estratégia de Isolamento |
|---------|--------------------------|
| **Portas** | Porta 8090 (única, não usada por outros projetos) |
| **Processos** | Processo dedicado, sem PM2, sem systemd |
| **Logs** | Diretório `./logs/` isolado |
| **Config** | `.env.gemma-remote` isolado |
| **Dados** | Zero escrita em dados existentes |
| **Recursos** | Read-only em modelos/backends existentes |
| **Estado** | `./state/` para PID e status |

---

## 📁 Estrutura de Diretórios

```
gemma-4-26b-remote/
├── README.md                 # Este ficheiro
├── DIARIO_BORDO.md           # Diário de bordo detalhado
├── docs/
│   ├── ARQUITETURA.md        # Arquitetura detalhada
│   ├── ESTRATEGIA_COMMITS.md # Estratégia de commits e reversão
│   └── TROUBLESHOOTING.md    # Guia de troubleshooting
├── scripts/
│   ├── setup.sh              # Setup inicial (isolado)
│   ├── start-server.sh       # Iniciar llama-server
│   ├── stop-server.sh        # Parar llama-server
│   ├── status-server.sh      # Status do servidor
│   └── test-connectivity.sh  # Testar conectividade
├── config/
│   ├── .env.gemma-remote     # Configuração isolada
│   └── server-config.yaml    # Config llama-server
├── logs/                     # Logs isolados
│   ├── server-out.log
│   └── server-err.log
└── state/                    # Estado do processo
    └── server.pid
```

---

## 🔧 Pré-requisitos

### No waphixai (servidor)

- **Hardware**: AMD Ryzen 5 2600, 15GB RAM, RX 6600 8GB VRAM
- **Modelo**: `gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf` (já existe)
- **Backend**: llama.cpp Vulkan (já compilado em waphix-ao-os-v0.5)
- **Porta 8090**: Livre e não bloqueada por firewall
- **UV**: Gerenciador de pacotes Python (já instalado)

### No laptopdev (cliente)

- **SSH**: Acesso a mike@192.168.1.130 (já funcional)
- **Claude Code**: Configurado para endpoint customizado
- **Rede**: Na mesma LAN (192.168.1.x)

---

## 🚀 Quick Start

### 1. Configurar SSH (laptopdev)

**No Windows (PowerShell)**:
```powershell
cd C:\Users\Pixie\OneDrive\Documents\aa-mike\gemma-4-26b-remote
.\scripts\setup-ssh-key.ps1
```

**No Linux/Mac (Bash)**:
```bash
cd ~/gemma-4-26b-remote
bash scripts/setup-ssh-key.sh
```

### 2. Setup Inicial (waphixai)

```bash
cd /home/mike/CascadeProjects/gemma-4-26b-remote
bash scripts/setup.sh
```

### 3. Iniciar Servidor (waphixai)

```bash
cd /home/mike/CascadeProjects/gemma-4-26b-remote
bash scripts/start-server.sh
```

### 4. Verificar Status (waphixai)

```bash
cd /home/mike/CascadeProjects/gemma-4-26b-remote
bash scripts/status-server.sh
```

### 5. Configurar Claude Code (laptopdev)

No Claude Code, configurar:
- **Endpoint**: `http://192.168.1.130:8090/v1`
- **Model ID**: `gemma-4-26b-a4b-q4kxl`
- **API Key**: `dummy` (ou qualquer valor, servidor não valida)

---

## 📊 Configuração do Modelo

### Gemma 4 26B A4B

| Parâmetro | Valor |
|-----------|-------|
| **Ficheiro** | `gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf` |
| **Tamanho** | 14.2 GB |
| **Parâmetros** | 25.2B total / 3.8B ativos (MoE) |
| **Quantização** | Q4_K_XL |
| **Backend** | Vulkan (ROCm bloqueado) |
| **NGL** | 99 (settings apurados no waphix-ao-os-v0.5) |
| **NMOE** | 20 (para modelos MoE) |
| **Context** | 8192 tokens (settings apurados no waphix-ao-os-v0.5) |
| **Arquitetura** | SWA (window=1024) |

### Restrições Críticas

- **ROCm bloqueado**: `rocm_blocked: true` - só funciona com Vulkan
- **NGL 99**: Settings agressivos apurados no waphix-ao-os-v0.5, podem usar mais VRAM
- **NMOE 20**: Específico para modelos MoE como Gemma 4 26B A4B
- **SWA**: Sliding Window Attention com window=1024
- **Multimodal**: Disponível via `gemma-4-26b-mmproj-F16.gguf` (opcional)

---

## 🔒 Segurança e Isolamento

### Regras de Ouro

1. **NÃO modificar** ficheiros dos projetos existentes
2. **NÃO usar** PM2 ou systemd (processo manual isolado)
3. **NÃO escrever** em `/srv/ai/` ou outros diretórios de projetos
4. **NÃO expor** portas usadas por outros projetos
5. **READ-ONLY** em modelos e backends existentes
6. **LOGS isolados** em `./logs/`
7. **ZERO impacto** em serviços existentes

### Verificação de Isolamento

```bash
# Verificar que não estamos a usar PM2
pm2 list  # Deve mostrar só processos de outros projetos

# Verificar porta única
ss -tulpn | grep 8090  # Deve estar livre ou só nosso processo

# Verificar logs isolados
ls -la logs/  # Só nossos logs
```

---

## 📝 Estratégia de Commits

### Padrão de Commits

```
feat: descrição curta
- Detalhe 1
- Detalhe 2
- Impacto em projetos existentes: NENHUM
```

### Pontos de Reversão

Cada commit deve ser:
- **Reversível**: `git revert` ou `git reset` deve funcionar
- **Documentado**: DIARIO_BORDO.md atualizado
- **Testado**: Funcionalidade verificada antes de commit
- **Isolado**: Não afeta outros projetos

### Frequência

- **Commits frequentes**: Após cada funcionalidade/teste
- **Push imediato**: Após cada commit bem-sucedido
- **Branch principal**: `main` (sem branches por enquanto)

---

## 🐛 Troubleshooting

Ver `docs/TROUBLESHOOTING.md` para guia detalhado.

### Problemas Comuns

| Problema | Solução |
|----------|---------|
| Porta 8090 em uso | `bash scripts/stop-server.sh` |
| OOM VRAM | Reduzir NGL para 12 em `config/server-config.yaml` |
| Sem conectividade | Verificar firewall: `sudo ufw status` |
| Modelo não encontrado | Verificar path em `config/.env.gemma-remote` |

---

## 📚 Documentação Adicional

- `DIARIO_BORDO.md` - Diário de bordo detalhado
- `docs/ARQUITETURA.md` - Arquitetura técnica detalhada
- `docs/ESTRATEGIA_COMMITS.md` - Estratégia de commits e reversão
- `docs/TROUBLESHOOTING.md` - Guia de troubleshooting

---

## 🎯 Próximos Passos

1. ✅ Criar estrutura de diretórios isolada
2. ⏳ Criar documentação principal (README.md)
3. ⏳ Criar diário de bordo (DIARIO_BORDO.md)
4. ⏳ Criar scripts de setup e gestão
5. ⏳ Testar setup isolado
6. ⏳ Configurar pubkey SSH
7. ⏳ Testar conectividade
8. ⏳ Iniciar servidor pela primeira vez
9. ⏳ Configurar Claude Code no laptopdev
10. ⏳ Testar end-to-end

---

## 📞 Suporte

Em caso de problemas:
1. Consultar `docs/TROUBLESHOOTING.md`
2. Verificar `DIARIO_BORDO.md` para decisões recentes
3. Verificar logs em `./logs/`
4. Reverter para commit anterior se necessário

---

**Estado Atual**: 🟡 Setup inicial em progresso  
**Última Atualização**: 2026-06-17 23:48 UTC  
**Versão**: 0.1.0-alpha
