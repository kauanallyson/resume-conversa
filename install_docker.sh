#!/bin/bash
set -e

echo "Iniciando configuracao para Oracle Cloud..."

# 1. Atualizar e instalar dependencias
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg lsb-release certbot net-tools iptables-persistent git

# 2. Abrir firewall (portas 80 e 443 no SO)
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -F
sudo netfilter-persistent save

# 3. Instalar Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

# 4. Criar Swap de 2GB (essencial para n8n + Evolution na OCI free tier)
if [ ! -f /swapfile ]; then
    echo "Criando Swap de 2GB..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# 5. Clonar o repositorio
REPO_DIR="/home/$USER/resume-conversa"
if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/kauanallyson/resume-conversa.git "$REPO_DIR"
fi
cd "$REPO_DIR"

# 6. Configurar o .env
if [ ! -f .env ]; then
    cp .env.example .env
    echo "ATENCAO: edite o .env antes de continuar."
    echo "Comando: nano $REPO_DIR/.env"
    echo "Quando terminar, pressione ENTER para continuar..."
    read -r
fi

# 7. Gerar certificado SSL (Nginx deve estar parado neste momento)
if [ -z "$DOMAIN" ]; then
    read -rp "Digite seu dominio DuckDNS (ex: fdmeneses.duckdns.org): " DOMAIN
fi
if [ -z "$CERTBOT_EMAIL" ]; then
    read -rp "Digite seu e-mail para o Certbot: " CERTBOT_EMAIL
fi
sudo certbot certonly --standalone -d "$DOMAIN" --email "$CERTBOT_EMAIL" --agree-tos --non-interactive
echo "Certificado gerado em /etc/letsencrypt/live/$DOMAIN/"

# 8. Configurar renovacao automatica do SSL via cron
(sudo crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && docker exec nginx nginx -s reload") | sudo crontab -
echo "Renovacao automatica do SSL configurada (cron diario as 3h)."

# 9. Subir os containers
newgrp docker <<EOF
docker compose up -d --build
EOF

echo ""
echo "Instalacao concluida!"
echo ""
echo "Verifique os containers: docker compose ps"
echo "Acompanhe os logs: docker compose logs -f"