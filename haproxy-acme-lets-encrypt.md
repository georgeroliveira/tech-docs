
# Integração HAProxy com Let's Encrypt via acme.sh (Ubuntu 22.04 ou superior)

Este guia ensina como emitir, instalar e renovar certificados automaticamente no HAProxy usando acme.sh e Let's Encrypt sem reiniciar o serviço.

## 1. Instalar o HAProxy (versão mais recente)

```bash
sudo apt-get update
sudo apt-get install --no-install-recommends software-properties-common gnupg2 curl -y
sudo add-apt-repository ppa:vbernat/haproxy-2.9 -y
sudo apt-get update
sudo apt-get install haproxy=2.9.*
haproxy -v
```

## 2. Criar usuário dedicado acme

```bash
sudo adduser \
  --system \
  --disabled-password \
  --disabled-login \
  --home /var/lib/acme \
  --quiet \
  --force-badname \
  --group \
  acme

sudo adduser acme haproxy
```

## 3. Instalar o git e acme.sh

```bash
sudo apt install git -y
sudo mkdir -p /usr/local/share/acme.sh/
git clone https://github.com/acmesh-official/acme.sh.git
cd acme.sh/

sudo ./acme.sh --install \
  --no-cron \
  --no-profile \
  --home /usr/local/share/acme.sh

sudo ln -s /usr/local/share/acme.sh/acme.sh /usr/local/bin/
sudo chmod 755 /usr/local/share/acme.sh/
```

### 3.1. Instalar socat (obrigatório para hot reload via Runtime API)

```bash
sudo apt install socat -y
```

## 4. Criar conta ACME no Let's Encrypt (produção)

### 4.1. Entrar como usuário acme

```bash
sudo -u acme -s
```

### 4.2 Criar diretório de trabalho (se necessário)

```bash
mkdir -p /var/lib/acme/.acme.sh
```

### 4.3 Definir o Let's Encrypt como a CA padrão

```bash
acme.sh --home /var/lib/acme/.acme.sh --set-default-ca --server letsencrypt
```

### 4.4 Registrar a conta no Let's Encrypt com e-mail de contato

```bash
acme.sh --home /var/lib/acme/.acme.sh --register-account \
  --server letsencrypt \
  -m teste@teste.com.br \
  --accountkeylength ec-256 \
  --create-account-key
```

### 4.5 Sair do shell do usuário acme

```bash
exit
```

> ⚠️ IMPORTANTE: Anote o valor exibido `ACCOUNT_THUMBPRINT='...'` e insira no seu `haproxy.cfg` no bloco `global`.

## 5. Configurar HAProxy para responder desafios HTTP-01

```bash
sudo mkdir -p /etc/haproxy/certs
sudo chown haproxy:haproxy /etc/haproxy/certs
sudo chmod 770 /etc/haproxy/certs
```

### Editar `/etc/haproxy/haproxy.cfg`

```haproxy
global
    stats socket /var/run/haproxy/admin.sock level admin mode 660
    setenv ACCOUNT_THUMBPRINT 'SEU_THUMBPRINT_AQUI'

frontend web
    bind :80
    http-request return status 200 content-type text/plain lf-string "%[path,field(-1,/)].${ACCOUNT_THUMBPRINT}\n" if { path_beg '/.well-known/acme-challenge/' }
```

### Reiniciar HAProxy

```bash
sudo systemctl restart haproxy
```

## 6. Emitir certificado com acme.sh

```bash
sudo -u acme -s
acme.sh --set-default-ca --server letsencrypt
acme.sh --issue -d teste.com.br --stateless
exit
```

### 6.1 Instalar o certificado manualmente

```bash
cat /var/lib/acme/.acme.sh/teste.com.br_ecc/fullchain.cer \
    /var/lib/acme/.acme.sh/teste.com.br_ecc/xvia-dev.cloud.mti.mt.gov.br.key \
  | sudo tee /etc/haproxy/teste.com.br.pem > /dev/null

sudo chown haproxy:haproxy /etc/haproxy/certs/teste.com.br.pem
sudo chmod 640 /etc/haproxy/certs/teste.com.br.pem
```

### 6.2 Validar e reiniciar

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl restart haproxy
```

## 7. Configurar crt-list para múltiplos certificados

```bash
echo "/etc/haproxy/certs/teste.com.br.pem" > /etc/haproxy/certs/crt-list.txt
chown haproxy:haproxy /etc/haproxy/certs/crt-list.txt
chmod 640 /etc/haproxy/certs/crt-list.txt
```

### 7.1 Deploy automático com acme.sh

```bash
acme.sh --install-cert -d teste.com.br \
  --fullchain-file /etc/haproxy/certs/teste.com.br.pem \
  --reloadcmd "echo '[INFO] Reload via Runtime API, não precisa reiniciar'" \
  --deploy-hook haproxy
```

## 8. Verificar certificado carregado no HAProxy

```bash
echo "show ssl cert /etc/haproxy/certs/teste.com.br.pem" |\
socat /var/run/haproxy/admin.sock -
```

## 9. Exemplo de haproxy.cfg completo

```haproxy
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    setenv ACCOUNT_THUMBPRINT zYV_tPO4MwV8cm82pMeR7AX0mu7a6PRmHS52OCtM5_Q
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:...
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:...
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    log global
    mode tcp
    option dontlognull
    option tcplog
    timeout connect 10s
    timeout client 1m
    timeout server 3600s
    timeout check 10s
    timeout queue 1m
    maxconn 3000

frontend web
    mode http
    bind :80
    http-request return status 200 content-type text/plain lf-string "%[path,field(-1,/)].${ACCOUNT_THUMBPRINT}\n" if { path_beg '/.well-known/acme-challenge/' }

frontend xvia-443
    bind 0.0.0.0:443 ssl crt-list /etc/haproxy/certs/crt-list.txt
    default_backend xvia_4000

backend xvia_4000
    server criar-docum-xvia 127.0.0.1:4000 ssl verify none
```

## 10. Testar acesso

```bash
curl -v https://teste.com.br
```

## 11. Automatizar renovação de certificados (Systemd Timer)

### 11.1 Criar Service Unit: `/etc/systemd/system/acme_letsencrypt.service`

```ini
[Unit]
Description=Renew Let's Encrypt certificates using acme.sh
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/acme.sh --cron --home /var/lib/acme/.acme.sh
User=acme
Group=acme
SuccessExitStatus=0 2
```

### 11.2 Criar Timer Unit: `/etc/systemd/system/acme_letsencrypt.timer`

```ini
[Unit]
Description=Daily renewal of Let's Encrypt certificates

[Timer]
OnCalendar=daily
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
```

### 11.3 Ativar o Timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now acme_letsencrypt.timer
```

### 11.4 Verificar se está funcionando

```bash
systemctl status acme_letsencrypt.timer
systemctl list-timers | grep acme
```

### 11.5 Testar execução manual

```bash
sudo systemctl start acme_letsencrypt.service
journalctl -u acme_letsencrypt.service -n 30 --no-pager
```
