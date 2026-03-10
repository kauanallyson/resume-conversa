#!/bin/bash
set -e

echo "Iniciando configuração otimizada para Oracle Cloud..."

# 1. Atualizar e instalar dependências
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg lsb-release certbot python3-certbot-nginx net-tools

# 2. LIMPEZA TOTAL DO FIREWALL (Correção do Erro de Timeout)
# Isso abre as portas no nível do SO para que o Certbot consiga validar o domínio
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -F
# Garante que as mudanças persistam após o reboot
sudo apt install iptables-persistent -y
sudo netfilter-persistent save

# 3. Adicionar chave GPG oficial do Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 4. Configurar o repositório
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 6. Permissões de Usuário
sudo usermod -aG docker $USER

# 7. Criar Swap (Essencial para não travar n8n + Evolution na Oracle)
if [ ! -f /swapfile ]; then
    echo "Creating 2GB Swap..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

echo "Docker e Certbot instalados!"
echo "PRÓXIMO PASSO OBRIGATÓRIO:"
echo "Vá no painel da Oracle (VCN > Security Lists) e abra as portas 80 e 443 (TCP)."