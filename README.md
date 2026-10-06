# Projeto Integrador — Cloud Computing e DevOps

Aplicação web publicada em nuvem com Docker, DNS e HTTPS pelo Cloudflare, CI/CD com GitHub Actions e monitoramento com Uptime Kuma. Feita para o Projeto Integrador da disciplina de **Cloud Computing e DevOps**.

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

## 4. Estrutura do projeto

```
projeto-devops/
├── .github/workflows/docker.yml   # pipeline CI/CD
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
| VPS perdida | Criar nova VPS, instalar Docker, configurar o firewall, atualizar o IP no Cloudflare e rodar a pipeline (*Actions → Run workflow*) |
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
