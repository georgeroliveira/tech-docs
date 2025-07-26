# Gerenciamento Seguro de Acesso Administrativo com `sudo` no Ubuntu

##  Objetivo

Padronizar, restringir e auditar o acesso privilegiado (`sudo`) no ambiente Linux, substituindo permissões diretas por uma abordagem segura baseada em grupos, especialmente em ambientes onde não há acesso direto ao console (ex.: VMware, nuvem).

---

## Visão Geral

| Item                         | Prática Recomendada              |
|-----------------------------|----------------------------------|
| Acesso root direto          | Desabilitado ou com senha forte |
| Acesso administrativo       | Via grupo `admin`               |
| Arquivos sudoers individuais| Evitar, exceto para automações  |
| Grupo `sudo`                | Esvaziado, não utilizado        |
| Controle por grupo          | Sim, via `/etc/sudoers.d/`   |

---

##  Etapas de Configuração

### 1. Criar grupo de administradores

```bash
sudo groupadd admin
```

---

### 2. Adicionar usuários confiáveis ao grupo

```bash
sudo usermod -aG admin vmadmin
sudo usermod -aG admin george
```

Verifique os membros do grupo:

```bash
getent group admin
```

---

### 3. Criar arquivo sudoers para o grupo `admin`

Abra o editor seguro:

```bash
sudo visudo -f /etc/sudoers.d/admin
```

#### ➕ Exigir senha:
```sudoers
%admin ALL=(ALL:ALL) ALL
```

####  Sem exigir senha (ex.: automação):
```sudoers
%admin ALL=(ALL) NOPASSWD: ALL
```

Verifique permissões do arquivo:

```bash
sudo chmod 0440 /etc/sudoers.d/admin
```

---

### 4. Testar se o grupo `admin` tem acesso

Com um usuário do grupo `admin`, execute:

```bash
sudo whoami
```

Saída esperada:

```
root
```

---

### 5. (Opcional) Remover usuários do grupo `sudo`

Após validar o acesso com `admin`, limpe o grupo `sudo`:

```bash
sudo gpasswd -d vmadmin sudo
sudo gpasswd -d george sudo
```

---

### 6. (Opcional) Remover arquivos individuais redundantes

Exemplo: `vmadmin` com entrada individual no sudoers

```bash
sudo rm /etc/sudoers.d/vmadmin-nopasswd
```

---

## Observações importantes

- Nunca edite diretamente `/etc/sudoers`. Use sempre `visudo`.
- A diretiva `#includedir /etc/sudoers.d` deve estar no final de `/etc/sudoers`:
  ```bash
  #includedir /etc/sudoers.d
  ```
- O grupo `adm` do sistema **não é para `sudo`**. Ele permite apenas leitura de logs.
- Arquivos dentro de `/etc/sudoers.d/` devem:
  - Ter **nomes sem ponto (`.`)** (ex.: `admin`, não `admin.conf`)
  - Ter permissão **0440** (`-r--r-----`)
- Nunca use subpastas dentro de `/etc/sudoers.d/`

---

## Resultado Final Esperado

| Componente                | Status Esperado                          |
|--------------------------|------------------------------------------|
| Grupo `admin`            | Criado e com usuários confiáveis         |
| Arquivo `/etc/sudoers.d/admin` | Presente, com permissões corretas    |
| Grupo `sudo`             | Esvaziado (opcional)                     |
| Root via sudo            | Disponível apenas para grupo `admin`     |
| Root via SSH             | Desabilitado (exceto emergência)         |

---

## Reversão de segurança (em caso de erro)

Se perder acesso ao `sudo`:
- Ainda pode usar o usuário `root` diretamente **(se o SSH estiver habilitado)** com:

```bash
ssh root@IP
```

- Ou alterar `/etc/sudoers` temporariamente via console (se tiver acesso ao VMware, LiveCD, etc.)

---

## Sugestões para expansão futura

- Criar um grupo `automacao` com `NOPASSWD` só para scripts (Ansible, Veeam, etc.)
- Auditar usuários com acesso root com script agendado (`sudo -l -U nome_usuario`)
- Versão automatizada com Ansible para múltiplos servidores

---

**Autor:** George Oliveira  
**Última atualização:** 2025-07-26  
**Licença:** MIT  
