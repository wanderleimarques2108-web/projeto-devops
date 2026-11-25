# Infra — Ansible

Provisiona a VPS do zero e publica a aplicação com o `docker-compose.yml` da raiz do repositório.

| Role | O que faz |
|---|---|
| `common` | apt update, pacotes básicos (curl, ufw, unattended-upgrades), fuso `America/Sao_Paulo` |
| `docker` | instala Docker Engine + Compose pelo repositório oficial, liga no boot e põe o usuário no grupo `docker` |
| `firewall` | UFW: nega entrada por padrão e libera só 22 (SSH) e 80 (HTTP do Cloudflare) |
| `app` | copia o `docker-compose.yml` para `~/projeto-devops`, faz `pull` + `up -d`, limpa imagens antigas e testa `http://127.0.0.1/` |

## Pré-requisitos (na sua máquina)

```bash
pipx install ansible-core     # ou: sudo apt install ansible
cd ansible
ansible-galaxy collection install -r requirements.yml
```

## Configurar o inventário

O IP e o usuário da VPS **não vão para o Git**: `inventory.ini` está no `.gitignore`.

```bash
cp inventory.example.ini inventory.ini
# edite: ansible_host, ansible_user, ansible_ssh_private_key_file
ansible vps -m ping
```

Variáveis ajustáveis em `group_vars/all.yml` (`app_dir`, `docker_install`, `firewall_allowed_ports`).

## Executar

```bash
ansible-playbook playbook.yml --check --diff   # simulação, não altera nada
ansible-playbook playbook.yml                  # provisiona tudo
ansible-playbook playbook.yml --tags app       # só o deploy da aplicação
ansible-playbook playbook.yml --tags firewall  # só o firewall
```

Se o usuário não tiver sudo sem senha, acrescente `-K`.

## Observações

- O playbook é idempotente: pode rodar várias vezes; só muda o que estiver diferente.
- A role `docker` remove pacotes não oficiais (`docker.io`, `containerd`, ...) antes de instalar os oficiais. Se a VPS já tem o Docker funcionando e você não quer mexer nele, use `-e docker_install=false`.
- A regra do SSH é criada antes de ativar o UFW, para não perder o acesso.
- O Docker publica portas por fora do UFW; por isso o Uptime Kuma fica só em `127.0.0.1:3001` no compose.
- A VPS não faz build: a imagem vem pronta do GHCR, publicada pela pipeline.
