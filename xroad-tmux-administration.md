# Tmux e Gerenciamento de Sessão X-Road no Ubuntu

Documentação completa para uso do tmux em ambientes Ubuntu com X-Road, incluindo comandos essenciais, configurações otimizadas e scripts de automação.

## Índice

- [Instalação](#instalação)
- [Comandos Básicos](#comandos-básicos)
- [Configuração](#configuração)
- [Scripts de Automação](#scripts-de-automação)
- [Cenários Práticos](#cenários-práticos)
- [Resolução de Problemas](#resolução-de-problemas)
- [Referências](#referências)

## Instalação

### Instalação do Tmux no Ubuntu

```bash
# Atualizar repositórios
sudo apt update

# Instalar tmux
sudo apt install tmux -y

# Verificar versão instalada
tmux -V
```

### Dependências Adicionais

```bash
# Para monitoramento avançado
sudo apt install htop iotop net-tools -y

# Para análise de logs
sudo apt install multitail ccze -y
```

### Configuração do Ambiente Ubuntu

```bash
# Verificar grupo X-Road
groups $USER | grep -q xroad || echo "Usuário não está no grupo xroad"

# Criar diretórios necessários
mkdir -p ~/.config/tmux
mkdir -p ~/scripts/tmux

# Definir variáveis de ambiente
echo 'export TMUX_TMPDIR=/tmp' >> ~/.bashrc
echo 'export TERM=xterm-256color' >> ~/.bashrc
source ~/.bashrc
```

## Comandos Básicos

### Gerenciamento de Sessões

| Comando | Função |
|---------|--------|
| `tmux new-session -s xroad` | Criar sessão X-Road |
| `tmux attach -t xroad` | Conectar à sessão X-Road |
| `tmux list-sessions` | Listar sessões ativas |
| `tmux kill-session -t xroad` | Encerrar sessão X-Road |
| `tmux detach` | Desconectar mantendo ativa |

### Atalhos de Teclado (Prefix: Ctrl+a)

| Combinação | Função |
|------------|--------|
| `Ctrl+a d` | Desconectar da sessão |
| `Ctrl+a c` | Criar nova janela |
| `Ctrl+a n` | Próxima janela |
| `Ctrl+a p` | Janela anterior |
| `Ctrl+a |` | Dividir painel verticalmente |
| `Ctrl+a -` | Dividir painel horizontalmente |
| `Ctrl+a h/j/k/l` | Navegar entre painéis |

## Configuração

### Arquivo ~/.tmux.conf Otimizado para Ubuntu

```bash
# Criar configuração personalizada
cat > ~/.tmux.conf << 'EOF'
# Configurações básicas para Ubuntu
set -g default-terminal "screen-256color"
set -g history-limit 10000

# Compatibilidade com Ubuntu e systemd
set -g default-command "${SHELL}"

# Prefix mais acessível
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Reload da configuração
bind r source-file ~/.tmux.conf \; display "Configuração recarregada!"

# Navegação entre painéis
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Divisão de painéis
bind | split-window -h
bind - split-window -v

# Status bar para X-Road Ubuntu
set -g status-bg colour235
set -g status-fg colour136
set -g status-left '[Ubuntu-XRoad] #S '
set -g status-right '#H %d/%m %H:%M'
set -g status-left-length 30
set -g status-right-length 50

# Highlight da janela ativa
set -g window-status-current-style 'bg=colour166,fg=colour235'

# Mouse support
set -g mouse on

# Configurações específicas para Ubuntu Server
set -g set-titles on
set -g set-titles-string '#H:#S.#I.#P #W #T'

# Integração com clipboard Ubuntu (se X11 disponível)
if-shell 'test -n "$DISPLAY"' 'bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -selection clipboard"'

# Timeout de segurança
set -g lock-after-time 1800
set -g lock-command 'vlock'
EOF

# Aplicar configuração
tmux source-file ~/.tmux.conf 2>/dev/null || echo "Configuração aplicada para próxima sessão"
```

## Scripts de Automação

### Script de Inicialização X-Road

```bash
# Criar script de inicialização
cat > ~/scripts/tmux/xroad-start.sh << 'EOF'
#!/bin/bash
SESSION_NAME="xroad"

# Verificar Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    echo "Aviso: Script otimizado para Ubuntu"
fi

# Verificar se sessão existe
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    tmux attach -t $SESSION_NAME
    exit 0
fi

# Criar nova sessão
tmux new-session -d -s $SESSION_NAME

# Dashboard principal
tmux rename-window -t $SESSION_NAME:0 'Ubuntu-Dashboard'
tmux send-keys -t $SESSION_NAME:0 'htop' C-m

# Logs X-Road
tmux new-window -t $SESSION_NAME:1 -n 'XRoad-Logs'
tmux send-keys -t $SESSION_NAME:1 'sudo tail -f /var/log/xroad/*.log' C-m

# Serviços
tmux new-window -t $SESSION_NAME:2 -n 'Services'
tmux send-keys -t $SESSION_NAME:2 'watch -n 5 "systemctl status xroad-*"' C-m

# Monitoramento
tmux new-window -t $SESSION_NAME:3 -n 'Monitor'
tmux split-window -h -t $SESSION_NAME:3
tmux send-keys -t $SESSION_NAME:3.0 'iostat -x 2' C-m
tmux send-keys -t $SESSION_NAME:3.1 'ss -tuln | grep xroad' C-m

# Administração
tmux new-window -t $SESSION_NAME:4 -n 'Admin'
tmux send-keys -t $SESSION_NAME:4 'cd /etc/xroad && ls -la' C-m

# Journal logs
tmux new-window -t $SESSION_NAME:5 -n 'Journal'
tmux send-keys -t $SESSION_NAME:5 'sudo journalctl -f -u xroad-*' C-m

# Conectar
tmux select-window -t $SESSION_NAME:0
tmux attach -t $SESSION_NAME
EOF

chmod +x ~/scripts/tmux/xroad-start.sh
```

### Script de Conexão Rápida

```bash
# Criar script de conexão
cat > ~/scripts/tmux/xroad-connect.sh << 'EOF'
#!/bin/bash
SESSION_NAME="xroad"

case "${1:-}" in
    -l|--list)
        tmux list-sessions 2>/dev/null || echo "Nenhuma sessão ativa"
        ;;
    -k|--kill)
        tmux kill-session -t $SESSION_NAME 2>/dev/null && echo "Sessão encerrada" || echo "Sessão não encontrada"
        ;;
    -h|--help)
        echo "Uso: $0 [opções]"
        echo "  -l, --list    Listar sessões"
        echo "  -k, --kill    Encerrar sessão xroad"
        echo "  -h, --help    Mostrar ajuda"
        ;;
    *)
        if tmux has-session -t $SESSION_NAME 2>/dev/null; then
            tmux attach -t $SESSION_NAME
        else
            ~/scripts/tmux/xroad-start.sh
        fi
        ;;
esac
EOF

chmod +x ~/scripts/tmux/xroad-connect.sh
```

### Instalação dos Scripts

```bash
# Copiar para sistema
sudo cp ~/scripts/tmux/xroad-*.sh /usr/local/bin/

# Tornar executáveis
sudo chmod +x /usr/local/bin/xroad-*.sh

# Criar aliases
cat >> ~/.bashrc << 'EOF'
# Aliases para tmux X-Road no Ubuntu
alias xroad-tmux="/usr/local/bin/xroad-connect.sh"
alias xr-tmux="tmux attach -t xroad 2>/dev/null || /usr/local/bin/xroad-start.sh"
EOF

source ~/.bashrc
```

## Cenários Práticos

### Manutenção Programada

```bash
# Criar sessão para manutenção
tmux new-session -d -s manutencao

# Configurar janelas
tmux new-window -t manutencao -n 'backup'
tmux new-window -t manutencao -n 'update'
tmux new-window -t manutencao -n 'test'

# Conectar
tmux attach -t manutencao
```

### Monitoramento 24/7

```bash
# Sessão dedicada para monitoramento
tmux new-session -d -s monitor

# Logs críticos
tmux send-keys -t monitor 'sudo tail -f /var/log/xroad/proxy.log | grep ERROR' C-m

# Recursos do sistema
tmux split-window -h -t monitor
tmux send-keys -t monitor.1 'watch -n 10 "df -h && echo && free -h"' C-m
```

### Desenvolvimento e Debug

```bash
# Sessão para desenvolvimento
tmux new-session -d -s dev

# Logs de desenvolvimento
tmux rename-window -t dev:0 'logs'
tmux send-keys -t dev:0 'sudo tail -f /var/log/xroad/proxy.log' C-m

# Testes
tmux new-window -t dev -n 'tests'
tmux send-keys -t dev:1 'cd /opt/xroad' C-m

# Configurações
tmux new-window -t dev -n 'config'
tmux send-keys -t dev:2 'cd /etc/xroad' C-m
```

## Resolução de Problemas

### Sessão Não Encontrada

```bash
# Verificar se tmux está rodando
pgrep tmux || echo "Tmux não está rodando"

# Listar sessões
tmux list-sessions

# Verificar socket
ls -la /tmp/tmux-*/default 2>/dev/null || echo "Socket não encontrado"
```

### Problemas de Permissão

```bash
# Verificar permissões do socket
namei -l /tmp/tmux-*/

# Corrigir se necessário
sudo chown $(whoami):$(whoami) /tmp/tmux-*/*
```

### Limpeza de Sessões

```bash
# Script de limpeza
cat > ~/scripts/tmux/cleanup.sh << 'EOF'
#!/bin/bash
echo "Limpando sessões órfãs..."
tmux list-sessions 2>/dev/null | grep -v attached | cut -d: -f1 | xargs -I {} tmux kill-session -t {}
echo "Limpeza concluída"
EOF

chmod +x ~/scripts/tmux/cleanup.sh
```

### Debug Avançado

```bash
# Verificar logs do sistema
sudo journalctl -u xroad-tmux --since "1 hour ago" --no-pager

# Status dos serviços X-Road
sudo systemctl is-active xroad-proxy xroad-signer xroad-confclient

# Conectividade
ss -tuln | grep -E "(4001|8080|8443)"

# Configuração tmux
tmux show-options -g | grep -E "(default-terminal|history-limit)"
```

## Comandos de Emergência

### Forçar Desconexão

```bash
# Matar sessão específica
tmux kill-session -t xroad

# Matar todas as sessões
tmux kill-server
```

### Recuperar Sessão

```bash
# Listar disponíveis
tmux list-sessions

# Conectar à última
tmux attach

# Forçar conexão
tmux attach -t xroad -d
```

### Backup de Configuração

```bash
# Fazer backup
cp ~/.tmux.conf ~/.tmux.conf.backup.$(date +%Y%m%d)

# Verificar configuração
tmux show-options -g
```

## Integração com Systemd

### Serviço Automático (Opcional)

```bash
# Criar serviço systemd
sudo tee /etc/systemd/system/xroad-tmux.service << 'EOF'
[Unit]
Description=X-Road Tmux Session para Ubuntu
After=network.target xroad-proxy.service
Wants=xroad-proxy.service

[Service]
Type=forking
User=xroad
Group=xroad
Environment=TERM=xterm-256color
ExecStart=/usr/bin/tmux new-session -d -s xroad
ExecStop=/usr/bin/tmux kill-session -t xroad
Restart=on-failure
RestartSec=5

# Segurança Ubuntu
PrivateTmp=true
ProtectSystem=strict
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# Configurar serviço
sudo systemctl daemon-reload
sudo systemctl enable xroad-tmux.service

# Verificar status
sudo systemctl status xroad-tmux.service --no-pager
```

## Monitoramento

### Script de Monitoramento Ubuntu

```bash
# Criar monitor
cat > ~/scripts/tmux/monitor.sh << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "=== Ubuntu X-Road Monitor - $(date) ==="
    echo
    echo "Sessões tmux:"
    tmux list-sessions 2>/dev/null || echo "Nenhuma sessão ativa"
    echo
    echo "Serviços X-Road:"
    systemctl is-active xroad-* | head -5
    echo
    echo "Recursos:"
    free -m | grep Mem
    df -h /var/log | tail -1
    echo
    sleep 30
done
EOF

chmod +x ~/scripts/tmux/monitor.sh
```

## Resumo de Comandos

| Situação | Comando |
|----------|---------|
| Conectar à sessão xroad | `tmux attach -t xroad` |
| Criar sessão xroad | `tmux new-session -s xroad` |
| Listar sessões | `tmux ls` |
| Desconectar mantendo ativa | `Ctrl+a d` |
| Matar sessão | `tmux kill-session -t xroad` |
| Script de inicialização | `xroad-tmux` |

## Referências

- [Documentação oficial tmux](https://github.com/tmux/tmux/wiki)
- [Manual tmux](https://man.openbsd.org/tmux)
- [X-Road Documentation](https://x-road.global/)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)

---

**Versão:** 1.0 Ubuntu-Specific  
**Compatibilidade:** Ubuntu 18.04 LTS+, Ubuntu 20.04 LTS+, Ubuntu 22.04 LTS+  
**X-Road:** v6.x+ em ambiente Ubuntu  
**Tmux:** 2.6+ (repositórios Ubuntu)  
**Licença:** MIT
