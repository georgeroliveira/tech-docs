# Monitoramento de Segurança com auditd no Ubuntu

Este guia descreve como configurar a auditoria no Ubuntu usando `auditd` para registrar modificações em arquivos sensíveis do sistema e o uso do comando `sudo`, como parte das melhores práticas de segurança e rastreabilidade.

## 1. Instalação do auditd

```bash
sudo apt update
sudo apt install auditd audispd-plugins -y
```

Verifique o status do serviço:

```bash
sudo systemctl status auditd
```

Para habilitar a inicialização automática:

```bash
sudo systemctl enable auditd
```

## 2. Monitoramento de Diretórios Críticos

### Configuração Básica de Monitoramento

Para monitorar alterações em diretórios sensíveis do sistema:

```bash
# Monitorar diretório de configurações do sistema
sudo auditctl -w /etc/security/ -p wa -k security-config

# Monitorar logs do sistema
sudo auditctl -w /var/log/ -p wa -k system-logs

# Monitorar arquivos de configuração de serviços
sudo auditctl -w /etc/systemd/ -p wa -k systemd-config
```

### Parâmetros Explicados

- `-w`: adiciona uma regra de watch
- `-p wa`: monitora gravações (write) e alterações de atributos (attribute change)
- `-k security-config`: nome da chave para facilitar buscas futuras

## 3. Monitoramento do Comando sudo

Para auditar sempre que alguém utilizar o comando `sudo`:

```bash
sudo auditctl -a always,exit -F arch=b64 -F path=/usr/bin/sudo -F perm=x -k sudo-monitor
```

### Parâmetros Explicados

- `arch=b64`: arquitetura de 64 bits (use `arch=b32` para sistemas 32 bits)
- `perm=x`: execução do binário
- `-k sudo-monitor`: chave para identificação posterior

## 4. Configuração Permanente

Para garantir que as regras sejam restauradas após reinicialização, crie um arquivo de regras:

```bash
sudo nano /etc/audit/rules.d/security-audit.rules
```

Adicione o seguinte conteúdo:

```bash
# Auditoria de alterações em diretórios críticos
-w /etc/security/ -p wa -k security-config
-w /var/log/ -p wa -k system-logs
-w /etc/systemd/ -p wa -k systemd-config

# Auditoria do uso de sudo
-a always,exit -F arch=b64 -F path=/usr/bin/sudo -F perm=x -k sudo-monitor

# Monitoramento de comandos privilegiados
-a always,exit -F arch=b64 -F euid=0 -S execve -k privileged-commands

# Auditoria de alterações em arquivos críticos
-w /etc/passwd -p wa -k user-management
-w /etc/group -p wa -k group-management
-w /etc/shadow -p wa -k password-changes
```

Salve o arquivo e recompile as regras:

```bash
sudo augenrules --load
```

Verifique se as regras foram aplicadas:

```bash
sudo auditctl -l
```

## 5. Consulta de Eventos Registrados

### Consultas por Chave

```bash
# Ver modificações em configurações de segurança
sudo ausearch -k security-config

# Ver comandos executados com sudo
sudo ausearch -k sudo-monitor

# Ver comandos privilegiados
sudo ausearch -k privileged-commands
```

### Consultas por Período

```bash
# Eventos das últimas 24 horas
sudo ausearch -ts yesterday

# Eventos de uma data específica
sudo ausearch -ts 2024-01-15 -te 2024-01-16
```

### Consultas Interpretadas

Para uma saída mais legível:

```bash
sudo ausearch -k sudo-monitor --interpret
```

## 6. Validação do Funcionamento

### Teste de Monitoramento de Arquivos

```bash
# Criar um arquivo de teste
sudo touch /etc/security/teste.txt

# Modificar o arquivo
echo "teste" | sudo tee /etc/security/teste.txt

# Remover o arquivo
sudo rm /etc/security/teste.txt
```

Consulte os logs gerados:

```bash
sudo ausearch -k security-config --interpret
```

### Teste de Monitoramento do sudo

Execute qualquer comando com `sudo` e verifique:

```bash
sudo ls /root
sudo ausearch -k sudo-monitor --interpret
```

## 7. Relatórios e Análise

### Gerar Relatório Resumido

```bash
sudo aureport --summary
```

### Relatório de Comandos Executados

```bash
sudo aureport -x --summary
```

### Relatório de Usuários Mais Ativos

```bash
sudo aureport -u --summary
```

## 8. Configurações Avançadas

### Rotação de Logs

Configure a rotação automática dos logs de auditoria editando:

```bash
sudo nano /etc/audit/auditd.conf
```

Principais configurações:

```bash
# Tamanho máximo do arquivo de log (em MB)
max_log_file = 100

# Ação quando o arquivo atingir o tamanho máximo
max_log_file_action = rotate

# Número de arquivos de rotação a manter
num_logs = 10
```

### Filtros para Reduzir Ruído

Para evitar logs excessivos, adicione filtros:

```bash
# Ignorar comandos específicos (exemplo: ls)
-a never,exit -F arch=b64 -S execve -F exe=/bin/ls

# Ignorar usuários específicos (exemplo: backup)
-a never,exit -F arch=b64 -F auid=1001
```

## 9. Monitoramento de Sistema de Arquivos

### Monitoramento de Arquivos Específicos

```bash
# Monitorar arquivo de hosts
sudo auditctl -w /etc/hosts -p wa -k network-config

# Monitorar crontab do sistema
sudo auditctl -w /etc/crontab -p wa -k scheduled-tasks

# Monitorar SSH configuration
sudo auditctl -w /etc/ssh/sshd_config -p wa -k ssh-config
```

### Monitoramento de Tentativas de Acesso

```bash
# Monitorar tentativas de leitura em arquivos sensíveis
sudo auditctl -w /etc/shadow -p r -k shadow-access

# Monitorar tentativas de acesso a chaves SSH
sudo auditctl -w /root/.ssh/ -p rwa -k ssh-keys
```

## 10. Observações Importantes

### Identificação de Usuários

- O `auid` (Audit User ID) mostrado nos logs representa o usuário real que iniciou a sessão, mesmo que o processo tenha sido executado como root com `sudo`
- O `uid` representa o usuário efetivo no momento da execução

### Performance

- O `auditd` pode impactar a performance do sistema em ambientes com alta atividade
- Monitore o uso de CPU e I/O após a implementação
- Configure filtros adequados para reduzir logs desnecessários

### Segurança

- Proteja os arquivos de configuração do `auditd` contra modificações não autorizadas
- Implemente backup regular dos logs de auditoria
- Esta configuração é essencial para garantir não repúdio e auditoria completa de ações críticas no sistema

### Compatibilidade

Este guia é compatível com as seguintes versões do Ubuntu:
- Ubuntu 18.04 LTS
- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS

## 11. Próximos Passos

### Integração com SIEM

Configure o envio dos logs para sistemas de monitoramento centralizados usando rsyslog ou filebeat.

### Alertas Automáticos

Implemente scripts para alertas em tempo real sobre eventos críticos:

```bash
#!/bin/bash
# Script para monitorar eventos críticos
ausearch -k sudo-monitor --start recent | mail -s "Alerta: Uso de sudo detectado" admin@empresa.com
```

### Análise Forense

Desenvolva procedimentos para investigação de incidentes usando os logs de auditoria, incluindo correlação de eventos e timeline de atividades.

## 12. Troubleshooting

### Problemas Comuns

**Serviço não inicia:**
```bash
sudo systemctl restart auditd
sudo journalctl -u auditd
```

**Regras não são aplicadas:**
```bash
sudo auditctl -D  # Remove todas as regras
sudo augenrules --load  # Recarrega as regras
```

**Logs não são gerados:**
```bash
sudo ausearch -m all  # Verifica se há eventos
sudo tail -f /var/log/audit/audit.log  # Monitora em tempo real
```

### Verificação de Configuração

```bash
# Verificar configuração atual
sudo auditctl -s

# Listar todas as regras ativas
sudo auditctl -l

# Verificar status do daemon
sudo systemctl status auditd
```
