# Projeto Integrador — Cloud Computing e DevOps

Aplicação web publicada em nuvem com Docker, DNS e HTTPS pelo Cloudflare, CI/CD com GitHub Actions e monitoramento com Uptime Kuma. Na **N2**, a preparação do servidor e a implantação foram automatizadas com **Ansible** (seção 15). Feita para o Projeto Integrador da disciplina de **Cloud Computing e DevOps**.

- **URL da aplicação:** https://www.pvhdevops.tech
- **Repositório:** https://github.com/wanderleimarques2108-web/projeto-devops
- **Professor:** Claudio Castelo

## Integrantes

- WANDERLEI MARQUES FILHO
- MAGGIO HENRIQUE VALENTE LOBO
- KAIKY DE BRITO CINTA LARGA
- CAUAN FURTADO SILVA
- CHRISTYANNS JUAN LIMA DE OLIVEIRA
- PEDRO HENRIQUE ALBURQUERQUE LOPES
- PEDRO HENRIQUE TEXEIRA SOUZA DE SÁ
- HERTON NASCIMENTO CAVALCANTE
- ADAM LUCAS SMITH DE CARVALHO
- CARLOS EDUARDO CORREIA DE FREITAS

## 1. Descrição da aplicação

Página web estática (HTML + CSS) com a disciplina, os integrantes do grupo, uma descrição do projeto e o professor. O foco do trabalho é o caminho do código até a produção: versionamento, containerização, nuvem, DNS, HTTPS, pipeline CI/CD, monitoramento e segurança.

## 2. Arquitetura do ambiente

```
 Usuário
   │  https://www.pvhdevops.tech
   ▼
 Cloudflare  (DNS + proxy + certificado HTTPS)
   │  HTTP, porta 80
   ▼
 ┌──────────── VPS (Hostinger) ────────────────────────────────┐
 │   Docker Compose                                            │
 │   ┌───────────────┐        ┌───────────────┐                │
 │   │ site (Nginx)  │        │ kuma          │                │
 │   │ porta 80      │        │ 127.0.0.1:3001│ (monitoramento)│
 │   └───────────────┘        └───────────────┘                │
 └─────────────────────────────────────────────────────────────┘

 Git push ─► GitHub Actions ─► build ─► teste ─► imagem no GHCR ─► deploy via SSH
```

Cadeia principal: **Domínio → DNS (Cloudflare) → IP/Servidor (VPS) → Container Nginx → Aplicação**.

Cadeia Docker: **Código → Dockerfile → Imagem → Container → Aplicação**.

### Ambiente Cloud

| Item | Valor |
|---|---|
| Provedor | Hostinger (VPS KVM 1, Campinas/BR) |
| Sistema operacional | Ubuntu 24.04.5 LTS |
| Recursos | 1 vCPU, 3,8 GB de RAM, 48 GB de disco |
| IP público | Omitido por segurança: enviado ao professor por e-mail |
| Domínio | www.pvhdevops.tech |
| DNS | Cloudflare |
| Acesso ao ambiente | SSH (`ssh <usuario>@<IP>`). IP e credenciais de acesso foram enviados ao professor por e-mail, não ficam no repositório |

### Portas

| Porta | Uso | Exposta ao público |
|---|---|---|
| 22 | SSH | Sim |
| 80 | Nginx do container `site` (recebe o tráfego do Cloudflare) | Sim |
| 3001 | Uptime Kuma | Não: só em `127.0.0.1`, acesso por túnel SSH |

## 3. Tecnologias utilizadas

- HTML5 e CSS3
- Nginx (imagem `nginx:alpine`)
- Docker e Docker Compose
- Cloudflare (DNS, proxy e HTTPS)
- Uptime Kuma (monitoramento)
- GitHub e GitHub Actions (CI/CD)
- GitHub Container Registry (GHCR)
- Ansible (automação do servidor e da implantação, N2)

## 4. Estrutura do projeto

```
projeto-devops/
├── .github/workflows/docker.yml   # pipeline CI/CD
├── .github/workflows/ansible.yml  # valida a sintaxe do Ansible (N2)
├── ansible/                       # automação com Ansible (N2) - ver seção 15
├── docs/evidencias/               # prints das evidências
├── site/                          # aplicação (HTML, CSS, favicon)
│   ├── index.html
│   ├── styles.css
│   └── favicon.png
├── Dockerfile                     # imagem do site (Nginx)
├── docker-compose.yml             # site + Uptime Kuma
└── README.md
```

## 5. Processo de instalação (rodar localmente)

Requisitos: Git e Docker com Docker Compose.

```bash
git clone https://github.com/wanderleimarques2108-web/projeto-devops.git
cd projeto-devops
docker compose up -d --build
```

Acesse http://localhost (site) e http://localhost:3001 (Uptime Kuma). Para parar: `docker compose down`.

## 6. Configuração do Docker

**Dockerfile**

```dockerfile
FROM nginx:alpine
COPY site/ /usr/share/nginx/html
```

A imagem parte do Nginx leve (Alpine) e copia os arquivos do site para a pasta pública.

**docker-compose.yml** define dois serviços:

| Serviço | Imagem | Função |
|---|---|---|
| `site` | `ghcr.io/wanderleimarques2108-web/projeto-devops:latest` | serve a página na porta 80 |
| `kuma` | `louislam/uptime-kuma:1` | monitoramento; dados no volume `kuma_data`; porta 3001 só em `127.0.0.1` |

Os dois têm `restart: unless-stopped` e voltam sozinhos se a VPS reiniciar. O volume `kuma_data` preserva o histórico do monitor quando o container é recriado.

## 7. Configuração do DNS

O domínio `pvhdevops.tech` usa o DNS do Cloudflare, com o proxy ligado (nuvem laranja):

| Tipo | Nome | Conteúdo | Proxy |
|---|---|---|---|
| A | `pvhdevops.tech` | IP da VPS (informado ao professor) | Ativo |
| CNAME | `www.pvhdevops.tech` | `pvhdevops.tech` | Ativo |

Por isso o DNS público mostra IPs do Cloudflare e não o IP da VPS.

```bash
nslookup www.pvhdevops.tech
```

Fluxo: o navegador pergunta ao DNS pelo domínio, recebe um IP do Cloudflare, conecta nele, e o Cloudflare encaminha o pedido para a VPS.

## 8. Configuração do HTTPS

O certificado SSL/TLS é fornecido e renovado automaticamente pelo **Cloudflare**. O modo configurado em *SSL/TLS → Overview* é **Flexible**:

- Navegador → Cloudflare: **HTTPS** (certificado válido, cadeado no navegador).
- Cloudflare → VPS: **HTTP**, porta 80.

O **Always Use HTTPS** está ativo: qualquer acesso por `http://` recebe um redirecionamento 301 para `https://`.

Limitação conhecida: no modo Flexible o trecho entre o Cloudflare e a VPS não é criptografado. Como melhoria futura, o modo **Full (strict)** com um *Origin Certificate* do Cloudflare instalado no Nginx criptografa também esse trecho.

Teste: `curl -I http://www.pvhdevops.tech` retorna `301` com `Location: https://www.pvhdevops.tech/`, e `curl -I https://www.pvhdevops.tech` retorna `200` com `server: cloudflare`.

## 9. Processo de CI/CD

Arquivo: `.github/workflows/docker.yml`.

```
Git push na main ─► Checkout ─► Build da imagem ─► Teste (curl) ─► Login no GHCR
                 ─► Push da imagem (latest e vN) ─► Envia o compose à VPS ─► docker compose up -d
```

- **Pull Request:** executa só build e teste, sem publicar e sem deploy.
- **Push na `main`:** executa tudo, inclusive o deploy.
- **Teste:** sobe o container e verifica com `curl` que `/` e os arquivos `.html` e `.css` respondem.
- **Deploy:** copia o `docker-compose.yml` para `~/projeto-devops` na VPS e roda `docker compose pull` e `docker compose up -d`.
- **Segredos** (em *Settings → Secrets and variables → Actions*, nunca no código): `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`. O `GITHUB_TOKEN` é fornecido pelo GitHub.

Fluxo de trabalho: branch `feature/...` → Pull Request → merge na `main` → a pipeline publica sozinha.

## 10. Monitoramento

Ferramenta: **Uptime Kuma**, executada como container no mesmo `docker-compose.yml` da aplicação. O painel **não é público**: o container escuta só em `127.0.0.1:3001` e o acesso é feito por túnel SSH, com usuário e senha próprios.

```bash
ssh -L 3001:127.0.0.1:3001 <usuario>@<IP-DA-VPS>
# depois, no navegador: http://localhost:3001
```

### Monitores configurados

| Monitor | Tipo | Alvo | Intervalo | Responde a |
|---|---|---|---|---|
| site - Aplicação | HTTP(s) | `https://www.pvhdevops.tech` | 60 s | A aplicação está online? (passa pelo Cloudflare e acompanha a validade do certificado HTTPS) |
| Container - site (Nginx) | HTTP(s) | `http://site:80` | 60 s | O container está funcionando? (acesso pela rede interna do Docker, sem passar pelo Cloudflare) |
| Servidor - VPS (SSH) | TCP Port | IP da VPS (informado ao professor), porta 22 | 60 s | O servidor está funcionando? |

### Como identificar uma indisponibilidade

O painel mostra o monitor em vermelho (**Desligado**), com horário, mensagem de erro e histórico de disponibilidade. A combinação dos monitores indica onde está a falha:

- Só **site - Aplicação** em vermelho: problema no Cloudflare, no DNS ou no certificado.
- **site - Aplicação** e **Container - site (Nginx)** em vermelho, com **Servidor - VPS (SSH)** verde: o container do Nginx parou, mas a VPS está de pé.
- Os três em vermelho: a VPS está fora do ar ou inacessível.

### Teste de indisponibilidade realizado

O container do site foi parado com `docker stop site`. O Kuma registrou:

- **Container - site (Nginx):** Desligado, mensagem `getaddrinfo EAI_AGAIN site` (o container deixou de existir na rede do Docker).
- **site - Aplicação:** Desligado, mensagem `Request failed with status code 522` (erro do Cloudflare quando a origem não responde).
- **Servidor - VPS (SSH):** continuou Ligado (100%), pois só o container caiu.

Após `docker start site`, o monitor **site - Aplicação** voltou para Ligado (`200 - OK`) em cerca de 1 minuto.

Evidências: `monitor-site.png`, `monitor-container.png`, `monitor-servidor.png`, `monitor-queda-site.png`, `monitor-queda-container.png` e `monitor-recuperacao-site.png`, em `docs/evidencias/`.

## 11. Segurança

- Nenhuma senha ou chave no Git: a pipeline usa *GitHub Secrets* e o acesso à VPS é por chave SSH própria do deploy.
- O Uptime Kuma não é exposto à internet: escuta só em `127.0.0.1` e é protegido por usuário e senha.
- HTTPS entre usuário e Cloudflare, com certificado válido e renovação automática, e redirecionamento de HTTP para HTTPS.
- O IP da VPS e as credenciais de acesso não ficam no repositório: foram enviados ao professor por e-mail.
- Firewall (UFW) da VPS liberando somente as portas 22 e 80.

## 12. Processo de deploy

**Automático (padrão):** merge na `main` → a pipeline faz o resto.

**Manual (emergência), na VPS:**

```bash
cd ~/projeto-devops
docker compose pull
docker compose up -d
docker image prune -f
```

## 13. Procedimentos básicos de recuperação

| Problema | O que fazer |
|---|---|
| Site fora do ar | `ssh` na VPS, `cd ~/projeto-devops`, `docker compose ps` e `docker compose logs --tail 50`; depois `docker compose up -d` |
| Container parado | Têm `restart: unless-stopped` e sobem sozinhos; se não, `docker compose up -d` |
| Deploy ruim | Reverter o commit na `main` (`git revert`) e a pipeline publica a versão anterior; ou usar uma tag antiga da imagem (`:v<N>`) |
| VPS reiniciou | O Docker inicia no boot e os containers voltam sozinhos |
| Erro 52x do Cloudflare | A VPS não respondeu: conferir `docker compose ps`, o firewall (porta 80) e se a VPS está ligada |
| VPS perdida | Criar nova VPS, rodar o Ansible (seção 15: instala Docker, firewall e sobe as stacks) e atualizar o IP no Cloudflare |
| Dados do monitor | Volume `kuma_data`; backup: `docker run --rm -v projeto-devops_kuma_data:/d -v $PWD:/b alpine tar czf /b/kuma.tgz -C /d .` |

## 14. Evidências

Os prints estão em `docs/evidencias/`:

| Evidência | Arquivo |
|---|---|
| Painel do provedor (IP e nome do servidor ocultados) | `cloud-painel.png` |
| Acesso SSH, sistema operacional e recursos da VPS (IPs ocultados) | `cloud-ssh.png` |
| Containers em execução (`docker compose ps`) | `docker-ps.png` |
| Firewall UFW ativo (portas 22 e 80) | `seguranca-ufw.png` |
| Pipeline CI/CD (execução verde) | `pipeline-verde.png` |
| Site com HTTPS (cadeado) | `https-navegador.png` |
| Redirecionamento HTTP → HTTPS | `https-redirect.png` |
| Always Use HTTPS ativo no Cloudflare | `dns-https-always-https.png` |
| Monitor da aplicação (online) | `monitor-site.png` |
| Monitor do container (online) | `monitor-container.png` |
| Monitor do servidor (IP ocultado) | `monitor-servidor.png` |
| Teste de queda: aplicação fora do ar (erro 522) | `monitor-queda-site.png` |
| Teste de queda: container fora do ar | `monitor-queda-container.png` |
| Recuperação: aplicação voltou a responder | `monitor-recuperacao-site.png` |


> Os prints complementam o ambiente, que está no ar e pode ser validado pelo professor.

## 15. Automação com Ansible (N2)

Na N2, o ambiente da N1 passa a ser **reproduzível por código**: a partir de um servidor Linux novo, o Ansible instala o Docker, configura o firewall e sobe as stacks do `docker-compose.yml`, sem nenhum comando manual no servidor. Não foi usado Terraform: o servidor já existe (VPS da N1 ou um servidor fornecido pelo professor).

```
Servidor Linux novo ─► Ansible ─► Docker + Compose ─► Firewall ─► docker compose up ─► Aplicação em http://<IP>
```

### 15.1 Estrutura

```
ansible/
├── ansible.cfg               # configurações (inventário padrão, sem host key checking)
├── inventory.example.ini     # modelo do inventário (copiar para inventory.ini)
├── requirements.yml          # coleções: community.docker, community.general, ansible.posix
├── playbook.yml              # playbook principal (2 plays)
├── group_vars/all.yml        # variáveis do projeto (pasta, portas, pacotes, pull)
└── roles/
    ├── bootstrap/            # espera o SSH, garante Python 3.8+ e testa a conexão
    ├── docker/               # repositório oficial + docker-ce + plugin do compose
    ├── firewall/             # UFW (Ubuntu) ou firewalld (Oracle Linux): libera SSH e 80
    └── deploy/               # copia compose/Dockerfile/site e roda o docker compose up
```

| Role | O que faz | Módulos principais |
|---|---|---|
| `bootstrap` | Aguarda a porta 22, detecta (ou instala) um Python compatível, faz o "ping" do Ansible e espera o `cloud-init` | `wait_for`, `raw`, `ping` |
| `docker` | Remove pacotes conflitantes, adiciona o repositório oficial, instala Docker CE + Buildx + Compose, habilita o serviço e põe o usuário no grupo `docker` | `apt`/`dnf`, `apt_repository`, `get_url`, `systemd`, `user` |
| `firewall` | Libera a porta SSH e a 80, bloqueia o resto da entrada | `community.general.ufw`, `ansible.posix.firewalld` |
| `deploy` | Cria `~/projeto-devops`, copia os arquivos, sobe `site` e `kuma`, testa HTTP 200 e mostra o `docker compose ps` | `copy`, `community.docker.docker_compose_v2`, `uri` |

Distribuições suportadas (detectadas automaticamente pelos *facts* do Ansible): **Ubuntu/Debian** (VPS Hostinger da N1, Ubuntu 24.04) e **Oracle Linux/RHEL 8+** (VM da OCI, usuário `opc`).

Decisões importantes:

- **Mesmo `docker-compose.yml` da N1.** O Ansible não duplica a definição das stacks: ele copia o arquivo do repositório. A pasta (`~/projeto-devops`) e o nome do projeto são os mesmos usados pelo deploy do GitHub Actions, então Ansible e pipeline gerenciam os mesmos containers.
- **Imagem do GHCR com plano B.** O `up` usa `pull: missing`: baixa `ghcr.io/wanderleimarques2108-web/projeto-devops:latest` se ela não existir no servidor. Se o pull falhar, o Compose faz o build local com o `Dockerfile` e o `site/` copiados (o compose tem `build: .`).
- **Sem SDK Python do Docker.** O módulo `docker_compose_v2` usa o Docker CLI direto. Isso evita o `pip install docker`, que no Ubuntu 24.04 é bloqueado (PEP 668).
- **Idempotência.** Todas as tarefas só alteram o que está fora do estado desejado. Na segunda execução o resumo mostra `changed=0`.
- **Segurança.** O `inventory.ini` (IP, usuário, chave) está no `.gitignore`. O Uptime Kuma continua só em `127.0.0.1:3001`. O firewall libera somente SSH e HTTP.

### 15.2 Pré-requisitos (control node = máquina de quem executa)

O Ansible roda em Linux/macOS. **No Windows, use o WSL** (Ubuntu):

```powershell
# PowerShell como administrador (uma vez só; reinicie o PC depois)
wsl --install -d Ubuntu
```

Dentro do Linux/WSL:

```bash
sudo apt update && sudo apt install -y ansible git
ansible --version        # ansible-core 2.15 ou mais novo
```

Se o `apt` instalar um ansible-core mais antigo que 2.15 (ex.: Ubuntu 22.04), instale pelo pipx: `sudo apt install -y pipx && pipx install --include-deps ansible`.

> **Dica WSL:** clone o repositório **dentro** do Linux (`cd ~`) e não em `/mnt/c/...`. Em `/mnt/c` o Ansible ignora o `ansible.cfg` (pasta "world writable") e o `chmod 400` da chave não funciona.

No servidor de destino só é preciso: acesso SSH com um usuário que tenha `sudo` (ou `root`) e acesso à internet. Docker, Python moderno e firewall são resolvidos pelo playbook.

### 15.3 Execução passo a passo

```bash
# 1) Clonar o repositório e entrar na pasta do Ansible
git clone https://github.com/wanderleimarques2108-web/projeto-devops.git
cd projeto-devops/ansible

# 2) Instalar as coleções usadas no playbook
ansible-galaxy collection install -r requirements.yml

# 3) Criar o inventário com os dados do servidor
cp inventory.example.ini inventory.ini
nano inventory.ini       # trocar <IP_DO_SERVIDOR>, <USUARIO> e <SUA_CHAVE>

# 4) Chave SSH com a permissão correta
cp /caminho/da/chave ~/.ssh/minha-chave && chmod 400 ~/.ssh/minha-chave

# 5) Testar a conexão (SSH + Python). Esperado: "ping": "pong"
ansible web -m ping

# 6) Executar a automação
ansible-playbook playbook.yml

# 7) Rodar de novo para provar a idempotência (esperado: changed=0)
ansible-playbook playbook.yml
```

Se o usuário do servidor pedir senha no `sudo`, acrescente `--ask-become-pass` (`-K`) nos comandos. No Oracle Linux 8 o `ansible web -m ping` do passo 5 pode falhar (só há Python 3.6); o próprio playbook instala o Python 3.11, então pule direto para o passo 6.

Comandos úteis:

| Comando | Para quê |
|---|---|
| `ansible-playbook playbook.yml --syntax-check` | Confere a sintaxe (também roda no GitHub Actions, workflow **Ansible**) |
| `ansible-playbook playbook.yml --check --diff` | Ensaio: mostra o que mudaria. Use em um servidor já configurado; num servidor zerado o ensaio para no Docker, que ainda não existe |
| `ansible-playbook playbook.yml -e app_pull_policy=always` | Força baixar a versão mais nova da imagem no GHCR |
| `ansible-playbook playbook.yml -v` | Saída detalhada para depuração (`-vv`, `-vvv` mostram ainda mais) |

### 15.4 Acesso HTTP à aplicação

Ao final, o playbook testa a aplicação de dentro do servidor (`http://127.0.0.1`) e da máquina de quem executou (`http://<IP>`), e imprime:

```
Acesse no navegador: http://<IP_DO_SERVIDOR>
```

- **Servidor novo (professor):** `http://<IP_DO_SERVIDOR>` mostra a página do projeto.
- **Ambiente de produção do grupo:** `https://www.pvhdevops.tech` (o Cloudflare aponta para a VPS, ver seções 7 e 8).
- **Uptime Kuma:** não é público. Acesso por túnel SSH (seção 10) e, num servidor novo, crie o usuário admin e os monitores na primeira entrada.

### 15.5 Problemas comuns

| Sintoma | Causa / solução |
|---|---|
| `UNREACHABLE` / `Permission denied (publickey)` | Usuário ou chave errados no `inventory.ini`; chave sem `chmod 400`; no Oracle Linux o usuário é `opc` |
| `System is booting up ... pam_nologin` | O servidor acabou de ser criado. Espere 1 minuto e rode de novo |
| `couldn't resolve module/action 'community.docker...'` | Faltou o passo 2: `ansible-galaxy collection install -r requirements.yml` |
| `Missing sudo password` | Rode com `-K` (`--ask-become-pass`) |
| Teste interno OK, mas o externo falha / navegador não abre | É o firewall **da nuvem** (Security List da OCI ou firewall do painel da Hostinger): libere a porta 80 de entrada |
| Ubuntu na OCI sem acesso mesmo com UFW liberado | A imagem Ubuntu da OCI traz regras próprias de `iptables` que bloqueiam tudo menos a 22. Libere a porta 80 também nessas regras ou use a imagem Oracle Linux |
| Erro ao baixar a imagem do GHCR | Se o pacote estiver privado, o Compose faz o build local. Para usar a imagem, torne o pacote público no GitHub (*Packages → Package settings*) |

### 15.6 Evidências da N2

Os prints ficam em `docs/evidencias/`:

| Evidência | Arquivo |
|---|---|
| Versão do Ansible no control node (`ansible --version`) | `ansible-versao.png` |
| Teste de conexão (`ansible web -m ping` → `pong`) | `ansible-ping.png` |
| 1ª execução do playbook (tarefas `changed` e `PLAY RECAP` sem falhas) | `ansible-execucao-1.png` |
| 2ª execução mostrando `changed=0` (idempotência) | `ansible-idempotencia.png` |
| Docker e stacks no servidor (`docker --version` e `docker compose ps`) | `ansible-docker-ps.png` |
| Aplicação acessível por HTTP no navegador (`http://<IP>`) | `ansible-http-navegador.png` |
| Workflow **Ansible** verde no GitHub Actions (syntax check) | `ansible-pipeline.png` |
