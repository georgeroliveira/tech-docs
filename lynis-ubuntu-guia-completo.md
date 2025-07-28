# Guia Completo do Lynis no Ubuntu

## 📋 Índice

1. [Introdução](#introdução)
2. [Instalação](#instalação)
3. [Configuração Inicial](#configuração-inicial)
4. [Comandos Básicos](#comandos-básicos)
5. [Executando Auditorias](#executando-auditorias)
6. [Interpretando Resultados](#interpretando-resultados)
7. [Correções de Segurança](#correções-de-segurança)
8. [Automação e Monitoramento](#automação-e-monitoramento)
9. [Troubleshooting](#troubleshooting)
10. [Melhores Práticas](#melhores-práticas)

---

## Introdução

O **Lynis** é uma ferramenta de auditoria de segurança open source desenvolvida pela CISOfy, projetada para sistemas UNIX/Linux. Ela realiza uma análise abrangente do sistema, identificando vulnerabilidades, configurações inadequadas e oportunidades de hardening.

### Características Principais

- ✅ **Open Source** - Licença GPL v3
- ✅ **Sem agentes** - Não requer instalação complexa
- ✅ **Multiplataforma** - Linux, BSD, macOS
- ✅ **Relatórios detalhados** - Saídas estruturadas e logs
- ✅ **Hardening Index** - Pontuação clara de segurança
- ✅ **Sugestões práticas** - Recomendações de correção

### Casos de Uso

- **Pentesting** - Reconhecimento e identificação de vulnerabilidades
- **Compliance** - Verificação de conformidade com padrões
- **Hardening** - Endurecimento de sistemas em produção
- **Auditoria** - Revisões periódicas de segurança
- **DevSecOps** - Integração em pipelines de CI/CD

---

## Instalação

### Método 1: Repositório Oficial Ubuntu

```bash
# Atualizar repositórios
sudo apt update

# Instalar Lynis
sudo apt install lynis

# Verificar instalação
lynis --version
```

### Método 2: Repositório CISOfy (Versão Mais Atual)

```bash
# Adicionar chave GPG
wget -O - https://packages.cisofy.com/keys/cisofy-software-public.key | sudo apt-key add -

# Adicionar repositório
echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list

# Atualizar e instalar
sudo apt update
sudo apt install lynis
```

### Método 3: Download Direto (Portátil)

```bash
# Baixar versão mais recente
cd /opt
sudo wget https://downloads.cisofy.com/lynis/lynis-3.0.9.tar.gz

# Extrair
sudo tar xzf lynis-3.0.9.tar.gz

# Criar link simbólico
sudo ln -sf /opt/lynis/lynis /usr/local/bin/lynis

# Executar
sudo /opt/lynis/lynis audit system
```

### Verificação da Instalação

```bash
# Verificar versão
lynis --version

# Verificar caminhos
which lynis

# Ajuda básica
lynis --help
```

---

## Configuração Inicial

### Estrutura de Diretórios

```bash
/etc/lynis/           # Arquivos de configuração
├── default.prf       # Perfil padrão
├── custom.prf        # Configurações personalizadas
└── plugins/          # Plugins adicionais

/var/log/             # Logs e relatórios
├── lynis.log         # Log detalhado
└── lynis-report.dat  # Dados do relatório
```

### Configuração Personalizada

```bash
# Criar arquivo de configuração personalizada
sudo cp /etc/lynis/default.prf /etc/lynis/custom.prf

# Editar configurações
sudo vim /etc/lynis/custom.prf
```

**Configurações importantes:**

```ini
# Configurações gerais
config:colored_output:1
config:show_tool_tips:1

# Logs
config:log_tests_incorrect_os:0
config:show_warnings_only:0

# Relatórios
config:report_format:text
config:create_report_file:1

# Testes específicos
skip-test:SSH-7408:MaxAuthTries
skip-test:FILE-6310:/tmp
```

---

## Comandos Básicos

### Comandos Essenciais

```bash
# Auditoria completa do sistema
sudo lynis audit system

# Auditoria com verbosidade
sudo lynis audit system --verbose

# Auditoria rápida (para pentesting)
sudo lynis audit system --pentest --quick

# Usar perfil customizado
sudo lynis audit system --profile /etc/lynis/custom.prf
```

### Opções de Saída

```bash
# Salvar log em arquivo específico
sudo lynis audit system --logfile /var/log/lynis-$(date +%Y%m%d).log

# Modo silencioso (só warnings/sugestões)
sudo lynis audit system --quiet

# Cores desabilitadas
sudo lynis audit system --no-colors

# Saída em formato JSON
sudo lynis audit system --report-format json
```

### Comandos de Informação

```bash
# Mostrar versão
lynis version

# Mostrar grupos de testes
lynis show groups

# Mostrar plugins disponíveis
lynis show plugins

# Mostrar detalhes de teste específico
lynis show details TEST-ID

# Mostrar comandos disponíveis
lynis show commands
```

---

## Executando Auditorias

### Auditoria Básica

```bash
# Executar auditoria padrão
sudo lynis audit system
```

**Saída esperada:**
- Informações do sistema
- Testes executados
- Warnings e sugestões
- Hardening index

### Auditoria Focada

```bash
# Testar apenas SSH
sudo lynis audit system --tests-from-group ssh

# Testar categoria específica
sudo lynis audit system --tests-from-category security

# Executar teste específico
sudo lynis audit system --tests AUTH-9262

# Pular testes específicos
sudo lynis audit system --skip-test BOOT-5122,SSH-7408
```

### Auditoria para Compliance

```bash
# PCI-DSS
sudo lynis audit system --compliance-standard pci-dss

# CIS Benchmark
sudo lynis audit system --compliance-standard cis

# HIPAA
sudo lynis audit system --compliance-standard hipaa
```

### Scripts de Auditoria

**Script básico de auditoria:**

```bash
#!/bin/bash
# audit_script.sh

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="/var/log/lynis-audits"
REPORT_FILE="$LOG_DIR/lynis-report-$TIMESTAMP"

# Criar diretório se não existir
mkdir -p $LOG_DIR

# Executar auditoria
sudo lynis audit system \
    --logfile "$REPORT_FILE.log" \
    --verbose \
    --no-colors > "$REPORT_FILE.txt" 2>&1

# Resumo
echo "Auditoria concluída: $REPORT_FILE"
echo "Hardening Index:"
grep "Hardening index" "$REPORT_FILE.txt"
```

---

## Interpretando Resultados

### Estrutura do Relatório

```bash
# Visualizar relatório completo
less /var/log/lynis.log

# Ver apenas warnings
grep "WARNING" /var/log/lynis.log

# Ver apenas sugestões
grep "SUGGESTION" /var/log/lynis.log

# Ver hardening index
grep "Hardening index" /var/log/lynis.log
```

### Níveis de Severidade

| Tipo | Descrição | Ação Requerida |
|------|-----------|----------------|
| **WARNING** | Problemas críticos | Correção imediata |
| **SUGGESTION** | Melhorias recomendadas | Avaliar e implementar |
| **INFO** | Informações gerais | Opcional |

### Hardening Index

**Interpretação da pontuação:**

- **0-30**: Sistema muito vulnerável
- **31-50**: Segurança baixa
- **51-70**: Segurança moderada  
- **71-85**: Boa segurança
- **86-100**: Excelente segurança

### Códigos de Teste Comuns

| Código | Área | Descrição |
|--------|------|-----------|
| `SSH-7408` | SSH | Configurações SSH |
| `AUTH-9262` | Autenticação | Força da senha |
| `BOOT-5122` | Boot | Proteção GRUB |
| `NETW-2705` | Rede | Configuração DNS |
| `KRNL-6000` | Kernel | Parâmetros sysctl |

---

## Correções de Segurança

### Correções Críticas (Warnings)

#### 1. SSH Hardening

```bash
# Backup da configuração
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Editar configuração
sudo vim /etc/ssh/sshd_config
```

**Configurações recomendadas:**

```bash
# Porta não padrão
Port 2222

# Desabilitar root login
PermitRootLogin no

# Autenticação
MaxAuthTries 3
MaxSessions 5

# Forwards
AllowTcpForwarding no
X11Forwarding no
AllowAgentForwarding no

# Protocolo e criptografia
Protocol 2
Ciphers aes256-ctr,aes192-ctr,aes128-ctr

# Timeouts
LoginGraceTime 60
ClientAliveInterval 300
ClientAliveCountMax 2

# Logs
LogLevel VERBOSE
```

```bash
# Testar configuração
sudo sshd -t

# Aplicar (manter sessão atual aberta!)
sudo systemctl restart ssh
```

#### 2. Kernel Hardening (sysctl)

```bash
# Backup
sudo cp /etc/sysctl.conf /etc/sysctl.conf.backup

# Adicionar configurações
sudo vim /etc/sysctl.conf
```

**Configurações recomendadas:**

```bash
# Network Security
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1

# IPv6
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0

# Kernel Security
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.kexec_load_disabled = 1
kernel.unprivileged_bpf_disabled = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0
```

```bash
# Aplicar configurações
sudo sysctl -p
```

#### 3. Boot Security (GRUB)

```bash
# Gerar senha hash
grub-mkpasswd-pbkdf2

# Editar configuração
sudo vim /etc/grub.d/00_header
```

**Adicionar:**

```bash
cat << EOF
set superusers="admin"
password_pbkdf2 admin grub.pbkdf2.sha512.10000.HASH_GERADO
EOF
```

```bash
# Atualizar GRUB
sudo update-grub
```

### Ferramentas de Segurança

```bash
# Fail2ban (proteção contra brute force)
sudo apt install fail2ban
sudo systemctl enable fail2ban

# Auditd (logging de eventos)
sudo apt install auditd
sudo systemctl enable auditd

# Rkhunter (detecção de rootkits)
sudo apt install rkhunter
sudo rkhunter --update

# ClamAV (antivírus)
sudo apt install clamav clamav-daemon
sudo freshclam
```

---

## Automação e Monitoramento

### Script de Auditoria Automatizada

```bash
#!/bin/bash
# /usr/local/bin/lynis-audit.sh

# Configurações
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="/var/log/lynis-auto"
REPORT_FILE="$LOG_DIR/audit-$TIMESTAMP"
EMAIL="admin@empresa.com"
THRESHOLD=70

# Criar diretório
mkdir -p $LOG_DIR

# Executar auditoria
sudo lynis audit system \
    --logfile "$REPORT_FILE.log" \
    --quiet \
    --no-colors > "$REPORT_FILE.txt" 2>&1

# Extrair hardening index
HARDENING_INDEX=$(grep "Hardening index" "$REPORT_FILE.txt" | awk '{print $4}')

# Verificar threshold
if [ "$HARDENING_INDEX" -lt "$THRESHOLD" ]; then
    echo "ALERTA: Hardening Index ($HARDENING_INDEX) abaixo do limite ($THRESHOLD)" | \
    mail -s "Lynis Alert - $(hostname)" "$EMAIL"
fi

# Rotação de logs (manter últimos 30)
find $LOG_DIR -name "audit-*" -mtime +30 -delete

echo "Auditoria concluída: Hardening Index = $HARDENING_INDEX"
```

### Cron Job

```bash
# Editar crontab
sudo crontab -e

# Auditoria diária às 2:00 AM
0 2 * * * /usr/local/bin/lynis-audit.sh

# Auditoria semanal detalhada
0 3 * * 0 /usr/local/bin/lynis-audit.sh --verbose
```

### Integração com SIEM

```bash
# Enviar logs para rsyslog
sudo lynis audit system --logfile /dev/stdout | \
logger -t lynis -p local0.info

# Formato JSON para ELK Stack
sudo lynis audit system --report-format json | \
curl -X POST "elasticsearch:9200/lynis-$(date +%Y.%m.%d)/_doc" \
-H "Content-Type: application/json" -d @-
```

---

## Troubleshooting

### Problemas Comuns

#### Erro de Permissão

```bash
# Problema: Permission denied
# Solução: Executar com sudo
sudo lynis audit system
```

#### Teste Específico Falhando

```bash
# Verificar detalhes do teste
lynis show details TEST-ID

# Pular teste problemático
sudo lynis audit system --skip-test TEST-ID
```

#### Logs Não Encontrados

```bash
# Verificar localização dos logs
sudo find / -name "lynis*.log" 2>/dev/null

# Especificar local do log
sudo lynis audit system --logfile /tmp/lynis.log
```

### Debug e Verbosidade

```bash
# Modo debug
sudo lynis audit system --debug

# Máxima verbosidade
sudo lynis audit system --verbose --debug

# Log detalhado
sudo lynis audit system --log-file /tmp/debug.log --verbose
```

### Verificação de Integridade

```bash
# Verificar integridade do Lynis
sudo lynis update info

# Verificar assinatura
gpg --verify lynis-x.x.x.tar.gz.asc lynis-x.x.x.tar.gz
```

---

## Melhores Práticas

### Antes da Auditoria

1. **Backup do sistema** - Sempre fazer snapshot/backup
2. **Documentar estado atual** - Registrar configurações
3. **Planejar janela de manutenção** - Evitar horários críticos
4. **Ter acesso alternativo** - Console físico ou IPMI

### Durante a Auditoria

1. **Executar como root** - Para acesso completo ao sistema
2. **Manter logs detalhados** - Para análise posterior
3. **Não interromper** - Deixar auditoria completar
4. **Monitorar recursos** - CPU e I/O durante execução

### Após a Auditoria

1. **Analisar resultados** - Priorizar por criticidade
2. **Testar correções** - Em ambiente de desenvolvimento primeiro
3. **Implementar gradualmente** - Uma correção por vez
4. **Reauditoria** - Verificar melhorias implementadas

### Frequência Recomendada

| Ambiente | Frequência | Tipo |
|----------|------------|------|
| **Desenvolvimento** | Semanal | Completa |
| **Teste** | Quinzenal | Completa |
| **Produção** | Mensal | Completa |
| **Crítico** | Semanal | Focada |

### Integração DevSecOps

```bash
# Pipeline CI/CD example
stage('Security Audit') {
    steps {
        sh '''
            sudo lynis audit system --quiet --no-colors > lynis-report.txt
            HARDENING_INDEX=$(grep "Hardening index" lynis-report.txt | awk '{print $4}')
            if [ "$HARDENING_INDEX" -lt "75" ]; then
                echo "Security threshold not met: $HARDENING_INDEX"
                exit 1
            fi
        '''
    }
}
```

### Documentação e Compliance

1. **Manter registros** - Histórico de auditorias
2. **Documentar exceções** - Justificar testes ignorados
3. **Rastrear melhorias** - Evolução do hardening index
4. **Relatórios executivos** - Resumos para gestão

---

## Conclusão

O Lynis é uma ferramenta fundamental para auditoria de segurança em ambientes Ubuntu e Linux em geral. Este guia fornece uma base sólida para implementação, desde a instalação básica até automação avançada e integração em pipelines DevSecOps.

**Pontos-chave:**
- Sempre fazer backup antes de correções
- Implementar mudanças gradualmente
- Monitorar continuamente
- Documentar todo o processo
- Manter a ferramenta atualizada

Para mais informações, consulte:
- [Documentação oficial do Lynis](https://cisofy.com/lynis/)
- [Controles de segurança CISOfy](https://cisofy.com/controls/)
- [Repositório GitHub](https://github.com/CISOfy/lynis)

---

**Autor**: Especialista em Cibersegurança  
**Versão**: 1.0  
**Data**: 2025  
**Licença**: Creative Commons Attribution 4.0
