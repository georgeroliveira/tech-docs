## 1. Gerar nova chave SSH

```bash
# Gerar chave SSH (recomendado: Ed25519)
ssh-keygen -t ed25519 -C "seu-email@exemplo.com" -f ~/.ssh/github_deploy_key

# Ou RSA (se Ed25519 não for suportado)
ssh-keygen -t rsa -b 4096 -C "seu-email@exemplo.com" -f ~/.ssh/github_deploy_key
```

## 2. Configurar permissões

```bash
# Definir permissões corretas
chmod 600 ~/.ssh/github_deploy_key
chmod 644 ~/.ssh/github_deploy_key.pub
```

## 3. Adicionar chave ao SSH agent

```bash
# Iniciar SSH agent
eval "$(ssh-agent -s)"

# Adicionar chave privada
ssh-add ~/.ssh/github_deploy_key
```

## 4. Adicionar chave pública no GitHub

```bash
# Copiar chave pública
cat ~/.ssh/github_deploy_key.pub
```

**No GitHub:**
1. Vá para: **Settings** → **SSH and GPG keys**
2. Clique em **"New SSH key"**
3. Cole o conteúdo da chave pública
4. Dê um nome descritivo (ex: "Deploy Server")

## 5. Para Deploy Keys (acesso a repositório específico)

**No repositório GitHub:**
1. Vá para: **Settings** → **Deploy keys**
2. Clique em **"Add deploy key"**
3. Cole a chave pública
4. Marque **"Allow write access"** se precisar fazer push

## 6. Testar conexão

```bash
# Testar conexão SSH
ssh -T git@github.com

# Testar com chave específica
ssh -T -i ~/.ssh/github_deploy_key git@github.com
```

## 7. Configurar Git para usar a chave

### Opção A: SSH Config
```bash
# Criar/editar ~/.ssh/config
cat >> ~/.ssh/config << EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_deploy_key
    IdentitiesOnly yes
EOF
```

### Opção B: Git Config
```bash
# Configurar Git para usar SSH
git config --global url."git@github.com:".insteadOf "https://github.com/"

# Ou para repositório específico
git remote set-url origin git@github.com:usuario/repositorio.git
```

## 8. Clone/Deploy do repositório

```bash
# Clonar repositório
git clone git@github.com:usuario/repositorio.git

# Ou alterar remote existente
git remote set-url origin git@github.com:usuario/repositorio.git
```

## Para automação/CI/CD:

### GitHub Actions (usar secrets)
```yaml
# .github/workflows/deploy.yml
- name: Setup SSH
  run: |
    mkdir -p ~/.ssh
    echo "${{ secrets.DEPLOY_KEY }}" > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    ssh-keyscan github.com >> ~/.ssh/known_hosts
```

### Script de deploy
```bash
#!/bin/bash
# deploy.sh

# Usar chave específica para git
export GIT_SSH_COMMAND="ssh -i ~/.ssh/github_deploy_key -o IdentitiesOnly=yes"

# Pull das alterações
cd /caminho/para/projeto
git pull origin main

# Reiniciar serviços se necessário
sudo systemctl restart seu-servico
```

Você está configurando para qual tipo de deploy? (servidor, CI/CD, container, etc.) Posso dar exemplos mais específicos!
