#!/bin/bash
# Nome do Script: install-xroad-securityserver.sh
# Autor: georgeroliveira
# GitHub: github.com/georgeroliveira
# Licença: MIT
# Versão: 1.2 | Data: 2025-07-27
# Compatível: Ubuntu 20.04/22.04/24.04 (x86_64)
# Descrição: Instalação automatizada do X-Road Security Server single-node com banco local e sistema de cache.

set -euo pipefail

SCRIPT_VERSION="1.2"
SCRIPT_DATE="2025-07-27"
SCRIPT_COMPAT="Ubuntu 20.04/22.04/24.04 (x86_64)"
SCRIPT_DESC="Instalação automatizada do X-Road Security Server single-node com cache"
XROAD_ROLE="Security Server"
XROAD_PACKAGE="xroad-securityserver"
XROAD_KEYRING="/usr/share/keyrings/xroad.gpg"

# Configurações de cache
CACHE_DIR="/var/cache/xroad-installer"
CACHE_PACKAGES_DIR="$CACHE_DIR/packages"
CACHE_GPG_DIR="$CACHE_DIR/gpg"
CACHE_METADATA="$CACHE_DIR/metadata"
CACHE_MAX_AGE_DAYS=7
FORCE_DOWNLOAD=false

show_about() {
    echo "========================================================="
    echo " Script oficial de georgeroliveira"
    echo " GitHub: github.com/georgeroliveira"
    echo " Licença: MIT | Versão $SCRIPT_VERSION | $SCRIPT_DATE"
    echo " Compatível: $SCRIPT_COMPAT"
    echo " Descrição: $SCRIPT_DESC"
    echo "========================================================="
}

show_help() {
    show_about
    echo
    echo "Uso: $0 [--about|--help|--force-download|--clear-cache]"
    echo
    echo "Este script instala e configura o $XROAD_ROLE automaticamente."
    echo
    echo "Opções:"
    echo "  --force-download  Força o download mesmo se existir cache"
    echo "  --clear-cache     Limpa todo o cache antes de iniciar"
    echo "  --about           Mostra informações sobre o script"
    echo "  --help            Mostra esta ajuda"
    echo
    exit 0
}

log() {
    local tipo="$1"; shift
    local msg="$*"
    local cor=""
    case "$tipo" in
        INFO) cor="\033[1;34m";;
        OK)   cor="\033[1;32m";;
        WARN) cor="\033[1;33m";;
        ERRO) cor="\033[1;31m";;
        CACHE) cor="\033[1;36m";;
        *)    cor="";;
    esac
    echo -e "${cor}[$tipo]\033[0m $msg"
}

checar_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log ERRO "Permissão sudo é obrigatória para executar este script."
        exit 1
    fi
}

inicializar_cache() {
    log CACHE "Inicializando sistema de cache..."
    sudo mkdir -p "$CACHE_PACKAGES_DIR" "$CACHE_GPG_DIR" "$CACHE_METADATA"
    sudo chmod 755 "$CACHE_DIR"
    log OK "Diretório de cache criado em: $CACHE_DIR"
}

limpar_cache() {
    log CACHE "Limpando cache..."
    sudo rm -rf "$CACHE_DIR"
    log OK "Cache limpo completamente."
}

verificar_idade_cache() {
    local arquivo="$1"
    if [[ ! -f "$arquivo" ]]; then
        return 1
    fi
    
    local idade_arquivo=$(( ($(date +%s) - $(stat -c %Y "$arquivo")) / 86400 ))
    if [[ $idade_arquivo -gt $CACHE_MAX_AGE_DAYS ]]; then
        log CACHE "Cache expirado (${idade_arquivo} dias). Será atualizado."
        return 1
    fi
    
    log CACHE "Cache válido (${idade_arquivo} dias de idade)."
    return 0
}

salvar_metadados_cache() {
    local tipo="$1"
    local info="$2"
    echo "$(date -Iseconds)|$info" | sudo tee "$CACHE_METADATA/${tipo}.meta" >/dev/null
}

baixar_com_cache() {
    local url="$1"
    local destino="$2"
    local nome_arquivo=$(basename "$url")
    local cache_file="$CACHE_DIR/$nome_arquivo"
    
    if [[ "$FORCE_DOWNLOAD" == "false" ]] && [[ -f "$cache_file" ]] && verificar_idade_cache "$cache_file"; then
        log CACHE "Usando arquivo do cache: $nome_arquivo"
        sudo cp "$cache_file" "$destino"
        return 0
    fi
    
    log CACHE "Baixando arquivo: $nome_arquivo"
    if curl -fsSL "$url" | sudo tee "$cache_file" >/dev/null; then
        sudo cp "$cache_file" "$destino"
        salvar_metadados_cache "download" "$url|$nome_arquivo"
        log OK "Download concluído e salvo no cache."
        return 0
    else
        log ERRO "Falha no download de: $url"
        return 1
    fi
}

configurar_locale() {
    local LOCALE="en_US.UTF-8"
    log INFO "Configurando locale do sistema para $LOCALE..."
    
    # Verificar se locale já está configurado
    if locale -a 2>/dev/null | grep -q "^${LOCALE}$"; then
        log CACHE "Locale $LOCALE já está configurado."
    else
        sudo apt-get update -qq
        sudo apt-get install -y locales software-properties-common curl gnupg
        grep -qxF "LC_ALL=$LOCALE" /etc/environment || \
            echo "LC_ALL=$LOCALE" | sudo tee -a /etc/environment >/dev/null
        sudo locale-gen "$LOCALE"
        sudo update-locale LANG=$LOCALE LC_ALL=$LOCALE
        log OK "Locale configurado."
    fi
}

adicionar_repo_xroad() {
    local CODENAME
    CODENAME="$(lsb_release -sc)"
    local REPO="deb [signed-by=$XROAD_KEYRING] https://artifactory.niis.org/xroad-release-deb $CODENAME-current main"
    local GPG_URL="https://artifactory.niis.org/api/gpg/key/public"
    local CACHE_GPG_FILE="$CACHE_GPG_DIR/xroad-public.gpg"

    log INFO "Configurando repositório X-Road..."

    # Remover configurações antigas
    sudo rm -f "$XROAD_KEYRING" /etc/apt/sources.list.d/xroad.list || true

    # Baixar ou usar chave GPG do cache
    if [[ "$FORCE_DOWNLOAD" == "false" ]] && [[ -f "$CACHE_GPG_FILE" ]] && verificar_idade_cache "$CACHE_GPG_FILE"; then
        log CACHE "Usando chave GPG do cache"
        cat "$CACHE_GPG_FILE" | gpg --dearmor | sudo tee "$XROAD_KEYRING" >/dev/null
    else
        log CACHE "Baixando nova chave GPG"
        curl -fsSL "$GPG_URL" | sudo tee "$CACHE_GPG_FILE" >/dev/null
        cat "$CACHE_GPG_FILE" | gpg --dearmor | sudo tee "$XROAD_KEYRING" >/dev/null
        salvar_metadados_cache "gpg" "$GPG_URL"
    fi

    echo "$REPO" | sudo tee /etc/apt/sources.list.d/xroad.list >/dev/null

    # Atualizar lista de pacotes com cache
    local CACHE_APT_UPDATE="$CACHE_METADATA/apt-update-xroad"
    if [[ "$FORCE_DOWNLOAD" == "false" ]] && [[ -f "$CACHE_APT_UPDATE" ]] && verificar_idade_cache "$CACHE_APT_UPDATE"; then
        log CACHE "Pulando apt-get update (cache recente disponível)"
    else
        sudo apt-get update || {
            log ERRO "Falha ao atualizar repositórios APT."
            exit 1
        }
        touch "$CACHE_APT_UPDATE"
        salvar_metadados_cache "apt-update" "xroad-repo"
    fi

    log OK "Repositório X-Road configurado."
}

cache_pacotes_apt() {
    local pacote="$1"
    local versao
    
    # Verificar se pacote já está instalado
    if dpkg -l "$pacote" 2>/dev/null | grep -q "^ii"; then
        versao=$(dpkg-query -W -f='${Version}' "$pacote" 2>/dev/null)
        log CACHE "Pacote $pacote já instalado (versão: $versao)"
        return 0
    fi
    
    # Verificar cache de pacotes baixados
    local cache_deb=$(find "$CACHE_PACKAGES_DIR" -name "${pacote}_*.deb" -type f 2>/dev/null | head -n1)
    
    if [[ -n "$cache_deb" ]] && [[ "$FORCE_DOWNLOAD" == "false" ]]; then
        log CACHE "Instalando $pacote do cache: $(basename "$cache_deb")"
        sudo dpkg -i "$cache_deb" 2>/dev/null || sudo apt-get install -f -y
        return $?
    fi
    
    # Baixar pacote para o cache
    log CACHE "Baixando $pacote para o cache..."
    (cd "$CACHE_PACKAGES_DIR" && sudo apt-get download "$pacote" 2>/dev/null) || {
        log WARN "Não foi possível baixar $pacote para o cache, instalando diretamente..."
        sudo apt-get install -y "$pacote"
        return $?
    }
    
    # Instalar do cache
    cache_deb=$(find "$CACHE_PACKAGES_DIR" -name "${pacote}_*.deb" -type f 2>/dev/null | head -n1)
    if [[ -n "$cache_deb" ]]; then
        log CACHE "Instalando $pacote do cache recém-baixado"
        sudo dpkg -i "$cache_deb" 2>/dev/null || sudo apt-get install -f -y
        salvar_metadados_cache "package" "$pacote|$(basename "$cache_deb")"
    fi
}

criar_usuario_admin() {
    while true; do
        read -p "Digite o nome do usuário administrador (NÃO use 'xroad'): " ADMIN_USERNAME
        if [[ "$ADMIN_USERNAME" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] && [[ "$ADMIN_USERNAME" != "xroad" ]]; then
            break
        else
            log ERRO "Nome de usuário inválido ou reservado. Tente novamente."
        fi
    done

    if id "$ADMIN_USERNAME" &>/dev/null; then
        log OK "Usuário '$ADMIN_USERNAME' já existe."
        read -p "Deseja definir uma nova senha para '$ADMIN_USERNAME'? (s/N): " resp
        resp=${resp,,}
        if [[ "$resp" =~ ^(s|sim|y|yes)$ ]]; then
            while true; do
                read -s -p "Digite a nova senha para '$ADMIN_USERNAME': " senha
                echo
                read -s -p "Confirme a nova senha: " senha_conf
                echo
                if [[ "$senha" == "$senha_conf" ]] && [[ -n "$senha" ]]; then
                    echo "$ADMIN_USERNAME:$senha" | sudo chpasswd
                    unset senha senha_conf
                    log OK "Senha atualizada para o usuário '$ADMIN_USERNAME'."
                    break
                else
                    log ERRO "Senhas não coincidem ou estão em branco. Tente novamente."
                fi
            done
        else
            log INFO "Mantendo senha atual do usuário '$ADMIN_USERNAME'."
        fi
    else
        log INFO "Criando usuário '$ADMIN_USERNAME'..."
        sudo adduser --gecos "" --disabled-password "$ADMIN_USERNAME"
        while true; do
            read -s -p "Digite a senha para '$ADMIN_USERNAME': " senha
            echo
            read -s -p "Confirme a senha: " senha_conf
            echo
            if [[ "$senha" == "$senha_conf" ]] && [[ -n "$senha" ]]; then
                echo "$ADMIN_USERNAME:$senha" | sudo chpasswd
                unset senha senha_conf
                log OK "Usuário '$ADMIN_USERNAME' criado com senha definida."
                break
            else
                log ERRO "Senhas não coincidem ou estão em branco. Tente novamente."
            fi
        done
    fi
}

instalar_xroad() {
    log INFO "Instalando $XROAD_ROLE..."
    
    # Verificar dependências do Security Server que podem ser cacheadas
    local deps=("postgresql" "postgresql-contrib")
    
    for dep in "${deps[@]}"; do
        if ! dpkg -l "$dep" 2>/dev/null | grep -q "^ii"; then
            log INFO "Instalando dependência: $dep"
            cache_pacotes_apt "$dep"
        fi
    done
    
    # Tentar usar cache primeiro para o pacote principal
    if ! cache_pacotes_apt "$XROAD_PACKAGE"; then
        # Se falhar, instalar normalmente
        sudo apt-get install -y "$XROAD_PACKAGE"
    fi
    
    log OK "Pacote $XROAD_PACKAGE instalado."
}

mostrar_status() {
    log INFO "Status dos serviços X-Road:"
    sudo systemctl list-units "xroad*"
    
    # Mostrar também status de dependências importantes
    log INFO "Status dos serviços relacionados:"
    if systemctl is-active --quiet postgresql; then
        log OK "PostgreSQL está ativo"
    else
        log WARN "PostgreSQL não está ativo"
    fi
}

mostrar_status_cache() {
    log CACHE "Status do cache:"
    if [[ -d "$CACHE_DIR" ]]; then
        local tamanho=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
        local num_arquivos=$(find "$CACHE_DIR" -type f 2>/dev/null | wc -l)
        log CACHE "Localização: $CACHE_DIR"
        log CACHE "Tamanho: $tamanho"
        log CACHE "Arquivos: $num_arquivos"
        log CACHE "Idade máxima: $CACHE_MAX_AGE_DAYS dias"
        
        # Mostrar pacotes no cache
        if [[ -d "$CACHE_PACKAGES_DIR" ]]; then
            local pacotes=$(find "$CACHE_PACKAGES_DIR" -name "*.deb" -type f 2>/dev/null | wc -l)
            if [[ $pacotes -gt 0 ]]; then
                log CACHE "Pacotes .deb em cache: $pacotes"
            fi
        fi
    else
        log CACHE "Cache não inicializado"
    fi
}

verificar_requisitos() {
    log INFO "Verificando requisitos do sistema..."
    
    # Verificar memória RAM (mínimo 4GB recomendado)
    local mem_total=$(awk '/MemTotal/ {print int($2/1024/1024)}' /proc/meminfo)
    if [[ $mem_total -lt 4 ]]; then
        log WARN "Memória RAM: ${mem_total}GB (recomendado: mínimo 4GB)"
    else
        log OK "Memória RAM: ${mem_total}GB"
    fi
    
    # Verificar espaço em disco
    local disk_free=$(df -BG / | awk 'NR==2 {print int($4)}')
    if [[ $disk_free -lt 10 ]]; then
        log WARN "Espaço livre: ${disk_free}GB (recomendado: mínimo 10GB)"
    else
        log OK "Espaço livre: ${disk_free}GB"
    fi
}

main() {
    # Processar argumentos
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --about) show_about; exit 0 ;;
            --help) show_help ;;
            --force-download) FORCE_DOWNLOAD=true; shift ;;
            --clear-cache) 
                checar_sudo
                limpar_cache
                exit 0 
                ;;
            *) 
                log ERRO "Opção desconhecida: $1"
                show_help
                ;;
        esac
    done

    show_about
    checar_sudo
    verificar_requisitos
    inicializar_cache
    mostrar_status_cache
    configurar_locale
    adicionar_repo_xroad
    criar_usuario_admin
    instalar_xroad
    mostrar_status
    log OK "Instalação concluída."
    echo
    log INFO "Acesse a interface web do Security Server: https://$(hostname -f):4000/"
    echo
    log INFO "Guia oficial: https://docs.x-road.global/Manuals/ig-ss_x-road_v6_security_server_installation_guide.html"
    echo
    log INFO "Próximos passos:"
    log INFO "1. Configure o servidor através da interface web"
    log INFO "2. Registre o Security Server no Central Server"
    log INFO "3. Configure os certificados necessários"
    echo
    mostrar_status_cache
}

main "$@"
