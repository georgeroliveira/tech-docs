
#  Instalação do Matomo com Docker Compose – Passo a Passo Completo

>  *Este guia é compatível com Linux, macOS e WSL (Windows Subsystem for Linux).*

---

##  Pré-requisitos

Antes de começar, certifique-se de que você tem:

* Docker instalado
   [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)

* Docker Compose v2 instalado
   [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)

---

##  Passo 1 – Criar estrutura de diretórios

```bash
mkdir -p ~/matomo-docker
cd ~/matomo-docker
```

---

##  Passo 2 – Criar o `docker-compose.yml`

Crie o arquivo:

```bash
nano docker-compose.yml
```

E cole o conteúdo:

```yaml
version: '3.8'

services:
  db:
    image: mariadb:10.6
    container_name: matomo-db
    restart: always
    environment:
      MYSQL_DATABASE: matomo
      MYSQL_USER: matomo
      MYSQL_PASSWORD: matomo_pass
      MYSQL_ROOT_PASSWORD: root_pass
    volumes:
      - db_data:/var/lib/mysql

  matomo:
    image: matomo:latest
    container_name: matomo-app
    restart: always
    depends_on:
      - db
    ports:
      - "8080:80"
    environment:
      MATOMO_DATABASE_HOST: db
      MATOMO_DATABASE_ADAPTER: mysql
      MATOMO_DATABASE_TABLES_PREFIX: matomo_
      MATOMO_DATABASE_USERNAME: matomo
      MATOMO_DATABASE_PASSWORD: matomo_pass
      MATOMO_DATABASE_DBNAME: matomo
    volumes:
      - matomo_data:/var/www/html

volumes:
  db_data:
  matomo_data:
```

Salve com `Ctrl+O` e saia com `Ctrl+X`.

---

##  Passo 3 – Subir os containers

```bash
docker compose up -d
```

Verifique se os containers estão rodando:

```bash
docker ps
```

Você deve ver dois containers: `matomo-app` e `matomo-db`.

---

##  Passo 4 – Acessar a interface do Matomo

Abra seu navegador e acesse:

```
http://localhost:8080
```

---

##  Passo 5 – Concluir a instalação via navegador

Siga os passos na tela:

1. **Welcome to Matomo** – clique em “Next”
2. **System Check** – tudo deve estar verde ✔️
3. **Database Setup**

   * **Database Server**: `db`
   * **Login**: `matomo`
   * **Password**: `matomo_pass`
   * **Database Name**: `matomo`
   * **Table Prefix**: `matomo_`
4. **Super User** – Crie um usuário administrador Matomo
5. **Configure Your First Website** – Cadastre seu primeiro site a ser monitorado
6. **JavaScript Tracking Code** – Copie o código de rastreamento e cole no seu site
7. **Done!**

---

##  Passo 6 – (Opcional) Configurar HTTPS com Nginx e Let's Encrypt

Se quiser acessar via `https://meudominio.com`, você pode:

* Usar Nginx como proxy reverso
* Utilizar Certbot ou Traefik para certificados SSL
* Posso gerar um exemplo para isso se quiser

---

##  Passo 7 – Verificar volumes (persistência de dados)

```bash
docker volume ls
```

Verifique se os volumes `matomo-docker_db_data` e `matomo-docker_matomo_data` foram criados. Eles armazenam o banco e dados da aplicação.

---

##  Passo 8 – Fazer backup dos dados

Você pode fazer backup com:

```bash
docker run --rm -v matomo-docker_db_data:/volume -v $(pwd):/backup alpine tar czf /backup/db_backup.tar.gz -C /volume .  
docker run --rm -v matomo-docker_matomo_data:/volume -v $(pwd):/backup alpine tar czf /backup/matomo_backup.tar.gz -C /volume .
```

---

##  Passo 9 – Parar ou reiniciar o serviço

```bash
docker compose stop
docker compose start
docker compose down   # Remove os containers
```

---

##  Passo 10 – Remover tudo (caso queira resetar)

```bash
docker compose down -v
```

---

## Acesso e Referências

* Painel do Matomo: [http://localhost:8080](http://localhost:8080)
* Site oficial: [https://matomo.org/](https://matomo.org/)
* Documentação Docker: [https://github.com/matomo-org/docker](https://github.com/matomo-org/docker)

---
* um `.env` separado com as variáveis sensíveis
* um proxy com domínio e HTTPS automático (via Nginx + Certbot ou Traefik)

Deseja incluir algum desses?
