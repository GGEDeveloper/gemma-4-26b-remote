#!/bin/bash
# setup-ssh-key.sh - Configurar pubkey SSH para laptopdev -> waphixai
# Este script configura a pubkey SSH de forma isolada

set -e  # Exit on error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuração
REMOTE_USER="mike"
REMOTE_HOST="192.168.1.130"
REMOTE_PORT="22"

echo -e "${BLUE}=== Configurar Pubkey SSH - laptopdev -> waphixai ===${NC}"
echo ""
echo "Este script configura a pubkey SSH para:"
echo "  $REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT"
echo ""

# Função para verificar se pubkey já existe
check_existing_key() {
    echo -e "${BLUE}Verificando se pubkey já existe...${NC}"
    
    if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        echo -e "${GREEN}✓ Pubkey RSA já existe${NC}"
        PUBKEY_FILE="$HOME/.ssh/id_rsa.pub"
    elif [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
        echo -e "${GREEN}✓ Pubkey Ed25519 já existe${NC}"
        PUBKEY_FILE="$HOME/.ssh/id_ed25519.pub"
    else
        echo -e "${YELLOW}⚠ Nenhuma pubkey encontrada${NC}"
        return 1
    fi
    
    echo "  Ficheiro: $PUBKEY_FILE"
    echo ""
}

# Função para gerar nova pubkey
generate_key() {
    echo -e "${BLUE}Gerando nova pubkey (Ed25519)...${NC}"
    
    ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "laptopdev@waphixai"
    
    echo -e "${GREEN}✓ Pubkey gerada${NC}"
    PUBKEY_FILE="$HOME/.ssh/id_ed25519.pub"
    echo ""
}

# Função para verificar conectividade SSH
check_ssh_connectivity() {
    echo -e "${BLUE}Verificando conectividade SSH...${NC}"
    
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" echo "SSH OK" 2>/dev/null; then
        echo -e "${GREEN}✓ SSH com pubkey já funciona${NC}"
        echo ""
        return 0
    else
        echo -e "${YELLOW}⚠ SSH com pubkey não funciona (ainda precisa de password)${NC}"
        echo ""
        return 1
    fi
}

# Função para instalar pubkey no remote
install_pubkey() {
    echo -e "${BLUE}Instalando pubkey no remote...${NC}"
    
    local pubkey=$(cat "$PUBKEY_FILE")
    
    echo -e "${YELLOW}  A instalar pubkey em: $REMOTE_USER@$REMOTE_HOST${NC}"
    echo -e "${YELLOW}  Será pedida a password SSH${NC}"
    echo ""
    
    # Usar ssh-copy-id se disponível
    if command -v ssh-copy-id &> /dev/null; then
        ssh-copy-id -i "$PUBKEY_FILE" "$REMOTE_USER@$REMOTE_HOST"
    else
        # Fallback manual
        ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$pubkey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    fi
    
    echo -e "${GREEN}✓ Pubkey instalada${NC}"
    echo ""
}

# Função para testar pubkey
test_pubkey() {
    echo -e "${BLUE}Testando pubkey...${NC}"
    
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" echo "SSH OK"; then
        echo -e "${GREEN}✓ SSH com pubkey funciona${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ SSH com pubkey falhou${NC}"
        echo ""
        return 1
    fi
}

# Função para mostrar resumo
show_summary() {
    echo -e "${BLUE}=== Resumo ===${NC}"
    echo ""
    echo "Pubkey: $PUBKEY_FILE"
    echo "Remote: $REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT"
    echo ""
    
    if check_ssh_connectivity > /dev/null 2>&1; then
        echo -e "${GREEN}Status: SSH com pubkey configurado e funcionando${NC}"
    else
        echo -e "${YELLOW}Status: SSH com pubkey configurado mas não testado${NC}"
    fi
    
    echo ""
    echo "Teste manual:"
    echo "  ssh $REMOTE_USER@$REMOTE_HOST"
    echo ""
}

# Main
main() {
    # Verificar se pubkey já existe
    if ! check_existing_key; then
        generate_key
    fi
    
    # Verificar se já funciona
    if check_ssh_connectivity; then
        echo -e "${GREEN}✓ Pubkey já configurada e funcionando${NC}"
        show_summary
        exit 0
    fi
    
    # Instalar pubkey
    install_pubkey
    
    # Testar pubkey
    if test_pubkey; then
        show_summary
        echo -e "${GREEN}✓ Configuração SSH concluída com sucesso${NC}"
    else
        echo -e "${RED}✗ Configuração SSH falhou${NC}"
        exit 1
    fi
}

# Executar main
main
