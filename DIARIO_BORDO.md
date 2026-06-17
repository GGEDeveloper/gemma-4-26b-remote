# Diário de Bordo - Gemma 4 26B Remote

**Projeto isolado para expor modelo Gemma 4 26B A4B no waphixai para uso no Claude Code (laptopdev)**

---

## 2026-06-17 23:48 UTC - Início do Projeto

### Contexto Inicial

**Objetivo**: Criar servidor LLM isolado no waphixai (192.168.1.130) para expor modelo Gemma 4 26B A4B via API OpenAI-compatible para uso no Claude Code no laptopdev.

**Requisitos Críticos**:
- Isolamento completo de projetos existentes (waphix-ai-os, waphix-ao-os-v0.5)
- Documentação exaustiva (doc + diário de bordo)
- Commits frequentes com múltiplos pontos de reversão
- Modularidade máxima

**Contexto Extra**:
- laptopdev já consegue SSH para waphixai (mike@192.168.1.130, pw fuckub1tch)
- pubkey SSH ainda não configurada
- devin ai já está ligado no laptopdev via SSH host para waphixai

### Decisões Arquiteturais

#### 1. Localização do Projeto
**Decisão**: Criar em `/home/mike/CascadeProjects/gemma-4-26b-remote/`
**Justificativa**:
- Diretório CascadeProjects já existe e está vazio
- Isolado de `/srv/ai/` e projetos existentes
- Fácil acesso e backup
- Não interfere com waphix-ai-os ou waphix-ao-os-v0.5

#### 2. Estrutura de Diretórios
**Decisão**: Estrutura modular isolada
```
gemma-4-26b-remote/
├── README.md                 # Documentação principal
├── DIARIO_BORDO.md           # Este ficheiro
├── docs/                     # Documentação adicional
├── scripts/                  # Scripts de gestão
├── config/                   # Configuração isolada
├── logs/                     # Logs isolados
└── state/                    # Estado do processo
```
**Justificativa**:
- Separação clara de responsabilidades
- Logs isolados para debugging
- Config isolado para não afetar outros projetos
- State para tracking de processo

#### 3. Escolha de Porta
**Decisão**: Porta 8090
**Justificativa**:
- Não usada por waphix-ai-os (3010, 4000, 8080, 8083)
- Não usada por waphix-ao-os-v0.5 (7331)
- Fora do range comum (8000-8080)
- Fácil de lembrar (8090 = 809 + 0)

#### 4. Estratégia de Processo
**Decisão**: Processo manual isolado (sem PM2, sem systemd)
**Justificativa**:
- PM2 já usado por waphix-ai-os
- Isolamento completo garantido
- Start/stop manual permite controlo total
- Logs isolados em `./logs/`
- Zero dependência de serviços externos

#### 5. Acesso a Recursos
**Decisão**: Read-only em recursos existentes
**Justificativa**:
- Modelo já existe em `/home/mike/waphix-ao-os-v0.5/models/`
- Backend Vulkan já compilado em `/home/mike/waphix-ao-os-v0.5/runtimes/vulkan/`
- Zero escrita em diretórios de projetos existentes
- Isolamento completo mantido

### Análise de Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|------------|
| Porta 8090 bloqueada por firewall | Média | Alto | Verificar UFW antes de setup |
| Conflito com processo existente | Baixa | Médio | Verificar porta antes de start |
| OOM VRAM (8GB limit) | Média | Alto | NGL=14 (6.8GB) com margem |
| SSH sem pubkey | Alta | Baixo | Configurar pubkey após setup |
| Claude Code não suporta endpoint custom | Baixa | Alto | Verificar docs Claude Code |

### Próximos Passos Imediatos

1. ✅ Criar estrutura de diretórios isolada
2. ✅ Criar README.md com arquitetura completa
3. ⏳ Criar DIARIO_BORDO.md (este ficheiro)
4. ⏳ Criar ficheiro de configuração isolado (.env.gemma-remote)
5. ⏳ Criar script de setup isolado
6. ⏳ Criar scripts de start/stop/status
7. ⏳ Documentar estratégia de commits
8. ⏳ Configurar pubkey SSH
9. ⏳ Testar conectividade
10. ⏳ Commit inicial e push

### Commit Planejado

**Mensagem**: `feat: estrutura inicial e documentação do projeto isolado`

**Conteúdo**:
- Estrutura de diretórios isolada
- README.md com arquitetura completa
- DIARIO_BORDO.md inicial
- Decisões arquiteturais documentadas
- Análise de riscos inicial

**Reversibilidade**: Sim - `git rm -rf` reverte tudo

---

## 2026-06-17 23:50 UTC - Continuação do Setup

### Estado Atual

- ✅ Estrutura de diretórios criada
- ✅ README.md criado com arquitetura completa
- ✅ DIARIO_BORDO.md inicializado
- ⏳ Ficheiros de configuração pendentes
- ⏳ Scripts de gestão pendentes

### Próximas Ações

1. Criar `.env.gemma-remote` com configuração isolada
2. Criar `scripts/setup.sh` para setup inicial
3. Criar `scripts/start-server.sh` para iniciar servidor
4. Criar `scripts/stop-server.sh` para parar servidor
5. Criar `scripts/status-server.sh` para verificar status
6. Criar `docs/ESTRATEGIA_COMMITS.md` para estratégia de commits
7. Commit e push do progresso

### Notas Técnicas

**Modelo Gemma 4 26B A4B**:
- Ficheiro: `gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf` (14.2 GB)
- Localização: `/home/mike/waphix-ao-os-v0.5/models/`
- Backend: Vulkan (ROCm bloqueado)
- NGL seguro: 14 (~6.8 GB VRAM)
- Context: 4096 tokens
- Arquitetura: SWA (window=1024)

**Backend Vulkan**:
- Localização: `/home/mike/waphix-ao-os-v0.5/runtimes/vulkan/`
- Binário: `llama-server`
- Variáveis de ambiente: `VK_ICD_FILENAMES`, `GGML_VK_DEVICE`

---

## 2026-06-17 23:52 UTC - Criação de Configuração

### Ficheiro .env.gemma-remote

**Decisão**: Criar ficheiro `.env.gemma-remote` em `config/`

**Conteúdo Planejado**:
```bash
# Configuração isolada para Gemma 4 26B Remote Server
# Este ficheiro é usado apenas por este projeto isolado

# Servidor
SERVER_PORT=8090
SERVER_HOST=0.0.0.0

# Modelo
MODEL_PATH=/home/mike/waphix-ao-os-v0.5/models/gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf
MODEL_NAME=gemma-4-26b-a4b-q4kxl

# Backend
BACKEND_PATH=/home/mike/waphix-ao-os-v0.5/runtimes/vulkan
BACKEND_TYPE=vulkan

# Configuração LLM
NGL=14
CTX_SIZE=4096
N_PREDICT=2048

# Variáveis de Ambiente Vulkan
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.json
GGML_VK_DEVICE=0

# Logs
LOG_DIR=/home/mike/CascadeProjects/gemma-4-26b-remote/logs
LOG_OUT=server-out.log
LOG_ERR=server-err.log

# Estado
STATE_DIR=/home/mike/CascadeProjects/gemma-4-26b-remote/state
PID_FILE=server.pid
```

**Justificativa**:
- Todas as configurações centralizadas
- Paths absolutos para evitar ambiguidade
- Comentários explicativos
- Fácil de modificar sem afetar código

---

## 2026-06-17 23:55 UTC - Planeamento de Scripts

### Script: setup.sh

**Objetivo**: Setup inicial do projeto isolado

**Funcionalidades**:
1. Verificar pré-requisitos (uv, modelo, backend)
2. Verificar porta 8090 disponível
3. Criar diretórios de logs e state
4. Verificar permissões de escrita
5. Testar conectividade básica
6. Relatório de status

**Segurança**:
- Read-only em recursos existentes
- Zero escrita em projetos existentes
- Verificações antes de qualquer ação

### Script: start-server.sh

**Objetivo**: Iniciar llama-server isolado

**Funcionalidades**:
1. Carregar configuração do .env.gemma-remote
2. Verificar se servidor já está a correr
3. Iniciar llama-server com configuração correta
4. Guardar PID em state/server.pid
5. Redirecionar logs para logs/
6. Verificar startup bem-sucedido

**Segurança**:
- Verificar porta disponível
- Não sobrescrever PID existente
- Logs isolados
- Variáveis de ambiente corretas

### Script: stop-server.sh

**Objetivo**: Parar llama-server isolado

**Funcionalidades**:
1. Ler PID de state/server.pid
2. Verificar se processo existe
3. Enviar SIGTERM (graceful shutdown)
4. Esperar até 10 segundos
5. Se necessário, enviar SIGKILL
6. Limpar ficheiro PID
7. Relatório de status

**Segurança**:
- Só matar processo nosso (verificar PID)
- Graceful shutdown primeiro
- Cleanup de state

### Script: status-server.sh

**Objetivo**: Verificar status do servidor

**Funcionalidades**:
1. Verificar se PID existe em state/server.pid
2. Verificar se processo está a correr
3. Verificar se porta 8090 está em uso
4. Testar API health endpoint
5. Relatório detalhado de status

**Segurança**:
- Read-only
- Zero impacto no servidor

---

## 2026-06-17 23:58 UTC - Estratégia de Commits

### Padrão de Commits

**Formato**:
```
<tipo>: <descrição curta>

<detalhes>
- Detalhe 1
- Detalhe 2

<impacto>
Impacto em projetos existentes: NENHUM
```

**Tipos**:
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Documentação
- `refactor`: Refatoração
- `test`: Testes
- `chore`: Manutenção

### Pontos de Reversão

**Cada commit deve ser**:
- **Reversível**: `git revert` ou `git reset` deve funcionar
- **Documentado**: DIARIO_BORDO.md atualizado
- **Testado**: Funcionalidade verificada antes de commit
- **Isolado**: Não afeta outros projetos

### Frequência de Commits

- **Após cada funcionalidade**: Commit imediato
- **Após cada teste**: Commit se sucesso
- **Após cada decisão**: Commit com documentação
- **Push imediato**: Após cada commit bem-sucedido

### Histórico de Commits

| Commit | Data | Descrição | Reversível |
|--------|------|-----------|------------|
| (pendente) | 2026-06-17 23:58 | Estrutura inicial e documentação | Sim |

---

## 2026-06-18 00:00 UTC - Resumo de Progresso

### Concluído

- ✅ Estrutura de diretórios isolada criada
- ✅ README.md com arquitetura completa
- ✅ DIARIO_BORDO.md inicializado
- ✅ Decisões arquiteturais documentadas
- ✅ Análise de riscos inicial
- ✅ Planeamento de scripts detalhado
- ✅ Estratégia de commits definida

### Pendente

- ⏳ Criar .env.gemma-remote
- ⏳ Criar scripts/setup.sh
- ⏳ Criar scripts/start-server.sh
- ⏳ Criar scripts/stop-server.sh
- ⏳ Criar scripts/status-server.sh
- ⏳ Criar docs/ESTRATEGIA_COMMITS.md
- ⏳ Commit inicial e push
- ⏳ Configurar pubkey SSH
- ⏳ Testar conectividade
- ⏳ Testar setup completo

### Próximo Commit

**Mensagem**: `feat: estrutura inicial, documentação e planeamento de scripts`

**Conteúdo**:
- Estrutura de diretórios
- README.md completo
- DIARIO_BORDO.md inicial
- Decisões arquiteturais
- Planeamento de scripts
- Estratégia de commits

**Reversibilidade**: Sim - `git reset --hard HEAD~1`

---

## 2026-06-18 00:05 UTC - Implementação de Scripts e Configuração

### Ações Executadas

1. **Criado .env.gemma-remote**
   - Configuração isolada completa
   - Paths absolutos para modelo e backend
   - Variáveis de ambiente Vulkan
   - Configuração de logs e estado
   - Comentários explicativos detalhados

2. **Criado scripts/setup.sh**
   - Verificação de pré-requisitos (UV, modelo, backend)
   - Verificação de porta disponível
   - Criação de diretórios isolados (logs, state)
   - Verificação de isolamento (sem /srv/ai, sem PM2)
   - Teste de conectividade básica
   - Permissões de execução atribuídas

3. **Criado scripts/start-server.sh**
   - Carregamento de configuração
   - Verificação se servidor já está a correr
   - Verificação de recursos (modelo, backend)
   - Início de llama-server com configuração correta
   - Guarda de PID em state/server.pid
   - Redirecionamento de logs para logs/
   - Verificação de startup (timeout 30s)
   - Correção de erro de sintaxe (aspas em --port)

4. **Criado scripts/stop-server.sh**
   - Verificação se servidor está a correr
   - Graceful shutdown (SIGTERM, 10s timeout)
   - Force kill se necessário (SIGKILL)
   - Limpeza de PID file
   - Verificação de porta libertada

5. **Criado scripts/status-server.sh**
   - Verificação de PID e processo
   - Verificação de porta em uso
   - Teste de API endpoints (health, models)
   - Verificação de logs (tamanho, erros)
   - Verificação de recursos (VRAM, RAM)
   - Resumo de status com endpoints

6. **Criado docs/ESTRATEGIA_COMMITS.md**
   - Padrão de commits detalhado
   - Tipos de commits documentados
   - Pontos de reversão explicados
   - Frequência de commits definida
   - Checklist antes de commit
   - Procedimento de emergência
   - Métricas de qualidade

### Decisões Técnicas

1. **Scripts em Bash puro**
   - Sem dependências externas
   - Máxima compatibilidade
   - Fácil debugging

2. **Cores no output**
   - Facilita leitura de logs
   - Verde = sucesso, Vermelho = erro, Amarelo = aviso

3. **Verificações exaustivas**
   - Pré-requisitos antes de qualquer ação
   - Isolamento verificado em cada script
   - Recursos verificados antes de start

4. **Graceful degradation**
   - Scripts funcionam mesmo se parte falhar
   - Mensagens de erro claras
   - Sugestões de correção

### Isolamento Verificado

- ✅ Todos os scripts usam paths isolados
- ✅ Zero escrita em /srv/ai
- ✅ Zero uso de PM2 ou systemd
- ✅ Logs isolados em ./logs/
- ✅ Estado isolado em ./state/
- ✅ Configuração isolada em ./config/
- ✅ READ-ONLY em recursos existentes

### Próximos Passos

1. ⏳ Atualizar DIARIO_BORDO.md com este progresso
2. ⏳ Commit inicial com tudo criado
3. ⏳ Push para remoto
4. ⏳ Configurar pubkey SSH (laptopdev -> waphixai)
5. ⏳ Testar setup.sh no waphixai
6. ⏳ Testar start-server.sh no waphixai
7. ⏳ Testar conectividade do laptopdev
8. ⏳ Configurar Claude Code no laptopdev

### Commit Planejado

**Mensagem**: `feat: scripts de gestão completos e documentação de commits`

**Conteúdo**:
- config/.env.gemma-remote (configuração isolada)
- scripts/setup.sh (setup inicial)
- scripts/start-server.sh (iniciar servidor)
- scripts/stop-server.sh (parar servidor)
- scripts/status-server.sh (verificar status)
- docs/ESTRATEGIA_COMMITS.md (estratégia de commits)
- Permissões de execução em todos os scripts

**Impacto em projetos existentes**: NENHUM
- Todos os recursos são READ-ONLY
- Diretórios isolados em CascadeProjects
- Zero dependência de serviços externos

**Reversibilidade**: Sim - `git reset --hard HEAD~1`

---

## [Futuro] - Entradas serão adicionadas aqui

### Formato de Entrada

```markdown
## YYYY-MM-DD HH:MM UTC - Descrição

### Contexto
[Descrição do contexto]

### Decisões
[Decisões tomadas]

### Ações
[Ações executadas]

### Resultados
[Resultados obtidos]

### Próximos Passos
[Próximos passos planeados]

### Commit
[Detalhes do commit se aplicável]
```

---

**Última Atualização**: 2026-06-18 00:00 UTC  
**Estado**: 🟡 Setup inicial em progresso  
**Versão**: 0.1.0-alpha
