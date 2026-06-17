# Estratégia de Commits - Gemma 4 26B Remote

**Documento que define a estratégia de commits e pontos de reversão para o projeto isolado**

---

## 📋 Objetivo

Garantir que cada commit seja:
- **Reversível**: `git revert` ou `git reset` deve funcionar
- **Documentado**: DIARIO_BORDO.md atualizado com decisões
- **Testado**: Funcionalidade verificada antes de commit
- **Isolado**: Não afeta outros projetos (waphix-ai-os, waphix-ao-os-v0.5)

---

## 🔖 Padrão de Commits

### Formato

```
<tipo>: <descrição curta>

<detalhes>
- Detalhe 1
- Detalhe 2

<impacto>
Impacto em projetos existentes: NENHUM

<referência>
DIARIO_BORDO.md: YYYY-MM-DD HH:MM UTC
```

### Tipos de Commits

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| `feat` | Nova funcionalidade | `feat: criar script de setup isolado` |
| `fix` | Correção de bug | `fix: corrigir erro de sintaxe em start-server.sh` |
| `docs` | Documentação | `docs: adicionar estratégia de commits` |
| `refactor` | Refatoração | `refactor: melhorar verificação de isolamento` |
| `test` | Testes | `test: adicionar teste de conectividade` |
| `chore` | Manutenção | `chore: atualizar DIARIO_BORDO.md` |

---

## 🔄 Pontos de Reversão

### Regras de Ouro

1. **Cada commit deve ser reversível**
   - `git revert <commit>` deve funcionar
   - `git reset --hard HEAD~1` deve funcionar
   - `git checkout <commit>` deve funcionar

2. **Cada commit deve ser documentado**
   - DIARIO_BORDO.md atualizado
   - Decisões explicadas
   - Impacto em projetos existentes documentado

3. **Cada commit deve ser testado**
   - Funcionalidade verificada antes de commit
   - Scripts testados manualmente
   - Isolamento verificado

4. **Cada commit deve ser isolado**
   - Não afeta waphix-ai-os
   - Não afeta waphix-ao-os-v0.5
   - Não escreve em /srv/ai
   - Não usa PM2 ou systemd

### Exemplo de Commit Reversível

```
feat: criar script de setup isolado

Detalhes:
- Criado scripts/setup.sh com verificações de pré-requisitos
- Verificação de porta disponível
- Criação de diretórios isolados (logs, state)
- Verificação de isolamento (sem /srv/ai, sem PM2)
- Teste de conectividade básica

Impacto em projetos existentes: NENHUM
- Todos os recursos são READ-ONLY
- Diretórios isolados em CascadeProjects
- Zero dependência de serviços externos

DIARIO_BORDO.md: 2026-06-17 23:55 UTC
```

### Como Reverter

```bash
# Reverter último commit (mantendo histórico)
git revert HEAD

# Resetar último commit (perde histórico)
git reset --hard HEAD~1

# Ver commit específico
git checkout <commit-hash>

# Ver diff antes de reverter
git diff HEAD~1 HEAD
```

---

## 📅 Frequência de Commits

### Quando Fazer Commit

- **Após cada funcionalidade**: Commit imediato
- **Após cada teste**: Commit se sucesso
- **Após cada decisão**: Commit com documentação
- **Após cada correção**: Commit com fix
- **Antes de testar arriscado**: Commit como checkpoint

### Quando Fazer Push

- **Após cada commit bem-sucedido**: Push imediato
- **Antes de modificar código existente**: Push como backup
- **Ao fim de sessão de trabalho**: Push final
- **Antes de testar em produção**: Push como safety net

### Exemplo de Fluxo

```bash
# 1. Criar funcionalidade
vim scripts/novo-script.sh

# 2. Testar manualmente
bash scripts/novo-script.sh

# 3. Atualizar DIARIO_BORDO.md
vim DIARIO_BORDO.md

# 4. Commit
git add .
git commit -m "feat: adicionar novo script isolado"

# 5. Push imediato
git push origin main
```

---

## 📝 Histórico de Commits

| Commit | Data | Tipo | Descrição | Reversível |
|--------|------|------|-----------|------------|
| (pendente) | 2026-06-18 00:05 | feat | Scripts de gestão completos | Sim |
| (pendente) | 2026-06-18 00:02 | feat | Configuração isolada (.env) | Sim |
| (pendente) | 2026-06-17 23:58 | docs | Estratégia de commits | Sim |
| (pendente) | 2026-06-17 23:50 | feat | Estrutura inicial e documentação | Sim |

---

## 🎯 Checklist Antes de Commit

### Verificação de Isolamento

- [ ] Não escreve em /srv/ai
- [ ] Não usa PM2 ou systemd
- [ ] Não afeta waphix-ai-os
- [ ] Não afeta waphix-ao-os-v0.5
- [ ] Logs isolados em ./logs/
- [ ] Estado isolado em ./state/
- [ ] Configuração isolada em ./config/

### Verificação de Funcionalidade

- [ ] Scripts testados manualmente
- [ ] Funcionalidade verificada
- [ ] Erros tratados
- [ ] Logs verificáveis
- [ ] Startup/stop funciona

### Verificação de Documentação

- [ ] DIARIO_BORDO.md atualizado
- [ ] Decisões documentadas
- [ ] Impacto em projetos existentes documentado
- [ ] README.md atualizado se necessário

### Verificação de Git

- [ ] `git status` limpo (sem untracked files estranhos)
- [ ] `git diff` mostra apenas mudanças esperadas
- [ ] Commit message segue padrão
- [ ] Referência ao DIARIO_BORDO.md incluída

---

## 🚨 Procedimento de Emergência

### Se Algo Correr Mal

1. **Parar tudo imediatamente**
   ```bash
   # Parar servidor se estiver a correr
   bash scripts/stop-server.sh
   ```

2. **Verificar isolamento**
   ```bash
   # Verificar que não afetamos outros projetos
   pm2 list  # Deve mostrar só processos de outros projetos
   ss -tulpn | grep 8090  # Deve estar livre ou só nosso processo
   ```

3. **Reverter último commit**
   ```bash
   git reset --hard HEAD~1
   ```

4. **Documentar o problema**
   ```bash
   # Atualizar DIARIO_BORDO.md com o problema
   vim DIARIO_BORDO.md
   ```

5. **Commit da reversão**
   ```bash
   git add DIARIO_BORDO.md
   git commit -m "fix: reverter commit anterior devido a [problema]"
   git push origin main
   ```

### Se Precisar de Rollback Completo

```bash
# Resetar para commit específico
git reset --hard <commit-hash>

# Ou criar branch de backup
git branch backup-$(date +%Y%m%d-%H%M%S)
git reset --hard <commit-hash>
```

---

## 📊 Métricas de Qualidade

### KPIs de Commits

| Métrica | Alvo | Como Medir |
|---------|------|------------|
| Commits reversíveis | 100% | Testar `git revert HEAD` |
| Commits documentados | 100% | Verificar DIARIO_BORDO.md |
| Commits testados | 100% | Verificar funcionalidade |
| Commits isolados | 100% | Verificar isolamento |

### Relatório Semanal

```bash
# Gerar relatório de commits da última semana
git log --since="1 week ago" --pretty=format:"%h - %s" > weekly-commits.txt

# Verificar reversibilidade
git log --since="1 week ago" --pretty=format:"%h" | while read commit; do
    echo "Testing revert of $commit"
    git revert --no-commit $commit 2>&1 | head -5
    git revert --abort
done
```

---

## 🔄 Integração Contínua (Futuro)

### Possível CI/CD Pipeline

```yaml
# .github/workflows/ci.yml (futuro)
name: CI
on: [push]
jobs:
  test-isolation:
    - Verificar que não escreve em /srv/ai
    - Verificar que não usa PM2
    - Verificar que scripts funcionam
  test-documentation:
    - Verificar DIARIO_BORDO.md atualizado
    - Verificar commit message padrão
  test-reversibility:
    - Tentar reverter commit
    - Verificar que funciona
```

---

## 📚 Referências

- Git Documentation: https://git-scm.com/doc
- Conventional Commits: https://www.conventionalcommits.org/
- DIARIO_BORDO.md: Diário de bordo do projeto
- README.md: Documentação principal

---

**Última Atualização**: 2026-06-18 00:05 UTC  
**Versão**: 1.0.0  
**Estado**: 🟡 Ativo
