#!/bin/bash
# cloudsql_proxy.sh
# Script oficial de georgeroliveira
# github.com/georgeroliveira | MIT License
# Versão: 2.8 | Data: 2025-07-30
# Compatível: macOS, Ubuntu 20.04/22.04/24.04 (x86_64)
# Descrição: Conexão segura ao Cloud SQL (PostgreSQL) com autenticação humana, validação e deploy do Proxy.
# Dependências: curl, lsof, bash, gcloud, brew (macOS)

set -euo pipefail

PROJETO_GCP=""
INSTANCIA_GCP=""
PORTA_LOCAL="5432"
PROXY_VERSION="v2.16.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_PATH="$SCRIPT_DIR/cloud-sql-proxy"
PLATFORM=""
TEMP_DIR=""

log() {
    local tipo="$1"
    shift
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local cor
    case "$tipo" in
        INFO)  cor="\033[1;34m";;
        OK)    cor="\033[1;32m";;
        WARN)  cor="\033[1;33m";;
        ERRO)  cor="\033[1;31m";;
        *)     cor="";;
    esac
    echo -e "${cor}[$timestamp][$tipo]\033[0m $*" >&2
}

show_about() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Script oficial de georgeroliveira"
    echo "  GitHub: github.com/georgeroliveira"
    echo "  Licença: MIT | Versão 2.8 | 2025-07-30"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

[[ "${1:-}" == "--about" || "${1:-}" == "--version" ]] && { show_about; exit 0; }

cleanup() {
    [[ -d "${TEMP_DIR:-}" ]] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

detect_platform() {
    case "$(uname)" in
        Darwin)
            PLATFORM="macOS"
            PROXY_URL="https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/${PROXY_VERSION}/cloud-sql-proxy.darwin.amd64"
            ;;
        Linux)
            PLATFORM="Linux"
            PROXY_URL="https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/${PROXY_VERSION}/cloud-sql-proxy.linux.amd64"
            ;;
        *)
            log ERRO "Sistema operacional não suportado"
            exit 1
            ;;
    esac
    log OK "Plataforma detectada: $PLATFORM"
}

check_dependencies() {
    local deps=("curl" "lsof" "bash")
    local missing=()

    log INFO "Verificando dependências essenciais..."

    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ "${#missing[@]}" -eq 0 ]]; then
        log OK "Todas as dependências estão instaladas"
        return
    fi

    log WARN "Dependências ausentes: ${missing[*]}"

    if [[ "$PLATFORM" == "macOS" ]]; then
        if ! command -v brew &>/dev/null; then
            log ERRO "Homebrew não está instalado. Instale com:"
            echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            exit 1
        fi

        for pkg in "${missing[@]}"; do
            read -rp "Deseja instalar '$pkg' com brew? (s/N): " resp
            if [[ "$resp" =~ ^[sS]$ ]]; then
                brew install "$pkg" || {
                    log ERRO "Falha ao instalar '$pkg' via brew"
                    exit 1
                }
            else
                log ERRO "Instalação cancelada. Dependência '$pkg' não encontrada."
                exit 1
            fi
        done

    elif [[ "$PLATFORM" == "Linux" ]]; then
        if ! command -v sudo &>/dev/null; then
            log ERRO "'sudo' é necessário para instalar pacotes no Linux."
            exit 1
        fi

        for pkg in "${missing[@]}"; do
            read -rp "Deseja instalar '$pkg' com apt? (s/N): " resp
            if [[ "$resp" =~ ^[sS]$ ]]; then
                sudo apt install -y "$pkg" || {
                    log ERRO "Falha ao instalar '$pkg'"
                    exit 1
                }
            else
                log ERRO "Instalação cancelada. Dependência '$pkg' não encontrada."
                exit 1
            fi
        done
    else
        log ERRO "Plataforma não suportada para instalação automática"
        exit 1
    fi

    log OK "Todas as dependências foram instaladas com sucesso"
}

install_gcloud_sdk() {
    if command -v gcloud &>/dev/null; then
        log OK "Google Cloud SDK já instalado"
        return
    fi

    log ERRO "Google Cloud SDK não encontrado. Instale manualmente seguindo a documentação oficial:"
    echo "https://cloud.google.com/sdk/docs/install"
    exit 1
}

definir_projeto() {
    echo
    read -rp "Digite o nome do projeto GCP (ex: govinfra-dev-001): " PROJETO_GCP
    if [[ -z "$PROJETO_GCP" ]]; then
        log ERRO "Projeto não informado"
        exit 1
    fi
}

set_project() {
    if ! gcloud projects describe "$PROJETO_GCP" &>/dev/null; then
        log ERRO "Projeto '$PROJETO_GCP' não encontrado ou sem acesso"
        exit 1
    fi
    gcloud config set project "$PROJETO_GCP" &>/dev/null
    log OK "Projeto GCP definido: $PROJETO_GCP"
}

ensure_human_auth() {
    local active_user
    active_user="$(gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null || true)"
    if [[ -z "$active_user" || "$active_user" == *"compute@"* ]]; then
        log WARN "Login humano necessário. Abrindo navegador..."
        gcloud auth login
        active_user="$(gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null || true)"
        [[ -z "$active_user" || "$active_user" == *"compute@"* ]] && {
            log ERRO "Conta humana não autenticada. Abortando."
            exit 1
        }
    fi
    log OK "Conta autenticada: $active_user"
}

escolher_instancia() {
    echo
    echo "[INFO] Digite a string completa da instância do Cloud SQL no formato:"
    echo "       projeto:regiao:instancia"
    read -rp "Instância Cloud SQL: " INSTANCIA_GCP

    if [[ ! "$INSTANCIA_GCP" =~ ^[a-zA-Z0-9\-]+:[a-z0-9\-]+:[a-zA-Z0-9\-]+$ ]]; then
        log ERRO "Formato inválido. Exemplo: meu-projeto:southamerica-east1:pg-instance"
        exit 1
    fi
    log OK "Instância informada: $INSTANCIA_GCP"
}

verificar_porta() {
    if lsof -i TCP:$PORTA_LOCAL &>/dev/null; then
        log WARN "A porta padrão $PORTA_LOCAL já está em uso."
        lsof -i TCP:$PORTA_LOCAL | head -n 2
        PORTA_LOCAL=$(shuf -i 30000-39999 -n 1)
        log INFO "Usando automaticamente porta alta disponível: $PORTA_LOCAL"
    else
        log OK "Porta padrão $PORTA_LOCAL está livre."
    fi
}

install_proxy() {
    mkdir -p "$SCRIPT_DIR"
    if [[ -x "$PROXY_PATH" ]]; then
        log OK "Cloud SQL Proxy já instalado: $PROXY_PATH"
        "$PROXY_PATH" --version
        return
    fi
    log INFO "Baixando Cloud SQL Proxy..."
    curl -Lo "$PROXY_PATH" "$PROXY_URL"
    chmod +x "$PROXY_PATH"
    log OK "Proxy instalado: $PROXY_PATH"
    "$PROXY_PATH" --version
}

start_proxy() {
    log INFO "Iniciando o Cloud SQL Proxy em 127.0.0.1:$PORTA_LOCAL..."
    "$PROXY_PATH" "$INSTANCIA_GCP" --gcloud-auth --address 127.0.0.1 --port "$PORTA_LOCAL" &
    sleep 2
    show_connection_info
    wait
}

show_connection_info() {
    log OK "Conexão ativa com o banco de dados."
    echo
    echo "Host:     127.0.0.1"
    echo "Porta:    $PORTA_LOCAL"
    echo "Banco:    <nome_banco>"
    echo "Usuário:  <usuario>"
    echo "Senha:    <senha>"
    echo
    log INFO "Use PgAdmin, DBeaver, TablePlus ou terminal:"
    echo "psql -h 127.0.0.1 -U usuario -d nome_banco"
}

main() {
    show_about
    detect_platform
    check_dependencies
    install_gcloud_sdk
    ensure_human_auth
    definir_projeto
    set_project
    escolher_instancia
    verificar_porta
    install_proxy
    start_proxy
}

main "$@"
