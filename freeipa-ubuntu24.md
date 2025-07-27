# Instalação do FreeIPA no Ubuntu 24.04 LTS

Compatível com Ubuntu Server 24.04 LTS  
Recomendado para ambientes corporativos, DevOps, governo e educação  
Última atualização: Julho de 2025

## Sumário

1. [Requisitos](#requisitos)
2. [Preparar o sistema](#1-preparar-o-sistema)
3. [Instalar dependências e repositórios](#2-instalar-dependências-e-repositórios)
4. [Instalar o FreeIPA Server](#3-instalar-o-freeipa-server)
5. [Executar o instalador do FreeIPA](#4-executar-o-instalador-do-freeipa)
6. [Acessar a interface Web](#5-acessar-a-interface-web)
7. [Criar usuários e grupos](#6-criar-usuários-e-grupos)
8. [Configurar cliente FreeIPA](#7-configurar-cliente-freeipa)
9. [Dicas de segurança e boas práticas](#8-dicas-de-segurança-e-boas-práticas)
10. [Recursos úteis](#recursos-úteis)

## Requisitos

| Requisito       | Valor sugerido                     |
|-----------------|------------------------------------|
| SO              | Ubuntu Server 24.04 LTS            |
| RAM             | 2 GB mínimo, 4 GB recomendado      |
| CPU             | 2 núcleos mínimo                   |
| Hostname        | FQDN (ex: `ipa.example.local`)     |
| IP fixo         | Sim (não use DHCP dinâmico)        |
| Root ou sudo    | Acesso root ou com sudoers         |

## 1. Preparar o sistema

### Configure o hostname

```bash
sudo hostnamectl set-hostname ipa.example.local
```

### Configure `/etc/hosts`

```bash
sudo nano /etc/hosts
```

Adicione:

```
127.0.0.1       localhost
192.168.0.10    ipa.example.local ipa
```

### Atualize o sistema

```bash
sudo apt update && sudo apt upgrade -y
```

## 2. Instalar dependências e repositórios

O FreeIPA não está nos repositórios oficiais do Ubuntu. Utilizaremos o repositório Debian experimental adaptado para Ubuntu 24.04.

### Instale ferramentas de compilação e dependências

```bash
sudo apt install -y curl wget git build-essential gnupg2 python3-pip
```

### Adicione o repositório da comunidade

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:freipa/ppa -y
sudo apt update
```

Se o PPA não funcionar: como plano B, utilize um container ou VM CentOS/Rocky com suporte nativo ao FreeIPA.

## 3. Instalar o FreeIPA Server

```bash
sudo apt install freeipa-server freeipa-server-dns -y
```

## 4. Executar o instalador do FreeIPA

### Instalação interativa

```bash
sudo ipa-server-install
```

### Instalação automática

```bash
sudo ipa-server-install --unattended \
  --realm=EXAMPLE.LOCAL \
  --domain=example.local \
  --hostname=ipa.example.local \
  --ds-password=SenhaDM123 \
  --admin-password=SenhaAdmin123 \
  --setup-dns --auto-forwarders
```

## 5. Acessar a interface Web

- URL: `https://ipa.example.local`
- Usuário: `admin`
- Senha: definida na instalação

## 6. Criar usuários e grupos

### Criar um usuário

```bash
ipa user-add usuario1 --first=Usuario --last=Um --email=usuario1@example.local --password
```

### Criar um grupo e adicionar o usuário

```bash
ipa group-add devops
ipa group-add-member devops --users=usuario1
```

## 7. Configurar cliente FreeIPA (Ubuntu)

### No cliente

```bash
sudo apt install freeipa-client -y
```

### Instalar cliente

```bash
sudo ipa-client-install --domain=example.local --server=ipa.example.local --realm=EXAMPLE.LOCAL
```

Siga o assistente, insira o `admin` e senha configurados.

## 8. Dicas de segurança e boas práticas

| Ação                     | Comando / Ferramenta         |
|--------------------------|------------------------------|
| Ver status do IPA        | `ipactl status`              |
| Testar login             | `kinit usuario1`             |
| Ver entradas LDAP        | `ipa user-find`              |
| Criar sudo centralizado  | `ipa sudorule-*`             |
| 2FA                      | `ipa otptoken-add`           |
| Backup                   | `ipa-backup`, `ipa-restore`  |
| Replicação HA            | `ipa-replica-install`        |

## Recursos úteis

- Documentação oficial: https://www.freeipa.org/page/Documentation
- Guia de comandos CLI: https://www.freeipa.org/page/V4/CLI
- Comunidade: https://lists.fedoraproject.org/archives/list/freeipa-users@lists.fedorahosted.org/
