#!/bin/bash

# ===========================================================
# Autor:      George Rodrigues de Oliveira
# GitHub:     https://github.com/georgeroliveira
# Licença:    MIT
# Versão:     2.1 (Multiplataforma + Autocontida)
# Data:       2025-07-30
# Descrição:  Conexão ao Cloud SQL com autenticação humana
# ===========================================================

set -euo pipefail

# === CONFIGURAÇÕES PADRÃO ===
PROJETO_GCP="${1:-plataformagovdigital-gcp-main}"
INSTANCIA_GCP="${2:-plataformagovdigital-gcp-main:southamerica-east1:cluster-postgresql-dev}"
PROXY_VERSION="${3:-v2.16.0}"

# Diretório onde o script está localizado
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_DIR="$SCRIPT_DIR"
PROXY_PATH="$PROXY_DIR/cloud-sql-proxy"

# === DETECTAR PLATAFORMA ===
OS=$(uname)
case "$OS" in
    Darwin)
        PLATFORM="macOS"
        PROXY_URL="https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/${PROXY_VERSION}/cloud-sql-proxy.darwin.amd64"
        ;;
    Linux)
        PLATFORM="Linux"
        PROXY_URL="https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/${PROXY_VERSION}/cloud-sql-proxy.linux.amd64"
        ;;
    *)
        echo "[ERRO] Sistema operacional não suportado: $OS"
        exit 1
        ;;
esac

# === CORES ===
function log() {
    local type="$1"; shift
    local color=""
    case "$type" in
        INFO) color="\033[1;36m";;
        SUCCESS) color="\033[1;32m";;
        WARNING) color="\033[1;33m";;
        ERROR) color="\033[1;31m";;
    esac
    echo -e "${color}[$type] $* \033[0m"
}

# === PRÉ-REQUISITOS ===
function check_prerequisites() {
    log INFO "Verificando pré-requisitos..."
    for cmd in curl unzip bash; do
        if ! command -v $cmd &>/dev/null; then
            log ERROR "Comando '$cmd' não encontrado."
            exit 1
        fi
    done
    log SUCCESS "Pré-requisitos verificados com sucesso."
}

# === INSTALAR GOOGLE CLOUD SDK ===
function install_gcloud_sdk() {
    if command -v gcloud &>/dev/null; then
        log SUCCESS "Google Cloud SDK já está instalado."
        return
    fi

    log INFO "Instalando Google Cloud SDK..."

    if [[ "$PLATFORM" == "macOS" ]]; then
        brew install --cask google-cloud-sdk || {
            log ERROR "Falha ao instalar via Homebrew."
            exit 1
        }
    elif [[ "$PLATFORM" == "Linux" ]]; then
        sudo apt update && sudo apt install -y apt-transport-https ca-certificates gnupg curl
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
          | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
          | gpg --dearmor | sudo tee /usr/share/keyrings/cloud.google.gpg >/dev/null
        sudo apt update && sudo apt install -y google-cloud-sdk
    fi
}

# === LOGIN HUMANO ===
function ensure_human_auth() {
    local active_user
    active_user="$(gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null || true)"
    if [[ -z "$active_user" || "$active_user" == *"compute@"* ]]; then
        log WARNING "Login necessário. Será aberto o navegador para autenticação."
        gcloud auth login
        active_user="$(gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null || true)"
        if [[ -z "$active_user" || "$active_user" == *"compute@"* ]]; then
            log ERROR "A conta ativa ainda não é humana. Repita o login."
            exit 1
        fi
    fi
    log SUCCESS "Conta autenticada: $active_user"
}

# === DEFINIR PROJETO ===
function set_project() {
    log INFO "Verificando se a conta tem acesso ao projeto: $PROJETO_GCP"
    if ! gcloud projects describe "$PROJETO_GCP" &>/dev/null; then
        log ERROR "A conta não tem acesso ao projeto '$PROJETO_GCP'"
        echo -e "Use: gcloud projects list para ver os projetos disponíveis."
        exit 1
    fi
    gcloud config set project "$PROJETO_GCP" &>/dev/null
    log SUCCESS "Projeto GCP definido: $PROJETO_GCP"
}

# === INSTALAR PROXY ===
function install_proxy() {
    mkdir -p "$PROXY_DIR"

    if [[ -x "$PROXY_PATH" ]]; then
        version_installed="$("$PROXY_PATH" --version 2>/dev/null || true)"
        if [[ -n "$version_installed" ]]; then
            log SUCCESS "Cloud SQL Proxy já instalado em: $PROXY_PATH"
            echo -e "Versão instalada: $version_installed"
            return
        else
            log WARNING "Proxy inválido. Reinstalando..."
            rm -f "$PROXY_PATH"
        fi
    fi

    log INFO "Baixando Cloud SQL Proxy: $PROXY_URL"
    curl -Lo "$PROXY_PATH" "$PROXY_URL"
    chmod +x "$PROXY_PATH"
    log SUCCESS "Cloud SQL Proxy instalado com sucesso."
    "$PROXY_PATH" --version
}

# === INICIAR PROXY ===
function start_proxy() {
    log INFO "Iniciando Cloud SQL Proxy para instância: $INSTANCIA_GCP"
    log INFO "Executável: $PROXY_PATH"
    log WARNING "Pressione Ctrl+C para encerrar o proxy."
    "$PROXY_PATH" "$INSTANCIA_GCP" --gcloud-auth
}

# === EXECUÇÃO PRINCIPAL ===
function main() {
    check_prerequisites
    install_gcloud_sdk
    ensure_human_auth
    set_project
    install_proxy
    start_proxy
}

main "$@"
