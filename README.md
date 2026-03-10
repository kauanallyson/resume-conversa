# resume-conversa

Stack: n8n + Evolution API + PostgreSQL + Redis + Nginx (SSL)

## Pré-requisitos

- VM Ubuntu 22.04 (Oracle Cloud free tier ou superior)
- Portas 80 e 443 liberadas na OCI (VCN > Security Lists)
- Domínio DuckDNS apontando para o IP da VM

## Instalação

```bash
git clone https://github.com/kauanallyson/resume-conversa.git
cd resume-conversa
chmod +x install_docker.sh && sudo ./install_docker.sh
```

O script faz automaticamente:

- Instala Docker, Certbot e dependências
- Abre as portas 80 e 443 no firewall
- Cria swap de 2GB
- Pausa para você editar o `.env`
- Gera o certificado SSL via Certbot
- Configura renovação automática do SSL (cron diário às 3h)
- Sobe os containers com `docker compose up -d --build`

## Após a instalação

Verifique os containers:

```bash
docker compose ps
docker compose logs -f
```

## Deploy automático (CI/CD)

A cada push na branch `main`, o GitHub Actions faz o deploy automaticamente na VM.

Configure os secrets no repositório (Settings > Secrets > Actions):

| Secret | Valor |
|---|---|
| `OCI_HOST` | IP público da VM |
| `OCI_USER` | `ubuntu` |
| `OCI_SSH_KEY` | Conteúdo da chave privada SSH (.pem) |

## Atualizar manualmente

```bash
git pull origin main
docker compose up -d --build
docker image prune -f
```
