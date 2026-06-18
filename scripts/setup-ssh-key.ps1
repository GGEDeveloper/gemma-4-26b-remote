# setup-ssh-key.ps1 - Configurar pubkey SSH para laptopdev -> waphixai (Windows PowerShell)
# Este script configura a pubkey SSH de forma isolada

# Configuração
$REMOTE_USER = "mike"
$REMOTE_HOST = "192.168.1.130"
$REMOTE_PORT = "22"

Write-Host "=== Configurar Pubkey SSH - laptopdev -> waphixai ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este script configura a pubkey SSH para:"
Write-Host "  $REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT"
Write-Host ""

# Função para verificar se pubkey já existe
function Check-ExistingKey {
    Write-Host "Verificando se pubkey já existe..." -ForegroundColor Cyan
    
    $rsaKey = "$env:USERPROFILE\.ssh\id_rsa.pub"
    $ed25519Key = "$env:USERPROFILE\.ssh\id_ed25519.pub"
    
    if (Test-Path $rsaKey) {
        Write-Host "✓ Pubkey RSA já existe" -ForegroundColor Green
        $script:PUBKEY_FILE = $rsaKey
        Write-Host "  Ficheiro: $PUBKEY_FILE"
        return $true
    }
    elseif (Test-Path $ed25519Key) {
        Write-Host "✓ Pubkey Ed25519 já existe" -ForegroundColor Green
        $script:PUBKEY_FILE = $ed25519Key
        Write-Host "  Ficheiro: $PUBKEY_FILE"
        return $true
    }
    else {
        Write-Host "⚠ Nenhuma pubkey encontrada" -ForegroundColor Yellow
        return $false
    }
}

# Função para gerar nova pubkey
function Generate-Key {
    Write-Host "Gerando nova pubkey (Ed25519)..." -ForegroundColor Cyan
    
    $sshDir = "$env:USERPROFILE\.ssh"
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }
    
    $keyPath = "$sshDir\id_ed25519"
    
    # Usar ssh-keygen se disponível, senão usar PowerShell
    if (Get-Command ssh-keygen -ErrorAction SilentlyContinue) {
        ssh-keygen -t ed25519 -f $keyPath -N "" -C "laptopdev@waphixai"
    }
    else {
        Write-Host "⚠ ssh-keygen não encontrado. Por favor instale OpenSSH ou Git Bash." -ForegroundColor Yellow
        Write-Host "  No Windows 10/11: Settings > Apps > Optional Features > OpenSSH Client" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✓ Pubkey gerada" -ForegroundColor Green
    $script:PUBKEY_FILE = "$keyPath.pub"
}

# Função para verificar conectividade SSH
function Test-SSHConnectivity {
    Write-Host "Verificando conectividade SSH..." -ForegroundColor Cyan
    
    $result = ssh -o ConnectTimeout=5 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo SSH OK" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ SSH com pubkey já funciona" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "⚠ SSH com pubkey não funciona (ainda precisa de password)" -ForegroundColor Yellow
        return $false
    }
}

# Função para instalar pubkey no remote
function Install-Pubkey {
    Write-Host "Instalando pubkey no remote..." -ForegroundColor Cyan
    
    $pubkey = Get-Content $PUBKEY_FILE
    
    Write-Host "  A instalar pubkey em: $REMOTE_USER@$REMOTE_HOST" -ForegroundColor Yellow
    Write-Host "  Será pedida a password SSH" -ForegroundColor Yellow
    Write-Host ""
    
    # Usar ssh-copy-id se disponível
    if (Get-Command ssh-copy-id -ErrorAction SilentlyContinue) {
        ssh-copy-id -i $PUBKEY_FILE "$REMOTE_USER@$REMOTE_HOST"
    }
    else {
        # Fallback manual
        ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$pubkey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    }
    
    Write-Host "✓ Pubkey instalada" -ForegroundColor Green
}

# Função para testar pubkey
function Test-Pubkey {
    Write-Host "Testando pubkey..." -ForegroundColor Cyan
    
    $result = ssh -o ConnectTimeout=5 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo SSH OK" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ SSH com pubkey funciona" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "✗ SSH com pubkey falhou" -ForegroundColor Red
        return $false
    }
}

# Função para mostrar resumo
function Show-Summary {
    Write-Host ""
    Write-Host "=== Resumo ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Pubkey: $PUBKEY_FILE"
    Write-Host "Remote: $REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT"
    Write-Host ""
    
    if (Test-SSHConnectivity) {
        Write-Host "Status: SSH com pubkey configurado e funcionando" -ForegroundColor Green
    }
    else {
        Write-Host "Status: SSH com pubkey configurado mas não testado" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Teste manual:"
    Write-Host "  ssh $REMOTE_USER@$REMOTE_HOST"
    Write-Host ""
}

# Main
if (-not (Check-ExistingKey)) {
    Generate-Key
}

if (Test-SSHConnectivity) {
    Write-Host "✓ Pubkey já configurada e funcionando" -ForegroundColor Green
    Show-Summary
    exit 0
}

Install-Pubkey

if (Test-Pubkey) {
    Show-Summary
    Write-Host "✓ Configuração SSH concluída com sucesso" -ForegroundColor Green
}
else {
    Write-Host "✗ Configuração SSH falhou" -ForegroundColor Red
    exit 1
}
