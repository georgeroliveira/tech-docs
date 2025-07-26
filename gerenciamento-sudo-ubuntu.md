# Gerenciamento Seguro de Acesso Administrativo com `sudo` no Ubuntu

### Objetivo
Padronizar, restringir e auditar o acesso privilegiado (`sudo`) no ambiente Linux com foco em segurança empresarial, auditoria detalhada e compliance, substituindo permissões diretas por uma abordagem segura baseada em grupos e funções.

---

## Visão Geral

| Item                         | Prática Recomendada              |
|-----------------------------|----------------------------------|
| Acesso root direto          | Desabilitado ou com senha forte |
| Acesso administrativo       | Via grupos funcionais           |
| Arquivos sudoers individuais| Evitar, exceto para automações  |
| Grupo `sudo`                | Esvaziado, não utilizado        |
| Controle por grupo          | Sim, via `/etc/sudoers.d/`      |
| Auditoria                   | Logs detalhados habilitados     |
| Backup automático          | Configurado antes de mudanças   |

---

## Preparação e Backup

### 1. Backup dos arquivos críticos
```bash
# Backup completo do sudoers
sudo cp /etc/sudoers /etc/sudoers.backup.$(date +%Y%m%d-%H%M%S)
sudo cp -r /etc/sudoers.d /etc/sudoers.d.backup.$(date +%Y%m%d-%H%M%S)

# Verificar integridade
sudo visudo -c
```

### 2. Documentar estado atual
```bash
# Relatório de usuários privilegiados atual
echo "=== USUÁRIOS COM SUDO ATUAL ===" > /tmp/sudo-audit-$(date +%Y%m%d).txt
getent group sudo admin wheel 2>/dev/null >> /tmp/sudo-audit-$(date +%Y%m%d).txt
echo "=== ARQUIVOS SUDOERS ===" >> /tmp/sudo-audit-$(date +%Y%m%d).txt
ls -la /etc/sudoers.d/ >> /tmp/sudo-audit-$(date +%Y%m%d).txt
```

---

## Configuração de Grupos por Função

### 1. Criar grupos administrativos especializados
```bash
# Grupo para administradores completos
sudo groupadd admin-full

# Grupo para administradores de serviços
sudo groupadd admin-service

# Grupo para administradores de rede
sudo groupadd admin-network

# Grupo para automação (scripts, ansible, etc.)
sudo groupadd admin-automation

# Verificar criação
getent group | grep admin-
```

### 2. Adicionar usuários aos grupos apropriados
```bash
# Administradores completos (acesso total)
sudo usermod -aG admin-full george
sudo usermod -aG admin-full vmadmin

# Administradores de serviços específicos
sudo usermod -aG admin-service serviceuser

# Verificar membros dos grupos
for group in admin-full admin-service admin-network admin-automation; do
    echo "=== $group ==="
    getent group $group
done
```

---

## Configuração de Sudoers com Auditoria

### 1. Configuração para administradores completos
```bash
sudo visudo -f /etc/sudoers.d/admin-full
```

Conteúdo do arquivo `/etc/sudoers.d/admin-full`:
```sudoers
# Administradores com acesso completo
%admin-full ALL=(ALL:ALL) ALL

# Configurações de auditoria e segurança
Defaults:%admin-full log_host, log_year, logfile="/var/log/sudo-admin.log"
Defaults:%admin-full mailto="admin@empresa.com"
Defaults:%admin-full mail_badpass, mail_no_user, mail_no_host
Defaults:%admin-full timestamp_timeout=5
Defaults:%admin-full passwd_tries=3
Defaults:%admin-full badpass_message="Acesso negado. Tentativa registrada no log de auditoria."
Defaults:%admin-full lecture="always"
Defaults:%admin-full lecture_file="/etc/sudo-lecture.txt"
```

### 2. Configuração para administradores de serviços
```bash
sudo visudo -f /etc/sudoers.d/admin-service
```

Conteúdo do arquivo `/etc/sudoers.d/admin-service`:
```sudoers
# Administradores de serviços - acesso restrito
%admin-service ALL=(ALL) /bin/systemctl *, /usr/sbin/service *, /bin/journalctl *, /usr/bin/tail /var/log/*

# Configurações de auditoria
Defaults:%admin-service log_host, log_year, logfile="/var/log/sudo-service.log"
Defaults:%admin-service mailto="admin@empresa.com"
Defaults:%admin-service timestamp_timeout=5
Defaults:%admin-service passwd_tries=3
```

### 3. Configuração para administradores de rede
```bash
sudo visudo -f /etc/sudoers.d/admin-network
```

Conteúdo do arquivo `/etc/sudoers.d/admin-network`:
```sudoers
# Administradores de rede - comandos específicos
%admin-network ALL=(ALL) /sbin/iptables *, /usr/sbin/ufw *, /bin/netstat *, /sbin/ip *, /usr/bin/ss *, /usr/sbin/tcpdump *

# Configurações de auditoria
Defaults:%admin-network log_host, log_year, logfile="/var/log/sudo-network.log"
Defaults:%admin-network mailto="admin@empresa.com"
Defaults:%admin-network timestamp_timeout=5
```

### 4. Configuração para automação
```bash
sudo visudo -f /etc/sudoers.d/admin-automation
```

Conteúdo do arquivo `/etc/sudoers.d/admin-automation`:
```sudoers
# Usuários de automação - sem senha
%admin-automation ALL=(ALL) NOPASSWD: ALL

# Configurações de auditoria (mesmo sem senha)
Defaults:%admin-automation log_host, log_year, logfile="/var/log/sudo-automation.log"
Defaults:%admin-automation mailto="admin@empresa.com"
```

### 5. Criar arquivo de aviso para usuários
```bash
sudo tee /etc/sudo-lecture.txt << 'EOF'
[AVISO DE SEGURANÇA]
Você está acessando um sistema com privilégios administrativos.
- Todas as ações são registradas e auditadas
- Uso inadequado pode resultar em medidas disciplinares
- Em caso de dúvidas, consulte a política de TI da empresa
- Sessão será encerrada em 5 minutos de inatividade
EOF
```

---

## Configuração de Auditoria Avançada

### 1. Configurar auditoria PAM
```bash
# Adicionar ao /etc/pam.d/sudo
echo "session required pam_tty_audit.so enable=*" | sudo tee -a /etc/pam.d/sudo
```

### 2. Configurar rotação de logs
```bash
sudo tee /etc/logrotate.d/sudo-audit << 'EOF'
/var/log/sudo*.log {
    daily
    missingok
    rotate 90
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
        /usr/bin/killall -USR1 rsyslog 2>/dev/null || true
    endscript
}
EOF
```

### 3. Script de monitoramento em tempo real
```bash
sudo tee /usr/local/bin/sudo-monitor.sh << 'EOF'
#!/bin/bash
# Monitor de atividades sudo em tempo real

LOG_DIR="/var/log"
ALERT_EMAIL="admin@empresa.com"

# Monitorar tentativas de acesso negado
tail -f $LOG_DIR/sudo*.log | while read line; do
    if echo "$line" | grep -q "FAILED\|incorrect password\|NOT in sudoers"; then
        echo "[ALERTA] $(date): $line" | mail -s "Sudo: Tentativa de acesso negado" $ALERT_EMAIL
    fi
done &
EOF

sudo chmod +x /usr/local/bin/sudo-monitor.sh
```

---

## Scripts de Validação e Auditoria

### 1. Script de verificação de integridade
```bash
sudo tee /usr/local/bin/sudo-integrity-check.sh << 'EOF'
#!/bin/bash
# Verificação de integridade da configuração sudo

echo "=== VERIFICAÇÃO DE INTEGRIDADE SUDO ==="
echo "Data: $(date)"
echo

# Verificar sintaxe
echo "1. Verificando sintaxe dos arquivos sudoers..."
if sudo visudo -c; then
    echo "   ✓ Sintaxe OK"
else
    echo "   ✗ ERRO na sintaxe!"
    exit 1
fi

# Verificar permissões dos arquivos
echo "2. Verificando permissões..."
find /etc/sudoers.d/ -type f ! -perm 0440 -exec echo "   ✗ Permissão incorreta: {}" \;
find /etc/sudoers.d/ -type f -perm 0440 -exec echo "   ✓ Permissão OK: {}" \;

# Verificar usuários com acesso
echo "3. Usuários com acesso sudo:"
for group in admin-full admin-service admin-network admin-automation; do
    members=$(getent group $group 2>/dev/null | cut -d: -f4)
    if [ ! -z "$members" ]; then
        echo "   $group: $members"
    fi
done

# Verificar logs
echo "4. Status dos logs de auditoria:"
for log in /var/log/sudo*.log; do
    if [ -f "$log" ]; then
        size=$(ls -lh "$log" | awk '{print $5}')
        echo "   ✓ $log ($size)"
    fi
done

echo
echo "=== FIM DA VERIFICAÇÃO ==="
EOF

sudo chmod +x /usr/local/bin/sudo-integrity-check.sh
```

### 2. Script de relatório de usuários privilegiados
```bash
sudo tee /usr/local/bin/sudo-user-report.sh << 'EOF'
#!/bin/bash
# Relatório detalhado de usuários com privilégios sudo

REPORT_FILE="/tmp/sudo-report-$(date +%Y%m%d-%H%M%S).txt"

echo "=== RELATÓRIO DE USUÁRIOS PRIVILEGIADOS ===" > $REPORT_FILE
echo "Gerado em: $(date)" >> $REPORT_FILE
echo "Hostname: $(hostname)" >> $REPORT_FILE
echo >> $REPORT_FILE

# Listar todos os grupos administrativos
echo "GRUPOS ADMINISTRATIVOS:" >> $REPORT_FILE
for group in admin-full admin-service admin-network admin-automation sudo; do
    members=$(getent group $group 2>/dev/null | cut -d: -f4)
    if [ ! -z "$members" ]; then
        echo "  $group: $members" >> $REPORT_FILE
    else
        echo "  $group: (vazio)" >> $REPORT_FILE
    fi
done

echo >> $REPORT_FILE

# Verificar privilégios individuais
echo "PRIVILÉGIOS POR USUÁRIO:" >> $REPORT_FILE
for user in $(getent passwd | awk -F: '$3 >= 1000 {print $1}'); do
    privileges=$(sudo -l -U $user 2>/dev/null | grep -v "may run\|Matching")
    if [ ! -z "$privileges" ]; then
        echo "  $user:" >> $REPORT_FILE
        echo "$privileges" | sed 's/^/    /' >> $REPORT_FILE
    fi
done

echo >> $REPORT_FILE
echo "=== FIM DO RELATÓRIO ===" >> $REPORT_FILE

echo "Relatório gerado: $REPORT_FILE"
cat $REPORT_FILE
EOF

sudo chmod +x /usr/local/bin/sudo-user-report.sh
```

---

## Definir Permissões e Testar

### 1. Aplicar permissões corretas
```bash
# Definir permissões para todos os arquivos sudoers
sudo chmod 0440 /etc/sudoers.d/admin-*

# Verificar permissões
ls -la /etc/sudoers.d/
```

### 2. Testes de validação
```bash
# Testar cada grupo
echo "Testando grupo admin-full..."
sudo -l -g admin-full

echo "Testando grupo admin-service..."  
sudo -l -g admin-service

echo "Testando sintaxe geral..."
sudo visudo -c
```

---

## Limpeza e Migração

### 1. Remover usuários do grupo sudo padrão
```bash
# Listar usuários atuais no grupo sudo
echo "Usuários no grupo sudo antes da limpeza:"
getent group sudo

# Remover usuários (após confirmar que estão nos novos grupos)
for user in vmadmin george; do
    if id -nG $user | grep -q admin-full; then
        sudo gpasswd -d $user sudo
        echo "Usuário $user removido do grupo sudo"
    else
        echo "AVISO: $user não está no admin-full, mantendo no sudo"
    fi
done
```

### 2. Remover arquivos individuais redundantes
```bash
# Listar arquivos sudoers individuais
echo "Arquivos sudoers individuais encontrados:"
ls -la /etc/sudoers.d/ | grep -v "admin-"

# Remover arquivos específicos (exemplo)
# sudo rm /etc/sudoers.d/vmadmin-nopasswd
# sudo rm /etc/sudoers.d/george-individual
```

---

## Monitoramento e Compliance

### 1. Configurar cron para auditoria automática
```bash
# Executar verificação diária
echo "0 6 * * * root /usr/local/bin/sudo-integrity-check.sh > /var/log/sudo-integrity.log 2>&1" | sudo tee -a /etc/crontab

# Relatório semanal
echo "0 8 * * 1 root /usr/local/bin/sudo-user-report.sh | mail -s 'Relatório Semanal - Usuários Privilegiados' admin@empresa.com" | sudo tee -a /etc/crontab
```

### 2. Configurar alertas em tempo real
```bash
# Iniciar monitor de sudo (pode ser adicionado ao systemd)
sudo /usr/local/bin/sudo-monitor.sh
```

---

## Resultado Final Esperado

| Componente                     | Status Esperado                          |
|-------------------------------|------------------------------------------|
| Grupos `admin-*`              | Criados com usuários apropriados        |
| Arquivos `/etc/sudoers.d/`    | Configurados com auditoria              |
| Grupo `sudo`                  | Esvaziado (opcional)                     |
| Logs de auditoria             | Habilitados e rotacionados               |
| Alertas de segurança          | Configurados para admin@empresa.com     |
| Scripts de verificação        | Instalados e agendados                   |
| Backup automático            | Configurado antes de mudanças           |

---

## Procedimentos de Emergência

### Reversão completa
```bash
# Em caso de perda total de acesso sudo
# (via console físico, SSH root, ou live boot)

# 1. Restaurar backup
sudo cp /etc/sudoers.backup.YYYYMMDD /etc/sudoers
sudo cp -r /etc/sudoers.d.backup.YYYYMMDD/* /etc/sudoers.d/

# 2. Acesso temporário via grupo sudo
sudo usermod -aG sudo $(whoami)

# 3. Verificar e corrigir
sudo visudo -c
```

### Acesso de emergência sem sudo
```bash
# Via SSH como root (se habilitado)
ssh root@servidor

# Via console físico/VMware
# Boot em single user mode ou live CD
```

---

## Compliance e Documentação

### Atendimento a Normas
- **ISO 27001:** Controle de acesso documentado e auditado
- **SOX/PCI-DSS:** Logs detalhados com retenção de 90 dias
- **LGPD:** Princípio do menor privilégio implementado
- **NIST:** Segregação de funções e auditoria contínua

### Documentação Obrigatória
- Matriz de responsabilidades por grupo
- Procedimentos de concessão/revogação de acesso
- Logs de auditoria preservados
- Plano de contingência documentado

---

## Expansões Futuras

### 1. Integração com LDAP/Active Directory
```bash
# Exemplo de configuração para grupos LDAP
%ldap-admins ALL=(ALL:ALL) ALL
```

### 2. Implementação com Ansible
```yaml
# Playbook para múltiplos servidores
- name: Configure sudo security
  hosts: linux_servers
  tasks:
    - name: Create admin groups
      group:
        name: "{{ item }}"
        state: present
      loop:
        - admin-full
        - admin-service
```

### 3. Monitoramento com ELK Stack
```bash
# Enviar logs para Elasticsearch
# Configurar Filebeat para sudo logs
```

---

**Autor:** George Oliveira  
**Versão:** 2.0
**Última atualização:** 2025-07-26  
**Licença:** MIT  
**Revisão Técnica:** Baseada em padrões LPI-3, ISO 27001 e NIST Cybersecurity Framework
